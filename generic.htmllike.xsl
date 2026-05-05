<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output method="html" encoding="UTF-8" indent="yes"/>

  <xsl:template match="/">
    <html>
      <head>
        <meta charset="UTF-8"/>
        <style>
          body { font-family: 'Segoe UI', Roboto, Arial, sans-serif; background:#f6f8fa; color:#111827; padding:28px; }
          .page { max-width:1050px; margin:0 auto; background:#fff; border-radius:8px; box-shadow:0 8px 24px rgba(16,24,40,0.06); padding:28px; }
          .title { border-bottom:3px solid #0ea5e9; padding-bottom:10px; margin-bottom:18px; }
          .title h1{ margin:0; font-size:20px; color:#0f172a }
          .title .meta{ color:#475569; font-size:12px; margin-top:6px }

          section.block{ margin:16px 0; border:1px solid #e6edf3; border-radius:6px; overflow:hidden }
          section.block .block-head{ background:#fbfdff; padding:12px 16px; border-bottom:1px solid #e6edf3; font-weight:600; color:#0f172a }
          section.block .block-body{ padding:14px 16px }

          table.kv{ width:100%; border-collapse:collapse; }
          table.kv td{ vertical-align:top; padding:8px 6px; }
          table.kv td.label { width:240px; color:#475569; font-weight:700; font-size:12px; text-transform:uppercase }
          table.kv td.value { color:#0b1220; font-size:14px; }
          pre.trunc { background:#f8fafc; padding:8px; border-radius:4px; color:#0b1220; font-family:inherit; white-space:pre-wrap }

          .small { font-size:12px; color:#64748b }
        </style>
      </head>
      <body>
        <div class="page">
          <div class="title">
            <h1>XML — Humanized View</h1>
            <div class="meta">Document: <xsl:value-of select="local-name(/*)"/></div>
          </div>

          <xsl:apply-templates/>
        </div>
      </body>
    </html>
  </xsl:template>

  <!-- Elements that have child elements become blocks -->
  <xsl:template match="*[count(*) > 0]">
    <section class="block">
      <div class="block-head"><xsl:call-template name="humanName"><xsl:with-param name="n" select="local-name()"/></xsl:call-template></div>
      <div class="block-body">
        <!-- Build a table for direct leaf children -->
        <xsl:if test="*[count(*) = 0]">
          <table class="kv">
            <xsl:for-each select="*[count(*) = 0]">
              <tr>
                <td class="label"><xsl:call-template name="humanName"><xsl:with-param name="n" select="local-name()"/></xsl:call-template></td>
                <td class="value">
                  <xsl:choose>
                    <xsl:when test="normalize-space(.) = ''"> <span class="small">(empty)</span> </xsl:when>
                    <xsl:when test="string-length(normalize-space(.)) &gt; 400 and (contains(local-name(), 'Certificate') or contains(local-name(), 'Signature') or contains(local-name(), 'Value'))">
                      <pre class="trunc">{base64 truncated — length: <xsl:value-of select="string-length(normalize-space(.))"/>}</pre>
                    </xsl:when>
                    <xsl:otherwise>
                      <xsl:value-of select="normalize-space(.)"/>
                    </xsl:otherwise>
                  </xsl:choose>
                </td>
              </tr>
            </xsl:for-each>
          </table>
        </xsl:if>

        <!-- Render nested child blocks afterwards -->
        <xsl:for-each select="*[count(*) &gt; 0]">
          <xsl:apply-templates select="."/>
        </xsl:for-each>
      </div>
    </section>
  </xsl:template>

  <!-- Elements that are leaves and not shown in parent table (if called directly) -->
  <xsl:template match="*[count(*) = 0]">
    <table class="kv">
      <tr>
        <td class="label"><xsl:call-template name="humanName"><xsl:with-param name="n" select="local-name()"/></xsl:call-template></td>
        <td class="value">
          <xsl:choose>
            <xsl:when test="normalize-space(.) = ''"> <span class="small">(empty)</span> </xsl:when>
            <xsl:when test="string-length(normalize-space(.)) &gt; 400 and (contains(local-name(), 'Certificate') or contains(local-name(), 'Signature') or contains(local-name(), 'Value'))">
              <pre class="trunc">{base64 truncated — length: <xsl:value-of select="string-length(normalize-space(.))"/>}</pre>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="normalize-space(.)"/>
            </xsl:otherwise>
          </xsl:choose>
        </td>
      </tr>
    </table>
  </xsl:template>

  <!-- Humanize local-name() -->
  <xsl:template name="humanName">
    <xsl:param name="n"/>
    <xsl:variable name="repl" select="translate($n, '-_', '  ')"/>
    <xsl:variable name="first" select="substring($repl,1,1)"/>
    <xsl:variable name="rest" select="substring($repl,2)"/>
    <xsl:value-of select="concat(translate($first, 'abcdefghijklmnopqrstuvwxyz', 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'), $rest)"/>
  </xsl:template>

</xsl:stylesheet>
