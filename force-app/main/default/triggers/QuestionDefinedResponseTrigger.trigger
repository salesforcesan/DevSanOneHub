trigger QuestionDefinedResponseTrigger on QuestionDefinedResponse__c (before insert, after insert, before Update,after update,before delete) {
   new QuestionDefinedResponseHandler().run();
}