<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>ProjectSvcCertUpdateUniqueKey</fullName>
        <field>UniqueKey__c</field>
        <formula>(CASESAFEID(ProjectService__c) &amp; &quot;-&quot; &amp; CASESAFEID(Certification__c))</formula>
        <name>ProjectSvcCertUpdateUniqueKey</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Project Service Certification - Prevent Duplicates</fullName>
        <actions>
            <name>ProjectSvcCertUpdateUniqueKey</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>ProjectServiceCertification__c.Name</field>
            <operation>notEqual</operation>
            <value>null</value>
        </criteriaItems>
        <triggerType>onAllChanges</triggerType>
    </rules>
</Workflow>
