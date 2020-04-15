//This class will help track number of trigger executions

global class TriggerUtil {
    
    global static boolean skipTrigger = false;
    global static boolean skipAttachmentTrigger = false;
    global static boolean skipProjectTrigger = false;
    global static boolean skipProjectDeleteTrigger = false;
    global static boolean skipProjectAccountTrigger = false;
    global static boolean skipProjectLocationTrigger = false;
    global static boolean skipProjectServiceTrigger = false;
    global static boolean skipProjServColTrigger = false;
    global static boolean skipProjectServiceTargetTrigger = false;  
    global static boolean skipProjectServiceTargetAttributeTrigger = false;
    global static boolean skipJobTrigger = false;    
    global static boolean skipJobAttemptTrigger = false;
    global static boolean skipJobUpdateTrigger = false;
    global static boolean skipJobDeleteTrigger = false;  
    global static boolean skipProjAcctTrigger = false;
    global static boolean skipOpportunityTrigger = false;    
    global static boolean skipDeepClonedRecords = false;  
    global static boolean skipLocationEquipmentTrigger = false;  
    global static boolean skipProjectAfterInsertTrigger = false;
    global static boolean skipQuestionDefinedResponseTrigger = false;
    global static boolean skipContactTrigger = false;
    global static boolean skipJobAttemptWorkerTrigger = false;
    global static boolean skipJobAttemptWorkerTimeEntryTrigger = false;
    global static boolean skipJobImageTrigger = false;
    global static boolean skipCDLinkTrigger = false;
    global static boolean skipProjectInvoiceTrigger = false;
    global static boolean skipProjectInvoiceLineItemTrigger = false;
    global static boolean skipProjectInvoiceLineItemDetailTrigger = false;
    global static boolean skipOpportunity = false;
    
    
    
    public final static  Boolean isDRModeEnabled{get;set;}    
    
    static {
        
        List<DRecoverySettings__c> settings= [SELECT DRMode__c FROM DRecoverySettings__c  LIMIT 1];
        if(settings != null && settings.size() > 0 && settings[0] != null )
        {
            
            isDRModeEnabled  = Boolean.valueOf(settings[0].DRMode__c);
            
        }
        else
        {
            isDRModeEnabled  = false;
        }
        
        system.debug(isDRModeEnabled);
        
    }
    
    global static void SkipAllTriggers()
    {
        skipTrigger = true;
        skipProjectTrigger = true;
        skipProjectAccountTrigger =true;
        skipProjectLocationTrigger = true;
        skipProjectServiceTrigger = true;
        skipProjServColTrigger = true;
        skipProjectServiceTargetTrigger = true;  
        skipProjectServiceTargetAttributeTrigger = true;  
        skipProjAcctTrigger=true;
        skipJobTrigger = true;    
        skipJobUpdateTrigger = true;
        skipJobDeleteTrigger = true;  
        skipJobAttemptTrigger = true;
        skipDeepClonedRecords = true;
        skipProjectDeleteTrigger = true;
        skipLocationEquipmentTrigger = true;  
        skipOpportunityTrigger = true;
        skipProjectAfterInsertTrigger = true;
        skipQuestionDefinedResponseTrigger=true;
        skipContactTrigger =true;
        skipJobAttemptWorkerTrigger = true;
        skipJobAttemptWorkerTimeEntryTrigger = true;   
        skipJobImageTrigger =true;
        skipCDLinkTrigger =true;
        skipProjectInvoiceTrigger = true;
        skipProjectInvoiceLineItemTrigger = true;
        skipProjectInvoiceLineItemDetailTrigger = true;
        skipOpportunity=true;
        skipAttachmentTrigger=true;
    }
}