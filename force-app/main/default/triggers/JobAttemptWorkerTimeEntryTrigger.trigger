trigger JobAttemptWorkerTimeEntryTrigger on JobAttemptWorkerTimeEntry__c (after insert, after update) {
    new JobAttemptWorkerTimeEntryTriggerHandler().run();

}