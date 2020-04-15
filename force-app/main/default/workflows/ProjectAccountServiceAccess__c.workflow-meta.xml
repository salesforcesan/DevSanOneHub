<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>UpdatePASAccessUniqueKey</fullName>
        <field>UniqueKey__c</field>
        <formula>CASESAFEID( ProjectAccount__c ) + CASESAFEID( ProjectService__c )</formula>
        <name>Update PASAccess Unique Key</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Project Account Service Access - Prevent Duplicates</fullName>
        <actions>
            <name>UpdatePASAccessUniqueKey</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>ProjectAccountServiceAccess__c.Name</field>
            <operation>notEqual</operation>
            <value>NULL</value>
        </criteriaItems>
        <description>Project Account Service Access - Prevent Duplicates</description>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
</Workflow>
