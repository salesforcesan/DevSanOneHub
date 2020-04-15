trigger ProjectAccountTrigger on ProjectAccount__c (before insert, after insert, before update,after update, before delete) {
    new ProjectAccountTriggerHandler().run();
}