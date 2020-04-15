<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Populate_RetailerCode_Material</fullName>
        <field>OneHubRetailerId__c</field>
        <formula>Retailer__r.OneHubRetailerId__c</formula>
        <name>Populate RetailerCode Material</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_Material_Retailer_Code</fullName>
        <field>OneHubRetailerId__c</field>
        <formula>FulfillmentCenter__r.OneHubRetailerId__c</formula>
        <name>Update Material Retailer Code</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Populate Material OneHub Retailer ID</fullName>
        <actions>
            <name>Populate_RetailerCode_Material</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Material__c.Name</field>
            <operation>notEqual</operation>
            <value>NULL</value>
        </criteriaItems>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Set Material Retailer Code On Create</fullName>
        <actions>
            <name>Update_Material_Retailer_Code</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Material__c.Name</field>
            <operation>notEqual</operation>
            <value>null</value>
        </criteriaItems>
        <triggerType>onCreateOnly</triggerType>
    </rules>
</Workflow>
