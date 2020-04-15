<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Unique_Attribute</fullName>
        <description>Unique rule to prevent duplicate Attribute</description>
        <field>UniqueKey__c</field>
        <formula>TEXT(AttributeOrder__c)&amp;&quot;-&quot;&amp;CASESAFEID(Service__c)</formula>
        <name>Unique Attribute</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
        <reevaluateOnChange>true</reevaluateOnChange>
    </fieldUpdates>
    <rules>
        <fullName>Prevent Duplicate Service Attributes</fullName>
        <actions>
            <name>Unique_Attribute</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>ServiceAttribute__c.AttributeOrder__c</field>
            <operation>notEqual</operation>
        </criteriaItems>
        <triggerType>onAllChanges</triggerType>
    </rules>
</Workflow>
