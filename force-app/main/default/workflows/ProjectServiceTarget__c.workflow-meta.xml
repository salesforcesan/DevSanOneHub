<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>UpdatePSTUniqueKey</fullName>
        <field>UniqueKey__c</field>
        <formula>CASESAFEID(ProjectService__c) +  CASESAFEID(Target__c)</formula>
        <name>Update PST Unique Key</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>UpdateTargetType</fullName>
        <field>TargetType__c</field>
        <formula>Target__r.RecordType.Name</formula>
        <name>UpdateTargetType</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
        <targetObject>ProjectService__c</targetObject>
    </fieldUpdates>
    <rules>
        <fullName>Project Service Target - Prevent Duplicates</fullName>
        <actions>
            <name>UpdatePSTUniqueKey</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>UpdateTargetType</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <booleanFilter>1</booleanFilter>
        <criteriaItems>
            <field>ProjectServiceTarget__c.Name</field>
            <operation>notEqual</operation>
            <value>Null</value>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
</Workflow>
