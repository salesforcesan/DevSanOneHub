trigger ProjectLocationTrigger on ProjectLocation__c (after insert, before delete, after Update, after delete,before Update) {
    
    new ProjectLocationTriggerHandler().run();
}