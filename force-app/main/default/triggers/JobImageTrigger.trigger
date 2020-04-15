trigger JobImageTrigger on JobImage__c (before insert) {
  new JobImageTriggerHandler().run();
    
}