public without sharing class CancelProjectExt {

    public String errorMessage {get;set;}   
    public Project__c projObj {get;set;}
    public String cancelReason{get;set;}
    ApexPages.StandardSetController setCon;

    public CancelProjectExt(ApexPages.StandardController controller) {
        projObj  = (Project__c) controller.getRecord();
    }
    
     public pagereference cancel(){ return null; }

   
    public pagereference cancelProj()
    {
        Savepoint sp = Database.setSavePoint();
        try
        {
            TriggerUtil.SkipAllTriggers();
            
            string selReason = projObj.CancelReason__c;
            string selComm = projObj.CancelReasonComment__c;
            
            projObj = [select name,Status__c,CancelReason__c, ProjectCancelLeadTime__c,ApexJobName__c,BatchProcessId__c, CancelReasonComment__c  from project__c where id=: projObj.id]; 
            
            ProjectActionsHelper.CancelProject(projObj.Id, selReason, selComm);        
            PageReference pageRef  = new ApexPages.StandardController(projObj).view();
            pageRef.setRedirect(true);
            return pageRef;   
         }    
         catch(Exception ex)
         {
             Database.rollback(sp);
             errorMessage = ex.getMessage();       
         } 
         return null;
    }
    
    public pagereference DoNotCancel()
    {    
        PageReference pageRef  = new ApexPages.StandardController(projObj).view();
        pageRef.setRedirect(true);
        return pageRef;
    }

}