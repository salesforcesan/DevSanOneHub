<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>UpdatePAUniqueKey</fullName>
        <field>UniqueKey__c</field>
        <formula>CASESAFEID(Project__c) + CASESAFEID(Account__c) +  CASESAFEID(BillToContact__c)</formula>
        <name>Update PA Unique Key</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Prevent Duplicates Accounts</fullName>
        <actions>
            <name>UpdatePAUniqueKey</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>ProjectAccount__c.AccountName__c</field>
            <operation>notEqual</operation>
            <value>Null</value>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
</Workflow>
