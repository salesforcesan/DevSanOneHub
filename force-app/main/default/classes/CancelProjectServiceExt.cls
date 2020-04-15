public with sharing class CancelProjectServiceExt {

    ApexPages.StandardSetController setCon;
    public String errorMessage {get;set;}
    
    public projectservice__c  psObj;
   
    public string psNames{get;set;}
    public Project__c projObj{get;set;}
    public List<ProjectService__c> selectedProjectServices{get; set;}
    public string CancelComment{get;set;}  

    public project__c proj{get;set;}  
    
     public projectservice__c getpsObj(){
       psObj=new projectservice__c();
       system.debug('RUN...'+psObj); 
       return psObj;
     }
     
     public void setpsObj(projectservice__c psObj){
         system.debug('RUN SETTER...'+psObj); 
         this.psObj = psObj;
     }

    public project__c getproj() {return proj;}
    public void setproj(project__c value) {proj = value;}    
    
    public CancelProjectServiceExt(ApexPages.StandardSetController controller) {
        setCon = controller;  
        selectedProjectServices = new List<ProjectService__c>();
        String psids = Apexpages.CurrentPage().getParameters().get('psids');
        String projectId = Apexpages.CurrentPage().getParameters().get('id');
        projObj = [select id, name, StartDate__c, Status__c,ProjectCancelLeadTime__c from project__c where id=:projectId];
        selectedProjectServices = [select id, Name, Status__c, Service__r.Name, Project__c, CancelReason__c, CancelReasonComment__c  from projectservice__c where id  IN:  controller.getSelected() and status__c!= 'Canceled'];
        if(selectedProjectServices.size()==0){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'Please select a valid Project Service.',''));
        }
        getpsNames();        
    }
    

 
    public string getpsNames() {                
        psNames='';
        for(projectservice__c ps: selectedProjectServices)
        {            
            psNames = psNames + ps.Name + ' - ' + ps.Service__r.Name + ' , ';
        }
        psNames = psNames.removeEnd(', ');
        return psNames;
    }
    
   
    public pagereference CancelService()
    {
        Savepoint sp = Database.setSavePoint();        
        try{
            Id[] PSIDArr =new List<Id>(new Map<Id, ProjectService__c>(selectedProjectServices).keySet());
             ProjectServiceActionsHelper.CancelProjectService(PSIDArr, psObj.CancelReason__c,psObj.CancelReasonComment__c );
            
        }
        catch(Exception ex){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, ex.getMessage(),''));
            Database.rollback(sp);
            return null;
        }
       PageReference cancel = setCon.cancel();        
        system.debug('cancel::'+cancel);
        return cancel;           
        
    }

    public pagereference DoNotCancel()
    {
        PageReference pageRef  = new ApexPages.StandardController(projObj).view();
        pageRef.setRedirect(true);
        return pageRef;
    }    
    
    
}