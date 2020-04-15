<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>UpdateSQUniqueKey</fullName>
        <field>UniqueKey__c</field>
        <formula>(CASESAFEID(Service__c) &amp; &quot;-&quot; &amp; CASESAFEID(Question__c))</formula>
        <name>Update SQ Unique Key</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Service Question - Prevent Duplicates</fullName>
        <actions>
            <name>UpdateSQUniqueKey</name>
            <type>FieldUpdate</type>
        </actions>
        <active>false</active>
        <criteriaItems>
            <field>ServiceQuestion__c.Name</field>
            <operation>notEqual</operation>
            <value>null</value>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
</Workflow>
