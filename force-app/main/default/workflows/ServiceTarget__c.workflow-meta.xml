<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Service_Target_Prevent_Duplicates</fullName>
        <field>UniqueKey__c</field>
        <formula>CASESAFEID(Service__c) + &quot;_&quot; + CASESAFEID(Target__c)</formula>
        <name>Service Target - Prevent Duplicates</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Service Target - Prevent Duplicates</fullName>
        <actions>
            <name>Service_Target_Prevent_Duplicates</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>ServiceTarget__c.TargetName__c</field>
            <operation>notEqual</operation>
            <value>null</value>
        </criteriaItems>
        <triggerType>onCreateOnly</triggerType>
    </rules>
</Workflow>
