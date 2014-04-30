<?xml version="1.0" encoding="UTF-8"?>
<!--
  Title: CDA XSL StyleSheet
  Original Filename: cda.xsl 
  Version: 4.1
  Revision History:  08/12/08 Jingdong Li updated
  Revision History:  12/11/09 KH updated
  Revision History:  03/30/10 Jingdong Li updated.
  Revision History:  08/25/10 Jingdong Li updated
  Revision History:  09/17/10 Jingdong Li updated
  Revision History:  01/05/11 Jingdong Li updated
  Revision History:  12/20/13 Daniel Bergquist Added language
  Revision History:  12/20/13 Erik Wrenholt, Daniel Bergquist Cleaner aesthetics
  Revision History:  01/15/14 Daniel Bergquist Fixed a couple of issues selecting office names
  Revision History:  03/17/14 Daniel Bergquist Add encounter location address
  Revision History:  04/06/14 Rick Geimer security hot fixes: Addressed javascript in nonXMLBody/text/reference/@value and non-sanitized copy of all table attributes.
  Revision History:  04/07/14 Rick Geimer more security fixes. Limited copy of only legal CDA table attributes to XHTML output.
  Revision History:  04/07/14 Rick Geimer more security fixes. Fixed some bugs from the hot fix on 4/6 ($uc and $lc swapped during some translates). Added limit-external-images param that defaults to yes. When set to yes, no URIs with colons (protocol URLs) or beginning with double slashes (protocol relative URLs) are allowed in observation media. I'll revise later to add a whitelist capability.
  Revision History:  04/13/14 Rick Geimer more security fixes. Added sandbox attribute to iframe. Added td to the list of elements with restricted table attributes (missed that one previously). Fixed some typos. Cleaned up CSS styles. Merged the table templates since they all use the same code. Fixed a bug with styleCode processing that could result in lost data. Added external-image-whitelist param.
  Specification: ANSI/HL7 CDAR2
-->
<!--
  Fork us at
-->
<!--
  Original version information:
  The current version and documentation are available at http://www.lantanagroup.com/resources/tools/. 
  We welcome feedback and contributions to tools@lantanagroup.com
  The stylesheet is the cumulative work of several developers; the most significant prior milestones were the foundation work from HL7 
  Germany and Finland (Tyylitiedosto) and HL7 US (Calvin Beebe), and the presentation approach from Tony Schaller, medshare GmbH provided at IHIC 2009. 
-->
<!-- LICENSE INFORMATION
  Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License.
  You may obtain a copy of the License at  http://www.apache.org/licenses/LICENSE-2.0 
-->
<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:n1="urn:hl7-org:v3"
                xmlns:in="urn:lantana-com:inline-variable-data">
    <xsl:output method="html" indent="yes" version="4.01" encoding="utf-8" doctype-system="http://www.w3.org/TR/html4/strict.dtd" doctype-public="-//W3C//DTD HTML 4.01//EN"/>
    <xsl:param name="limit-external-images" select="'yes'"/>
    <!-- A vertical bar separated list of URI prefixes, such as "http://www.example.com|https://www.example.com" -->
    <xsl:param name="external-image-whitelist"/>
    <!-- string processing variables -->
    <xsl:variable name="lc" select="'abcdefghijklmnopqrstuvwxyz'" />
    <xsl:variable name="uc" select="'ABCDEFGHIJKLMNOPQRSTUVWXYZ'" />
    <!-- removes the following characters, in addition to line breaks "':;?`{}“”„‚’ -->
    <xsl:variable name="simple-sanitizer-match"><xsl:text>&#10;&#13;&#34;&#39;&#58;&#59;&#63;&#96;&#123;&#125;&#8220;&#8221;&#8222;&#8218;&#8217;</xsl:text></xsl:variable>
    <xsl:variable name="simple-sanitizer-replace" select="'***************'"/>
    <xsl:variable name="javascript-injection-warning">WARNING: Javascript injection attempt detected in source CDA document. Terminating</xsl:variable>
    <xsl:variable name="malicious-content-warning">WARNING: Potentially malicious content found in CDA document.</xsl:variable>

    <!-- global variable title -->
    <xsl:variable name="title">
        <xsl:choose>
            <xsl:when test="string-length(/n1:ClinicalDocument/n1:title)  &gt;= 1">
                <xsl:value-of select="/n1:ClinicalDocument/n1:title"/>
            </xsl:when>
            <xsl:when test="/n1:ClinicalDocument/n1:code/@displayName">
                <xsl:value-of select="/n1:ClinicalDocument/n1:code/@displayName"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>Clinical Document</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <!-- Main -->
    <xsl:template match="/">
        <xsl:apply-templates select="n1:ClinicalDocument"/>
    </xsl:template>
    <!-- produce browser rendered, human readable clinical document -->
    <xsl:template match="n1:ClinicalDocument">
        <html lang="en">
            <head>
                <xsl:comment> Do NOT edit this HTML directly: it was generated via an XSLT transformation from a CDA Release 2 XML document. </xsl:comment>
                <title>
                    <xsl:value-of select="$title"/>
                </title>
                <xsl:call-template name="addCSS"/>
            </head>
            <body>
                <h1 class="h1center">
                    <xsl:value-of select="$title"/>
                </h1>
                <!-- START display top portion of clinical document -->
                <xsl:call-template name="recordTarget"/>
                <xsl:call-template name="documentGeneral"/>
                <xsl:call-template name="documentationOf"/>
                <xsl:call-template name="author"/>
                <xsl:call-template name="componentOf"/>
                <xsl:call-template name="participant"/>
                <xsl:call-template name="dataEnterer"/>
                <xsl:call-template name="authenticator"/>
                <xsl:call-template name="informant"/>
                <xsl:call-template name="informationRecipient"/>
                <xsl:call-template name="legalAuthenticator"/>
                <xsl:call-template name="custodian"/>
                <!-- END display top portion of clinical document -->
                <!-- produce table of contents -->
                <xsl:if test="not(//n1:nonXMLBody)">
                    <xsl:if test="count(/n1:ClinicalDocument/n1:component/n1:structuredBody/n1:component[n1:section]) &gt; 1">
                        <xsl:call-template name="make-tableofcontents"/>
                    </xsl:if>
                </xsl:if>
                <hr align="left" color="#888888" size="2" width="100%"/>
                <!-- produce human readable document content -->
                <xsl:apply-templates select="n1:component/n1:structuredBody|n1:component/n1:nonXMLBody"/>
                <br/>
                <br/>
            </body>
        </html>
    </xsl:template>
    <!-- generate table of contents -->
    <xsl:template name="make-tableofcontents">
        <h2>
            <a name="toc">Table of Contents</a>
        </h2>
        <ul>
            <xsl:for-each select="n1:component/n1:structuredBody/n1:component/n1:section/n1:title">
                <li>
                    <a href="#{generate-id(.)}">
                        <xsl:value-of select="."/>
                    </a>
                </li>
            </xsl:for-each>
        </ul>
    </xsl:template>
    <!-- header elements -->
    <xsl:template name="documentGeneral">
        <table class="header_table">
            <tbody>
                <tr>
                    <td width="20%" class="header_table_label">
                        <span class="td_label">
                            <xsl:text>Document Id</xsl:text>
                        </span>
                    </td>
                    <td class="td_header_role_value">
                        <xsl:call-template name="show-id">
                            <xsl:with-param name="id" select="n1:id"/>
                        </xsl:call-template>
                    </td>
                </tr>
                <tr>
                    <td width="20%" class="header_table_label">
                        <span class="td_label">
                            <xsl:text>Document Created:</xsl:text>
                        </span>
                    </td>
                    <td class="td_header_role_value">
                        <xsl:call-template name="show-time">
                            <xsl:with-param name="datetime" select="n1:effectiveTime"/>
                        </xsl:call-template>
                    </td>
                </tr>
            </tbody>
        </table>
    </xsl:template>
    <!-- confidentiality -->
    <xsl:template name="confidentiality">
        <table class="header_table">
            <tbody>
                <td width="20%" class="header_table_label">
                    <xsl:text>Confidentiality</xsl:text>
                </td>
                <td class="td_header_role_value">
                    <xsl:choose>
                        <xsl:when test="n1:confidentialityCode/@code  = &apos;N&apos;">
                            <xsl:text>Normal</xsl:text>
                        </xsl:when>
                        <xsl:when test="n1:confidentialityCode/@code  = &apos;R&apos;">
                            <xsl:text>Restricted</xsl:text>
                        </xsl:when>
                        <xsl:when test="n1:confidentialityCode/@code  = &apos;V&apos;">
                            <xsl:text>Very restricted</xsl:text>
                        </xsl:when>
                    </xsl:choose>
                    <xsl:if test="n1:confidentialityCode/n1:originalText">
                        <xsl:text> </xsl:text>
                        <xsl:value-of select="n1:confidentialityCode/n1:originalText"/>
                    </xsl:if>
                </td>
            </tbody>
        </table>
    </xsl:template>
    <!-- author -->
    <xsl:template name="author">
        <xsl:if test="n1:author">
            <table class="header_table">
                <tbody>
                    <xsl:for-each select="n1:author/n1:assignedAuthor">
                        <tr>
                            <td width="20%" class="header_table_label">
                                <span class="td_label">
                                    <xsl:text>Author</xsl:text>
                                </span>
                            </td>
                            <td class="td_header_role_value">
                                <xsl:choose>
                                    <xsl:when test="n1:assignedPerson/n1:name">
                                        <xsl:call-template name="show-name">
                                            <xsl:with-param name="name" select="n1:assignedPerson/n1:name"/>
                                        </xsl:call-template>
                                        <xsl:if test="n1:representedOrganization">
                                            <xsl:text>, </xsl:text>
                                            <xsl:call-template name="show-name">
                                                <xsl:with-param name="name" select="n1:representedOrganization/n1:name"/>
                                            </xsl:call-template>
                                        </xsl:if>
                                    </xsl:when>
                                    <xsl:when test="n1:assignedAuthoringDevice/n1:softwareName">
                                        <xsl:value-of select="n1:assignedAuthoringDevice/n1:softwareName"/>
                                    </xsl:when>
                                    <xsl:when test="n1:representedOrganization">
                                        <xsl:call-template name="show-name">
                                            <xsl:with-param name="name" select="n1:representedOrganization/n1:name"/>
                                        </xsl:call-template>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <xsl:for-each select="n1:id">
                                            <xsl:call-template name="show-id">
                                                <xsl:with-param name="id" select="."/>
                                            </xsl:call-template>
                                            <br/>
                                        </xsl:for-each>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </td>
                        </tr>
                        <xsl:if test="n1:addr | n1:telecom">
                            <tr>
                                <td class="header_table_label">
                                    <span class="td_label">Contact info</span>
                                </td>
                                <td class="td_header_role_value">
                                    <xsl:call-template name="show-contactInfo">
                                        <xsl:with-param name="contact" select="."/>
                                    </xsl:call-template>
                                </td>
                            </tr>
                        </xsl:if>
                    </xsl:for-each>
                </tbody>
            </table>
        </xsl:if>
    </xsl:template>
    <!--  authenticator -->
    <xsl:template name="authenticator">
        <xsl:if test="n1:authenticator">
            <table class="header_table">
                <tbody>
                    <tr>
                        <xsl:for-each select="n1:authenticator">
                            <tr>
                                <td width="20%" class="header_table_label">
                                    <span class="td_label">
                                        <xsl:text>Signed </xsl:text>
                                    </span>
                                </td>
                                <td class="td_header_role_value">
                                    <xsl:call-template name="show-name">
                                        <xsl:with-param name="name" select="n1:assignedEntity/n1:assignedPerson/n1:name"/>
                                    </xsl:call-template>
                                    <xsl:text> at </xsl:text>
                                    <xsl:call-template name="show-time">
                                        <xsl:with-param name="datetime" select="n1:time"/>
                                    </xsl:call-template>
                                </td>
                            </tr>
                            <xsl:if test="n1:assignedEntity/n1:addr | n1:assignedEntity/n1:telecom">
                                <tr>
                                    <td class="header_table_label">
                                        <span class="td_label">Contact info</span>
                                    </td>
                                    <td class="td_header_role_value">
                                        <xsl:call-template name="show-contactInfo">
                                            <xsl:with-param name="contact" select="n1:assignedEntity"/>
                                        </xsl:call-template>
                                    </td>
                                </tr>
                            </xsl:if>
                        </xsl:for-each>
                    </tr>
                </tbody>
            </table>
        </xsl:if>
    </xsl:template>
    <!-- legalAuthenticator -->
    <xsl:template name="legalAuthenticator">
        <xsl:if test="n1:legalAuthenticator">
            <table class="header_table">
                <tbody>
                    <tr>
                        <td width="20%" class="header_table_label">
                            <span class="td_label">
                                <xsl:text>Legal authenticator</xsl:text>
                            </span>
                        </td>
                        <td class="td_header_role_value">
                            <xsl:call-template name="show-assignedEntity">
                                <xsl:with-param name="asgnEntity" select="n1:legalAuthenticator/n1:assignedEntity"/>
                            </xsl:call-template>
                            <xsl:text> </xsl:text>
                            <xsl:call-template name="show-sig">
                                <xsl:with-param name="sig" select="n1:legalAuthenticator/n1:signatureCode"/>
                            </xsl:call-template>
                            <xsl:if test="n1:legalAuthenticator/n1:time/@value">
                                <xsl:text> at </xsl:text>
                                <xsl:call-template name="show-time">
                                    <xsl:with-param name="datetime" select="n1:legalAuthenticator/n1:time"/>
                                </xsl:call-template>
                            </xsl:if>
                        </td>
                    </tr>
                    <xsl:if test="n1:legalAuthenticator/n1:assignedEntity/n1:addr | n1:legalAuthenticator/n1:assignedEntity/n1:telecom">
                        <tr>
                            <td class="header_table_label">
                                <span class="td_label">Contact info</span>
                            </td>
                            <td class="td_header_role_value">
                                <xsl:call-template name="show-contactInfo">
                                    <xsl:with-param name="contact" select="n1:legalAuthenticator/n1:assignedEntity"/>
                                </xsl:call-template>
                            </td>
                        </tr>
                    </xsl:if>
                </tbody>
            </table>
        </xsl:if>
    </xsl:template>
    <!-- dataEnterer -->
    <xsl:template name="dataEnterer">
        <xsl:if test="n1:dataEnterer">
            <table class="header_table">
                <tbody>
                    <tr>
                        <td width="20%" class="header_table_label">
                            <span class="td_label">
                                <xsl:text>Entered by</xsl:text>
                            </span>
                        </td>
                        <td class="td_header_role_value">
                            <xsl:call-template name="show-assignedEntity">
                                <xsl:with-param name="asgnEntity" select="n1:dataEnterer/n1:assignedEntity"/>
                            </xsl:call-template>
                        </td>
                    </tr>
                    <xsl:if test="n1:dataEnterer/n1:assignedEntity/n1:addr | n1:dataEnterer/n1:assignedEntity/n1:telecom">
                        <tr>
                            <td class="header_table_label">
                                <span class="td_label">Contact info</span>
                            </td>
                            <td class="td_header_role_value">
                                <xsl:call-template name="show-contactInfo">
                                    <xsl:with-param name="contact" select="n1:dataEnterer/n1:assignedEntity"/>
                                </xsl:call-template>
                            </td>
                        </tr>
                    </xsl:if>
                </tbody>
            </table>
        </xsl:if>
    </xsl:template>
    <!-- componentOf -->
    <xsl:template name="componentOf">
        <xsl:if test="n1:componentOf">
            <table class="header_table">
                <tbody>
                    <xsl:for-each select="n1:componentOf/n1:encompassingEncounter">
                        <xsl:if test="n1:id">
                            <xsl:choose>
                                <xsl:when test="n1:code">
                                    <tr>
                                        <td width="20%" class="header_table_label">
                                            <span class="td_label">
                                                <xsl:text>Encounter Id</xsl:text>
                                            </span>
                                        </td>
                                        <td class="td_header_role_value">
                                            <xsl:call-template name="show-id">
                                                <xsl:with-param name="id" select="n1:id"/>
                                            </xsl:call-template>
                                        </td>
                                    </tr>
                                    <tr>
                                        <td width="15%" class="header_table_label">
                                            <span class="td_label">
                                                <xsl:text>Encounter Type</xsl:text>
                                            </span>
                                        </td>
                                        <td class="td_header_role_value">
                                            <xsl:call-template name="show-code">
                                                <xsl:with-param name="code" select="n1:code"/>
                                            </xsl:call-template>
                                        </td>
                                    </tr>
                                </xsl:when>
                                <xsl:otherwise>
                                    <tr>
                                        <td width="20%" class="header_table_label">
                                            <span class="td_label">
                                                <xsl:text>Encounter Id</xsl:text>
                                            </span>
                                        </td>
                                        <td class="td_header_role_value">
                                            <xsl:call-template name="show-id">
                                                <xsl:with-param name="id" select="n1:id"/>
                                            </xsl:call-template>
                                        </td>
                                    </tr>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:if>
                        <tr>
                            <td width="20%" class="header_table_label">
                                <span class="td_label">
                                    <xsl:text>Encounter Date</xsl:text>
                                </span>
                            </td>
                            <td class="td_header_role_value">
                                <xsl:if test="n1:effectiveTime">
                                    <xsl:choose>
                                        <xsl:when test="n1:effectiveTime/@value">
                                            <xsl:text> at </xsl:text>
                                            <xsl:call-template name="show-time">
                                                <xsl:with-param name="datetime" select="n1:effectiveTime"/>
                                            </xsl:call-template>
                                        </xsl:when>
                                        <xsl:when test="n1:effectiveTime/n1:low">
                                            <xsl:text> From </xsl:text>
                                            <xsl:call-template name="show-time">
                                                <xsl:with-param name="datetime" select="n1:effectiveTime/n1:low"/>
                                            </xsl:call-template>
                                            <xsl:if test="n1:effectiveTime/n1:high">
                                                <xsl:text> to </xsl:text>
                                                <xsl:call-template name="show-time">
                                                    <xsl:with-param name="datetime" select="n1:effectiveTime/n1:high"/>
                                                </xsl:call-template>
                                            </xsl:if>
                                        </xsl:when>
                                    </xsl:choose>
                                </xsl:if>
                            </td>
                        </tr>
                        <xsl:if test="n1:location/n1:healthCareFacility">
                            <tr>
                                <td width="20%" class="header_table_label">
                                    <span class="td_label">
                                        <xsl:text>Encounter Location</xsl:text>
                                    </span>
                                </td>
                                <td class="td_header_role_value">
                                    <xsl:choose>
                                        <xsl:when test="n1:location/n1:healthCareFacility/n1:location/n1:name">
                                            <xsl:call-template name="show-name">
                                                <xsl:with-param name="name" select="n1:location/n1:healthCareFacility/n1:location/n1:name"/>
                                            </xsl:call-template>
                                            <xsl:for-each select="n1:location/n1:serviceProviderOrganization/n1:name">
                                                <xsl:text> of </xsl:text>
                                                <xsl:call-template name="show-name">
                                                    <xsl:with-param name="name" select="n1:location/n1:serviceProviderOrganization/n1:name"/>
                                                </xsl:call-template>
                                            </xsl:for-each>
                                        </xsl:when>
                                        <xsl:when test="n1:location/n1:healthCareFacility/n1:code">
                                            <xsl:call-template name="show-code">
                                                <xsl:with-param name="code" select="n1:location/n1:healthCareFacility/n1:code"/>
                                            </xsl:call-template>
                                        </xsl:when>
                                        <xsl:otherwise>
                                            <xsl:if test="n1:location/n1:healthCareFacility/n1:id">
                                                <xsl:text>id: </xsl:text>
                                                <xsl:for-each select="n1:location/n1:healthCareFacility/n1:id">
                                                    <xsl:call-template name="show-id">
                                                        <xsl:with-param name="id" select="."/>
                                                    </xsl:call-template>
                                                </xsl:for-each>
                                            </xsl:if>
                                        </xsl:otherwise>
                                    </xsl:choose>
                                    <xsl:if test="n1:location/n1:healthCareFacility/n1:location/n1:addr/n1:streetAddressLine[not(@nullFlavor)]">
                                        <br/>
                                            <xsl:call-template name="show-address">
                                                <xsl:with-param name="address" select="n1:location/n1:healthCareFacility/n1:location/n1:addr"/>
                                            </xsl:call-template>
                                    </xsl:if>
                                </td>
                            </tr>
                        </xsl:if>
                        <xsl:if test="n1:responsibleParty">
                            <tr>
                                <td width="20%" class="header_table_label">
                                    <span class="td_label">
                                        <xsl:text>Responsible party</xsl:text>
                                    </span>
                                </td>
                                <td class="td_header_role_value">
                                    <xsl:call-template name="show-assignedEntity">
                                        <xsl:with-param name="asgnEntity" select="n1:responsibleParty/n1:assignedEntity"/>
                                    </xsl:call-template>
                                </td>
                            </tr>
                        </xsl:if>
                        <xsl:if test="n1:responsibleParty/n1:assignedEntity/n1:addr | n1:responsibleParty/n1:assignedEntity/n1:telecom">
                            <tr>
                                <td class="header_table_label">
                                    <span class="td_label">Contact info</span>
                                </td>
                                <td class="td_header_role_value">
                                    <xsl:call-template name="show-contactInfo">
                                        <xsl:with-param name="contact" select="n1:responsibleParty/n1:assignedEntity"/>
                                    </xsl:call-template>
                                </td>
                            </tr>
                        </xsl:if>
                    </xsl:for-each>
                </tbody>
            </table>
        </xsl:if>
    </xsl:template>
    <!-- custodian -->
    <xsl:template name="custodian">
        <xsl:if test="n1:custodian">
            <table class="header_table">
                <tbody>
                    <tr>
                        <td width="20%" class="header_table_label">
                            <span class="td_label">
                                <xsl:text>Document maintained by</xsl:text>
                            </span>
                        </td>
                        <td class="td_header_role_value">
                            <xsl:choose>
                                <xsl:when test="n1:custodian/n1:assignedCustodian/n1:representedCustodianOrganization/n1:name">
                                    <xsl:call-template name="show-name">
                                        <xsl:with-param name="name" select="n1:custodian/n1:assignedCustodian/n1:representedCustodianOrganization/n1:name"/>
                                    </xsl:call-template>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:for-each select="n1:custodian/n1:assignedCustodian/n1:representedCustodianOrganization/n1:id">
                                        <xsl:call-template name="show-id"/>
                                        <xsl:if test="position()!=last()">
                                            <br/>
                                        </xsl:if>
                                    </xsl:for-each>
                                </xsl:otherwise>
                            </xsl:choose>
                        </td>
                    </tr>
                    <xsl:if test="n1:custodian/n1:assignedCustodian/n1:representedCustodianOrganization/n1:addr |             n1:custodian/n1:assignedCustodian/n1:representedCustodianOrganization/n1:telecom">
                        <tr>
                            <td class="header_table_label">
                                <span class="td_label">Contact info</span>
                            </td>
                            <td class="td_header_role_value">
                                <xsl:call-template name="show-contactInfo">
                                    <xsl:with-param name="contact" select="n1:custodian/n1:assignedCustodian/n1:representedCustodianOrganization"/>
                                </xsl:call-template>
                            </td>
                        </tr>
                    </xsl:if>
                </tbody>
            </table>
        </xsl:if>
    </xsl:template>
    <!-- documentationOf -->
    <xsl:template name="documentationOf">
        <xsl:if test="n1:documentationOf">
            <table class="header_table">
                <tbody>
                    <xsl:for-each select="n1:documentationOf">
                        <xsl:if test="n1:serviceEvent/@classCode and n1:serviceEvent/n1:code">
                            <xsl:variable name="displayName">
                                <xsl:call-template name="show-actClassCode">
                                    <xsl:with-param name="clsCode" select="n1:serviceEvent/@classCode"/>
                                </xsl:call-template>
                            </xsl:variable>
                            <xsl:if test="$displayName">
                                <tr>
                                    <td width="20%" class="header_table_label">
                                        <span class="td_label">
                                            <xsl:call-template name="firstCharCaseUp">
                                                <xsl:with-param name="data" select="$displayName"/>
                                            </xsl:call-template>
                                        </span>
                                    </td>
                                    <td class="td_header_role_value">
                                        <xsl:call-template name="show-code">
                                            <xsl:with-param name="code" select="n1:serviceEvent/n1:code"/>
                                        </xsl:call-template>
                                        <xsl:if test="n1:serviceEvent/n1:effectiveTime">
                                            <xsl:choose>
                                                <xsl:when test="n1:serviceEvent/n1:effectiveTime/@value">
                                                    <xsl:text> at </xsl:text>
                                                    <xsl:call-template name="show-time">
                                                        <xsl:with-param name="datetime" select="n1:serviceEvent/n1:effectiveTime"/>
                                                    </xsl:call-template>
                                                </xsl:when>
                                                <xsl:when test="n1:serviceEvent/n1:effectiveTime/n1:low">
                                                    <xsl:text> from </xsl:text>
                                                    <xsl:call-template name="show-time">
                                                        <xsl:with-param name="datetime" select="n1:serviceEvent/n1:effectiveTime/n1:low"/>
                                                    </xsl:call-template>
                                                    <xsl:if test="n1:serviceEvent/n1:effectiveTime/n1:high">
                                                        <xsl:text> to </xsl:text>
                                                        <xsl:call-template name="show-time">
                                                            <xsl:with-param name="datetime" select="n1:serviceEvent/n1:effectiveTime/n1:high"/>
                                                        </xsl:call-template>
                                                    </xsl:if>
                                                </xsl:when>
                                            </xsl:choose>
                                        </xsl:if>
                                    </td>
                                </tr>
                            </xsl:if>
                        </xsl:if>
                        <xsl:for-each select="n1:serviceEvent/n1:performer">
                            <xsl:variable name="displayName">
                                <xsl:call-template name="show-participationType">
                                    <xsl:with-param name="ptype" select="@typeCode"/>
                                </xsl:call-template>
                                <xsl:text> </xsl:text>
                                <xsl:if test="n1:functionCode/@code">
                                    <xsl:call-template name="show-participationFunction">
                                        <xsl:with-param name="pFunction" select="n1:functionCode/@code"/>
                                    </xsl:call-template>
                                </xsl:if>
                            </xsl:variable>
                            <tr>
                                <td width="20%" class="header_table_label">
                                    <span class="td_label">
                                        <xsl:call-template name="firstCharCaseUp">
                                            <xsl:with-param name="data" select="$displayName"/>
                                        </xsl:call-template>
                                    </span>
                                </td>
                                <td class="td_header_role_value">
                                    <xsl:call-template name="show-assignedEntity">
                                        <xsl:with-param name="asgnEntity" select="n1:assignedEntity"/>
                                    </xsl:call-template>
                                    <br/>
                                    <xsl:call-template name="show-contactInfo">
                                        <xsl:with-param name="contact" select="n1:assignedEntity"/>
                                    </xsl:call-template>
                                </td>
                            </tr>
                        </xsl:for-each>
                    </xsl:for-each>
                </tbody>
            </table>
        </xsl:if>
    </xsl:template>
    <!-- inFulfillmentOf -->
    <xsl:template name="inFulfillmentOf">
        <xsl:if test="n1:infulfillmentOf">
            <table class="header_table">
                <tbody>
                    <xsl:for-each select="n1:inFulfillmentOf">
                        <tr>
                            <td width="20%" class="header_table_label">
                                <span class="td_label">
                                    <xsl:text>In fulfillment of</xsl:text>
                                </span>
                            </td>
                            <td class="td_header_role_value">
                                <xsl:for-each select="n1:order">
                                    <xsl:for-each select="n1:id">
                                        <xsl:call-template name="show-id"/>
                                    </xsl:for-each>
                                    <xsl:for-each select="n1:code">
                                        <xsl:text> </xsl:text>
                                        <xsl:call-template name="show-code">
                                            <xsl:with-param name="code" select="."/>
                                        </xsl:call-template>
                                    </xsl:for-each>
                                    <xsl:for-each select="n1:priorityCode">
                                        <xsl:text> </xsl:text>
                                        <xsl:call-template name="show-code">
                                            <xsl:with-param name="code" select="."/>
                                        </xsl:call-template>
                                    </xsl:for-each>
                                </xsl:for-each>
                            </td>
                        </tr>
                    </xsl:for-each>
                </tbody>
            </table>
        </xsl:if>
    </xsl:template>
    <!-- informant -->
    <xsl:template name="informant">
        <xsl:if test="n1:informant">
            <table class="header_table">
                <tbody>
                    <xsl:for-each select="n1:informant">
                        <tr>
                            <td width="20%" class="header_table_label">
                                <span class="td_label">
                                    <xsl:text>Informant</xsl:text>
                                </span>
                            </td>
                            <td class="td_header_role_value">
                                <xsl:if test="n1:assignedEntity">
                                    <xsl:call-template name="show-assignedEntity">
                                        <xsl:with-param name="asgnEntity" select="n1:assignedEntity"/>
                                    </xsl:call-template>
                                </xsl:if>
                                <xsl:if test="n1:relatedEntity">
                                    <xsl:call-template name="show-relatedEntity">
                                        <xsl:with-param name="relatedEntity" select="n1:relatedEntity"/>
                                    </xsl:call-template>
                                </xsl:if>
                            </td>
                        </tr>
                        <xsl:choose>
                            <xsl:when test="n1:assignedEntity/n1:addr | n1:assignedEntity/n1:telecom">
                                <tr>
                                    <td class="header_table_label">
                                        <span class="td_label">Contact info</span>
                                    </td>
                                    <td class="td_header_role_value">
                                        <xsl:if test="n1:assignedEntity">
                                            <xsl:call-template name="show-contactInfo">
                                                <xsl:with-param name="contact" select="n1:assignedEntity"/>
                                            </xsl:call-template>
                                        </xsl:if>
                                    </td>
                                </tr>
                            </xsl:when>
                            <xsl:when test="n1:relatedEntity/n1:addr | n1:relatedEntity/n1:telecom">
                                <tr>
                                    <td class="header_table_label">
                                        <span class="td_label">Contact info</span>
                                    </td>
                                    <td class="td_header_role_value">
                                        <xsl:if test="n1:relatedEntity">
                                            <xsl:call-template name="show-contactInfo">
                                                <xsl:with-param name="contact" select="n1:relatedEntity"/>
                                            </xsl:call-template>
                                        </xsl:if>
                                    </td>
                                </tr>
                            </xsl:when>
                        </xsl:choose>
                    </xsl:for-each>
                </tbody>
            </table>
        </xsl:if>
    </xsl:template>
    <!-- informantionRecipient -->
    <xsl:template name="informationRecipient">
        <xsl:if test="n1:informationRecipient">
            <table class="header_table">
                <tbody>
                    <xsl:for-each select="n1:informationRecipient">
                        <tr>
                            <td width="20%" class="header_table_label">
                                <span class="td_label">
                                    <xsl:text>Information recipient:</xsl:text>
                                </span>
                            </td>
                            <td class="td_header_role_value">
                                <xsl:choose>
                                    <xsl:when test="n1:intendedRecipient/n1:informationRecipient/n1:name">
                                        <xsl:for-each select="n1:intendedRecipient/n1:informationRecipient">
                                            <xsl:call-template name="show-name">
                                                <xsl:with-param name="name" select="n1:name"/>
                                            </xsl:call-template>
                                            <xsl:if test="position() != last()">
                                                <br/>
                                            </xsl:if>
                                        </xsl:for-each>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <xsl:for-each select="n1:intendedRecipient">
                                            <xsl:for-each select="n1:id">
                                                <xsl:call-template name="show-id"/>
                                            </xsl:for-each>
                                            <xsl:if test="position() != last()">
                                                <br/>
                                            </xsl:if>
                                            <br/>
                                        </xsl:for-each>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </td>
                        </tr>
                        <xsl:if test="n1:intendedRecipient/n1:addr | n1:intendedRecipient/n1:telecom">
                            <tr>
                                <td class="header_table_label">
                                    <span class="td_label">Contact info</span>
                                </td>
                                <td class="td_header_role_value">
                                    <xsl:call-template name="show-contactInfo">
                                        <xsl:with-param name="contact" select="n1:intendedRecipient"/>
                                    </xsl:call-template>
                                </td>
                            </tr>
                        </xsl:if>
                    </xsl:for-each>
                </tbody>
            </table>
        </xsl:if>
    </xsl:template>
    <!-- participant -->
    <xsl:template name="participant">
        <xsl:if test="n1:participant">
            <table class="header_table">
                <tbody>
                    <xsl:for-each select="n1:participant">
                        <tr>
                            <td width="20%" class="header_table_label">
                                <xsl:variable name="participtRole">
                                    <xsl:call-template name="translateRoleAssoCode">
                                        <xsl:with-param name="classCode" select="n1:associatedEntity/@classCode"/>
                                        <xsl:with-param name="code" select="n1:associatedEntity/n1:code"/>
                                    </xsl:call-template>
                                </xsl:variable>
                                <xsl:choose>
                                    <xsl:when test="$participtRole">
                                        <span class="td_label">
                                            <xsl:call-template name="firstCharCaseUp">
                                                <xsl:with-param name="data" select="$participtRole"/>
                                            </xsl:call-template>
                                        </span>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <span class="td_label">
                                            <xsl:text>Participant</xsl:text>
                                        </span>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </td>
                            <td class="td_header_role_value">
                                <xsl:if test="n1:functionCode">
                                    <xsl:call-template name="show-code">
                                        <xsl:with-param name="code" select="n1:functionCode"/>
                                    </xsl:call-template>
                                </xsl:if>
                                <xsl:call-template name="show-associatedEntity">
                                    <xsl:with-param name="assoEntity" select="n1:associatedEntity"/>
                                </xsl:call-template>
                                <xsl:if test="n1:time">
                                    <xsl:if test="n1:time/n1:low">
                                        <xsl:text> from </xsl:text>
                                        <xsl:call-template name="show-time">
                                            <xsl:with-param name="datetime" select="n1:time/n1:low"/>
                                        </xsl:call-template>
                                    </xsl:if>
                                    <xsl:if test="n1:time/n1:high">
                                        <xsl:text> to </xsl:text>
                                        <xsl:call-template name="show-time">
                                            <xsl:with-param name="datetime" select="n1:time/n1:high"/>
                                        </xsl:call-template>
                                    </xsl:if>
                                </xsl:if>
                                <xsl:if test="position() != last()">
                                    <br/>
                                </xsl:if>
                            </td>
                        </tr>
                        <xsl:if test="n1:associatedEntity/n1:addr | n1:associatedEntity/n1:telecom">
                            <tr>
                                <td class="header_table_label">
                                    <span class="td_label">
                                        <xsl:text>Contact info</xsl:text>
                                    </span>
                                </td>
                                <td class="td_header_role_value">
                                    <xsl:call-template name="show-contactInfo">
                                        <xsl:with-param name="contact" select="n1:associatedEntity"/>
                                    </xsl:call-template>
                                </td>
                            </tr>
                        </xsl:if>
                    </xsl:for-each>
                </tbody>
            </table>
        </xsl:if>
    </xsl:template>
    <!-- recordTarget -->
    <xsl:template name="recordTarget">
        <table class="header_table">
            <xsl:for-each select="/n1:ClinicalDocument/n1:recordTarget/n1:patientRole">
                <xsl:if test="not(n1:id/@nullFlavor)">
                    <tr>
                        <td width="20%" class="header_table_label">
                            <span class="td_label">
                                <xsl:text>Patient</xsl:text>
                            </span>
                        </td>
                        <td  class="td_header_role_value">
                            <xsl:call-template name="show-name">
                                <xsl:with-param name="name" select="n1:patient/n1:name"/>
                            </xsl:call-template>
                        </td>
                    </tr>
                    <tr>
                        <td width="20%" class="header_table_label">
                            <span class="td_label">
                                <xsl:text>Date of birth</xsl:text>
                            </span>
                        </td>
                        <td class="td_header_role_value">
                            <xsl:call-template name="show-time">
                                <xsl:with-param name="datetime" select="n1:patient/n1:birthTime"/>
                            </xsl:call-template>
                        </td>
                    </tr>
                    <tr>
                        <td width="15%" class="header_table_label">
                            <span class="td_label">
                                <xsl:text>Sex</xsl:text>
                            </span>
                        </td>
                        <td class="td_header_role_value">
                            <xsl:for-each select="n1:patient/n1:administrativeGenderCode">
                                <xsl:call-template name="show-gender"/>
                            </xsl:for-each>
                        </td>
                    </tr>
                    <xsl:if test="n1:patient/n1:raceCode | (n1:patient/n1:ethnicGroupCode)">
                        <tr>
                            <td width="20%" class="header_table_label">
                                <span class="td_label">
                                    <xsl:text>Race</xsl:text>
                                </span>
                            </td>
                            <td class="td_header_role_value">
                                <xsl:choose>
                                    <xsl:when test="n1:patient/n1:raceCode">
                                        <xsl:for-each select="n1:patient/n1:raceCode">
                                            <xsl:call-template name="show-race-ethnicity"/>
                                        </xsl:for-each>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <xsl:text>Information not available</xsl:text>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </td>
                        </tr>
                        <tr>
                            <td class="header_table_label">
                                <span class="td_label">
                                    <xsl:text>Ethnicity</xsl:text>
                                </span>
                            </td>
                            <td class="td_header_role_value">
                                <xsl:choose>
                                    <xsl:when test="n1:patient/n1:ethnicGroupCode">
                                        <xsl:for-each select="n1:patient/n1:ethnicGroupCode">
                                            <xsl:call-template name="show-race-ethnicity"/>
                                        </xsl:for-each>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <xsl:text>Information not available</xsl:text>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </td>
                        </tr>
                    </xsl:if>
                    <xsl:if test="n1:patient/n1:languageCommunication/n1:languageCode">
                      <tr>
                          <td width="20%" class="header_table_label">
                              <span class="td_label">
                                  <xsl:text>Preferred Language</xsl:text>
                              </span>
                          </td>
                          <td width="30%">
                              <xsl:choose>
                                  <xsl:when test="n1:patient/n1:languageCommunication/n1:languageCode">
                                      <xsl:for-each select="n1:patient/n1:languageCommunication/n1:languageCode">
                                          <xsl:call-template name="show-preferred-language"/>
                                      </xsl:for-each>
                                  </xsl:when>
                              </xsl:choose>
                          </td>
                          <td width="15%" class="header_table_label">
                              <span class="td_label">
                              </span>
                          </td>
                          <td>
                          </td>
                      </tr>
                  </xsl:if>
                    <tr>
                        <td class="header_table_label">
                            <span class="td_label">
                                <xsl:text>Contact info</xsl:text>
                            </span>
                        </td>
                        <td class="td_header_role_value">
                            <xsl:call-template name="show-contactInfo">
                                <xsl:with-param name="contact" select="."/>
                            </xsl:call-template>
                        </td>
                    </tr>
                    <tr>
                        <td class="header_table_label">
                            <span class="td_label">Patient IDs</span>
                        </td>
                        <td class="td_header_role_value">
                            <xsl:for-each select="n1:id">
                                <xsl:call-template name="show-id"/>
                                <br/>
                            </xsl:for-each>
                        </td>
                    </tr>
                </xsl:if>
            </xsl:for-each>
        </table>
    </xsl:template>
    <!-- relatedDocument -->
    <xsl:template name="relatedDocument">
        <xsl:if test="n1:relatedDocument">
            <table class="header_table">
                <tbody>
                    <xsl:for-each select="n1:relatedDocument">
                        <tr>
                            <td width="20%" class="header_table_label">
                                <span class="td_label">
                                    <xsl:text>Related document</xsl:text>
                                </span>
                            </td>
                            <td class="td_header_role_value">
                                <xsl:for-each select="n1:parentDocument">
                                    <xsl:for-each select="n1:id">
                                        <xsl:call-template name="show-id"/>
                                        <br/>
                                    </xsl:for-each>
                                </xsl:for-each>
                            </td>
                        </tr>
                    </xsl:for-each>
                </tbody>
            </table>
        </xsl:if>
    </xsl:template>
    <!-- authorization (consent) -->
    <xsl:template name="authorization">
        <xsl:if test="n1:authorization">
            <table class="header_table">
                <tbody>
                    <xsl:for-each select="n1:authorization">
                        <tr>
                            <td width="20%" class="header_table_label">
                                <span class="td_label">
                                    <xsl:text>Consent</xsl:text>
                                </span>
                            </td>
                            <td class="td_header_role_value">
                                <xsl:choose>
                                    <xsl:when test="n1:consent/n1:code">
                                        <xsl:call-template name="show-code">
                                            <xsl:with-param name="code" select="n1:consent/n1:code"/>
                                        </xsl:call-template>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <xsl:call-template name="show-code">
                                            <xsl:with-param name="code" select="n1:consent/n1:statusCode"/>
                                        </xsl:call-template>
                                    </xsl:otherwise>
                                </xsl:choose>
                                <br/>
                            </td>
                        </tr>
                    </xsl:for-each>
                </tbody>
            </table>
        </xsl:if>
    </xsl:template>
    <!-- setAndVersion -->
    <xsl:template name="setAndVersion">
        <xsl:if test="n1:setId and n1:versionNumber">
            <table class="header_table">
                <tbody>
                    <tr>
                        <td class="td_header_role_name">
                            <xsl:text>SetId and Version</xsl:text>
                        </td>
                        <td class="td_header_role_value">
                            <xsl:text>SetId: </xsl:text>
                            <xsl:call-template name="show-id">
                                <xsl:with-param name="id" select="n1:setId"/>
                            </xsl:call-template>
                            <xsl:text>  Version: </xsl:text>
                            <xsl:value-of select="n1:versionNumber/@value"/>
                        </td>
                    </tr>
                </tbody>
            </table>
        </xsl:if>
    </xsl:template>
    <!-- show StructuredBody  -->
    <xsl:template match="n1:component/n1:structuredBody">
        <xsl:for-each select="n1:component/n1:section">
            <xsl:call-template name="section"/>
        </xsl:for-each>
    </xsl:template>
    <!-- show nonXMLBody -->
    <xsl:template match='n1:component/n1:nonXMLBody'>
        <xsl:choose>
            <!-- if there is a reference, use that in an IFRAME -->
            <xsl:when test='n1:text/n1:reference'>
                <xsl:variable name="source" select="string(n1:text/n1:reference/@value)"/>
                <xsl:variable name="lcSource" select="translate($source, $uc, $lc)"/>
                <xsl:variable name="scrubbedSource" select="translate($source, $simple-sanitizer-match, $simple-sanitizer-replace)"/>
                <xsl:message><xsl:value-of select="$source"/>, <xsl:value-of select="$lcSource"/></xsl:message>
                <xsl:choose>
                    <xsl:when test="contains($lcSource,'javascript')">
                        <p><xsl:value-of select="$javascript-injection-warning"/> </p>
                        <xsl:message><xsl:value-of select="$javascript-injection-warning"/></xsl:message>
                    </xsl:when>
                    <xsl:when test="not($source = $scrubbedSource)">
                        <p><xsl:value-of select="$malicious-content-warning"/> </p>
                        <xsl:message><xsl:value-of select="$malicious-content-warning"/></xsl:message>
                    </xsl:when>
                    <xsl:otherwise>
                        <iframe name='nonXMLBody' id='nonXMLBody' WIDTH='80%' HEIGHT='600' src='{$source}' sandbox=""/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:when test='n1:text/@mediaType="text/plain"'>
                <pre><xsl:value-of select='n1:text/text()'/></pre>
            </xsl:when>
            <xsl:otherwise>
                <pre>Cannot display the text</pre>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <!-- top level component/section: display title and text,
      and process any nested component/sections
    -->
    <xsl:template name="section">
        <xsl:call-template name="section-title">
            <xsl:with-param name="title" select="n1:title"/>
        </xsl:call-template>
        <xsl:call-template name="section-author"/>
        <xsl:call-template name="section-text"/>
        <xsl:for-each select="n1:component/n1:section">
            <xsl:call-template name="nestedSection">
                <xsl:with-param name="margin" select="2"/>
            </xsl:call-template>
        </xsl:for-each>
    </xsl:template>
    <!-- top level section title -->
    <xsl:template name="section-title">
        <xsl:param name="title"/>
        <xsl:choose>
            <xsl:when test="count(/n1:ClinicalDocument/n1:component/n1:structuredBody/n1:component[n1:section]) &gt; 1">
                <h3>
                    <a name="{generate-id($title)}" href="#toc">
                        <xsl:value-of select="$title"/>
                    </a>
                </h3>
            </xsl:when>
            <xsl:otherwise>
                <h3>
                    <xsl:value-of select="$title"/>
                </h3>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <!-- section author -->
    <xsl:template name="section-author">
        <xsl:if test="count(n1:author)&gt;0">
            <div style="margin-left : 2em;">
                <b>
                    <xsl:text>Section Author: </xsl:text>
                </b>
                <xsl:for-each select="n1:author/n1:assignedAuthor">
                    <xsl:choose>
                        <xsl:when test="n1:assignedPerson/n1:name">
                            <xsl:call-template name="show-name">
                                <xsl:with-param name="name" select="n1:assignedPerson/n1:name"/>
                            </xsl:call-template>
                            <xsl:if test="n1:representedOrganization">
                                <xsl:text>, </xsl:text>
                                <xsl:call-template name="show-name">
                                    <xsl:with-param name="name" select="n1:representedOrganization/n1:name"/>
                                </xsl:call-template>
                            </xsl:if>
                        </xsl:when>
                        <xsl:when test="n1:assignedAuthoringDevice/n1:softwareName">
                            <xsl:value-of select="n1:assignedAuthoringDevice/n1:softwareName"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:for-each select="n1:id">
                                <xsl:call-template name="show-id"/>
                                <br/>
                            </xsl:for-each>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:for-each>
                <br/>
            </div>
        </xsl:if>
    </xsl:template>
    <!-- top-level section Text   -->
    <xsl:template name="section-text">
        <div>
            <xsl:apply-templates select="n1:text"/>
        </div>
    </xsl:template>
    <!-- nested component/section -->
    <xsl:template name="nestedSection">
        <xsl:param name="margin"/>
        <h4 style="margin-left : {$margin}em;">
            <xsl:value-of select="n1:title"/>
        </h4>
        <div style="margin-left : {$margin}em;">
            <xsl:apply-templates select="n1:text"/>
        </div>
        <xsl:for-each select="n1:component/n1:section">
            <xsl:call-template name="nestedSection">
                <xsl:with-param name="margin" select="2*$margin"/>
            </xsl:call-template>
        </xsl:for-each>
    </xsl:template>
    <!--   paragraph  -->
    <xsl:template match="n1:paragraph">
        <p>
            <xsl:apply-templates/>
        </p>
    </xsl:template>
    <!--   pre format  -->
    <xsl:template match="n1:pre">
        <pre>
            <xsl:apply-templates/>
        </pre>
    </xsl:template>
    <!--   Content w/ deleted text is hidden -->
    <xsl:template match="n1:content[@revised='delete']"/>
    <!--   content  -->
    <xsl:template match="n1:content">
        <span>
            <xsl:apply-templates select="@styleCode"/>
            <xsl:apply-templates/>
        </span>
    </xsl:template>
    <!-- line break -->
    <xsl:template match="n1:br">
        <xsl:element name='br'>
            <xsl:apply-templates/>
        </xsl:element>
    </xsl:template>
    <!--   list  -->
    <xsl:template match="n1:list">
        <xsl:if test="n1:caption">
            <p>
                <b>
                    <xsl:apply-templates select="n1:caption"/>
                </b>
            </p>
        </xsl:if>
        <ul>
            <xsl:for-each select="n1:item">
                <li>
                    <xsl:apply-templates/>
                </li>
            </xsl:for-each>
        </ul>
    </xsl:template>
    <xsl:template match="n1:list[@listType='ordered']">
        <xsl:if test="n1:caption">
            <span style="font-weight:bold; ">
                <xsl:apply-templates select="n1:caption"/>
            </span>
        </xsl:if>
        <ol>
            <xsl:for-each select="n1:item">
                <li>
                    <xsl:apply-templates/>
                </li>
            </xsl:for-each>
        </ol>
    </xsl:template>
    <!--   caption  -->
    <xsl:template match="n1:caption">
        <xsl:apply-templates/>
        <xsl:text>: </xsl:text>
    </xsl:template>
    <!--  Tables   -->
    <!--
    <xsl:template match="n1:table/@*|n1:thead/@*|n1:tfoot/@*|n1:tbody/@*|n1:colgroup/@*|n1:col/@*|n1:tr/@*|n1:th/@*|n1:td/@*">

        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:apply-templates/>
        </xsl:copy>
    </xsl:template>
    -->
    <xsl:variable name="table-elem-attrs">
        <in:tableElems>
            <in:elem name="table">
                <in:attr name="ID"/>
                <in:attr name="language"/>
                <in:attr name="styleCode"/>
                <in:attr name="summary"/>
                <in:attr name="width"/>
                <in:attr name="border"/>
                <in:attr name="frame"/>
                <in:attr name="rules"/>
                <in:attr name="cellspacing"/>
                <in:attr name="cellpadding"/>
            </in:elem>
            <in:elem name="thead">
                <in:attr name="ID"/>
                <in:attr name="language"/>
                <in:attr name="styleCode"/>
                <in:attr name="align"/>
                <in:attr name="char"/>
                <in:attr name="charoff"/>
                <in:attr name="valign"/>
            </in:elem>
            <in:elem name="tfoot">
                <in:attr name="ID"/>
                <in:attr name="language"/>
                <in:attr name="styleCode"/>
                <in:attr name="align"/>
                <in:attr name="char"/>
                <in:attr name="charoff"/>
                <in:attr name="valign"/>
            </in:elem>
            <in:elem name="tbody">
                <in:attr name="ID"/>
                <in:attr name="language"/>
                <in:attr name="styleCode"/>
                <in:attr name="align"/>
                <in:attr name="char"/>
                <in:attr name="charoff"/>
                <in:attr name="valign"/>
            </in:elem>
            <in:elem name="colgroup">
                <in:attr name="ID"/>
                <in:attr name="language"/>
                <in:attr name="styleCode"/>
                <in:attr name="span"/>
                <in:attr name="width"/>
                <in:attr name="align"/>
                <in:attr name="char"/>
                <in:attr name="charoff"/>
                <in:attr name="valign"/>
            </in:elem>
            <in:elem name="col">
                <in:attr name="ID"/>
                <in:attr name="language"/>
                <in:attr name="styleCode"/>
                <in:attr name="span"/>
                <in:attr name="width"/>
                <in:attr name="align"/>
                <in:attr name="char"/>
                <in:attr name="charoff"/>
                <in:attr name="valign"/>
            </in:elem>
            <in:elem name="tr">
                <in:attr name="ID"/>
                <in:attr name="language"/>
                <in:attr name="styleCode"/>
                <in:attr name="align"/>
                <in:attr name="char"/>
                <in:attr name="charoff"/>
                <in:attr name="valign"/>
            </in:elem>
            <in:elem name="th">
                <in:attr name="ID"/>
                <in:attr name="language"/>
                <in:attr name="styleCode"/>
                <in:attr name="abbr"/>
                <in:attr name="axis"/>
                <in:attr name="headers"/>
                <in:attr name="scope"/>
                <in:attr name="rowspan"/>
                <in:attr name="colspan"/>
                <in:attr name="align"/>
                <in:attr name="char"/>
                <in:attr name="charoff"/>
                <in:attr name="valign"/>
            </in:elem>
            <in:elem name="td">
                <in:attr name="ID"/>
                <in:attr name="language"/>
                <in:attr name="styleCode"/>
                <in:attr name="abbr"/>
                <in:attr name="axis"/>
                <in:attr name="headers"/>
                <in:attr name="scope"/>
                <in:attr name="rowspan"/>
                <in:attr name="colspan"/>
                <in:attr name="align"/>
                <in:attr name="char"/>
                <in:attr name="charoff"/>
                <in:attr name="valign"/>
            </in:elem>
        </in:tableElems>
    </xsl:variable>

    <xsl:template name="output-attrs">
        <xsl:variable name="elem-name" select="local-name(.)"/>
        <xsl:for-each select="@*">
            <xsl:variable name="attr-name" select="local-name(.)"/>
            <xsl:variable name="source" select="."/>
            <xsl:variable name="lcSource" select="translate($source, $uc, $lc)"/>
            <xsl:variable name="scrubbedSource" select="translate($source, $simple-sanitizer-match, $simple-sanitizer-replace)"/>
            <xsl:choose>
                <xsl:when test="contains($lcSource,'javascript')">
                    <p><xsl:value-of select="$javascript-injection-warning"/></p>
                    <xsl:message terminate="yes"><xsl:value-of select="$javascript-injection-warning"/></xsl:message>
                </xsl:when>
                <xsl:when test="$attr-name='styleCode'">
                    <xsl:apply-templates select="."/>
                </xsl:when>
                <xsl:when test="not(document('')/xsl:stylesheet/xsl:variable[@name='table-elem-attrs']/in:tableElems/in:elem[@name=$elem-name]/in:attr[@name=$attr-name])">
                    <xsl:message><xsl:value-of select="$attr-name"/> is not legal in <xsl:value-of select="$elem-name"/></xsl:message>
                </xsl:when>
                <xsl:when test="not($source = $scrubbedSource)">
                    <p><xsl:value-of select="$malicious-content-warning"/> </p>
                    <xsl:message><xsl:value-of select="$malicious-content-warning"/></xsl:message>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:copy-of select="."/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>
    </xsl:template>

    <xsl:template match="n1:table | n1:thead | n1:tfoot | n1:tbody | n1:colgroup | n1:col | n1:tr | n1:th | n1:td">
        <xsl:element name="{local-name()}">
            <xsl:if test="name() = 'table'">
                <xsl:attribute name="class">narr_table</xsl:attribute>
            </xsl:if>
            <xsl:if test="name() = 'tr'">
                <xsl:attribute name="class">narr_tr</xsl:attribute>
            </xsl:if>
            <xsl:if test="name() = 'th'">
                <xsl:attribute name="class">narr_th</xsl:attribute>
            </xsl:if>
            <xsl:call-template name="output-attrs"/>
            <xsl:apply-templates/>
        </xsl:element>
    </xsl:template>

    <!--
    <xsl:template match="n1:table">
        <table>
            <xsl:call-template name="output-attrs"/>
            <xsl:apply-templates/>
        </table>
    </xsl:template>
    <xsl:template match="n1:thead">
        <thead>
            <xsl:call-template name="output-attrs"/>
            <xsl:apply-templates/>
        </thead>
    </xsl:template>
    <xsl:template match="n1:tfoot">
        <tfoot>
            <xsl:call-template name="output-attrs"/>
            <xsl:apply-templates/>
        </tfoot>
    </xsl:template>
    <xsl:template match="n1:tbody">
        <tbody>
            <xsl:call-template name="output-attrs"/>
            <xsl:apply-templates/>
        </tbody>
    </xsl:template>
    <xsl:template match="n1:colgroup">
        <colgroup>
            <xsl:call-template name="output-attrs"/>
            <xsl:apply-templates/>
        </colgroup>
    </xsl:template>
    <xsl:template match="n1:col">
        <col>
            <xsl:call-template name="output-attrs"/>
            <xsl:apply-templates/>
        </col>
    </xsl:template>
    <xsl:template match="n1:tr">
        <tr>
            <xsl:call-template name="output-attrs"/>
            <xsl:apply-templates/>
        </tr>
    </xsl:template>
    <xsl:template match="n1:th">
        <th>
            <xsl:call-template name="output-attrs"/>
            <xsl:apply-templates/>
        </th>
    </xsl:template>
    <xsl:template match="n1:td">
        <td>
            <xsl:call-template name="output-attrs"/>
            <xsl:apply-templates/>
        </td>
    </xsl:template>
-->


    <xsl:template match="n1:table/n1:caption">
        <span style="font-weight:bold; ">
            <xsl:apply-templates/>
        </span>
    </xsl:template>
    <!--   RenderMultiMedia
     this currently only handles GIF's and JPEG's.  It could, however,
     be extended by including other image MIME types in the predicate
     and/or by generating <object> or <applet> tag with the correct
     params depending on the media type  @ID  =$imageRef  referencedObject
     -->


    <xsl:template name="check-external-image-whitelist">
        <xsl:param name="current-whitelist"/>
        <xsl:param name="image-uri"/>
        <xsl:choose>
            <xsl:when test="string-length($current-whitelist) &gt; 0">
                <xsl:variable name="whitelist-item">
                    <xsl:choose>
                        <xsl:when test="contains($current-whitelist,'|')">
                            <xsl:value-of select="substring-before($current-whitelist,'|')"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="$current-whitelist"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
                <xsl:choose>
                    <xsl:when test="starts-with($image-uri,$whitelist-item)">
                        <br clear="all"/>
                        <xsl:element name="img">
                            <xsl:attribute name="src"><xsl:value-of select="$image-uri"/></xsl:attribute>
                        </xsl:element>
                        <xsl:message><xsl:value-of select="$image-uri"/> is in the whitelist</xsl:message>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:call-template name="check-external-image-whitelist">
                            <xsl:with-param name="current-whitelist" select="substring-after($current-whitelist,'|')"/>
                            <xsl:with-param name="image-uri" select="$image-uri"/>
                        </xsl:call-template>
                    </xsl:otherwise>
                </xsl:choose>

            </xsl:when>
            <xsl:otherwise>
                <p>WARNING: non-local image found <xsl:value-of select="$image-uri"/>. Removing. If you wish non-local images preserved please set the limit-external-images param to 'no'.</p>
                <xsl:message>WARNING: non-local image found <xsl:value-of select="$image-uri"/>. Removing. If you wish non-local images preserved please set the limit-external-images param to 'no'.</xsl:message>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>


    <xsl:template match="n1:renderMultiMedia">
        <xsl:variable name="imageRef" select="@referencedObject"/>
        <xsl:choose>
            <xsl:when test="//n1:regionOfInterest[@ID=$imageRef]">
                <!-- Here is where the Region of Interest image referencing goes -->
                <xsl:if test="//n1:regionOfInterest[@ID=$imageRef]//n1:observationMedia/n1:value[@mediaType='image/gif' or
 @mediaType='image/jpeg']">
                    <xsl:variable name="image-uri" select="//n1:regionOfInterest[@ID=$imageRef]//n1:observationMedia/n1:value/n1:reference/@value"/>

                    <xsl:choose>
                        <xsl:when test="$limit-external-images='yes' and (contains($image-uri,':') or starts-with($image-uri,'\\'))">
                            <xsl:call-template name="check-external-image-whitelist">
                                <xsl:with-param name="current-whitelist" select="$external-image-whitelist"/>
                                <xsl:with-param name="image-uri" select="$image-uri"/>
                            </xsl:call-template>
                            <!--
                            <p>WARNING: non-local image found <xsl:value-of select="$image-uri"/>. Removing. If you wish non-local images preserved please set the limit-external-images param to 'no'.</p>
                            <xsl:message>WARNING: non-local image found <xsl:value-of select="$image-uri"/>. Removing. If you wish non-local images preserved please set the limit-external-images param to 'no'.</xsl:message>
                            -->
                        </xsl:when>
                        <!--
                        <xsl:when test="$limit-external-images='yes' and starts-with($image-uri,'\\')">
                            <p>WARNING: non-local image found <xsl:value-of select="$image-uri"/></p>
                            <xsl:message>WARNING: non-local image found <xsl:value-of select="$image-uri"/>. Removing. If you wish non-local images preserved please set the limit-external-images param to 'no'.</xsl:message>
                        </xsl:when>
                        -->
                        <xsl:otherwise>
                            <br clear="all"/>
                            <xsl:element name="img">
                                <xsl:attribute name="src"><xsl:value-of select="$image-uri"/></xsl:attribute>
                            </xsl:element>
                        </xsl:otherwise>
                    </xsl:choose>

                </xsl:if>
            </xsl:when>
            <xsl:otherwise>
                <!-- Here is where the direct MultiMedia image referencing goes -->
                <xsl:if test="//n1:observationMedia[@ID=$imageRef]/n1:value[@mediaType='image/gif' or @mediaType='image/jpeg']">
                    <br clear="all"/>
                    <xsl:element name="img">
                        <xsl:attribute name="src"><xsl:value-of select="//n1:observationMedia[@ID=$imageRef]/n1:value/n1:reference/@value"/></xsl:attribute>
                    </xsl:element>
                </xsl:if>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <!--    Stylecode processing
     Supports Bold, Underline and Italics display
     -->
    <xsl:template match="@styleCode">
        <xsl:attribute name="class"><xsl:value-of select="."/></xsl:attribute>
    </xsl:template>
    <!--
    <xsl:template match="//n1:*[@styleCode]">
        <xsl:if test="@styleCode='Bold'">
            <xsl:element name="b">
                <xsl:apply-templates/>
            </xsl:element>
        </xsl:if>
        <xsl:if test="@styleCode='Italics'">
            <xsl:element name="i">
                <xsl:apply-templates/>
            </xsl:element>
        </xsl:if>
        <xsl:if test="@styleCode='Underline'">
            <xsl:element name="u">
                <xsl:apply-templates/>
            </xsl:element>
        </xsl:if>
        <xsl:if test="contains(@styleCode,'Bold') and contains(@styleCode,'Italics') and not (contains(@styleCode, 'Underline'))">
            <xsl:element name="b">
                <xsl:element name="i">
                    <xsl:apply-templates/>
                </xsl:element>
            </xsl:element>
        </xsl:if>
        <xsl:if test="contains(@styleCode,'Bold') and contains(@styleCode,'Underline') and not (contains(@styleCode, 'Italics'))">
            <xsl:element name="b">
                <xsl:element name="u">
                    <xsl:apply-templates/>
                </xsl:element>
            </xsl:element>
        </xsl:if>
        <xsl:if test="contains(@styleCode,'Italics') and contains(@styleCode,'Underline') and not (contains(@styleCode, 'Bold'))">
            <xsl:element name="i">
                <xsl:element name="u">
                    <xsl:apply-templates/>
                </xsl:element>
            </xsl:element>
        </xsl:if>
        <xsl:if test="contains(@styleCode,'Italics') and contains(@styleCode,'Underline') and contains(@styleCode, 'Bold')">
            <xsl:element name="b">
                <xsl:element name="i">
                    <xsl:element name="u">
                        <xsl:apply-templates/>
                    </xsl:element>
                </xsl:element>
            </xsl:element>
        </xsl:if>
        <xsl:if test="not (contains(@styleCode,'Italics') or contains(@styleCode,'Underline') or contains(@styleCode, 'Bold'))">
            <xsl:apply-templates/>
        </xsl:if>
    </xsl:template>
    -->
    <!--    Superscript or Subscript   -->
    <xsl:template match="n1:sup">
        <xsl:element name="sup">
            <xsl:apply-templates/>
        </xsl:element>
    </xsl:template>
    <xsl:template match="n1:sub">
        <xsl:element name="sub">
            <xsl:apply-templates/>
        </xsl:element>
    </xsl:template>
    <!-- show-signature -->
    <xsl:template name="show-sig">
        <xsl:param name="sig"/>
        <xsl:choose>
            <xsl:when test="$sig/@code =&apos;S&apos;">
                <xsl:text>signed</xsl:text>
            </xsl:when>
            <xsl:when test="$sig/@code=&apos;I&apos;">
                <xsl:text>intended</xsl:text>
            </xsl:when>
            <xsl:when test="$sig/@code=&apos;X&apos;">
                <xsl:text>signature required</xsl:text>
            </xsl:when>
        </xsl:choose>
    </xsl:template>
    <!--  show-id -->
    <xsl:template name="show-id">
        <xsl:param name="id" select="."/>
        <xsl:choose>
            <xsl:when test="not($id)">
                <xsl:if test="not(@nullFlavor)">
                    <xsl:if test="@extension">
                        <xsl:value-of select="@extension"/>
                    </xsl:if>
                    <xsl:text> </xsl:text>
                    <xsl:value-of select="@root"/>
                </xsl:if>
            </xsl:when>
            <xsl:otherwise>
                <xsl:if test="not($id/@nullFlavor)">
                    <xsl:if test="$id/@extension">
                        <xsl:value-of select="$id/@extension"/>
                    </xsl:if>
                    <xsl:text> </xsl:text>
                    <xsl:value-of select="$id/@root"/>
                </xsl:if>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <!-- show-name  -->
    <xsl:template name="show-name">
        <xsl:param name="name"/>
        <xsl:choose>
            <xsl:when test="$name/n1:family">
                <xsl:if test="$name/n1:prefix">
                    <xsl:value-of select="$name/n1:prefix"/>
                    <xsl:text> </xsl:text>
                </xsl:if>
                <xsl:value-of select="$name/n1:given"/>
                <xsl:text> </xsl:text>
                <xsl:value-of select="$name/n1:family"/>
                <xsl:if test="$name/n1:suffix">
                    <xsl:text>, </xsl:text>
                    <xsl:value-of select="$name/n1:suffix"/>
                </xsl:if>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$name"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <!-- show-gender  -->
    <xsl:template name="show-gender">
        <xsl:choose>
            <xsl:when test="@code   = &apos;M&apos;">
                <xsl:text>Male</xsl:text>
            </xsl:when>
            <xsl:when test="@code  = &apos;F&apos;">
                <xsl:text>Female</xsl:text>
            </xsl:when>
            <xsl:when test="@code  = &apos;U&apos;">
                <xsl:text>Undifferentiated</xsl:text>
            </xsl:when>
        </xsl:choose>
    </xsl:template>
    <!-- show-race-ethnicity  -->
    <xsl:template name="show-race-ethnicity">
        <xsl:choose>
            <xsl:when test="@displayName">
                <xsl:value-of select="@displayName"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="@code"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
       <!-- show-preferred-language  -->
   <xsl:template name="show-preferred-language">
       <xsl:choose>
           <xsl:when test="@code = 'aa'">
               <xsl:text>Afar</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'aar'">
               <xsl:text>Afar</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'ab'">
               <xsl:text>Abkhazian</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'abk'">
               <xsl:text>Abkhazian</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'ace'">
               <xsl:text>Achinese</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'ach'">
               <xsl:text>Acoli</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'ada'">
               <xsl:text>Adangme</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'ady'">
               <xsl:text>Adyghe; Adygei</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'ae'">
               <xsl:text>Avestan</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'af'">
               <xsl:text>Afrikaans</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'afa'">
               <xsl:text>Afro-Asiatic languages</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'afh'">
               <xsl:text>Afrihili</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'afr'">
               <xsl:text>Afrikaans</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'ain'">
               <xsl:text>Ainu</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'ak'">
               <xsl:text>Akan</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'aka'">
               <xsl:text>Akan</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'akk'">
               <xsl:text>Akkadian</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'alb'">
               <xsl:text>Albanian</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'ale'">
               <xsl:text>Aleut</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'alg'">
               <xsl:text>Algonquian languages</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'alt'">
               <xsl:text>Southern Altai</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'am'">
               <xsl:text>Amharic</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'amh'">
               <xsl:text>Amharic</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'an'">
               <xsl:text>Aragonese</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'ang'">
               <xsl:text>English, Old (ca.450-1100)</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'anp'">
               <xsl:text>Angika</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'apa'">
               <xsl:text>Apache languages</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'ar'">
               <xsl:text>Arabic</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'ara'">
               <xsl:text>Arabic</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'arc'">
               <xsl:text>Official Aramaic (700-300 BCE); Imperial Aramaic (700-300 BCE)</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'arg'">
               <xsl:text>Aragonese</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'arm'">
               <xsl:text>Armenian</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'arn'">
               <xsl:text>Mapudungun; Mapuche</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'arp'">
               <xsl:text>Arapaho</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'art'">
               <xsl:text>Artificial languages</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'arw'">
               <xsl:text>Arawak</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'as'">
               <xsl:text>Assamese</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'asm'">
               <xsl:text>Assamese</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'ast'">
               <xsl:text>Asturian; Bable; Leonese; Asturleonese</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'ath'">
               <xsl:text>Athapascan languages</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'aus'">
               <xsl:text>Australian languages</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'av'">
               <xsl:text>Avaric</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'ava'">
               <xsl:text>Avaric</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'ave'">
               <xsl:text>Avestan</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'awa'">
               <xsl:text>Awadhi</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'ay'">
               <xsl:text>Aymara</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'aym'">
               <xsl:text>Aymara</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'az'">
               <xsl:text>Azerbaijani</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'aze'">
               <xsl:text>Azerbaijani</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'ba'">
               <xsl:text>Bashkir</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'bad'">
               <xsl:text>Banda languages</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'bai'">
               <xsl:text>Bamileke languages</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'bak'">
               <xsl:text>Bashkir</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'bal'">
               <xsl:text>Baluchi</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'bam'">
               <xsl:text>Bambara</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'ban'">
               <xsl:text>Balinese</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'baq'">
               <xsl:text>Basque</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'bas'">
               <xsl:text>Basa</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'bat'">
               <xsl:text>Baltic languages</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'be'">
               <xsl:text>Belarusian</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'bej'">
               <xsl:text>Beja; Bedawiyet</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'bel'">
               <xsl:text>Belarusian</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'bem'">
               <xsl:text>Bemba</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'ben'">
               <xsl:text>Bengali</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'ber'">
               <xsl:text>Berber languages</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'bg'">
               <xsl:text>Bulgarian</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'bh'">
               <xsl:text>Bihari</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'bho'">
               <xsl:text>Bhojpuri</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'bi'">
               <xsl:text>Bislama</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'bih'">
               <xsl:text>Bihari</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'bik'">
               <xsl:text>Bikol</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'bin'">
               <xsl:text>Bini; Edo</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'bis'">
               <xsl:text>Bislama</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'bla'">
               <xsl:text>Siksika</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'bm'">
               <xsl:text>Bambara</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'bn'">
               <xsl:text>Bengali</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'bnt'">
               <xsl:text>Bantu (Other)</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'bo'">
               <xsl:text>Tibetan</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'bos'">
               <xsl:text>Bosnian</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'br'">
               <xsl:text>Breton</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'bra'">
               <xsl:text>Braj</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'bre'">
               <xsl:text>Breton</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'bs'">
               <xsl:text>Bosnian</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'btk'">
               <xsl:text>Batak languages</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'bua'">
               <xsl:text>Buriat</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'bug'">
               <xsl:text>Buginese</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'bul'">
               <xsl:text>Bulgarian</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'bur'">
               <xsl:text>Burmese</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'byn'">
               <xsl:text>Blin; Bilin</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'ca'">
               <xsl:text>Catalan; Valencian</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'cad'">
               <xsl:text>Caddo</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'cai'">
               <xsl:text>Central American Indian languages</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'car'">
               <xsl:text>Galibi Carib</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'cat'">
               <xsl:text>Catalan- Valencian</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'cau'">
               <xsl:text>Caucasian languages</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'ce'">
               <xsl:text>Chechen</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'ceb'">
               <xsl:text>Cebuano</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'cel'">
               <xsl:text>Celtic languages</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'ch'">
               <xsl:text>Chamorro</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'cha'">
               <xsl:text>Chamorro</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'chb'">
               <xsl:text>Chibcha</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'che'">
               <xsl:text>Chechen</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'chg'">
               <xsl:text>Chagatai</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'chi'">
               <xsl:text>Chinese</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'chk'">
               <xsl:text>Chuukese</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'chm'">
               <xsl:text>Mari</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'chn'">
               <xsl:text>Chinook jargon</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'cho'">
               <xsl:text>Choctaw</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'chp'">
               <xsl:text>Chipewyan; Dene Suline</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'chr'">
               <xsl:text>Cherokee</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'chu'">
               <xsl:text>Church Slavic- Church Slavonic- Old Bulgarian- </xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'chv'">
               <xsl:text>Chuvash</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'chy'">
               <xsl:text>Cheyenne</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'cmc'">
               <xsl:text>Chamic languages</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'co'">
               <xsl:text>Corsican</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'cop'">
               <xsl:text>Coptic</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'cor'">
               <xsl:text>Cornish</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'cos'">
               <xsl:text>Corsican</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'cpe'">
               <xsl:text>Creoles and pidgins, English based (Other)</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'cpf'">
               <xsl:text>Creoles and pidgins, French-based (Other)</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'cpp'">
               <xsl:text>Creoles and pidgins, Portuguese-based (Other)</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'cr'">
               <xsl:text>Cree</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'cre'">
               <xsl:text>Cree</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'crh'">
               <xsl:text>Crimean Tatar; Crimean Turkish</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'crp'">
               <xsl:text>Creoles and pidgins (Other)</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'cs'">
               <xsl:text>Czech</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'csb'">
               <xsl:text>Kashubian</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'cu'">
               <xsl:text>Church Slavic; Old Slavonic; Church Slavonic; Old Bulgarian; Old Church Slavonic</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'cus'">
               <xsl:text>Cushitic languages</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'cv'">
               <xsl:text>Chuvash</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'cy'">
               <xsl:text>Welsh</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'cze'">
               <xsl:text>Czech</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'da'">
               <xsl:text>Danish</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'dak'">
               <xsl:text>Dakota</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'dan'">
               <xsl:text>Danish</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'dar'">
               <xsl:text>Dargwa</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'day'">
               <xsl:text>Land Dayak languages</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'de'">
               <xsl:text>German</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'del'">
               <xsl:text>Delaware</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'den'">
               <xsl:text>Slave (Athapascan)</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'dgr'">
               <xsl:text>Dogrib</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'din'">
               <xsl:text>Dinka</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'div'">
               <xsl:text>Divehi- Dhivehi- Maldivian</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'doi'">
               <xsl:text>Dogri</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'dra'">
               <xsl:text>Dravidian languages</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'dsb'">
               <xsl:text>Lower Sorbian</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'dua'">
               <xsl:text>Duala</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'dum'">
               <xsl:text>Dutch, Middle (ca.1050-1350)</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'dut'">
               <xsl:text>Dutch- Flemish</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'dv'">
               <xsl:text>Divehi; Dhivehi; Maldivian</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'dyu'">
               <xsl:text>Dyula</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'dz'">
               <xsl:text>Dzongkha</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'dzo'">
               <xsl:text>Dzongkha</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'ee'">
               <xsl:text>Ewe</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'efi'">
               <xsl:text>Efik</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'egy'">
               <xsl:text>Egyptian (Ancient)</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'eka'">
               <xsl:text>Ekajuk</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'el'">
               <xsl:text>Greek, Modern (1453-)</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'elx'">
               <xsl:text>Elamite</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'en'">
               <xsl:text>English</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'eng'">
               <xsl:text>English</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'enm'">
               <xsl:text>English, Middle (1100-1500)</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'eo'">
               <xsl:text>Esperanto</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'epo'">
               <xsl:text>Esperanto</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'es'">
               <xsl:text>Spanish; Castilian</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'est'">
               <xsl:text>Estonian</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'et'">
               <xsl:text>Estonian</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'eu'">
               <xsl:text>Basque</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'ewe'">
               <xsl:text>Ewe</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'ewo'">
               <xsl:text>Ewondo</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'fa'">
               <xsl:text>Persian</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'fan'">
               <xsl:text>Fang</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'fao'">
               <xsl:text>Faroese</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'fat'">
               <xsl:text>Fanti</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'ff'">
               <xsl:text>Fulah</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'fi'">
               <xsl:text>Finnish</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'fij'">
               <xsl:text>Fijian</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'fil'">
               <xsl:text>Filipino; Pilipino</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'fin'">
               <xsl:text>Finnish</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'fiu'">
               <xsl:text>Finno-Ugrian languages</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'fj'">
               <xsl:text>Fijian</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'fo'">
               <xsl:text>Faroese</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'fon'">
               <xsl:text>Fon</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'fr'">
               <xsl:text>French</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'fre'">
               <xsl:text>French</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'frm'">
               <xsl:text>French, Middle (ca.1400-1600)</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'fro'">
               <xsl:text>French, Old (842-ca.1400)</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'frr'">
               <xsl:text>Northern Frisian</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'frs'">
               <xsl:text>Eastern Frisian</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'fry'">
               <xsl:text>Western Frisian</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'ful'">
               <xsl:text>Fulah</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'fur'">
               <xsl:text>Friulian</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'fy'">
               <xsl:text>Western Frisian</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'ga'">
               <xsl:text>Irish</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'gaa'">
               <xsl:text>Ga</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'gay'">
               <xsl:text>Gayo</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'gba'">
               <xsl:text>Gbaya</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'gd'">
               <xsl:text>Gaelic; Scottish Gaelic</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'gem'">
               <xsl:text>Germanic languages</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'geo'">
               <xsl:text>Georgian</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'ger'">
               <xsl:text>German</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'gez'">
               <xsl:text>Geez</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'gil'">
               <xsl:text>Gilbertese</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'gl'">
               <xsl:text>Galician</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'gla'">
               <xsl:text>Gaelic- Scottish Gaelic</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'gle'">
               <xsl:text>Irish</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'glg'">
               <xsl:text>Galician</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'glv'">
               <xsl:text>Manx</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'gmh'">
               <xsl:text>German, Middle High (ca.1050-1500)</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'gn'">
               <xsl:text>Guarani</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'goh'">
               <xsl:text>German, Old High (ca.750-1050)</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'gon'">
               <xsl:text>Gondi</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'gor'">
               <xsl:text>Gorontalo</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'got'">
               <xsl:text>Gothic</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'grb'">
               <xsl:text>Grebo</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'grc'">
               <xsl:text>Greek, Ancient (to 1453)</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'gre'">
               <xsl:text>Greek</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'grn'">
               <xsl:text>Guarani</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'gsw'">
               <xsl:text>Swiss German; Alemannic</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'gu'">
               <xsl:text>Gujarati</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'guj'">
               <xsl:text>Gujarati</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'gv'">
               <xsl:text>Manx</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'gwi'">
               <xsl:text>Gwich'in</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'ha'">
               <xsl:text>Hausa</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'hai'">
               <xsl:text>Haida</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'hat'">
               <xsl:text>Haitian- Haitian Creole</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'hau'">
               <xsl:text>Hausa</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'haw'">
               <xsl:text>Hawaiian</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'he'">
               <xsl:text>Hebrew</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'heb'">
               <xsl:text>Hebrew</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'her'">
               <xsl:text>Herero</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'hi'">
               <xsl:text>Hindi</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'hil'">
               <xsl:text>Hiligaynon</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'him'">
               <xsl:text>Himachali</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'hin'">
               <xsl:text>Hindi</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'hit'">
               <xsl:text>Hittite</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'hmn'">
               <xsl:text>Hmong</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'hmo'">
               <xsl:text>Hiri Motu</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'ho'">
               <xsl:text>Hiri Motu</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'hr'">
               <xsl:text>Croatian</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'hrv'">
               <xsl:text>Croatian</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'hsb'">
               <xsl:text>Upper Sorbian</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'ht'">
               <xsl:text>Haitian; Haitian Creole</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'hu'">
               <xsl:text>Hungarian</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'hun'">
               <xsl:text>Hungarian</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'hup'">
               <xsl:text>Hupa</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'hy'">
               <xsl:text>Armenian</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'hz'">
               <xsl:text>Herero</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'ia'">
               <xsl:text>Interlingua (International Auxiliary Language Association)</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'iba'">
               <xsl:text>Iban</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'ibo'">
               <xsl:text>Igbo</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'ice'">
               <xsl:text>Icelandic</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'id'">
               <xsl:text>Indonesian</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'ido'">
               <xsl:text>Ido</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'ie'">
               <xsl:text>Interlingue; Occidental</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'ig'">
               <xsl:text>Igbo</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'ii'">
               <xsl:text>Sichuan Yi; Nuosu</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'iii'">
               <xsl:text>Sichuan Yi- Nuosu</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'ijo'">
               <xsl:text>Ijo languages</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'ik'">
               <xsl:text>Inupiaq</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'iku'">
               <xsl:text>Inuktitut</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'ile'">
               <xsl:text>Interlingue- Occidental</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'ilo'">
               <xsl:text>Iloko</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'ina'">
               <xsl:text>Interlingua (International Auxiliary Language Association)</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'inc'">
               <xsl:text>Indic languages</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'ind'">
               <xsl:text>Indonesian</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'ine'">
               <xsl:text>Indo-European languages</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'inh'">
               <xsl:text>Ingush</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'io'">
               <xsl:text>Ido</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'ipk'">
               <xsl:text>Inupiaq</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'ira'">
               <xsl:text>Iranian languages</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'iro'">
               <xsl:text>Iroquoian languages</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'is'">
               <xsl:text>Icelandic</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'it'">
               <xsl:text>Italian</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'ita'">
               <xsl:text>Italian</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'iu'">
               <xsl:text>Inuktitut</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'ja'">
               <xsl:text>Japanese</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'jav'">
               <xsl:text>Javanese</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'jbo'">
               <xsl:text>Lojban</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'jpn'">
               <xsl:text>Japanese</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'jpr'">
               <xsl:text>Judeo-Persian</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'jrb'">
               <xsl:text>Judeo-Arabic</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'jv'">
               <xsl:text>Javanese</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'ka'">
               <xsl:text>Georgian</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'kaa'">
               <xsl:text>Kara-Kalpak</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'kab'">
               <xsl:text>Kabyle</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'kac'">
               <xsl:text>Kachin; Jingpho</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'kal'">
               <xsl:text>Kalaallisut- Greenlandic</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'kam'">
               <xsl:text>Kamba</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'kan'">
               <xsl:text>Kannada</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'kar'">
               <xsl:text>Karen languages</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'kas'">
               <xsl:text>Kashmiri</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'kau'">
               <xsl:text>Kanuri</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'kaw'">
               <xsl:text>Kawi</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'kaz'">
               <xsl:text>Kazakh</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'kbd'">
               <xsl:text>Kabardian</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'kg'">
               <xsl:text>Kongo</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'kha'">
               <xsl:text>Khasi</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'khi'">
               <xsl:text>Khoisan languages</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'khm'">
               <xsl:text>Central Khmer</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'kho'">
               <xsl:text>Khotanese- Sakan</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'ki'">
               <xsl:text>Kikuyu; Gikuyu</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'kik'">
               <xsl:text>Kikuyu- Gikuyu</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'kin'">
               <xsl:text>Kinyarwanda</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'kir'">
               <xsl:text>Kirghiz- Kyrgyz</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'kj'">
               <xsl:text>Kuanyama; Kwanyama</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'kk'">
               <xsl:text>Kazakh</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'kl'">
               <xsl:text>Kalaallisut; Greenlandic</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'km'">
               <xsl:text>Central Khmer</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'kmb'">
               <xsl:text>Kimbundu</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'kn'">
               <xsl:text>Kannada</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'ko'">
               <xsl:text>Korean</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'kok'">
               <xsl:text>Konkani</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'kom'">
               <xsl:text>Komi</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'kon'">
               <xsl:text>Kongo</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'kor'">
               <xsl:text>Korean</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'kos'">
               <xsl:text>Kosraean</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'kpe'">
               <xsl:text>Kpelle</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'kr'">
               <xsl:text>Kanuri</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'krc'">
               <xsl:text>Karachay-Balkar</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'krl'">
               <xsl:text>Karelian</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'kro'">
               <xsl:text>Kru languages</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'kru'">
               <xsl:text>Kurukh</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'ks'">
               <xsl:text>Kashmiri</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'ku'">
               <xsl:text>Kurdish</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'kua'">
               <xsl:text>Kuanyama- Kwanyama</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'kum'">
               <xsl:text>Kumyk</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'kur'">
               <xsl:text>Kurdish</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'kut'">
               <xsl:text>Kutenai</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'kv'">
               <xsl:text>Komi</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'kw'">
               <xsl:text>Cornish</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'ky'">
               <xsl:text>Kirghiz; Kyrgyz</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'la'">
               <xsl:text>Latin</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'lad'">
               <xsl:text>Ladino</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'lah'">
               <xsl:text>Lahnda</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'lam'">
               <xsl:text>Lamba</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'lao'">
               <xsl:text>Lao</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'lat'">
               <xsl:text>Latin</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'lav'">
               <xsl:text>Latvian</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'lb'">
               <xsl:text>Luxembourgish; Letzeburgesch</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'lez'">
               <xsl:text>Lezghian</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'lg'">
               <xsl:text>Ganda</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'li'">
               <xsl:text>Limburgan; Limburger; Limburgish</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'lim'">
               <xsl:text>Limburgan- Limburger- Limburgish</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'lin'">
               <xsl:text>Lingala</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'lit'">
               <xsl:text>Lithuanian</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'ln'">
               <xsl:text>Lingala</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'lo'">
               <xsl:text>Lao</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'lol'">
               <xsl:text>Mongo</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'loz'">
               <xsl:text>Lozi</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'lt'">
               <xsl:text>Lithuanian</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'ltz'">
               <xsl:text>Luxembourgish- Letzeburgesch</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'lu'">
               <xsl:text>Luba-Katanga</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'lua'">
               <xsl:text>Luba-Lulua</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'lub'">
               <xsl:text>Luba-Katanga</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'lug'">
               <xsl:text>Ganda</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'lui'">
               <xsl:text>Luiseno</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'lun'">
               <xsl:text>Lunda</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'luo'">
               <xsl:text>Luo (Kenya and Tanzania)</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'lus'">
               <xsl:text>Lushai</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'lv'">
               <xsl:text>Latvian</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'mac'">
               <xsl:text>Macedonian</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'mad'">
               <xsl:text>Madurese</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'mag'">
               <xsl:text>Magahi</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'mah'">
               <xsl:text>Marshallese</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'mai'">
               <xsl:text>Maithili</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'mak'">
               <xsl:text>Makasar</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'mal'">
               <xsl:text>Malayalam</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'man'">
               <xsl:text>Mandingo</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'mao'">
               <xsl:text>Maori</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'map'">
               <xsl:text>Austronesian languages</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'mar'">
               <xsl:text>Marathi</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'mas'">
               <xsl:text>Masai</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'may'">
               <xsl:text>Malay</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'mdf'">
               <xsl:text>Moksha</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'mdr'">
               <xsl:text>Mandar</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'men'">
               <xsl:text>Mende</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'mg'">
               <xsl:text>Malagasy</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'mga'">
               <xsl:text>Irish, Middle (900-1200)</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'mh'">
               <xsl:text>Marshallese</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'mi'">
               <xsl:text>Maori</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'mic'">
               <xsl:text>Mi'kmaq- Micmac</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'min'">
               <xsl:text>Minangkabau</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'mis'">
               <xsl:text>Uncoded languages</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'mk'">
               <xsl:text>Macedonian</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'mkh'">
               <xsl:text>Mon-Khmer languages</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'ml'">
               <xsl:text>Malayalam</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'mlg'">
               <xsl:text>Malagasy</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'mlt'">
               <xsl:text>Maltese</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'mn'">
               <xsl:text>Mongolian</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'mnc'">
               <xsl:text>Manchu</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'mni'">
               <xsl:text>Manipuri</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'mno'">
               <xsl:text>Manobo languages</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'mo'">
               <xsl:text>Moldavian</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'moh'">
               <xsl:text>Mohawk</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'mon'">
               <xsl:text>Mongolian</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'mos'">
               <xsl:text>Mossi</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'mr'">
               <xsl:text>Marathi</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'ms'">
               <xsl:text>Malay</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'mt'">
               <xsl:text>Maltese</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'mul'">
               <xsl:text>Multiple languages</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'mun'">
               <xsl:text>Munda languages</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'mus'">
               <xsl:text>Creek</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'mwl'">
               <xsl:text>Mirandese</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'mwr'">
               <xsl:text>Marwari</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'my'">
               <xsl:text>Burmese</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'myn'">
               <xsl:text>Mayan languages</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'myv'">
               <xsl:text>Erzya</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'na'">
               <xsl:text>Nauru</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'nah'">
               <xsl:text>Nahuatl languages</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'nai'">
               <xsl:text>North American Indian languages</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'nap'">
               <xsl:text>Neapolitan</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'nau'">
               <xsl:text>Nauru</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'nav'">
               <xsl:text>Navajo- Navaho</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'nb'">
               <xsl:text>Bokmål, Norwegian; Norwegian Bokmål</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'nbl'">
               <xsl:text>Ndebele, South- South Ndebele</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'nd'">
               <xsl:text>Ndebele, North; North Ndebele</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'nde'">
               <xsl:text>Ndebele, North- North Ndebele</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'ndo'">
               <xsl:text>Ndonga</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'nds'">
               <xsl:text>Low German; Low Saxon; German, Low; Saxon, Low</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'ne'">
               <xsl:text>Nepali</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'nep'">
               <xsl:text>Nepali</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'new'">
               <xsl:text>Nepal Bhasa; Newari</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'ng'">
               <xsl:text>Ndonga</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'nia'">
               <xsl:text>Nias</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'nic'">
               <xsl:text>Niger-Kordofanian languages</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'niu'">
               <xsl:text>Niuean</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'nl'">
               <xsl:text>Dutch; Flemish</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'nn'">
               <xsl:text>Norwegian Nynorsk; Nynorsk, Norwegian</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'nno'">
               <xsl:text>Norwegian Nynorsk- Nynorsk, Norwegian</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'no'">
               <xsl:text>Norwegian</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'nob'">
               <xsl:text>Bokmål, Norwegian- Norwegian Bokmål</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'nog'">
               <xsl:text>Nogai</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'non'">
               <xsl:text>Norse, Old</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'nor'">
               <xsl:text>Norwegian</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'nqo'">
               <xsl:text>N'Ko</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'nr'">
               <xsl:text>Ndebele, South; South Ndebele</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'nso'">
               <xsl:text>Pedi; Sepedi; Northern Sotho</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'nub'">
               <xsl:text>Nubian languages</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'nv'">
               <xsl:text>Navajo; Navaho</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'nwc'">
               <xsl:text>Classical Newari; Old Newari; Classical Nepal Bhasa</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'ny'">
               <xsl:text>Chichewa; Chewa; Nyanja</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'nya'">
               <xsl:text>Chichewa- Chewa- Nyanja</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'nym'">
               <xsl:text>Nyamwezi</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'nyn'">
               <xsl:text>Nyankole</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'nyo'">
               <xsl:text>Nyoro</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'nzi'">
               <xsl:text>Nzima</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'oc'">
               <xsl:text>Occitan (post 1500); Provençal</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'oci'">
               <xsl:text>Occitan (post 1500)- Provençal</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'oj'">
               <xsl:text>Ojibwa</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'oji'">
               <xsl:text>Ojibwa</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'om'">
               <xsl:text>Oromo</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'or'">
               <xsl:text>Oriya</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'ori'">
               <xsl:text>Oriya</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'orm'">
               <xsl:text>Oromo</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'os'">
               <xsl:text>Ossetian; Ossetic</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'osa'">
               <xsl:text>Osage</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'oss'">
               <xsl:text>Ossetian- Ossetic</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'ota'">
               <xsl:text>Turkish, Ottoman (1500-1928)</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'oto'">
               <xsl:text>Otomian languages</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'pa'">
               <xsl:text>Panjabi; Punjabi</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'paa'">
               <xsl:text>Papuan languages</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'pag'">
               <xsl:text>Pangasinan</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'pal'">
               <xsl:text>Pahlavi</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'pam'">
               <xsl:text>Pampanga; Kapampangan</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'pan'">
               <xsl:text>Panjabi- Punjabi</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'pap'">
               <xsl:text>Papiamento</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'pau'">
               <xsl:text>Palauan</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'peo'">
               <xsl:text>Persian, Old (ca.600-400 B.C.)</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'per'">
               <xsl:text>Persian</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'phi'">
               <xsl:text>Philippine languages</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'phn'">
               <xsl:text>Phoenician</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'pi'">
               <xsl:text>Pali</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'pl'">
               <xsl:text>Polish</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'pli'">
               <xsl:text>Pali</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'pol'">
               <xsl:text>Polish</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'pon'">
               <xsl:text>Pohnpeian</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'por'">
               <xsl:text>Portuguese</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'pra'">
               <xsl:text>Prakrit languages</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'pro'">
               <xsl:text>Provençal, Old (to 1500)</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'ps'">
               <xsl:text>Pushto; Pashto</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'pt'">
               <xsl:text>Portuguese</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'pus'">
               <xsl:text>Pushto- Pashto</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'qaa'">
               <xsl:text>displayName="Reserved for local use</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'qu'">
               <xsl:text>Quechua</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'que'">
               <xsl:text>Quechua</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'raj'">
               <xsl:text>Rajasthani</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'rap'">
               <xsl:text>Rapanui</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'rar'">
               <xsl:text>Rarotongan; Cook Islands Maori</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'rm'">
               <xsl:text>Romansh</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'rn'">
               <xsl:text>Rundi</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'ro'">
               <xsl:text>Romanian</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'roa'">
               <xsl:text>Romance languages</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'roh'">
               <xsl:text>Romansh</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'rom'">
               <xsl:text>Romany</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'ru'">
               <xsl:text>Russian</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'rum'">
               <xsl:text>Romanian- Moldavian- Moldovan</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'run'">
               <xsl:text>Rundi</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'rup'">
               <xsl:text>Aromanian; Arumanian; Macedo-Romanian</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'rus'">
               <xsl:text>Russian</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'rw'">
               <xsl:text>Kinyarwanda</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'sa'">
               <xsl:text>Sanskrit</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'sad'">
               <xsl:text>Sandawe</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'sag'">
               <xsl:text>Sango</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'sah'">
               <xsl:text>Yakut</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'sai'">
               <xsl:text>South American Indian (Other)</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'sal'">
               <xsl:text>Salishan languages</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'sam'">
               <xsl:text>Samaritan Aramaic</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'san'">
               <xsl:text>Sanskrit</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'sas'">
               <xsl:text>Sasak</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'sat'">
               <xsl:text>Santali</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'sc'">
               <xsl:text>Sardinian</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'scn'">
               <xsl:text>Sicilian</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'sco'">
               <xsl:text>Scots</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'sd'">
               <xsl:text>Sindhi</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'se'">
               <xsl:text>Northern Sami</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'sel'">
               <xsl:text>Selkup</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'sem'">
               <xsl:text>Semitic languages</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'sg'">
               <xsl:text>Sango</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'sga'">
               <xsl:text>Irish, Old (to 900)</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'sgn'">
               <xsl:text>Sign Languages</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'shn'">
               <xsl:text>Shan</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'si'">
               <xsl:text>Sinhala; Sinhalese</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'sid'">
               <xsl:text>Sidamo</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'sin'">
               <xsl:text>Sinhala- Sinhalese</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'sio'">
               <xsl:text>Siouan languages</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'sit'">
               <xsl:text>Sino-Tibetan languages</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'sk'">
               <xsl:text>Slovak</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'sl'">
               <xsl:text>Slovenian</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'sla'">
               <xsl:text>Slavic languages</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'slo'">
               <xsl:text>Slovak</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'slv'">
               <xsl:text>Slovenian</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'sm'">
               <xsl:text>Samoan</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'sma'">
               <xsl:text>Southern Sami</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'sme'">
               <xsl:text>Northern Sami</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'smi'">
               <xsl:text>Sami languages (Other)</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'smj'">
               <xsl:text>Lule Sami</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'smn'">
               <xsl:text>Inari Sami</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'smo'">
               <xsl:text>Samoan</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'sms'">
               <xsl:text>Skolt Sami</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'sn'">
               <xsl:text>Shona</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'sna'">
               <xsl:text>Shona</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'snd'">
               <xsl:text>Sindhi</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'snk'">
               <xsl:text>Soninke</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'so'">
               <xsl:text>Somali</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'sog'">
               <xsl:text>Sogdian</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'som'">
               <xsl:text>Somali</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'son'">
               <xsl:text>Songhai languages</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'sot'">
               <xsl:text>Sotho, Southern</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'spa'">
               <xsl:text>Spanish- Castilian</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'sq'">
               <xsl:text>Albanian</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'sr'">
               <xsl:text>Serbian</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'srd'">
               <xsl:text>Sardinian</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'srn'">
               <xsl:text>Sranan Tongo</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'srp'">
               <xsl:text>Serbian</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'srr'">
               <xsl:text>Serer</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'ss'">
               <xsl:text>Swati</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'ssa'">
               <xsl:text>Nilo-Saharan languages</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'ssw'">
               <xsl:text>Swati</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'st'">
               <xsl:text>Sotho, Southern</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'su'">
               <xsl:text>Sundanese</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'suk'">
               <xsl:text>Sukuma</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'sun'">
               <xsl:text>Sundanese</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'sus'">
               <xsl:text>Susu</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'sux'">
               <xsl:text>Sumerian</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'sv'">
               <xsl:text>Swedish</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'sw'">
               <xsl:text>Swahili</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'swa'">
               <xsl:text>Swahili</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'swe'">
               <xsl:text>Swedish</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'syc'">
               <xsl:text>Classical Syriac</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'syr'">
               <xsl:text>Syriac</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'ta'">
               <xsl:text>Tamil</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'tah'">
               <xsl:text>Tahitian</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'tai'">
               <xsl:text>Tai languages</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'tam'">
               <xsl:text>Tamil</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'tat'">
               <xsl:text>Tatar</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'te'">
               <xsl:text>Telugu</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'tel'">
               <xsl:text>Telugu</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'tem'">
               <xsl:text>Timne</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'ter'">
               <xsl:text>Tereno</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'tet'">
               <xsl:text>Tetum</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'tg'">
               <xsl:text>Tajik</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'tgk'">
               <xsl:text>Tajik</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'tgl'">
               <xsl:text>Tagalog</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'th'">
               <xsl:text>Thai</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'tha'">
               <xsl:text>Thai</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'ti'">
               <xsl:text>Tigrinya</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'tib'">
               <xsl:text>Tibetan</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'tig'">
               <xsl:text>Tigre</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'tir'">
               <xsl:text>Tigrinya</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'tiv'">
               <xsl:text>Tiv</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'tk'">
               <xsl:text>Turkmen</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'tkl'">
               <xsl:text>Tokelau</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'tl'">
               <xsl:text>Tagalog</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'tlh'">
               <xsl:text>Klingon; tlhIngan-Hol</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'tli'">
               <xsl:text>Tlingit</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'tmh'">
               <xsl:text>Tamashek</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'tn'">
               <xsl:text>Tswana</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'to'">
               <xsl:text>Tonga (Tonga Islands)</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'tog'">
               <xsl:text>Tonga (Nyasa)</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'ton'">
               <xsl:text>Tonga (Tonga Islands)</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'tpi'">
               <xsl:text>Tok Pisin</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'tr'">
               <xsl:text>Turkish</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'ts'">
               <xsl:text>Tsonga</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'tsi'">
               <xsl:text>Tsimshian</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'tsn'">
               <xsl:text>Tswana</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'tso'">
               <xsl:text>Tsonga</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'tt'">
               <xsl:text>Tatar</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'tuk'">
               <xsl:text>Turkmen</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'tum'">
               <xsl:text>Tumbuka</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'tup'">
               <xsl:text>Tupi languages</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'tur'">
               <xsl:text>Turkish</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'tut'">
               <xsl:text>Altaic languages</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'tvl'">
               <xsl:text>Tuvalu</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'tw'">
               <xsl:text>Twi</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'twi'">
               <xsl:text>Twi</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'ty'">
               <xsl:text>Tahitian</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'tyv'">
               <xsl:text>Tuvinian</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'udm'">
               <xsl:text>Udmurt</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'ug'">
               <xsl:text>Uighur; Uyghur</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'uga'">
               <xsl:text>Ugaritic</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'uig'">
               <xsl:text>Uighur- Uyghur</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'uk'">
               <xsl:text>Ukrainian</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'ukr'">
               <xsl:text>Ukrainian</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'umb'">
               <xsl:text>Umbundu</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'und'">
               <xsl:text>Undetermined</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'ur'">
               <xsl:text>Urdu</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'urd'">
               <xsl:text>Urdu</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'uz'">
               <xsl:text>Uzbek</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'uzb'">
               <xsl:text>Uzbek</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'vai'">
               <xsl:text>Vai</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 've'">
               <xsl:text>Venda</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'ven'">
               <xsl:text>Venda</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'vi'">
               <xsl:text>Vietnamese</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'vie'">
               <xsl:text>Vietnamese</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'vo'">
               <xsl:text>Volapük</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'vol'">
               <xsl:text>Volapük</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'vot'">
               <xsl:text>Votic</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'wa'">
               <xsl:text>Walloon</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'wak'">
               <xsl:text>Wakashan languages</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'wal'">
               <xsl:text>Walamo</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'war'">
               <xsl:text>Waray</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'was'">
               <xsl:text>Washo</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'wel'">
               <xsl:text>Welsh</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'wen'">
               <xsl:text>Sorbian languages</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'wln'">
               <xsl:text>Walloon</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'wo'">
               <xsl:text>Wolof</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'wol'">
               <xsl:text>Wolof</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'xal'">
               <xsl:text>Kalmyk; Oirat</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'xh'">
               <xsl:text>Xhosa</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'xho'">
               <xsl:text>Xhosa</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'yao'">
               <xsl:text>Yao</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'yap'">
               <xsl:text>Yapese</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'yi'">
               <xsl:text>Yiddish</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'yid'">
               <xsl:text>Yiddish</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'yo'">
               <xsl:text>Yoruba</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'yor'">
               <xsl:text>Yoruba</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'ypk'">
               <xsl:text>Yupik languages</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'za'">
               <xsl:text>Zhuang; Chuang</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'zap'">
               <xsl:text>Zapotec</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'zbl'">
               <xsl:text>Blissymbols; Blissymbolics; Bliss</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'zen'">
               <xsl:text>Zenaga</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'zh'">
               <xsl:text>Chinese</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'zha'">
               <xsl:text>Zhuang- Chuang</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'znd'">
               <xsl:text>Zande languages</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'zu'">
               <xsl:text>Zulu</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'zul'">
               <xsl:text>Zulu</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'zun'">
               <xsl:text>Zuni</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'zxx'">
               <xsl:text>No linguistic content</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'zza'">
               <xsl:text>Zaza- Dimili- Dimli- Kirdki- Kirmanjki- Zazaki</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'sqi'">
               <xsl:text>Albanian</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'hye'">
               <xsl:text>Armenian</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'eus'">
               <xsl:text>Basque</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'mya'">
               <xsl:text>Burmese</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'zho'">
               <xsl:text>Chinese</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'ces'">
               <xsl:text>Czech</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'nld'">
               <xsl:text>Dutch; Flemish</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'fra'">
               <xsl:text>French</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'kat'">
               <xsl:text>Georgian</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'deu'">
               <xsl:text>German</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'ell'">
               <xsl:text>Greek, Modern (1453-)</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'isl'">
               <xsl:text>Icelandic</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'mkd'">
               <xsl:text>Macedonian</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'mri'">
               <xsl:text>Maori</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'msa'">
               <xsl:text>Malay</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'fas'">
               <xsl:text>Persian</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'ron'">
               <xsl:text>Romanian; Moldavian; Moldovan</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'slk'">
               <xsl:text>Slovak</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'bod'">
               <xsl:text>Tibetan</xsl:text>
           </xsl:when>
           <xsl:when test="@code = 'cym'">
               <xsl:text>Welsh</xsl:text>
           </xsl:when>
           <xsl:otherwise>
               <xsl:value-of select="@code"/>
           </xsl:otherwise>
       </xsl:choose>
   </xsl:template>
    <!-- show-contactInfo -->
    <xsl:template name="show-contactInfo">
        <xsl:param name="contact"/>
        <xsl:call-template name="show-address">
            <xsl:with-param name="address" select="$contact/n1:addr"/>
        </xsl:call-template>
        <xsl:call-template name="show-telecom">
            <xsl:with-param name="telecom" select="$contact/n1:telecom"/>
        </xsl:call-template>
    </xsl:template>
    <!-- show-address -->
    <xsl:template name="show-address">
        <xsl:param name="address"/>
        <xsl:choose>
            <xsl:when test="$address">
                <xsl:if test="$address/@use">
                    <xsl:text> </xsl:text>
                    <xsl:call-template name="translateTelecomCode">
                        <xsl:with-param name="code" select="$address/@use"/>
                    </xsl:call-template>
                    <xsl:text>:</xsl:text>
                    <br/>
                </xsl:if>
                <xsl:for-each select="$address/n1:streetAddressLine">
                    <xsl:value-of select="."/>
                    <br/>
                </xsl:for-each>
                <xsl:if test="$address/n1:streetName">
                    <xsl:value-of select="$address/n1:streetName"/>
                    <xsl:text> </xsl:text>
                    <xsl:value-of select="$address/n1:houseNumber"/>
                    <br/>
                </xsl:if>
                <xsl:if test="string-length($address/n1:city)>0">
                    <xsl:value-of select="$address/n1:city"/>
                </xsl:if>
                <xsl:if test="string-length($address/n1:state)>0">
                    <xsl:text>, </xsl:text>
                    <xsl:value-of select="$address/n1:state"/>
                </xsl:if>
                <xsl:if test="string-length($address/n1:postalCode)>0">
                    <xsl:text> </xsl:text>
                    <xsl:value-of select="$address/n1:postalCode"/>
                </xsl:if>
                <xsl:if test="string-length($address/n1:country)>0">
                    <xsl:text>, </xsl:text>
                    <xsl:value-of select="$address/n1:country"/>
                </xsl:if>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>address not available</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
        <br/>
    </xsl:template>
    <!-- show-telecom -->
    <xsl:template name="show-telecom">
        <xsl:param name="telecom"/>
        <xsl:choose>
            <xsl:when test="$telecom">
                <xsl:variable name="type" select="substring-before($telecom/@value, ':')"/>
                <xsl:variable name="value" select="substring-after($telecom/@value, ':')"/>
                <xsl:if test="$type">
                    <xsl:call-template name="translateTelecomCode">
                        <xsl:with-param name="code" select="$type"/>
                    </xsl:call-template>
                    <xsl:if test="@use">
                        <xsl:text> (</xsl:text>
                        <xsl:call-template name="translateTelecomCode">
                            <xsl:with-param name="code" select="@use"/>
                        </xsl:call-template>
                        <xsl:text>)</xsl:text>
                    </xsl:if>
                    <xsl:text>: </xsl:text>
                    <xsl:text> </xsl:text>
                    <xsl:value-of select="$value"/>
                </xsl:if>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>Telecom information not available</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
        <br/>
    </xsl:template>
    <!-- show-recipientType -->
    <xsl:template name="show-recipientType">
        <xsl:param name="typeCode"/>
        <xsl:choose>
            <xsl:when test="$typeCode='PRCP'">Primary Recipient:</xsl:when>
            <xsl:when test="$typeCode='TRC'">Secondary Recipient:</xsl:when>
            <xsl:otherwise>Recipient:</xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <!-- Convert Telecom URL to display text -->
    <xsl:template name="translateTelecomCode">
        <xsl:param name="code"/>
        <!--xsl:value-of select="document('voc.xml')/systems/system[@root=$code/@codeSystem]/code[@value=$code/@code]/@displayName"/-->
        <!--xsl:value-of select="document('codes.xml')/*/code[@code=$code]/@display"/-->
        <xsl:choose>
            <!-- lookup table Telecom URI -->
            <xsl:when test="$code='tel'">
                <xsl:text>Tel</xsl:text>
            </xsl:when>
            <xsl:when test="$code='fax'">
                <xsl:text>Fax</xsl:text>
            </xsl:when>
            <xsl:when test="$code='http'">
                <xsl:text>Web</xsl:text>
            </xsl:when>
            <xsl:when test="$code='mailto'">
                <xsl:text>Mail</xsl:text>
            </xsl:when>
            <xsl:when test="$code='H'">
                <xsl:text>Home</xsl:text>
            </xsl:when>
            <xsl:when test="$code='HV'">
                <xsl:text>Vacation Home</xsl:text>
            </xsl:when>
            <xsl:when test="$code='HP'">
                <xsl:text>Primary Home</xsl:text>
            </xsl:when>
            <xsl:when test="$code='WP'">
                <xsl:text>Work Place</xsl:text>
            </xsl:when>
            <xsl:when test="$code='PUB'">
                <xsl:text>Pub</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>{$code='</xsl:text>
                <xsl:value-of select="$code"/>
                <xsl:text>'?}</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <!-- convert RoleClassAssociative code to display text -->
    <xsl:template name="translateRoleAssoCode">
        <xsl:param name="classCode"/>
        <xsl:param name="code"/>
        <xsl:choose>
            <xsl:when test="$classCode='AFFL'">
                <xsl:text>affiliate</xsl:text>
            </xsl:when>
            <xsl:when test="$classCode='AGNT'">
                <xsl:text>agent</xsl:text>
            </xsl:when>
            <xsl:when test="$classCode='ASSIGNED'">
                <xsl:text>assigned entity</xsl:text>
            </xsl:when>
            <xsl:when test="$classCode='COMPAR'">
                <xsl:text>commissioning party</xsl:text>
            </xsl:when>
            <xsl:when test="$classCode='CON'">
                <xsl:text>contact</xsl:text>
            </xsl:when>
            <xsl:when test="$classCode='ECON'">
                <xsl:text>emergency contact</xsl:text>
            </xsl:when>
            <xsl:when test="$classCode='NOK'">
                <xsl:text>next of kin</xsl:text>
            </xsl:when>
            <xsl:when test="$classCode='SGNOFF'">
                <xsl:text>signing authority</xsl:text>
            </xsl:when>
            <xsl:when test="$classCode='GUARD'">
                <xsl:text>guardian</xsl:text>
            </xsl:when>
            <xsl:when test="$classCode='GUAR'">
                <xsl:text>guardian</xsl:text>
            </xsl:when>
            <xsl:when test="$classCode='CIT'">
                <xsl:text>citizen</xsl:text>
            </xsl:when>
            <xsl:when test="$classCode='COVPTY'">
                <xsl:text>covered party</xsl:text>
            </xsl:when>
            <xsl:when test="$classCode='PRS'">
                <xsl:text>personal relationship</xsl:text>
            </xsl:when>
            <xsl:when test="$classCode='CAREGIVER'">
                <xsl:text>care giver</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>{$classCode='</xsl:text>
                <xsl:value-of select="$classCode"/>
                <xsl:text>'?}</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
        <xsl:if test="($code/@code) and ($code/@codeSystem='2.16.840.1.113883.5.111')">
            <xsl:text> </xsl:text>
            <xsl:choose>
                <xsl:when test="$code/@code='FTH'">
                    <xsl:text>(Father)</xsl:text>
                </xsl:when>
                <xsl:when test="$code/@code='MTH'">
                    <xsl:text>(Mother)</xsl:text>
                </xsl:when>
                <xsl:when test="$code/@code='NPRN'">
                    <xsl:text>(Natural parent)</xsl:text>
                </xsl:when>
                <xsl:when test="$code/@code='STPPRN'">
                    <xsl:text>(Step parent)</xsl:text>
                </xsl:when>
                <xsl:when test="$code/@code='SONC'">
                    <xsl:text>(Son)</xsl:text>
                </xsl:when>
                <xsl:when test="$code/@code='DAUC'">
                    <xsl:text>(Daughter)</xsl:text>
                </xsl:when>
                <xsl:when test="$code/@code='CHILD'">
                    <xsl:text>(Child)</xsl:text>
                </xsl:when>
                <xsl:when test="$code/@code='EXT'">
                    <xsl:text>(Extended family member)</xsl:text>
                </xsl:when>
                <xsl:when test="$code/@code='NBOR'">
                    <xsl:text>(Neighbor)</xsl:text>
                </xsl:when>
                <xsl:when test="$code/@code='SIGOTHR'">
                    <xsl:text>(Significant other)</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text>{$code/@code='</xsl:text>
                    <xsl:value-of select="$code/@code"/>
                    <xsl:text>'?}</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:if>
    </xsl:template>
    <!-- show time -->
    <xsl:template name="show-time">
        <xsl:param name="datetime"/>
        <xsl:choose>
            <xsl:when test="not($datetime)">
                <xsl:call-template name="formatDateTime">
                    <xsl:with-param name="date" select="@value"/>
                </xsl:call-template>
                <xsl:text> </xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:call-template name="formatDateTime">
                    <xsl:with-param name="date" select="$datetime/@value"/>
                </xsl:call-template>
                <xsl:text> </xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <!-- paticipant facility and date -->
    <xsl:template name="facilityAndDates">
        <table class="header_table">
            <tbody>
                <!-- facility id -->
                <tr>
                    <td width="20%" class="header_table_label">
                        <span class="td_label">
                            <xsl:text>Facility ID</xsl:text>
                        </span>
                    </td>
                    <td class="td_header_role_value">
                        <xsl:choose>
                            <xsl:when test="count(/n1:ClinicalDocument/n1:participant
                                      [@typeCode='LOC'][@contextControlCode='OP']
                                      /n1:associatedEntity[@classCode='SDLOC']/n1:id)&gt;0">
                                <!-- change context node -->
                                <xsl:for-each select="/n1:ClinicalDocument/n1:participant
                                      [@typeCode='LOC'][@contextControlCode='OP']
                                      /n1:associatedEntity[@classCode='SDLOC']/n1:id">
                                    <xsl:call-template name="show-id"/>
                                    <!-- change context node again, for the code -->
                                    <xsl:for-each select="../n1:code">
                                        <xsl:text> (</xsl:text>
                                        <xsl:call-template name="show-code">
                                            <xsl:with-param name="code" select="."/>
                                        </xsl:call-template>
                                        <xsl:text>)</xsl:text>
                                    </xsl:for-each>
                                </xsl:for-each>
                            </xsl:when>
                            <xsl:otherwise>
                                Not available
                            </xsl:otherwise>
                        </xsl:choose>
                    </td>
                </tr>
                <!-- Period reported -->
                <tr>
                    <td width="20%" class="header_table_label">
                        <span class="td_label">
                            <xsl:text>First day of period reported</xsl:text>
                        </span>
                    </td>
                    <td class="td_header_role_value">
                        <xsl:call-template name="show-time">
                            <xsl:with-param name="datetime" select="/n1:ClinicalDocument/n1:documentationOf
                                      /n1:serviceEvent/n1:effectiveTime/n1:low"/>
                        </xsl:call-template>
                    </td>
                </tr>
                <tr>
                    <td width="20%" class="header_table_label">
                        <span class="td_label">
                            <xsl:text>Last day of period reported</xsl:text>
                        </span>
                    </td>
                    <td class="td_header_role_value">
                        <xsl:call-template name="show-time">
                            <xsl:with-param name="datetime" select="/n1:ClinicalDocument/n1:documentationOf
                                      /n1:serviceEvent/n1:effectiveTime/n1:high"/>
                        </xsl:call-template>
                    </td>
                </tr>
            </tbody>
        </table>
    </xsl:template>
    <!-- show assignedEntity -->
    <xsl:template name="show-assignedEntity">
        <xsl:param name="asgnEntity"/>
        <xsl:choose>
            <xsl:when test="$asgnEntity/n1:assignedPerson/n1:name">
                <xsl:call-template name="show-name">
                    <xsl:with-param name="name" select="$asgnEntity/n1:assignedPerson/n1:name"/>
                </xsl:call-template>
                <xsl:if test="$asgnEntity/n1:representedOrganization/n1:name and not($asgnEntity/n1:representedOrganization/n1:name/@nullFlavor)">
                    <xsl:text> of </xsl:text>
                    <xsl:value-of select="$asgnEntity/n1:representedOrganization/n1:name"/>
                </xsl:if>
            </xsl:when>
            <xsl:when test="$asgnEntity/n1:representedOrganization">
                <xsl:value-of select="$asgnEntity/n1:representedOrganization/n1:name"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:for-each select="$asgnEntity/n1:id">
                    <xsl:call-template name="show-id"/>
                    <xsl:choose>
                        <xsl:when test="position()!=last()">
                            <xsl:text>, </xsl:text>
                        </xsl:when>
                        <xsl:otherwise>
                            <br/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:for-each>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <!-- show relatedEntity -->
    <xsl:template name="show-relatedEntity">
        <xsl:param name="relatedEntity"/>
        <xsl:choose>
            <xsl:when test="$relatedEntity/n1:relatedPerson/n1:name">
                <xsl:call-template name="show-name">
                    <xsl:with-param name="name" select="$relatedEntity/n1:relatedPerson/n1:name"/>
                </xsl:call-template>
            </xsl:when>
        </xsl:choose>
    </xsl:template>
    <!-- show associatedEntity -->
    <xsl:template name="show-associatedEntity">
        <xsl:param name="assoEntity"/>
        <xsl:choose>
            <xsl:when test="$assoEntity/n1:associatedPerson">
                <xsl:for-each select="$assoEntity/n1:associatedPerson/n1:name">
                    <xsl:call-template name="show-name">
                        <xsl:with-param name="name" select="."/>
                    </xsl:call-template>
                    <br/>
                </xsl:for-each>
            </xsl:when>
            <xsl:when test="$assoEntity/n1:scopingOrganization">
                <xsl:for-each select="$assoEntity/n1:scopingOrganization">
                    <xsl:if test="n1:name">
                        <xsl:call-template name="show-name">
                            <xsl:with-param name="name" select="n1:name"/>
                        </xsl:call-template>
                        <br/>
                    </xsl:if>
                    <xsl:if test="n1:standardIndustryClassCode">
                        <xsl:value-of select="n1:standardIndustryClassCode/@displayName"/>
                        <xsl:text> code:</xsl:text>
                        <xsl:value-of select="n1:standardIndustryClassCode/@code"/>
                    </xsl:if>
                </xsl:for-each>
            </xsl:when>
            <xsl:when test="$assoEntity/n1:code">
                <xsl:call-template name="show-code">
                    <xsl:with-param name="code" select="$assoEntity/n1:code"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:when test="$assoEntity/n1:id">
                <xsl:value-of select="$assoEntity/n1:id/@extension"/>
                <xsl:text> </xsl:text>
                <xsl:value-of select="$assoEntity/n1:id/@root"/>
            </xsl:when>
        </xsl:choose>
    </xsl:template>
    <!-- show code
     if originalText present, return it, otherwise, check and return attribute: display name
     -->
    <xsl:template name="show-code">
        <xsl:param name="code"/>
        <xsl:variable name="this-codeSystem">
            <xsl:value-of select="$code/@codeSystem"/>
        </xsl:variable>
        <xsl:variable name="this-code">
            <xsl:value-of select="$code/@code"/>
        </xsl:variable>
        <xsl:choose>
            <xsl:when test="$code/n1:originalText">
                <xsl:value-of select="$code/n1:originalText"/>
            </xsl:when>
            <xsl:when test="$code/@displayName">
                <xsl:value-of select="$code/@displayName"/>
            </xsl:when>
            <!--
         <xsl:when test="$the-valuesets/*/voc:system[@root=$this-codeSystem]/voc:code[@value=$this-code]/@displayName">
           <xsl:value-of select="$the-valuesets/*/voc:system[@root=$this-codeSystem]/voc:code[@value=$this-code]/@displayName"/>
         </xsl:when>
         -->
            <xsl:otherwise>
                <xsl:value-of select="$this-code"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <!-- show classCode -->
    <xsl:template name="show-actClassCode">
        <xsl:param name="clsCode"/>
        <xsl:choose>
            <xsl:when test=" $clsCode = 'ACT' ">
                <xsl:text>healthcare service</xsl:text>
            </xsl:when>
            <xsl:when test=" $clsCode = 'ACCM' ">
                <xsl:text>accommodation</xsl:text>
            </xsl:when>
            <xsl:when test=" $clsCode = 'ACCT' ">
                <xsl:text>account</xsl:text>
            </xsl:when>
            <xsl:when test=" $clsCode = 'ACSN' ">
                <xsl:text>accession</xsl:text>
            </xsl:when>
            <xsl:when test=" $clsCode = 'ADJUD' ">
                <xsl:text>financial adjudication</xsl:text>
            </xsl:when>
            <xsl:when test=" $clsCode = 'CONS' ">
                <xsl:text>consent</xsl:text>
            </xsl:when>
            <xsl:when test=" $clsCode = 'CONTREG' ">
                <xsl:text>container registration</xsl:text>
            </xsl:when>
            <xsl:when test=" $clsCode = 'CTTEVENT' ">
                <xsl:text>clinical trial timepoint event</xsl:text>
            </xsl:when>
            <xsl:when test=" $clsCode = 'DISPACT' ">
                <xsl:text>disciplinary action</xsl:text>
            </xsl:when>
            <xsl:when test=" $clsCode = 'ENC' ">
                <xsl:text>encounter</xsl:text>
            </xsl:when>
            <xsl:when test=" $clsCode = 'INC' ">
                <xsl:text>incident</xsl:text>
            </xsl:when>
            <xsl:when test=" $clsCode = 'INFRM' ">
                <xsl:text>inform</xsl:text>
            </xsl:when>
            <xsl:when test=" $clsCode = 'INVE' ">
                <xsl:text>invoice element</xsl:text>
            </xsl:when>
            <xsl:when test=" $clsCode = 'LIST' ">
                <xsl:text>working list</xsl:text>
            </xsl:when>
            <xsl:when test=" $clsCode = 'MPROT' ">
                <xsl:text>monitoring program</xsl:text>
            </xsl:when>
            <xsl:when test=" $clsCode = 'PCPR' ">
                <xsl:text>care provision</xsl:text>
            </xsl:when>
            <xsl:when test=" $clsCode = 'PROC' ">
                <xsl:text>procedure</xsl:text>
            </xsl:when>
            <xsl:when test=" $clsCode = 'REG' ">
                <xsl:text>registration</xsl:text>
            </xsl:when>
            <xsl:when test=" $clsCode = 'REV' ">
                <xsl:text>review</xsl:text>
            </xsl:when>
            <xsl:when test=" $clsCode = 'SBADM' ">
                <xsl:text>substance administration</xsl:text>
            </xsl:when>
            <xsl:when test=" $clsCode = 'SPCTRT' ">
                <xsl:text>speciment treatment</xsl:text>
            </xsl:when>
            <xsl:when test=" $clsCode = 'SUBST' ">
                <xsl:text>substitution</xsl:text>
            </xsl:when>
            <xsl:when test=" $clsCode = 'TRNS' ">
                <xsl:text>transportation</xsl:text>
            </xsl:when>
            <xsl:when test=" $clsCode = 'VERIF' ">
                <xsl:text>verification</xsl:text>
            </xsl:when>
            <xsl:when test=" $clsCode = 'XACT' ">
                <xsl:text>financial transaction</xsl:text>
            </xsl:when>
        </xsl:choose>
    </xsl:template>
    <!-- show participationType -->
    <xsl:template name="show-participationType">
        <xsl:param name="ptype"/>
        <xsl:choose>
            <xsl:when test=" $ptype='PPRF' ">
                <xsl:text>primary performer</xsl:text>
            </xsl:when>
            <xsl:when test=" $ptype='PRF' ">
                <xsl:text>performer</xsl:text>
            </xsl:when>
            <xsl:when test=" $ptype='VRF' ">
                <xsl:text>verifier</xsl:text>
            </xsl:when>
            <xsl:when test=" $ptype='SPRF' ">
                <xsl:text>secondary performer</xsl:text>
            </xsl:when>
        </xsl:choose>
    </xsl:template>
    <!-- show participationFunction -->
    <xsl:template name="show-participationFunction">
        <xsl:param name="pFunction"/>
        <xsl:choose>
            <!-- From the HL7 v3 ParticipationFunction code system -->
            <xsl:when test=" $pFunction = 'ADMPHYS' ">
                <xsl:text>(admitting physician)</xsl:text>
            </xsl:when>
            <xsl:when test=" $pFunction = 'ANEST' ">
                <xsl:text>(anesthesist)</xsl:text>
            </xsl:when>
            <xsl:when test=" $pFunction = 'ANRS' ">
                <xsl:text>(anesthesia nurse)</xsl:text>
            </xsl:when>
            <xsl:when test=" $pFunction = 'ATTPHYS' ">
                <xsl:text>(attending physician)</xsl:text>
            </xsl:when>
            <xsl:when test=" $pFunction = 'DISPHYS' ">
                <xsl:text>(discharging physician)</xsl:text>
            </xsl:when>
            <xsl:when test=" $pFunction = 'FASST' ">
                <xsl:text>(first assistant surgeon)</xsl:text>
            </xsl:when>
            <xsl:when test=" $pFunction = 'MDWF' ">
                <xsl:text>(midwife)</xsl:text>
            </xsl:when>
            <xsl:when test=" $pFunction = 'NASST' ">
                <xsl:text>(nurse assistant)</xsl:text>
            </xsl:when>
            <xsl:when test=" $pFunction = 'PCP' ">
                <xsl:text>(primary care physician)</xsl:text>
            </xsl:when>
            <xsl:when test=" $pFunction = 'PRISURG' ">
                <xsl:text>(primary surgeon)</xsl:text>
            </xsl:when>
            <xsl:when test=" $pFunction = 'RNDPHYS' ">
                <xsl:text>(rounding physician)</xsl:text>
            </xsl:when>
            <xsl:when test=" $pFunction = 'SASST' ">
                <xsl:text>(second assistant surgeon)</xsl:text>
            </xsl:when>
            <xsl:when test=" $pFunction = 'SNRS' ">
                <xsl:text>(scrub nurse)</xsl:text>
            </xsl:when>
            <xsl:when test=" $pFunction = 'TASST' ">
                <xsl:text>(third assistant)</xsl:text>
            </xsl:when>
            <!-- From the HL7 v2 Provider Role code system (2.16.840.1.113883.12.443) which is used by HITSP -->
            <xsl:when test=" $pFunction = 'CP' ">
                <xsl:text>(consulting provider)</xsl:text>
            </xsl:when>
            <xsl:when test=" $pFunction = 'PP' ">
                <xsl:text>(primary care provider)</xsl:text>
            </xsl:when>
            <xsl:when test=" $pFunction = 'RP' ">
                <xsl:text>(referring provider)</xsl:text>
            </xsl:when>
            <xsl:when test=" $pFunction = 'MP' ">
                <xsl:text>(medical home provider)</xsl:text>
            </xsl:when>
        </xsl:choose>
    </xsl:template>
    <xsl:template name="formatDateTime">
        <xsl:param name="date"/>
        <!-- month -->
        <xsl:variable name="month" select="substring ($date, 5, 2)"/>
        <xsl:choose>
            <xsl:when test="$month='01'">
                <xsl:text>January </xsl:text>
            </xsl:when>
            <xsl:when test="$month='02'">
                <xsl:text>February </xsl:text>
            </xsl:when>
            <xsl:when test="$month='03'">
                <xsl:text>March </xsl:text>
            </xsl:when>
            <xsl:when test="$month='04'">
                <xsl:text>April </xsl:text>
            </xsl:when>
            <xsl:when test="$month='05'">
                <xsl:text>May </xsl:text>
            </xsl:when>
            <xsl:when test="$month='06'">
                <xsl:text>June </xsl:text>
            </xsl:when>
            <xsl:when test="$month='07'">
                <xsl:text>July </xsl:text>
            </xsl:when>
            <xsl:when test="$month='08'">
                <xsl:text>August </xsl:text>
            </xsl:when>
            <xsl:when test="$month='09'">
                <xsl:text>September </xsl:text>
            </xsl:when>
            <xsl:when test="$month='10'">
                <xsl:text>October </xsl:text>
            </xsl:when>
            <xsl:when test="$month='11'">
                <xsl:text>November </xsl:text>
            </xsl:when>
            <xsl:when test="$month='12'">
                <xsl:text>December </xsl:text>
            </xsl:when>
        </xsl:choose>
        <!-- day -->
        <xsl:choose>
            <xsl:when test='substring ($date, 7, 1)="0"'>
                <xsl:value-of select="substring ($date, 8, 1)"/>
                <xsl:text>, </xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="substring ($date, 7, 2)"/>
                <xsl:text>, </xsl:text>
            </xsl:otherwise>
        </xsl:choose>
        <!-- year -->
        <xsl:value-of select="substring ($date, 1, 4)"/>
        <!-- time and US timezone -->
        <xsl:if test="string-length($date) > 8">
            <xsl:text>, </xsl:text>
            <!-- time -->
            <xsl:variable name="time">
                <xsl:value-of select="substring($date,9,6)"/>
            </xsl:variable>
            <xsl:variable name="hh">
                <xsl:value-of select="substring($time,1,2)"/>
            </xsl:variable>
            <xsl:variable name="mm">
                <xsl:value-of select="substring($time,3,2)"/>
            </xsl:variable>
            <xsl:variable name="ss">
                <xsl:value-of select="substring($time,5,2)"/>
            </xsl:variable>
            <xsl:if test="string-length($hh)&gt;1">
                <xsl:value-of select="$hh"/>
                <xsl:if test="string-length($mm)&gt;1 and not(contains($mm,'-')) and not (contains($mm,'+'))">
                    <xsl:text>:</xsl:text>
                    <xsl:value-of select="$mm"/>
                    <xsl:if test="string-length($ss)&gt;1 and not(contains($ss,'-')) and not (contains($ss,'+'))">
                        <xsl:text>:</xsl:text>
                        <xsl:value-of select="$ss"/>
                    </xsl:if>
                </xsl:if>
            </xsl:if>
            <!-- time zone -->
            <xsl:variable name="tzon">
                <xsl:choose>
                    <xsl:when test="contains($date,'+')">
                        <xsl:text>+</xsl:text>
                        <xsl:value-of select="substring-after($date, '+')"/>
                    </xsl:when>
                    <xsl:when test="contains($date,'-')">
                        <xsl:text>-</xsl:text>
                        <xsl:value-of select="substring-after($date, '-')"/>
                    </xsl:when>
                </xsl:choose>
            </xsl:variable>
            <xsl:choose>
                <!-- reference: http://www.timeanddate.com/library/abbreviations/timezones/na/ -->
                <xsl:when test="$tzon = '-0500' ">
                    <xsl:text>, EST</xsl:text>
                </xsl:when>
                <xsl:when test="$tzon = '-0600' ">
                    <xsl:text>, CST</xsl:text>
                </xsl:when>
                <xsl:when test="$tzon = '-0700' ">
                    <xsl:text>, MST</xsl:text>
                </xsl:when>
                <xsl:when test="$tzon = '-0800' ">
                    <xsl:text>, PST</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text> </xsl:text>
                    <xsl:value-of select="$tzon"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:if>
    </xsl:template>
    <!-- convert to lower case -->
    <xsl:template name="caseDown">
        <xsl:param name="data"/>
        <xsl:if test="$data">
            <xsl:value-of select="translate($data, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ','abcdefghijklmnopqrstuvwxyz')"/>
        </xsl:if>
    </xsl:template>
    <!-- convert to upper case -->
    <xsl:template name="caseUp">
        <xsl:param name="data"/>
        <xsl:if test="$data">
            <xsl:value-of select="translate($data,'abcdefghijklmnopqrstuvwxyz', 'ABCDEFGHIJKLMNOPQRSTUVWXYZ')"/>
        </xsl:if>
    </xsl:template>
    <!-- convert first character to upper case -->
    <xsl:template name="firstCharCaseUp">
        <xsl:param name="data"/>
        <xsl:if test="$data">
            <xsl:call-template name="caseUp">
                <xsl:with-param name="data" select="substring($data,1,1)"/>
            </xsl:call-template>
            <xsl:value-of select="substring($data,2)"/>
        </xsl:if>
    </xsl:template>
    <!-- show-noneFlavor -->
    <xsl:template name="show-noneFlavor">
        <xsl:param name="nf"/>
        <xsl:choose>
            <xsl:when test=" $nf = 'NI' ">
                <xsl:text>no information</xsl:text>
            </xsl:when>
            <xsl:when test=" $nf = 'INV' ">
                <xsl:text>invalid</xsl:text>
            </xsl:when>
            <xsl:when test=" $nf = 'MSK' ">
                <xsl:text>masked</xsl:text>
            </xsl:when>
            <xsl:when test=" $nf = 'NA' ">
                <xsl:text>not applicable</xsl:text>
            </xsl:when>
            <xsl:when test=" $nf = 'UNK' ">
                <xsl:text>unknown</xsl:text>
            </xsl:when>
            <xsl:when test=" $nf = 'OTH' ">
                <xsl:text>other</xsl:text>
            </xsl:when>
        </xsl:choose>
    </xsl:template>
    <xsl:template name="addCSS">
        <style type="text/css">
         <xsl:text>
body {
    padding-left: 2em;
    padding-right: 2em;
    color: #000;
    background-color: #FFF;
    font-family: "Verdana", "Lucida Grande", Tahoma, sans-serif;
    font-size: 12px;
}

a {
    text-decoration: none;
    color: black;
}
a:hover {
    text-decoration: underline;
    color: black;
}

div
{
    margin-left: 3em;
}
table {
    width: 100%;
}

ul{
    list-style: none;
    line-height: 150%;
}

h3
{
    padding-top: 16px;
}

td {
    padding: 4px;
    vertical-align: top;
    border-width: 0px;
}

.header_table tr td:first-child
{
    background-color: #dde;
}

.header_table tr td:nth-child(3)
{
    background-color: #dde;
}

.header_table td
{
    padding: 4px;
    vertical-align: top;
    border-width: 0px;
    background-color: #eef;
}

.h1center {
    font-size: 12pt;
}

.header_table{
    margin-bottom: 8px;
    border-spacing: 1px;
    background-color: #bbc;
}

.header_table_label
{
    background-color: #ccd;
    text-align: left;
}

.narr_table {
    border-collapse:separate; 
    border: 0px; 
    border-spacing: 1px;
    width: 100%;
    background-color: #dd9;
    margin-top: 8px;
    margin-bottom: 8px;
}

.narr_tr {
    background-color: #ffc;
    color: black;
}

.narr_th {
    background-color: #eea;
    text-align: left;
    padding: 4px;
    border-width: 0px;
}

.td_label {
    font-weight: bold;
}

hr
{
    width: 100%;
    border: 0;
    height: 1px;
    background: #ccc;
}

          </xsl:text>
        </style>
    </xsl:template>
</xsl:stylesheet>
