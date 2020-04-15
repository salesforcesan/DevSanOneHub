<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>PopulateRetailerCode</fullName>
        <field>OneHubRetailerId__c</field>
        <formula>Retailer__r.OneHubRetailerId__c</formula>
        <name>Populate Retailer Code</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_Retailer_Code</fullName>
        <field>OneHubRetailerId__c</field>
        <name>Update Retailer Code</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Null</operation>
        <protected>false</protected>
        <reevaluateOnChange>true</reevaluateOnChange>
    </fieldUpdates>
    <rules>
        <fullName>Populate Target OneHub Retailer ID</fullName>
        <actions>
            <name>PopulateRetailerCode</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Target__c.TargetName__c</field>
            <operation>notEqual</operation>
            <value>NULL</value>
        </criteriaItems>
        <triggerType>onAllChanges</triggerType>
    </rules>
</Workflow>
