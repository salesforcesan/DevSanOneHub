<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>UniqueRetailerServiceEquipment</fullName>
        <field>UniqueKey__c</field>
        <formula>(CASESAFEID(Retailer__c) &amp; &quot;-&quot; &amp; CASESAFEID(Service__c) &amp; &quot;-&quot; &amp; CASESAFEID(Equipment__c))</formula>
        <name>UniqueRetailerServiceEquipment</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
        <reevaluateOnChange>true</reevaluateOnChange>
    </fieldUpdates>
    <rules>
        <fullName>Retailer Service Equipment - Prevent Duplicates</fullName>
        <actions>
            <name>UniqueRetailerServiceEquipment</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>RetailerServiceEquipment__c.Name</field>
            <operation>notEqual</operation>
        </criteriaItems>
        <triggerType>onAllChanges</triggerType>
    </rules>
</Workflow>
