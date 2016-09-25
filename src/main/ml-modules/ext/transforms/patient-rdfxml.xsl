<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:dveivr="http://dveivr.dha.health.mil/" xmlns:enc="http://dveivr.dha.health.mil/xml/encounter" xmlns:pat="http://dveivr.dha.health.mil/xml/patient" xmlns:env="http://dveivr.dha.health.mil/xml/envelope" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:dct="http://purl.org/dc/terms/" xmlns:core="http://model.dveivr.dha.health.mil/DVEIVR_core#" xmlns:xsd="http://www.w3.org/2001/XMLSchema#" version="2.0" exclude-result-prefixes="xsd dveivr enc pat env">
    <xsl:output encoding="UTF-8" indent="yes"/>
    <xsl:param name="iri-prefix" required="no" select="'http://rdf.dveivr.dha.health.mil/patient/'"/>
    <xsl:variable name="patientID" select="normalize-space(/env:envelope/pat:patient/pat:patientId)"/>
    <xsl:variable name="referralIDs" select="/env:envelope/enc:encounters/enc:encounter/enc:referralId"/>
    <xsl:function name="dveivr:branch-iri">
        <xsl:param name="branch" as="element(pat:serviceBranch)"/>
        <xsl:choose>
            <xsl:when test="contains(normalize-space($branch), 'Marine')">
                <xsl:sequence select="replace(concat($iri-prefix, 'Marines'), 'patient', 'branch')"/>
            </xsl:when>
            <xsl:when test="matches(normalize-space($branch), '(Navy|Naval)')">
                <xsl:sequence select="replace(concat($iri-prefix, 'Navy'), 'patient', 'branch')"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="replace(concat($iri-prefix, 'Unknown'), 'patient', 'branch')"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    <xsl:template match="/">
        <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:dct="http://purl.org/dc/terms/" xmlns:core="http://model.dveivr.dha.health.mil/DVEIVR_core#" xmlns:xsd="http://www.w3.org/2001/XMLSchema#">
            <xsl:apply-templates select="env:envelope"/>
        </rdf:RDF>
    </xsl:template>
    <xsl:template match="env:envelope">
        <xsl:apply-templates select="enc:encounters"/>
        <xsl:apply-templates select="pat:patient"/>
    </xsl:template>
    <xsl:template match="enc:encounters">
        <xsl:apply-templates select="enc:encounter"/>
    </xsl:template>
    <xsl:template match="enc:encounter">
        <xsl:variable name="subj-iri" select="replace(concat($iri-prefix, enc:encounterId/normalize-space()), 'patient', 'encounter')"/>
        <rdf:Description rdf:about="{$subj-iri}">
            <rdf:type rdf:resource="http://model.dveivr.dha.health.mil/DVEIVR_core#Encounter"/>
            <xsl:apply-templates select="enc:encounterId"/>
            <xsl:apply-templates select="enc:patientId">
                <xsl:with-param name="iri" select="concat($iri-prefix, $patientID)"/>
            </xsl:apply-templates>
            <xsl:apply-templates select="enc:visitDate"/>
            <xsl:apply-templates select="enc:procedureSummaryCommentText | enc:symptoms"/>
            <xsl:apply-templates select="enc:providerId" mode="domain-encounter"/>
            <!-- <core:providerInEncounter rdf:resource="http://prefix/provider/598"/> -->
        </rdf:Description>
        <xsl:apply-templates select="enc:providerId" mode="resource-description"/>
        <xsl:apply-templates select="enc:referralId" mode="resource-description"/>
    </xsl:template>
    <xsl:template match="pat:patient">
        <xsl:variable name="subj-iri" select="concat($iri-prefix, $patientID)"/>
        <rdf:Description rdf:about="{$subj-iri}">
            <rdf:type rdf:resource="http://model.dveivr.dha.health.mil/DVEIVR_core#Patient"/>
            <xsl:apply-templates select="pat:patientId"/>
            <xsl:apply-templates select="pat:edipn"/>
            <xsl:apply-templates select="pat:firstName"/>
            <xsl:apply-templates select="pat:middleName"/>
            <xsl:apply-templates select="pat:lastName"/>
            <xsl:apply-templates select="pat:gender" mode="domain-patient">
                <xsl:with-param name="iri" select="$subj-iri"/>
            </xsl:apply-templates>
            <xsl:apply-templates select="pat:ethnicity" mode="domain-patient">
                <xsl:with-param name="iri" select="$subj-iri"/>
            </xsl:apply-templates>
            <xsl:apply-templates select="pat:race"/>
            <xsl:apply-templates select="pat:birthDate"/>
            <xsl:apply-templates select="pat:category"/>
            <xsl:for-each select="$referralIDs">
                <xsl:comment>Referral or transfer</xsl:comment>
                <core:patientTransfer rdf:resource="{replace(concat($iri-prefix, normalize-space(.)), 'patient', 'referral')}"/>
            </xsl:for-each>
            <xsl:apply-templates select="pat:serviceBranch" mode="domain-patient"/>
        </rdf:Description>
        <xsl:apply-templates select="pat:gender" mode="resource-description">
            <xsl:with-param name="iri" select="$subj-iri"/>
        </xsl:apply-templates>
        <xsl:apply-templates select="pat:ethnicity" mode="resource-description">
            <xsl:with-param name="iri" select="$subj-iri"/>
        </xsl:apply-templates>
        <xsl:apply-templates select="pat:serviceBranch" mode="resource-description"/>
    </xsl:template>
    
    <!-- Begin domain templates -->
    <xsl:template match="pat:patientId">
        <core:personIdentifier rdf:datatype="http://www.w3.org/2001/XMLSchema#string">
            <xsl:value-of select="normalize-space(.)"/>
        </core:personIdentifier>
    </xsl:template>
    <xsl:template match="pat:edipn">
        <core:ElectronicDataInterchangePersonNumber rdf:datatype="http://www.w3.org/2001/XMLSchema#string">
            <xsl:value-of select="normalize-space(.)"/>
        </core:ElectronicDataInterchangePersonNumber>
    </xsl:template>
    <xsl:template match="pat:firstName">
        <core:personFirstName rdf:datatype="http://www.w3.org/2001/XMLSchema#string">
            <xsl:value-of select="normalize-space(.)"/>
        </core:personFirstName>
    </xsl:template>
    <xsl:template match="pat:middleName">
        <core:personMiddleName rdf:datatype="http://www.w3.org/2001/XMLSchema#string">
            <xsl:value-of select="normalize-space(.)"/>
        </core:personMiddleName>
    </xsl:template>
    <xsl:template match="pat:lastName">
        <core:personLastName rdf:datatype="http://www.w3.org/2001/XMLSchema#string">
            <xsl:value-of select="normalize-space(.)"/>
        </core:personLastName>
    </xsl:template>
    <xsl:template match="pat:gender" mode="domain-patient">
        <xsl:param name="iri"/>
        <core:hasGender rdf:resource="{replace($iri, 'patient', 'gender')}"/>
    </xsl:template>
    <xsl:template match="pat:ethnicity" mode="domain-patient">
        <xsl:param name="iri"/>
        <core:hasEthnicity rdf:resource="{replace($iri, 'patient', 'ethnicity')}"/>
    </xsl:template>
    <xsl:template match="pat:race">
        <core:personRace rdf:datatype="http://www.w3.org/2001/XMLSchema#string">
            <xsl:value-of select="normalize-space(.)"/>
        </core:personRace>
    </xsl:template>
    <xsl:template match="pat:birthDate">
        <core:dateOfBirth rdf:datatype="http://www.w3.org/2001/XMLSchema#dateTime">
            <xsl:value-of select="normalize-space(.)"/>
        </core:dateOfBirth>
    </xsl:template>
    <xsl:template match="pat:category">
        <core:patientCategory xml:lang="en">
            <xsl:value-of select="normalize-space(.)"/>
        </core:patientCategory>
    </xsl:template>
    <xsl:template match="pat:serviceBranch" mode="domain-patient">
        <xsl:comment>FIXME BEGIN</xsl:comment>
        <core:personMilitaryBranch rdf:resource="{dveivr:branch-iri(.)}"/>
        <xsl:comment>FIXME END</xsl:comment>
    </xsl:template>
    <xsl:template match="enc:encounterId">
        <xsl:comment>FIXME BEGIN</xsl:comment>
        <core:encounterIdentifier rdf:datatype="http://www.w3.org/2001/XMLSchema#string">
            <xsl:value-of select="normalize-space(.)"/>
        </core:encounterIdentifier>
        <xsl:comment>FIXME END</xsl:comment>
    </xsl:template>
    <xsl:template match="enc:patientId">
        <xsl:param name="iri"/>
        <core:patientInEncounter rdf:resource="{$iri}"/>
    </xsl:template>
    <xsl:template match="enc:visitDate">
        <core:encounterDate rdf:datatype="http://www.w3.org/2001/XMLSchema#dateTime">
            <xsl:value-of select="normalize-space(.)"/>
        </core:encounterDate>
    </xsl:template>
    <xsl:template match="enc:procedureSummaryCommentText | enc:symptoms">
        <xsl:comment>FIXME BEGIN</xsl:comment>
        <dct:description xml:lang="en">
            <xsl:value-of select="normalize-space(.)"/>
        </dct:description>
        <xsl:comment>FIXME END</xsl:comment>
    </xsl:template>
    <xsl:template match="enc:providerId" mode="domain-encounter">
        <core:providerInEncounter rdf:resource="{replace(concat($iri-prefix, normalize-space(.)), 'patient', 'provider')}"/>
    </xsl:template>
    <!-- End Domain templates -->
    <!-- Begin Resource Description templates -->
    <xsl:template match="pat:gender" mode="resource-description">
        <xsl:param name="iri"/>
        <rdf:Description rdf:about="{replace($iri, 'patient', 'gender')}">
            <rdf:type rdf:resource="http://model.dveivr.dha.health.mil/DVEIVR_core#PersonGender"/>
            <xsl:comment>FIXME BEGIN</xsl:comment>
            <core:gender xml:lang="en">
                <xsl:value-of select="normalize-space(.)"/>
            </core:gender>
            <xsl:comment>FIXME END</xsl:comment>
        </rdf:Description>
    </xsl:template>
    <xsl:template match="pat:ethnicity" mode="resource-description">
        <xsl:param name="iri"/>
        <rdf:Description rdf:about="{replace($iri, 'patient', 'ethnicity')}">
            <rdf:type rdf:resource="http://model.dveivr.dha.health.mil/DVEIVR_core#EthnicGroup"/>
            <xsl:comment>FIXME BEGIN</xsl:comment>
            <core:ethnicity xml:lang="en">
                <xsl:value-of select="normalize-space(.)"/>
            </core:ethnicity>
            <xsl:comment>FIXME END</xsl:comment>
        </rdf:Description>
    </xsl:template>
    <xsl:template match="enc:providerId" mode="resource-description">
        <rdf:Description rdf:about="{replace(concat($iri-prefix, normalize-space(.)), 'patient', 'provider')}">
            <rdf:type rdf:resource="http://model.dveivr.dha.health.mil/DVEIVR_core#Provider"/>
        </rdf:Description>
    </xsl:template>
    <xsl:template match="enc:referralId" mode="resource-description">
        <rdf:Description rdf:about="{replace(concat($iri-prefix, normalize-space(.)), 'patient', 'referral')}">
            <rdf:type rdf:resource="http://model.dveivr.dha.health.mil/DVEIVR_core#Transfer"/>
        </rdf:Description>            
    </xsl:template>
    <xsl:template match="pat:serviceBranch" mode="resource-description">
        <xsl:comment>FIXME BEGIN</xsl:comment>
        <rdf:Description rdf:about="{dveivr:branch-iri(.)}">
            <rdf:type rdf:resource="http://model.dveivr.dha.health.mil/DVEIVR_core#MilitaryServiceBranch"/>
        </rdf:Description>
        <xsl:comment>FIXME END</xsl:comment>
    </xsl:template>
</xsl:stylesheet>