trigger ProjectInvoiceLineItemTrigger on ProjectInvoiceLineItem__c (before insert)  {
    new ProjectInvoiceLineItemTriggerHandler().run();
}