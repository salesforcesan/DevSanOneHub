trigger ProjectInvoiceTrigger on ProjectInvoice__c (before insert, after insert,before update,after update) {
	new ProjectInvoiceTriggerHandler().run();
}