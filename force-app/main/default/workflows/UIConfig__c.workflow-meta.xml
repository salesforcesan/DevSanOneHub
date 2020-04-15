<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Set_UIConfig_Unique_Key</fullName>
        <field>UIElement__c</field>
        <formula>UI_Element__c &amp; &quot;-&quot; &amp; TEXT(Status__c)</formula>
        <name>Set UIConfig Unique Key</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>UI Config - Prevent Duplicates</fullName>
        <actions>
            <name>Set_UIConfig_Unique_Key</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>UIConfig__c.Name</field>
            <operation>notEqual</operation>
            <value>null</value>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
</Workflow>
