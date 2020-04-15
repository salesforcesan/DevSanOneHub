public with sharing class DeleteProjectServiceExt {
    ApexPages.StandardSetController setCon;
    public String errorMessage {get;set;}
    public projectservice__c  psObj;
    public string psNames{get;set;}
    public Project__c projObj{get;set;}
    public List<ProjectService__c> selectedProjectServices{get; set;}
    
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
    
    public DeleteProjectServiceExt(ApexPages.StandardSetController controller) {
        setCon = controller;  
        selectedProjectServices = new List<ProjectService__c>();
        String projectId = Apexpages.CurrentPage().getParameters().get('id');
        projObj = [select id, name, StartDate__c, Status__c,ProjectCancelLeadTime__c from project__c where id=:projectId];
        selectedProjectServices = [select id, name, status__c, Service__r.Name, project__c,CancelReasonComment__c,servicetitle__c  from projectservice__c where id  IN:  controller.getSelected()];
        if(selectedProjectServices.size()==0){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'Please select a valid Project Service.',''));
        }
        getpsNames();        
    }
    
    public string getpsNames() {                
        psNames='';
        for(projectservice__c ps: selectedProjectServices)
        {            
          
            psNames = psNames + ps.Name + ' - ' + ps.Service__r.Name + ' - ' + ps.servicetitle__c + ' , ';

        }
        psNames = psNames.removeEnd(', ');
        return psNames;
    }
    
   
    public pagereference DeleteService()
    {
        Savepoint sp = Database.setSavePoint();        
        try{
            TriggerUtil.SkipAllTriggers();
            
            Id[] PSIDArr =new List<Id>(new Map<Id, ProjectService__c>(selectedProjectServices).keySet());
            TriggerUtil.SkipAllTriggers();        
            ProjectServiceActionsHelper.DeleteProjectServices(PSIDArr);                         
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

    public pagereference cancelDelete()
    {
        PageReference pageRef  = new ApexPages.StandardController(projObj).view();
        pageRef.setRedirect(true);
        return pageRef;
    }   

}