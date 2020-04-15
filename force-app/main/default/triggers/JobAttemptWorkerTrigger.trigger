trigger JobAttemptWorkerTrigger on JobAttemptWorker__c (before insert, after insert, after update,before Update,before delete) {
  new JobAttemptWorkerTriggerHandler().run();
}