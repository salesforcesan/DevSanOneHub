public with sharing class ProjectServiceMaterialsAddExt {

   public ApexPages.StandardController controller;
    public ID psID {get;set;}    
    public Project__c project {get;set;}
    public ProjectService__c ps{get;set;}
    public projectservicematerial__c psm {get;set;}
    public Boolean IsLeadTimeAvailabe {get;set;}
    
    public list<projectservicematerial__c> materials{get;set;}
    public Boolean showMaterialButtons {get;private set;        }    
    public Map<String,Boolean> editableMap {get;set;}
    private void addMessage(ApexPages.Severity severity, String message){
    Apexpages.addMessage(new ApexPages.Message(severity, message));
    }

    private void initPSM() {
        psm= new projectservicematerial__c();
        psm.InvoiceType__c = 'Standard';
    }
    
    
    public ProjectServiceMaterialsAddExt(ApexPages.StandardController controller) {

        psID = ApexPages.CurrentPage().getParameters().get('id');   //'a0Hj0000002sPDp'; 'a0Hj00000037Dt5';
        ps = [SELECT Id, Name, Project__c, Project__r.ProjectNumber__c,    Service__c, TargetType__c, Status__c, FulfillmentCenterName__c, OneHubRetailerId__c FROM ProjectService__c where id =:psID ];
        
        initPSM();
        
        LoadMaterials();
        
        project = [Select Id, Name, Status__c, FulfillmentLeadTime__c,IsJobManualRegenReqd__c, ProjectCancelLeadTime__c , Project__c.StartDate__c, ProjectOrigin__c,ApexJobName__c, BatchProcessId__c from Project__c where Id =: ps.Project__c];
        
        Set<String> editableFields = new Set<String>{'Project__c.RL_Materials'};
        editableMap = UIConfig.isEditale(project.Status__c, editableFields);
        showMaterialButtons = editableMap.get('Project__c.RL_Materials');
        showMaterialButtons = showMaterialButtons && Schema.sObjectType.ProjectServiceMaterial__c.isUpdateable();  
        IsLeadTimeAvailabe = AppUtil.hasProjectLeadTimeByProjectId(project.Id);
        
    }

    private Boolean isAlaCarteMaterial(Material__c m) {
        return m.Kit__c == false ? true : false;
    }

    
    public PageReference AddMaterial(){ 
        //SaveAllChanges();   
        if(psm.Material__c == null) { return null; }
        if (psm.Quantity__c == null) {
            addMessage(ApexPages.Severity.ERROR, 'The quantity is required.');
            return null;
        }
        
        try{
            Material__c mat = [Select Id, Name, Description__c, EstimatedCostPerUnit__c, Kit__c from Material__c where Id = :psm.Material__c LIMIT 1];
            
            projectservicematerial__C pscObj = new projectservicematerial__C();
            pscObj.ProjectService__c = psID;
            pscObj.Material__c = psm.Material__c;
            pscObj.InvoiceType__c = psm.InvoiceType__c;
            //pscObj.MaterialName__c = mat.Name;
            pscObj.Quantity__c = psm.Quantity__c;
            pscObj.MaterialDescription__c = mat.Description__c;
            //pscObj.Kit__c=mat.Kit__c;
            //pscObj.CostPerUnit__c=mat.EstimatedCostPerUnit__c;
            insert pscObj;
            
            initPSM();

            UpdateProjectServiceFulfillmentCenter();        
            LoadMaterials();
            
            if(project.Status__c != CONSTANTS.PROJECT_STATUS_PLANNING)
            {
                List<ProjectServiceMaterial__c> psmList = [SELECT Id, ProjectService__c, Material__c FROM ProjectServiceMaterial__c WHERE id = :pscObj.Id];
                List<Job__c> jobs = [SELECT Id, ProjectService__c FROM Job__c WHERE  Project__c  = :project.Id AND ProjectService__c =: psId AND JobStatus__c != :CONSTANTS.JOB_ATTEMPT_STATUS_CANCELED];
                JobUpdatesHelper.createJobMaterials(jobs, psmList);
                project.IsJobManualRegenReqd__c=true;
                TriggerUtil.skipProjectTrigger = true;
                update project; 
            }
        }
        catch (Exception ex){
        
            if (ex.getMessage().Contains('duplicate'))
            {
                addMessage(ApexPages.Severity.ERROR, 'Material already added. Please check and try again.');
            }
            else if(!ex.getMessage().contains('VALIDATION_EXCEPTION')){
                addMessage(ApexPages.Severity.ERROR, ex.getMessage());
            }
            return null;
        }   
        
        return null;
    }
    
    public PageReference SaveAllChanges()
    {       
        update materials;
        if(project.Status__c != CONSTANTS.PROJECT_STATUS_PLANNING)
        {
            project.IsJobManualRegenReqd__c=true;
            TriggerUtil.skipProjectTrigger = true;
            update project; 
        }                
        UpdateProjectServiceFulfillmentCenter();        
        LoadMaterials();
        addMessage(ApexPages.Severity.CONFIRM, 'Material(s) saved successfully.'); 
        return null;
    }

    
    public PageReference DeleteMaterials()
    {
        
        string psmParamVal = ApexPages.currentpage().getParameters().get('psmParamDEL');

         if(project.Status__c != CONSTANTS.PROJECT_STATUS_PLANNING)
        {
            TriggerUtil.SkipAllTriggers();
            delete [SELECT Id FROM JobMaterial__c WHERE ProjectServiceMaterial__c =:psmParamVal];
            project.IsJobManualRegenReqd__c=true;
            TriggerUtil.skipProjectTrigger = true;
            update project; 
        }
        
        
        for (ProjectServiceMaterial__c m : materials) {
            if (psmParamVal == m.Id) {
                delete m;
                break;
            }
        }
        UpdateProjectServiceFulfillmentCenter();
        LoadMaterials();
        
        
        addMessage(ApexPages.Severity.CONFIRM, 'Material(s) deleted successfully.'); 
        return null;
    }
    

    public void LoadMaterials(){
        materials = [SELECT Id, ProjectService__c, Material__c, InvoiceType__c, MaterialDescription__c, CostPerUnit__c, TotalPrice__c, 
        Quantity__c, Kit__c,MaterialName__c, CustomDescription__c FROM ProjectServiceMaterial__c where ProjectService__c=:psid];       
		
    }
    
    private void UpdateProjectServiceFulfillmentCenter()
    {
        ProjectServiceMaterial__c psm;
        ProjectServiceMaterial__c[] psms = [Select Id, Material__r.FulfillmentCenterName__c from ProjectServiceMaterial__c where ProjectService__c = :ps.Id Limit 1];
        if (psms.size() > 0)
        {
            psm = psms[0];        
        }
        
        if (psm != null)
        {
            ps.FulfillmentCenterName__c = psm.Material__r.FulfillmentCenterName__c;
        }
        else
        {
            ps.FulfillmentCenterName__c = '';
        }

        TriggerUtil.SkipAllTriggers();
        update ps;
        //Comment Versioning Code
		/*        
        if (project.Status__c != 'Planning'){
                AppUtil.UpdateProjectVersion(project.Id);
        }
        */
    
    }       
}