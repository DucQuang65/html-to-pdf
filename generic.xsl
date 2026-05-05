<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output method="html" encoding="UTF-8" indent="yes"/>

  <!--
    generic.xsl — Business Clean Version
    Excludes technical/signature metadata for a clean human-readable PDF.
  -->

  <xsl:template match="/">
    <html>
      <head>
        <meta charset="UTF-8"/>
        <style>
          body {
            font-family: 'Segoe UI', Arial, sans-serif;
            background: #ffffff;
            color: #1e293b;
            padding: 40px 50px;
            margin: 0;
            font-size: 13px;
            line-height: 1.6;
          }
          .doc { max-width: 820px; margin: 0 auto; }

          .section {
            margin-top: 25px;
            border-top: 2px solid #f1f5f9;
            padding-top: 15px;
          }
          .section-head {
            font-size: 14px;
            font-weight: 700;
            color: #2563eb;
            text-transform: uppercase;
            letter-spacing: 0.5px;
            margin-bottom: 15px;
          }

          .sub-head {
            font-size: 12px;
            font-weight: 700;
            color: #64748b;
            text-transform: uppercase;
            margin: 15px 0 8px 0;
            padding-bottom: 4px;
            border-bottom: 1px solid #f8fafc;
          }

          table.kv {
            width: 100%;
            border-collapse: collapse;
            margin-bottom: 10px;
          }
          table.kv td {
            padding: 8px 0;
            vertical-align: top;
            border-bottom: 1px solid #f8fafc;
          }
          table.kv tr:last-child td { border-bottom: none; }

          td.k {
            width: 220px;
            font-size: 11px;
            font-weight: 600;
            color: #94a3b8;
            text-transform: uppercase;
          }
          td.v {
            font-size: 13px;
            color: #0f172a;
          }
          .empty { color: #cbd5e1; font-style: italic; }

          @media print {
            body { padding: 20px; }
            .section { page-break-inside: avoid; }
          }
        </style>
      </head>
      <body>
        <div class="doc">
          <!-- Document Title -->
          <div style="text-align: center; margin-bottom: 40px;">
            <h1 style="font-size: 20px; text-transform: uppercase; margin: 0;"><xsl:call-template name="humanName"><xsl:with-param name="n" select="local-name(/*)"/></xsl:call-template></h1>
            <div style="height: 2px; width: 60px; background: #2563eb; margin: 15px auto;"></div>
          </div>
          
          <xsl:apply-templates select="/*/*"/>
        </div>
      </body>
    </html>
  </xsl:template>

  <!-- Blacklist Template: Do not render signature and technical nodes -->
  <xsl:template priority="1" match="*[
    contains(local-name(), 'Signature') or 
    contains(local-name(), 'KeyInfo') or 
    contains(local-name(), 'X509') or 
    contains(local-name(), 'Digest') or 
    contains(local-name(), 'SignedInfo') or 
    contains(local-name(), 'Object') or 
    contains(local-name(), 'CKyDTu') or 
    local-name() = 'Signature'
  ]" />

  <!-- Section template -->
  <xsl:template match="*[count(*) > 0]">
    <div class="section">
      <div class="section-head">
        <xsl:call-template name="splitCamel">
          <xsl:with-param name="s" select="local-name()"/>
        </xsl:call-template>
      </div>
      
      <xsl:if test="*[count(*) = 0]">
        <table class="kv">
          <xsl:apply-templates select="*[count(*) = 0]" mode="row"/>
        </table>
      </xsl:if>
      
      <xsl:apply-templates select="*[count(*) > 0]" mode="sub"/>
    </div>
  </xsl:template>

  <!-- Nested groups -->
  <xsl:template match="*[count(*) > 0]" mode="sub">
    <!-- Check if this sub-section is also in blacklist -->
    <xsl:variable name="name" select="local-name()"/>
    <xsl:if test="not(
      contains($name, 'Signature') or 
      contains($name, 'KeyInfo') or 
      contains($name, 'X509') or 
      contains($name, 'CKyDTu')
    )">
      <div class="sub-head">
        <xsl:call-template name="splitCamel">
          <xsl:with-param name="s" select="local-name()"/>
        </xsl:call-template>
      </div>
      <table class="kv">
        <xsl:apply-templates select="*[count(*) = 0]" mode="row"/>
      </table>
      <xsl:apply-templates select="*[count(*) > 0]" mode="sub"/>
    </xsl:if>
  </xsl:template>

  <!-- Leaf node row -->
  <xsl:template match="*[count(*) = 0]" mode="row">
    <!-- Hide extremely long data or signature-related field values -->
    <xsl:if test="string-length(normalize-space(.)) &lt; 200">
      <tr>
        <td class="k">
          <xsl:call-template name="splitCamel">
            <xsl:with-param name="s" select="local-name()"/>
          </xsl:call-template>
        </td>
        <td class="v">
          <xsl:choose>
            <xsl:when test="normalize-space(.) = ''"><span class="empty">—</span></xsl:when>
            <xsl:otherwise><xsl:value-of select="normalize-space(.)"/></xsl:otherwise>
          </xsl:choose>
        </td>
      </tr>
    </xsl:if>
  </xsl:template>

  <!-- Helpers -->
  <xsl:template name="splitCamel">
    <xsl:param name="s"/>
    <xsl:param name="result" select="''"/>
    <xsl:param name="prev"   select="''"/>
    <xsl:choose>
      <xsl:when test="string-length($s) = 0"><xsl:value-of select="$result"/></xsl:when>
      <xsl:otherwise>
        <xsl:variable name="ch" select="substring($s, 1, 1)"/>
        <xsl:variable name="upper" select="'ABCDEFGHIJKLMNOPQRSTUVWXYZ'"/>
        <xsl:variable name="lower" select="'abcdefghijklmnopqrstuvwxyz'"/>
        <xsl:variable name="digits" select="'0123456789'"/>
        <xsl:variable name="space">
          <xsl:if test="((contains($upper, $ch) and contains($lower, $prev)) or (contains($upper or $lower, $ch) and contains($digits, $prev)) or (contains($digits, $ch) and (contains($upper, $prev) or contains($lower, $prev)))) and $result != ''">
            <xsl:text> </xsl:text>
          </xsl:if>
        </xsl:variable>
        <xsl:call-template name="splitCamel">
          <xsl:with-param name="s" select="substring($s, 2)"/><xsl:with-param name="result" select="concat($result, $space, $ch)"/><xsl:with-param name="prev" select="$ch"/>
        </xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="humanName">
    <xsl:param name="n"/>
    <xsl:variable name="repl" select="translate($n, '-_', '  ')"/>
    <xsl:variable name="first" select="substring($repl,1,1)"/>
    <xsl:variable name="rest" select="substring($repl,2)"/>
    <xsl:value-of select="concat(translate($first, 'abcdefghijklmnopqrstuvwxyz', 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'), $rest)"/>
  </xsl:template>

</xsl:stylesheet>
