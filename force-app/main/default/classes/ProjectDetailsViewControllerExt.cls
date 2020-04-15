public with sharing class ProjectDetailsViewControllerExt {

    public Project__c proj {
        get;
        private set;
    }
    public Boolean showCancelProjectButton {
        get;
        private set;
    }
    
    public Boolean showSubmitForApprovalButton {
        get;
        private set;
    }
    public Boolean showAddProjectServiceButton {
        get;
        private set;
    }
    public Boolean showDeleteProjectServiceButton {
        get;
        private set;
    }
    public Boolean showEditProjectServiceButton {
        get;
        private set;
    }
    public Boolean showCancelProjectServiceButton {
        get;
        private set;
    }
    public Boolean showAddUploadProjectLocationButton {
        get;
        private set;
    }
    public Boolean showSelectServiceButton {
        get;
        private set;
    }
    public Boolean showCancelJobButton {
        get;
        private set;
    }
    public Boolean showEditProjectButton {
        get;
        private set;
    }
    public Boolean isInPlanning {
        get;
        private set;
    }
    public Boolean isReserved {
        get;
        private set;
    }
 
    public Boolean isPageUpdateable {
        get {
            return Schema.sObjectType.Project__c.isUpdateable();
        }
        private set;
    }
    
    
    public Boolean hasLeadtime {
        get;
        private set;
    }
    
    public Integer locCount {
        get;
        private set;
    }
    
    public Boolean isExternalProject {
        get;
        private set;
    }
    
    public Integer newLocationCount {
        get;
        private set;
    }
    
    public Boolean reserveWarning {
        get;
        set;
    }
    public Boolean editProjectAccounts {get;set;}
    public String ProjectTag{get;set;}
    public list<ProjectAccount__c> ProjAccts{get;set;}
    public Boolean scheduledWithLeadTime{get;set;}
    public Boolean ShowDeleteProject{get;set;}
    public Map<String,Boolean> visibleMap {get;set;}            
    public Map<String,Boolean> hiddenMap {get;set;}
    public Map<String,Boolean> editableMap {get;set;}
    public Boolean hasAddLocationsLeadTime {get;set;}
    public boolean captureNumberOfDays {get;set;}
    
    public ProjectDetailsViewControllerExt(ApexPages.StandardController controller) {
        proj = [SELECT  Id,IsDeleted__c ,MaxServiceCount__c ,ApprovalDate__c,Approver__c,ApprovalRequestDate__c  ,ServiceCount__c, Name, Status__c, ProjectType__c, ProjectType__r.Name, FulfillmentLeadTime__c, ProjectCancelLeadTime__c,StartDate__c,EndDate__c,retailer__r.isMaterialReqd__c, OriginID__c, IsExternalProject__c, BudgetedLocationsCount__c, UpdateJobsFlag__c,  BookBudgetedOnly__c, ProjectOrigin__c, StatusComments__c, UpdateSequence__c, ApexJobName__c,ProjectLaunchDate__c, IsJobManualRegenReqd__c, AddLocationsLeadTime__c, ProjectType__r.AllowMultidays__c FROM Project__c WHERE Id = : controller.getId()];
        list<Project__Tag > projTag = [SELECT Id,ItemId,Name,TagDefinitionId,Type FROM Project__Tag where ItemId =: proj.id];
        ProjAccts = [SELECT Id, Name, Account__r.name, Project__r.name, SplitValue__c,  IsPrimary__c FROM ProjectAccount__c where project__c=:proj.id];
        List<ProjectService__c> psList = [select id FROM ProjectService__c WHERE Project__c =: proj.Id];
        scheduledWithLeadTime= false;
        captureNumberOfDays = proj.ProjectType__r.AllowMultidays__c;
        newLocationCount = 0;
        if (proj.Status__c == CONSTANTS.PROJECT_STATUS_BOOKED && AppUtil.hasProjectLeadTimeByProjectId(proj.Id))
        {
            scheduledWithLeadTime= true;    
            newLocationCount = [SELECT count() FROM ProjectLocation__c WHERE Project__c = : controller.getId() AND IsNewLocation__c = true];
        }
        
        ShowDeleteProject = false;
        showCancelProjectButton = false; 
        
        if (proj.Status__c == CONSTANTS.PROJECT_STATUS_PLANNING)
        {
            ShowDeleteProject = true;     
        }
        
        if(proj.Status__c == CONSTANTS.PROJECT_STATUS_BOOKED || proj.Status__c == CONSTANTS.PROJECT_STATUS_LAUNCHED || proj.Status__c == CONSTANTS.PROJECT_STATUS_INPROGRESS){       
            showCancelProjectButton = true;         
        }
        
        Set<String> hiddenElements = new Set<String>();
        hiddenElements.add('Project__c.Edit');
        hiddenElements.add('Project__c.Cancel');
        hiddenElements.add('Project__c.Delete');
        hiddenElements.add('Project__c.Submit');
        hiddenElements.add('Project__c.ViewPhotos');
        hiddenElements.add('ProjectAccount__c.Add');
        hiddenElements.add('ProjectAccount__c.Delete');
        hiddenElements.add('ProjectAccount__c.Edit');
        hiddenElements.add('ProjectService__c.Add');
        hiddenElements.add('ProjectService__c.Edit');
        hiddenElements.add('ProjectService__c.Delete');
        hiddenElements.add('ProjectService__c.Cancel');
        hiddenElements.add('ProjectLocation__c.Add');
        hiddenElements.add('ProjectLocation__c.Manage');
        hiddenElements.add('Job__c.Create');
        hiddenElements.add('Job__c.Mange');
        hiddenElements.add('Job__c.Cancel');
        hiddenElements.add('Project__c.JobManual');
        hiddenElements.add('Project__c.viewReport');
        hiddenMap = UIConfig.isHidden(proj.Status__c, hiddenElements);
        
        Set<String> editableFields = new Set<String>{'Project__c.RL_Accounts'};
        editableMap = UIConfig.isEditale(proj.Status__c, editableFields);
        editProjectAccounts = editableMap.get('Project__c.RL_Accounts') && Schema.sObjectType.ProjectAccount__c.isUpdateable();
        hasAddLocationsLeadTime = true;
        if(proj.AddLocationsLeadTime__c >=0 && (Date.Today() > proj.EndDate__c.addDays(-1* Integer.ValueOf(proj.AddLocationsLeadTime__c)))){
            hasAddLocationsLeadTime = false;
        }
        
        
        set<string> projtagsSet = new set<string>();
        for(Project__Tag td : projTag )
        {
            projtagsSet.add(td.Name);
        }
        ProjectTag =  String.join((new list<string>(projtagsSet)), ',');
            
        Integer reserveCount = [SELECT count() FROM ProjectLocation__c WHERE Status__c =:CONSTANTS.PROJECT_STATUS_BOOKED AND PRoject__c = : proj.Id];
        
        locCount = [SELECT count() FROM ProjectLocation__c WHERE PRoject__c = : proj.Id];
        
        hasLeadtime = AppUtil.hasProjectLeadTime(proj);
        isExternalProject = (proj.IsExternalProject__c == true) ? true : false;
        
        if (reserveCount > 0) {
            isReserved = true;
        }

     
        
        if(!isPageUpdateable){
            showCancelProjectButton = false;
        }
        
        
        if (proj.Status__c ==CONSTANTS.PROJECT_STATUS_PLANNING  || (proj.Status__c ==CONSTANTS.PROJECT_STATUS_BOOKED && hasLeadtime)) {
            showEditProjectButton = true;
        } else {
            showEditProjectButton = false;
        }

       
        //hide the button in scheduled (# 51474)
        reserveWarning = false;
        if ((proj.Status__c ==CONSTANTS.PROJECT_STATUS_PLANNING) && !isExternalProject) {
            showSubmitForApprovalButton = true;
        } else {
            showSubmitForApprovalButton = false;
        }
        
        showDeleteProjectServiceButton = false;                
        
        
        //if ((proj.Status__c ==CONSTANTS.PROJECT_STATUS_PLANNING) && (Date.today().daysBetween(proj.enddate__c))>=0)        { 
        
        showAddProjectServiceButton=false;
        if ((proj.Status__c ==CONSTANTS.PROJECT_STATUS_PLANNING))        {
            showAddProjectServiceButton = true && hiddenMap.get('ProjectService__c.Add');    
            if(psList.size()>0){
                if (Schema.sObjectType.ProjectService__c.isDeletable()) {
                    showDeleteProjectServiceButton = true;
                }   
            }    
            
            if (AppUtil.getAppSetting('ServiceSelector').toLowerCase() == 'onehub'  )
            {
                if (proj.MaxServiceCount__c > proj.ServiceCount__c )
                {
                    showAddProjectServiceButton = true && !hiddenMap.get('ProjectService__c.Add');
                }else{
                    Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.Info, 'Max service count reached.',''));     
                     showAddProjectServiceButton = false;       
                }
            }     
        } 
        
        
        
       
        
                      
        if(proj.ApexJobName__c  != null)
        {
              Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, '<b>' + proj.ApexJobName__c   +' in progress</b>', 'Please allow a few minutes to process your request.'));
        }
        
        
        if (proj.Status__c ==CONSTANTS.PROJECT_STATUS_PLANNING ||  (proj.Status__c ==CONSTANTS.PROJECT_STATUS_BOOKED && hasLeadtime) || proj.Status__c == 'Rejected' ) {
            showEditProjectServiceButton = true;
        } else {
            showEditProjectServiceButton = false;
        }
        
        if (proj.Status__c ==CONSTANTS.PROJECT_STATUS_INPROGRESS || (proj.Status__c ==CONSTANTS.PROJECT_STATUS_BOOKED && !isExternalProject)) {
            showCancelProjectServiceButton = true;
        } else {
            showCancelProjectServiceButton = false;
        }
        
        
        if (proj.Status__c ==CONSTANTS.PROJECT_STATUS_PLANNING || (proj.Status__c ==CONSTANTS.PROJECT_STATUS_BOOKED && !isExternalProject) ) {
            showAddUploadProjectLocationButton = true;
        } else {
            showAddUploadProjectLocationButton = false;
        }
        
        
        if ((proj.Status__c ==CONSTANTS.PROJECT_STATUS_BOOKED && !isExternalProject) || proj.Status__c ==CONSTANTS.PROJECT_STATUS_INPROGRESS ) {
            showCancelJobButton = true;
        } else {
            showCancelJobButton = false;
        }
        
        if (proj.Status__c ==CONSTANTS.PROJECT_STATUS_PLANNING ){  
            isInPlanning = true;
        } else {
            isInPlanning = false;
        }
        
        if( proj.IsJobManualRegenReqd__c == true && (proj.Status__c == CONSTANTS.PROJECT_STATUS_BOOKED || proj.Status__c == CONSTANTS.PROJECT_STATUS_LAUNCHED || proj.Status__c == CONSTANTS.PROJECT_STATUS_INPROGRESS)){
            Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, '<b>Job Manual(s)</b>', 'You have one or more changes that require the Job Manual(s) to be regenerated.'));
        }
        
      
        //if( proj.UpdateJobsFlag__c == true && proj.Status__c ==CONSTANTS.PROJECT_STATUS_BOOKED){
        //    Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, '<b>Jobs Update Required</b>', 'You have one or more Service attributes that will require Jobs to be updated.'));
        //}

        
    }

    public PageReference submitProject() {
        Pagereference ref = new Pagereference('/apex/SubmitProject?id=' + proj.Id);
        return ref;
    }

   
    
    public pagereference CloneProject(){
    
        CloneUtil.CloneAllAsync(proj.Id);
        
        PageReference pageRef = new PageReference('/apex/ProjectDashboard');
        pageRef.setRedirect(true);
        return pageRef;        
    }
    
    public pagereference DeleteProjects(){
        try{
            TriggerUtil.SkipAllTriggers();
            list<projectservice__c> psList = [SELECT Id,IsDeleted__c FROM projectservice__c WHERE project__c = :proj.Id];
            list<projectlocation__c> plLoc = [SELECT Id,IsDeleted__c FROM projectlocation__c WHERE project__c = :proj.Id];
            
            if(proj.Approver__c  !=null && proj.ApprovalRequestDate__c  !=null)  //to check for soft delete or hard delete
            {
                proj.IsDeleted__c=true;
                update proj;
                
                for(projectservice__c ps:psList){
                   ps.IsDeleted__c =true;
                }
                update psList;
                
                for(projectlocation__c pl:plLoc){
                   pl.IsDeleted__c =true;
                }
                update plLoc;

            }
            else{
                ProjectActionsHelper.DeleteProject(proj.Id);
            }
            
            //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM,'Successfully Deleted !',''));
            
            PageReference pageRef = new PageReference('/apex/ProjectDashboard');
            pageRef.setRedirect(true);
            return pageRef;
           
        }catch(exception ex){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,ex.getMessage(),''));
        }
        return null;
    }

    public PageReference viewProjectSummaryReport(){
         PageReference pageRef = Page.ProjectSummary;
        pageRef.getParameters().put('id', proj.Id);
        pageRef.getParameters().put('retURL', ApexPages.currentPage().getURL());
        pageRef.setRedirect(true);
        return pageRef;        
    }
    
    public pagereference ViewProjectPhotos(){
        PageReference pageRef = Page.ProjectPhotos;
        pageRef.getParameters().put('id', proj.Id);
        pageRef.getParameters().put('retURL', ApexPages.currentPage().getURL());
        pageRef.setRedirect(true);
        return pageRef;        
    }
    
    public pagereference GenerateJobManual(){
        system.debug('~~~GenerateJobManual~~~');
        AttachmentUrlGenerator.generateJobManualFutureCall(string.valueof(proj.Id)); 
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM,'Successfully generated Job manuals!',''));
        return null;       
    }
        
}