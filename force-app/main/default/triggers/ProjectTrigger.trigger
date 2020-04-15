trigger ProjectTrigger on Project__c(before insert, after insert, before update,after update, before delete) {

    new ProjectTriggerHandler().run();

}