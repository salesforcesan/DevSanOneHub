trigger JobTrigger on Job__c (after update,before Update,before delete,after delete,after insert) {

    new JobTriggerHandler().run();
}