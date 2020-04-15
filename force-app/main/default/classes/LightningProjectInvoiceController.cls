public with sharing class LightningProjectInvoiceController {
    
    @AuraEnabled
    public static string  getActiveGroupedInvoicesApex() {
        try
        {
            return ProjectInvoiceActionHelper.GetActiveGroupedInvoices();
        }
        catch(Exception ex)
        {
            throw new System.AuraHandledException(ex.getMessage());
        }
    }     
       
    @AuraEnabled
    public static string  getAvailableInvoicesforGroupedInvoiceApex(String jsonSearch) {
        //try
        //{
            return ProjectInvoiceActionHelper.GetAvailableInvoicesforGroupedInvoice(jsonSearch);
        //}
        //catch(Exception ex)
        //{            
        //    throw new System.AuraHandledException(ex.getMessage());
        //}
    }  
    
    @AuraEnabled
    public static string  GetGroupedProjectInvoicesApex(String groupedInvoiceId) {
        //try
        //{
            return ProjectInvoiceActionHelper.GetInvoices(groupedInvoiceId);
        //}
        //catch(Exception ex)
        //{
        //    throw new System.AuraHandledException(ex.getMessage());
        //}
    } 
        
    @AuraEnabled
    public static string  getInvoiceInfoApex(String invoiceId) {
        //try
        //{
            return ProjectInvoiceActionHelper.GetInvoiceInfo(invoiceId);
        //}
        //catch(Exception ex)
        //{
        //    throw new System.AuraHandledException(ex.getMessage());
        //}
    } 
    
    @AuraEnabled
    public static Boolean  getInvoicesApex(List<String> invoiceIds, String groupedInvoiceId) {
        //try
        //{
            return ProjectInvoiceActionHelper.GroupInvoices(invoiceIds, groupedInvoiceId);
        //}
        //catch(Exception ex)
        //{
        //    throw new System.AuraHandledException(ex.getMessage());
        //}
    } 
    
    @AuraEnabled
    public static string  manageGroupInvoice(string invoiceId, String groupedInvoiceIds) {
        //try
        //{
            return ProjectInvoiceActionHelper.ManageGroupInvoice(invoiceId, groupedInvoiceIds);
        //}
        //catch(Exception ex)
        //{
        //    throw new System.AuraHandledException(ex.getMessage());
        //}
    } 
    
    @AuraEnabled
    public static ProjectInvoiceWrapper GetProjectInvoice(String Id) {
        
        ProjectInvoiceWrapper piw = new ProjectInvoiceWrapper();        
        piw = ProjectInvoiceActionHelper.GetProjectInvoiceDetail(Id);
        return piw;        
    } 
    
    @AuraEnabled
    public static string CloneProjectInvoice(String Id, string reasonCode, string comments) {
        //try
        //{
            return ProjectInvoiceActionHelper.CloneProjectInvoice(Id,reasonCode,comments);
        //}
        //catch(Exception ex)
        //{
        //    throw new System.AuraHandledException(ex.getMessage());
        //}
    } 
    
    @AuraEnabled
    public static List<String> GetProjectInvoiceCancelReasons() {
        List<String> options = new List<String>();
        Schema.DescribeFieldResult fieldResult = ProjectInvoice__c.CloneReasonCode__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        options.add('--SELECT--');
        for (Schema.PicklistEntry f : ple) {
            options.add(f.getLabel());
        }
                
        return options;
    }
    
    @AuraEnabled
    public static String getNamespaceApex() {
        return CONSTANTS.CURRENTNAMESPACEPREFIX;
    } 
    
}