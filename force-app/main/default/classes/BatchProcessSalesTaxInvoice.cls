global class BatchProcessSalesTaxInvoice implements Database.Batchable<sObject>, Database.Stateful {
    
    
    
	Set<String> clearedpis = new Set<String>();    
	ApexJobTracker__c ajt {get; set;}    
    
    global BatchProcessSalesTaxInvoice() {
        
    }
    
    global BatchProcessSalesTaxInvoice(string projectTypeId) {
        
    }
        
    global Database.QueryLocator start(Database.BatchableContext BC) {
        
		ajt = AppUtil.InsertApexJobTrackerRecord('ProjectInvoice', 'Create SalesTax Invoice', '');        
        
        return Database.getQueryLocator([SELECT Id, Name, ProjectInvoice__c FROM ProjectInvoiceLineItem__c WHERE 
                                         ServiceType__c = :CONSTANTS.PROJECT_INVOICE_LINEITEM_SERVICETYPE_LABOR AND
                                         ProjectInvoice__r.Status__c = :CONSTANTS.PROJECT_INVOICE_STATUS_CREATED
                                        ]);
        
    }
   
    global void execute(Database.BatchableContext BC, List<ProjectInvoiceLineItem__c> scope) {
        
        List<ProjectInvoiceLineItem__c> newpilis = new List<ProjectInvoiceLineItem__c>();
        ProjectInvoiceLineItem__c pili = scope[0];
        
        //Check if there's an existing Line Item for SalesTax and remove it
        if (!clearedpis.contains(pili.ProjectInvoice__c))
        {
            delete [SELECT Id FROM ProjectInvoiceLineItem__c WHERE ProjectInvoice__c = :pili.ProjectInvoice__c AND 
                    ServiceType__c = :CONSTANTS.PROJECT_INVOICE_LINEITEM_SERVICETYPE_SALESTAX];
			clearedpis.add(pili.ProjectInvoice__c);
        }
        
        AggregateResult[] aggresults = [SELECT LaborTaxLawsonID__c, SUM(SalesTax__c) total FROM ProjectInvoiceLineItemDetail__c 
                                 		WHERE ProjectInvoiceLineItem__c = :pili.Id AND LaborTaxLawsonID__c != null 
                                        GROUP BY LaborTaxLawsonID__c HAVING SUM(SalesTax__c) > 0];
        
        for (AggregateResult ar : aggresults)  {
            string lawsontaxid = ar.get(CONSTANTS.CURRENTNAMESPACEPREFIX + 'LaborTaxLawsonID__c') == null? '':String.valueof(ar.get(CONSTANTS.CURRENTNAMESPACEPREFIX + 'LaborTaxLawsonID__c'));
            string lawsonsubaccount = lawsontaxid.right(3);
            ProjectInvoiceLineItem__c newpili = new ProjectInvoiceLineItem__c();
            newpili.ProjectInvoice__c = pili.ProjectInvoice__c;
            newpili.Description__c = 'Salestax for: ' + lawsontaxid; 
            newpili.Type__c = Constants.PROJECT_INVOICE_LINEITEM_TYPE_LUMPSUM;
            newpili.ServiceType__c = Constants.PROJECT_INVOICE_LINEITEM_SERVICETYPE_SALESTAX;
            newpili.Amount__c = ar.get('total') == null? 0:Decimal.valueOf(String.valueof(ar.get('total')));
            newpili.Rate__c = ar.get('total') == null? 0:Decimal.valueOf(String.valueof(ar.get('total')));
            newpili.LawsonSubAccount2__c = lawsonsubaccount;
            newpilis.add(newpili);
        }

		insert newpilis;        
    }

   	global void finish(Database.BatchableContext BC) {
    
        string status = 'Success';
        AsyncApexJob a = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email FROM AsyncApexJob WHERE Id = :BC.getJobId()];    
        
        if (a.NumberOfErrors > 0)
        {
        	status = 'Failure';
        }
        AppUtil.UpdateApexJobTracker(ajt.Id,status,null, DateTime.Now(), false);                
    
        //to clear batch processed
        EndProcess('ProjectInvoice');   
    }
    
     public static void EndProcess(String entity){
        
        List<ProcessLastSyncTime__c> plsts = [Select Id, CurrentProcessId__c 
                                              From ProcessLastSyncTime__c 
                                              WHERE ProcessName__c =: entity LIMIT 1];                
        
        plsts[0].CurrentProcessId__c = '';
        update plsts[0];
    }
    
}