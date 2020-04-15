trigger ProjectServiceTargetTrigger on ProjectServiceTarget__c (before insert, before update, before delete, after insert, after update, after delete)
{
    new ProjectServiceTargetTriggerHandler().run();
}