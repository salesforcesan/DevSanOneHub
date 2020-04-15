trigger JobCommentTrigger on JobComment__c (before insert) {
  new JobCommentTriggerHandler().run();
    
}