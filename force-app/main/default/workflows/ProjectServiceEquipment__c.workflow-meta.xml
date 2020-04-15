<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>UniqueProjectServiceEquipment</fullName>
        <field>UniqueKey__c</field>
        <formula>(CASESAFEID(ProjectService__c) &amp; &quot;-&quot; &amp; CASESAFEID(Equipment__c))</formula>
        <name>UniqueProjectServiceEquipment</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
        <reevaluateOnChange>true</reevaluateOnChange>
    </fieldUpdates>
    <rules>
        <fullName>Project Service Equipment - Prevent Duplicates</fullName>
        <actions>
            <name>UniqueProjectServiceEquipment</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>ProjectServiceEquipment__c.Name</field>
            <operation>notEqual</operation>
        </criteriaItems>
        <triggerType>onAllChanges</triggerType>
    </rules>
</Workflow>
