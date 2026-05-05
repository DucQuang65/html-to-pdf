#!/usr/bin/env node

const puppeteer = require('puppeteer');
const path = require('path');
const fs = require('fs');
const { pathToFileURL } = require('url');
const xsltProcessor = require('xslt-processor');
const { Xslt, XmlParser } = xsltProcessor;
/* c8 ignore next 2 */
const xsltEngine = Xslt ? new Xslt() : null;
const xmlParserInstance = XmlParser ? new XmlParser() : null;
const legacyXmlParse = xsltProcessor.xmlParse;
const legacyXsltProcess = xsltProcessor.xsltProcess;
let defaultPuppeteer = puppeteer;

// Convert Windows path to WSL mount point if running in WSL
function normalizePath(p, platform = process.platform) {
    if (platform !== 'win32' && p.match(/^[a-zA-Z]:\\/)) {
        return p.replace(/\\/g, '/').replace(/^([a-zA-Z]):/, (match, p1) => `/mnt/${p1.toLowerCase()}`);
    }
    return p;
}

function getSupportedExtensions() {
    return ['.html', '.htm', '.xml'];
}

function withBaseHref(html, baseHref) {
    const baseTag = `<base href="${baseHref}">`;

    if (/<base\s/i.test(html)) {
        return html;
    }

    if (/<head[^>]*>/i.test(html)) {
        return html.replace(/<head[^>]*>/i, (match) => `${match}${baseTag}`);
    }

    if (/<html[^>]*>/i.test(html)) {
        return html.replace(/<html[^>]*>/i, (match) => `${match}<head>${baseTag}</head>`);
    }

    return `<head>${baseTag}</head>${html}`;
}

function setDefaultPuppeteer(puppeteerLib) {
    defaultPuppeteer = puppeteerLib;
}

function findHtmlFilesRecursive(dirPath) {
    const entries = fs.readdirSync(dirPath, { withFileTypes: true });
    const htmlFiles = [];

    for (const entry of entries) {
        const fullEntryPath = path.join(dirPath, entry.name);

        if (entry.isDirectory()) {
            htmlFiles.push(...findHtmlFilesRecursive(fullEntryPath));
            continue;
        }

        const supportedExtensions = getSupportedExtensions();
        if (entry.isFile() && supportedExtensions.includes(path.extname(entry.name).toLowerCase())) {
            htmlFiles.push(fullEntryPath);
        }
    }

    return htmlFiles;
}

async function convertFile(page, filePath, options = {}) {
    const logger = options.logger || console;
    const defaultXslPath = options.defaultXslPath || path.join(__dirname, 'generic.xsl');
    const xsltEngineInstance = Object.prototype.hasOwnProperty.call(options, 'xsltEngine')
        ? options.xsltEngine
        : xsltEngine;
    const xmlParserInstanceOverride = Object.prototype.hasOwnProperty.call(options, 'xmlParserInstance')
        ? options.xmlParserInstance
        : xmlParserInstance;
    const legacyXmlParseOverride = Object.prototype.hasOwnProperty.call(options, 'legacyXmlParse')
        ? options.legacyXmlParse
        : legacyXmlParse;
    const legacyXsltProcessOverride = Object.prototype.hasOwnProperty.call(options, 'legacyXsltProcess')
        ? options.legacyXsltProcess
        : legacyXsltProcess;
    const fullPath = path.resolve(filePath);
    const targetOutputDir = path.dirname(fullPath);
    const ext = path.extname(fullPath).toLowerCase();
    const baseName = path.basename(fullPath, path.extname(fullPath));
    const fileName = ext === '.xml' ? `${baseName}_xml.pdf` : `${baseName}.pdf`;
    const outputPath = path.join(targetOutputDir, fileName);

    logger.log(`--- Processing: ${path.basename(fullPath)} ---`);
    
    if (ext === '.xml') {
        let xslPath = path.join(targetOutputDir, `${baseName}.xsl`);
        
        if (!fs.existsSync(xslPath) && fs.existsSync(defaultXslPath)) {
            logger.log(`No specific XSL found. Using smart generic fallback (generic.xsl)...`);
            xslPath = defaultXslPath;
        }

        if (fs.existsSync(xslPath)) {
            logger.log(`Applying stylesheet: ${path.basename(xslPath)}...`);
            const xmlContent = fs.readFileSync(fullPath, 'utf8');
            const xslContent = fs.readFileSync(xslPath, 'utf8');
            let htmlContent;

            if (xmlParserInstanceOverride && xsltEngineInstance) {
                const xmlDoc = xmlParserInstanceOverride.xmlParse(xmlContent);
                const xslDoc = xmlParserInstanceOverride.xmlParse(xslContent);
                htmlContent = await xsltEngineInstance.xsltProcess(xmlDoc, xslDoc);
            } else if (legacyXmlParseOverride && legacyXsltProcessOverride) {
                const xmlDoc = legacyXmlParseOverride(xmlContent);
                const xslDoc = legacyXmlParseOverride(xslContent);
                htmlContent = legacyXsltProcessOverride(xmlDoc, xslDoc);
            } else {
                throw new Error('XSLT processor is not available in this environment.');
            }
            const baseHref = pathToFileURL(`${path.resolve(targetOutputDir)}${path.sep}`).href;
            const htmlWithBase = withBaseHref(htmlContent, baseHref);
            await page.setContent(htmlWithBase, { waitUntil: 'networkidle0' });
        } else {
            logger.log(`No XSL stylesheet found. Falling back to native browser rendering...`);
            await page.goto(pathToFileURL(fullPath).href, { waitUntil: 'networkidle0' });
        }
    } else {
        await page.goto(pathToFileURL(fullPath).href, { waitUntil: 'networkidle2' });
    }

    // Get actual dimensions to prevent clipping
    /* c8 ignore next 4 */
    const dimensions = await page.evaluate(() => ({
        width: document.documentElement.scrollWidth,
        height: document.documentElement.scrollHeight
    }));

    await page.pdf({
        path: outputPath,
        width: dimensions.width + 'px',
        height: dimensions.height + 'px',
        printBackground: true,
        preferCSSPageSize: true,
        displayHeaderFooter: false,
        margin: { top: '0', right: '0', bottom: '0', left: '0' }
    });
    logger.log(`✅ Saved: ${outputPath}`);
}

async function runCli(args, options = {}) {
    const logger = options.logger || console;
    const exit = options.exit || process.exit;
    const puppeteerLib = options.puppeteerLib || defaultPuppeteer;
    const platform = options.platform || process.platform;
    const cwd = options.cwd || process.cwd;
    let browser;

    const input = args[2];
    if (!input) {
        logger.error("Usage: wsl-html-pdf <URL|FilePath|DirectoryPath>");
        exit(1);
        return;
    }

    try {
        browser = await puppeteerLib.launch({
            // Required for WSL2 environments without GUI
            args: ['--no-sandbox', '--disable-setuid-sandbox', '--disable-dev-shm-usage', '--disable-gpu', '--allow-file-access-from-files', '--enable-local-file-accesses'],
            executablePath: process.env.PUPPETEER_EXECUTABLE_PATH || undefined
        });
        const page = await browser.newPage();
        
        // Set viewport to standard desktop resolution
        await page.setViewport({ width: 1920, height: 1080 });

        if (input.startsWith('http')) {
            // Process single URL
            await page.goto(input, { waitUntil: 'networkidle2' });
            const pageTitle = await page.title() || 'output';
            const fileName = `${pageTitle.replace(/[/\\?%*:|"<>]/g, '-').trim()}.pdf`;
            const outputPath = path.join(cwd(), fileName);
            
            // For URLs, we might not know dimensions perfectly, fallback to A4 or let page dictate.
            await page.pdf({ 
                path: outputPath, 
                format: 'A4', 
                printBackground: true 
            });
            logger.log(`✅ Saved URL: ${outputPath}`);
            return;
        }

        const normalizedInput = normalizePath(input, platform);
        const fullPath = path.resolve(normalizedInput);

        if (!fs.existsSync(fullPath)) {
            throw new Error(`Path not found: ${fullPath}`);
        }

        const stats = fs.statSync(fullPath);
        if (stats.isDirectory()) {
            // BATCH MODE: Process all HTML/XML files in directory
            const files = findHtmlFilesRecursive(fullPath);
            logger.log(`Found ${files.length} supported files in directory.`);
            
            for (const file of files) {
                await convertFile(page, file, { logger });
            }
            return;
        }

        // Process single local file
        await convertFile(page, fullPath, { logger });
    } catch (error) {
        logger.error("Error:", error.message);
        exit(1);
    } finally {
        if (browser) await browser.close();
    }
}

module.exports = {
    convertFile,
    findHtmlFilesRecursive,
    getSupportedExtensions,
    normalizePath,
    runCli,
    setDefaultPuppeteer,
    withBaseHref
};

/* c8 ignore start */
if (require.main === module) {
    runCli(process.argv);
}
/* c8 ignore stop */
