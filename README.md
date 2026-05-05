# HTML to PDF Converter

A simple and efficient CLI tool to convert HTML/XML files or URLs into high-quality PDFs with dynamic sizing, XML deciphering and automated XSLT layouts.

## Features
- **Unified Support:** Seamlessly handles both `.html` and `.xml` files.
- **Smart XSLT Engine:** Automatically applies a professional "Business Clean" layout to XML data if no specific stylesheet is provided.
- **Dynamic Sizing:** Automatically calculates content dimensions to prevent clipping.
- **Data Prettification:** Intelligent CamelCase label splitting and automatic hiding of large encrypted blocks (Signatures/Certificates).
- **Cross-Platform:** Works on Windows, Linux, and macOS (including WSL2).
- **URL & Local File Support:** Convert online content or local markup files easily.
- **Minimal Configuration:** Sensible defaults for high-quality output.

## Installation
### Local Installation
```bash
npm install
```
### Global Installation (Use everywhere)
To use the `wsl-html-pdf` command from any folder on your machine:
```bash
npm install -g .
```

## Usage
### Local Usage
```bash
node index.js <URL, FilePath, or DirectoryPath>
```
### Global Usage (if installed globally)
```bash
wsl-html-pdf <URL, FilePath, or DirectoryPath>
```

## Examples
**Convert a single local XML or HTML file:**
```bash
wsl-html-pdf ./report.xml
```

**Batch Conversion (Entire Directory):**
```bash
wsl-html-pdf ./exports/
```
*It will scan for all .html and .xml files in the folder and create a PDF next to each one.*

**Convert a URL:**
```bash
wsl-html-pdf https://example.com
```

## Prerequisites for WSL2 Users
If you are running this on WSL2, you may need to install the following dependencies. Note that for Ubuntu 24.04+, some packages use the `t64` suffix (e.g., `libasound2t64` instead of `libasound2`).

```bash
sudo apt update && sudo apt install -y libnss3 libatk1.0-0t64 libatk-bridge2.0-0t64 libcups2t64 libdrm2 libxkbcommon0 libxcomposite1 libxdamage1 libxext6 libxfixes3 libxrandr2 libgbm1 libpango-1.0-0 libcairo2 libasound2t64
```
*If you are on an older version of Ubuntu, replace the `t64` packages with their standard names (e.g., `libasound2`).*

## License
Unlicense
