<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output method="html" encoding="UTF-8" indent="yes"/>

<xsl:template match="/">
  <html>
  <head>
    <meta charset="UTF-8"/>
    <style>
      :root { --primary: #2563eb; --secondary: #64748b; --bg: #f1f5f9; }
      body { font-family: 'Noto Sans CJK TC', 'Segoe UI', Arial, sans-serif; background: var(--bg); padding: 30px; color: #1e293b; }
      .container { max-width: 1000px; margin: 0 auto; background: white; padding: 30px; border-radius: 8px; box-shadow: 0 4px 6px rgba(0,0,0,0.05); }
      .header { border-bottom: 3px solid var(--primary); margin-bottom: 25px; padding-bottom: 15px; }
      .header h1 { margin: 0; color: var(--primary); font-size: 24px; }
      .meta { font-size: 12px; color: #64748b; margin-top: 5px; }
      .node-container { margin-bottom: 20px; border: 1px solid #e2e8f0; border-radius: 6px; overflow: hidden; }
      .node-header { background: #f8fafc; padding: 10px 15px; border-bottom: 1px solid #e2e8f0; font-weight: bold; color: var(--secondary); font-size: 13px; }
      .node-content { padding: 15px; display: grid; grid-template-columns: repeat(auto-fill, minmax(280px, 1fr)); gap: 15px; }
      .field { display: flex; flex-direction: column; }
      .label { font-size: 11px; color: #94a3b8; font-weight: bold; margin-bottom: 4px; }
      .value { font-size: 15px; color: #1e293b; word-break: break-all; }
      .child-group { grid-column: 1 / -1; margin-top: 10px; }
      .empty { color: #cbd5e1; font-style: italic; }
      pre.value { white-space: pre-wrap; word-break: break-word; background:#f8fafc; padding:8px; border-radius:4px; }
    </style>
  </head>
  <body>
    <div class="container">
      <div class="header">
        <h1>BẢN GIẢI MÃ DỮ LIỆU TỰ ĐỘNG (XML GENERIC VIEW)</h1>
        <p class="meta">Tài liệu: <xsl:value-of select="local-name(/*)"/></p>
      </div>
      <div class="data-wrapper">
        <xsl:apply-templates />
      </div>
    </div>
  </body>
  </html>
</xsl:template>

<!-- Match elements with children -->
<xsl:template match="*[count(*) > 0]">
  <div class="node-container">
    <div class="node-header"><xsl:call-template name="humanName"><xsl:with-param name="n" select="local-name()"/></xsl:call-template></div>
    <div class="node-content">
      <xsl:if test="normalize-space(text()) != ''">
         <div class="field"><span class="label">Nội dung</span><span class="value"><xsl:value-of select="normalize-space(text())"/></span></div>
      </xsl:if>

      <xsl:for-each select="*[count(*) = 0]">
        <xsl:choose>
          <xsl:when test="normalize-space(.) = ''">
            <div class="field"><span class="label"><xsl:call-template name="humanName"><xsl:with-param name="n" select="local-name()"/></xsl:call-template></span><span class="value empty">---</span></div>
          </xsl:when>
          <xsl:when test="string-length(normalize-space(.)) &gt; 300 and (contains(local-name(), 'Certificate') or contains(local-name(), 'Signature') or contains(local-name(), 'Value'))">
            <div class="field"><span class="label"><xsl:call-template name="humanName"><xsl:with-param name="n" select="local-name()"/></xsl:call-template></span>
              <pre class="value">{base64... truncated, length: <xsl:value-of select="string-length(normalize-space(.))"/>}</pre></div>
          </xsl:when>
          <xsl:otherwise>
            <div class="field"><span class="label"><xsl:call-template name="humanName"><xsl:with-param name="n" select="local-name()"/></xsl:call-template></span><span class="value"><xsl:value-of select="normalize-space(.)"/></span></div>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:for-each>

      <div class="child-group">
        <xsl:apply-templates select="*[count(*) > 0]" />
      </div>
    </div>
  </div>
</xsl:template>

<!-- Match leaf elements (Key-Value) -->
<xsl:template match="*[count(*) = 0]">
  <div class="field">
    <span class="label"><xsl:call-template name="humanName"><xsl:with-param name="n" select="local-name()"/></xsl:call-template></span>
    <span class="value">
      <xsl:choose>
        <xsl:when test="normalize-space(.) = ''"><span class="empty">---</span></xsl:when>
        <xsl:when test="string-length(normalize-space(.)) &gt; 300 and (contains(local-name(), 'Certificate') or contains(local-name(), 'Signature') or contains(local-name(), 'Value'))">
          <pre class="value">{base64... truncated, length: <xsl:value-of select="string-length(normalize-space(.))"/>}</pre>
        </xsl:when>
        <xsl:otherwise><xsl:value-of select="normalize-space(.)"/></xsl:otherwise>
      </xsl:choose>
    </span>
  </div>
</xsl:template>

<!-- Helper: humanize element/local-name into nicer label -->
<xsl:template name="humanName">
  <xsl:param name="n"/>
  <xsl:variable name="repl" select="translate($n, '-_', '  ')"/>
  <xsl:variable name="first" select="substring($repl,1,1)"/>
  <xsl:variable name="rest" select="substring($repl,2)"/>
  <xsl:value-of select="concat(translate($first, 'abcdefghijklmnopqrstuvwxyz', 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'), $rest)"/>
</xsl:template>

</xsl:stylesheet>
