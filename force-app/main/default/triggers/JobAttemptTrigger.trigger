trigger JobAttemptTrigger on JobAttempt__c (after update,before Update,before delete,after delete) {
    new JobAttemptTriggerHandler().run();
}