<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>uniqueCycle</fullName>
        <field>UniqueKey__c</field>
        <formula>Name&amp; &quot;-&quot; &amp; CASESAFEID(RetailerAccount__r.Name)</formula>
        <name>uniqueCycle</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
        <reevaluateOnChange>true</reevaluateOnChange>
    </fieldUpdates>
    <rules>
        <fullName>Set Cycle Uniquekey</fullName>
        <actions>
            <name>uniqueCycle</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Cycle__c.Name</field>
            <operation>notEqual</operation>
            <value>NULL</value>
        </criteriaItems>
        <triggerType>onAllChanges</triggerType>
    </rules>
</Workflow>
