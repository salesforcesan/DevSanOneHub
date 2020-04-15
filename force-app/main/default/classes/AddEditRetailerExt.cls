public with sharing class AddEditRetailerExt {
    public ApexPages.StandardController controller;
    public Retailer__c Retailer {get;set;}
    public string BODates {get; set;}
    
    public String mode {get; set;} 
        
    public AddEditRetailerExt(ApexPages.StandardController controller) {
    
        try {
            string retlID = ApexPages.currentPage().getParameters().get('id');
            if(retlID != null &&  retlID !=''){
                mode = 'edit';
                Retailer = [select name,user__c,isMaterialReqd__c, LogoURL__c, LogoHeight__c, OneHubRetailerId__c, TargetAcquiredDefault__c, ProjectCancelLeadTime__c, FulfillmentLeadTime__c from retailer__c where ID =: retlID limit 1];            
               
            }
            else{
                mode = 'add';
                Retailer = new retailer__c();  
            }
        }
        catch(Exception ex)
        {
            Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Unexpected error occurred. Please try later.'));
        }
    }

    public PageReference save() {
        try{
        
            if(mode == 'add'){
                insert Retailer; 
            }
            else{
                upsert retailer;
                           
            }
            Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.Info, 'Successfully saved.'));
            
            PageReference psPage = new ApexPages.StandardController(Retailer).view();
            psPage.setRedirect(true);
            return psPage;
            
        }    
        catch(Exception ex)
        {
            Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Unexpected error occurred. Please try later.'));
        }
        return null;
    }
    

}