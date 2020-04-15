<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>PopulateUniqueIDAttrinuteDefResponse</fullName>
        <field>UniqueID__c</field>
        <formula>Attribute__r.AttributeTitle__c+ DefinedResponse__c</formula>
        <name>Populate UniqueID AttrinuteDefResponse</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Populate AttributeDefResponse Unique ID</fullName>
        <actions>
            <name>PopulateUniqueIDAttrinuteDefResponse</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>AttributeDefinedResponse__c.Name</field>
            <operation>notEqual</operation>
        </criteriaItems>
        <description>Populates unique ID for Attribute Defined Response - a combination of attribute title and defined response.</description>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
</Workflow>
