create extension plxslt;

CREATE OR REPLACE FUNCTION striptags(xml) RETURNS text
	LANGUAGE xslt
AS $$<?xml version="1.0"?>
<xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns="http://www.w3.org/1999/xhtml"
>

  <xsl:output method="text" omit-xml-declaration="yes"/>

  <xsl:template match="/">
    <xsl:apply-templates/>
  </xsl:template>

</xsl:stylesheet>
$$;
