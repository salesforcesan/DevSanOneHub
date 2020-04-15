<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>UniqueRetailerService</fullName>
        <field>UniqueKey__c</field>
        <formula>(CASESAFEID(Retailer__c) &amp; &quot;-&quot; &amp; CASESAFEID(Service__c))</formula>
        <name>UniqueRetailerService</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
        <reevaluateOnChange>true</reevaluateOnChange>
    </fieldUpdates>
    <rules>
        <fullName>Retailer Service - Prevent Duplicates</fullName>
        <actions>
            <name>UniqueRetailerService</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>RetailerService__c.Name</field>
            <operation>notEqual</operation>
        </criteriaItems>
        <triggerType>onAllChanges</triggerType>
    </rules>
</Workflow>
