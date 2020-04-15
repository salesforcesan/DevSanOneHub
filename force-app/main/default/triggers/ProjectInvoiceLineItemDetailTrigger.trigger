trigger ProjectInvoiceLineItemDetailTrigger on ProjectInvoiceLineItemDetail__c (before insert, before update, after insert, after update, before delete) {
 new PILineItemDetailTriggerHandler().run();
}