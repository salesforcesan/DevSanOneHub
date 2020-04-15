trigger ProjectServiceTrigger on ProjectService__c (before insert, before update, after insert, after update, before delete) {

    new ProjectServiceTriggerHandler().run();
}