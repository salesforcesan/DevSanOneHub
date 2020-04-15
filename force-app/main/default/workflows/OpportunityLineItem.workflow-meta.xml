<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Copy_Value</fullName>
        <field>Gross_Margin__c</field>
        <formula>Margin_Calculation__c</formula>
        <name>Copy Value</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Update product Profit value</fullName>
        <actions>
            <name>Copy_Value</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>OpportunityLineItem.Margin_Calculation__c</field>
            <operation>notEqual</operation>
        </criteriaItems>
        <description>The rule is used to update the Profit field (currency field) with the value from Profit Calculated field (formula field)</description>
        <triggerType>onAllChanges</triggerType>
    </rules>
</Workflow>
