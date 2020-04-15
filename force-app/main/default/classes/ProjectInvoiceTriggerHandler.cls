public class ProjectInvoiceTriggerHandler extends TriggerHandler {
    
    public override void afterInsert(){
       if (TriggerUtil.skipProjectInvoiceTrigger) return;
       
        Set<String> projectInvoiceIds = new Set<String>();
                
        for(ProjectInvoice__c pi :(List<ProjectInvoice__c> )Trigger.new){
           
            if (pi.Status__c == Constants.PROJECT_INVOICE_STATUS_INVOICED ){
                projectInvoiceIds.add(pi.Id);
            }            
        } 
        
        updateReleatedAccountBudget(projectInvoiceIds);
    }
    
    public override void afterUpdate(){
                
        if (TriggerUtil.skipProjectInvoiceTrigger) return;
        
        Set<String> projectInvoiceIds = new Set<String>();
                
        for(ProjectInvoice__c pi :(List<ProjectInvoice__c> )Trigger.new){
            ProjectInvoice__c oldPi = (ProjectInvoice__c) System.Trigger.oldMap.get(pi.Id);
            
            if (oldPi.Status__c != pi.Status__c && pi.Status__c == Constants.PROJECT_INVOICE_STATUS_INVOICED ){
                projectInvoiceIds.add(pi.Id);
            }
            
        } 
        
        updateReleatedAccountBudget(projectInvoiceIds);
    }
    
    private void updateReleatedAccountBudget(Set<String> projectInvoiceIds){

		Set<String> accountBudgetIds = new Set<String>();
        
        List<ProjectInvoice__c> projectInvoiceList = [Select id,Status__c, TotalProjectInvoiceAmountCalculated__c,ProjectAccount__r.Opportunity__r.AccountBudget__c 
                                                      From ProjectInvoice__c 
                                                      Where ID IN :projectInvoiceIds 
                                                      And ProjectAccount__r.Opportunity__r.AccountBudget__c != null];
        
        //To get all associated Account Budget
        for(ProjectInvoice__c pi : projectInvoiceList){
            accountBudgetIds.add(pi.ProjectAccount__r.Opportunity__r.AccountBudget__c);
        }
        
        Map<String, AccountBudget__c> accountBudgetMap = new Map<String, AccountBudget__c>(
            [select id, ExecutedAgainstBudget__c 
             from AccountBudget__c 
             Where ID IN :accountBudgetIds]);
        
        List<AccountBudget__c> accountBudgetListToUpdate =  new List<AccountBudget__c>();
        
        //To update ExecutedAgainstBudget__c field of associated Account Budget object 
        for(ProjectInvoice__c pi : projectInvoiceList){
            
            AccountBudget__c ab = accountBudgetMap.get(pi.ProjectAccount__r.Opportunity__r.AccountBudget__c);
            ab.ExecutedAgainstBudget__c = ab.ExecutedAgainstBudget__c != null ? ab.ExecutedAgainstBudget__c + pi.TotalProjectInvoiceAmountCalculated__c : pi.TotalProjectInvoiceAmountCalculated__c;
            accountBudgetListToUpdate.add(ab);
        }
        
        // To update all account budget
        update accountBudgetListToUpdate;

    }

}