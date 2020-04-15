global with sharing class CreateEditProjectExt {
    public Project__c project{get;set;}
    public String projectTypeName {get;set;}
    public String mode{get;set;}
    public String fieldList{get;set;}
    public String ProjectTag{get;set;}
    public set<String> projtagsSet{get;set;}
    public String AvlTags{get;set;}
    public set<String> AvlTagsSet{get;set;}    
    private ApexPages.StandardController ctrler { get; set; }
    public transient string newTags{get;set;}    
    public list<Project__Tag> projTag{get;set;}  
    public boolean isProjTagVisible{get;set;}  
    public boolean isExternalProject{get;set;}  
    public integer rowID{get;set;}
    public string projectTypeId{get;set;}
    public boolean enableLocked{get;set;}
    public List<Retailer__c> retailers {get;set;}
    public string SelectedRetailer{get;set;}
    public List<SelectOption> RetailerSelectOptions {get;set;}
    public Boolean disableFields{get;set;}
    public Boolean showRereserveOverride {get;set;}
    public Boolean showOrop{get;set;}
    public boolean isScheduleOptionEditable{get;set;}
    public ProjectType__c projType{get;set;}
    public Map<String,Boolean> editableMap {get;set;}
    public boolean captureNumberOfDays {get;set;}
    public String getNAMESPACE() {
        return CONSTANTS.CURRENTNAMESPACEPREFIX;
    }
    public boolean canSetScheduleDate {get;set;}
    public boolean windowChangeWarning {get;set;}
    public CreateEditProjectExt(ApexPages.StandardController stdController) { 
    
        if(!Test.isRunningTest()) {
            List<String> additionalFields = new List<String>();
            additionalFields.add('OneHubRetailerId__c');
            additionalFields.add('Retailer__c');
            additionalFields.add('ProjectCancelLeadTime__c');
            additionalFields.add('FulfillmentLeadTime__c');
            additionalFields.add('ProjectOrigin__c');
            stdController.addFields(additionalFields);
        }
        isProjTagVisible = false;
        windowChangeWarning = false;
        
        ctrler = stdController;
      
        //get all tags
        list<TagDefinition> allTags= [SELECT Id,Name,Type FROM TagDefinition where Type='Public'];
        AvlTagsSet = new set<string>();
        for(TagDefinition td : allTags)
        {
            //alltagsSet.add('\''+td.Name+'\'');
            AvlTagsSet.add(td.Name);
        }
        AvlTags =  String.join((new list<string>(AvlTagsSet)), ',');  
        ProjectTag = '';
        
        String id= ApexPages.currentPage().getParameters().get('id');
        System.debug('Project Id: ' + id);
        this.project = (Project__c) stdController.getRecord();
        
        //if a new project is created, current login user id is assigned to project builder
        if (String.isBlank(id)){
            this.project.OwnerId  = UserInfo.getUserId();
        }
        
        String[] EC = AppUtil.getAppSetting('ResponsibleForExecution').split(',');
        
        Set<String> editableFields = new Set<String>{'Project__c.Name','Project__c.Retailer__c','Project__c.ProjectCycle__c', 'Project__c.StartDate__c', 'Project__c.EndDate__c', 'Project__c.ProjectLaunchDate__c', 'ProjectService__c.Edit', 'Project__c.SplitType__c', 'Project__c.Opportunity__c', 'Project__c.Program__c', 'Project__c.ProjectScheduleOption__c', 'Project__c.IsLocked__c', 'Project__c.BudgetedLocationsCount__c', 'Project__c.NumberOfDays__c', 'Project__c.ProjectSeller__c', 'Project__c.OwnerId'};
        String projectStatus = (id != null) ? this.project.Status__c : 'Create';
        editableMap = UIConfig.isEditale(projectStatus, editableFields);
        
        isScheduleOptionEditable=true;
        list<scheduleoption__c> soList = [select id from scheduleoption__c where isactive__c=true];
         if(soList.size()==1) {
            system.debug('~~~~sch'+soList.size());
            if(id==null)
            this.project.projectscheduleoption__c = soList[0].id;
            isScheduleOptionEditable=false;
        }
        else{
            isScheduleOptionEditable = editableMap.get('Project__c.ProjectScheduleOption__c');
        }
            
        canSetScheduleDate = true;        
        if (id != null) {
            isProjTagVisible = true;
            //get project tags
            projTag = [SELECT Id,ItemId,Name,TagDefinitionId,Type FROM Project__Tag where ItemId =: id];
            projtagsSet = new set<string>();
            for(Project__Tag td : projTag )
            {
                projtagsSet.add(td.Name);
            }
            ProjectTag =  String.join((new list<string>(projtagsSet)), ',');  
                
            Project__c projectWithType = [SELECT ProjectType__c, IsExternalProject__c,projectscheduleoption__c, ProjectScheduleOption__r.Code__c, ProjectType__r.AllowMultidays__c, Status__c  FROM Project__c WHERE ID = :id];
            
            projectTypeId = projectWithType.ProjectType__c;
            isExternalProject = projectWithType.IsExternalProject__c;
            captureNumberOfDays = projectWithType.ProjectType__r.AllowMultidays__c;
            
            if (projectTypeId!= null) {
                ProjectType__c projecttype = [SELECT name, AllowMultidays__c FROM ProjectType__c WHERE id = : projectTypeId];
                projectTypeName = projectType.name;
                captureNumberOfDays = projecttype.AllowMultidays__c;
            }
            if(projectWithType.ProjectScheduleOption__r.Code__c == CONSTANTS.SCHEDULE_OPTION_USER && projectWithType.Status__c == CONSTANTS.PROJECT_STATUS_PLANNING){
                Integer schduledJobCount = [SELECT Count() FROM Job__c WHERE Project__c =:id LIMIT 1];
                if(schduledJobCount == 1){
                    windowChangeWarning = true;
                }
            }
            
            enableLocked  = enableLockedFunc(this.Project.ProjectScheduleOption__c);
            canSetScheduleDate = AppUtil.canSetScheduleDate(id);
            
        }
        
        if (id == null)
        { 
            enableLocked = false;
            this.project.responsibleforexecution__c = CONSTANTS.RESPONSIBLE_FOR_EXECUTION_EXECUTIONCOMPANY;
            this.project.ExecutionSLA__c = decimal.valueof( [SELECT Value__c FROM AppSettings__mdt where DeveloperName='ExecutionSLA' limit 1].Value__c);
          
        }
          //NOTE: Uncomment if submit for approval is required
        /*if (project.Status__c == 'Booked' && isExternalProject == false) {
            //<!-- Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, '<b>Approval Required</b>', 'Submit For Approval is required if the following fields are modified: Responsible For Execution, Start Date and End Date.')); -->
            Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO,  'Submit For Approval is required if the following fields are modified: Responsible For Execution, Start Date and End Date.'));
        }*/
          
        if(project.status__c!=null){            
            List<ProjectAddEditViewCustomSettings__c> projectAddEditViewCustomSettings=[SELECT FieldList__c FROM ProjectAddEditViewCustomSettings__c WHERE ProjectType__c=:projectTypeName AND Status__c=:project.status__c LIMIT 1];
            if(projectAddEditViewCustomSettings.size()>0){
                this.fieldList=projectAddEditViewCustomSettings[0].FieldList__c;
                System.debug('FieldList: '+fieldList);
                if(this.fieldList!=null & this.fieldList!=''){
                    this.mode='edit';     
                }   
            }  
            else{                
                this.mode='new';                 
            }
        }  
        retailers = AppUtil.getProfileRetailers();
        if(retailers.size() > 1) {
            RetailerSelectOptions = new List<SelectOption>();
            RetailerSelectOptions = new List<SelectOption>();
                RetailerSelectOptions.add(new SelectOption('','-None-'));
                for(Retailer__c retailer : retailers){
                RetailerSelectOptions.add(new SelectOption(retailer.Id, retailer.Name));
                }
        }
        if(id != null && this.project.Retailer__c != null){
            SelectedRetailer = this.project.Retailer__c;
        }
    }

    
    public PageReference save() {
        
        PageReference projectView = Page.ProjectDetailsView;
        Boolean updateJobs = false;
        Boolean clearScheduledDates = false;
        try{
            if(captureNumberOfDays){
                List<AggregateResult> result = [select MAX(NumberOfDays__c) maxdays from ProjectService__c where Project__c =:this.Project.Id];
                Integer maxServiceDaysNeeded = Integer.valueOf(result[0].get('maxdays'));
                if(maxServiceDaysNeeded != null && maxServiceDaysNeeded > this.Project.NumberOfDays__c){
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Project number of days cannot be less than number of days at the services'));
                    return null;
                }
                
            }
            
            
            this.project.IsSplit__c = (this.project.SplitType__c!='Solo');
            ProjectType__c projectType = [SELECT name,maxservicecount__c,minservicecount__c, LaunchLeadTime__c   FROM ProjectType__c WHERE id =: projectTypeId ];
            this.project.maxservicecount__c = projectType.maxservicecount__c;
            this.project.minservicecount__c = projectType.minservicecount__c;
            
            if(retailers.size() == 1){
                this.project.Retailer__c = retailers[0].Id;
            }
            else{
                this.project.Retailer__c = selectedRetailer;
            }
            for(Retailer__c retailer: retailers) {
                if(retailer.Id == this.project.Retailer__c){
                    this.project.OneHubRetailerId__c = retailer.OneHubRetailerId__c;
                }
            }
            
            if(ApexPages.currentPage().getParameters().get('id') != null) {
                Project__c oldRecord  = [SELECT Id, StartDate__c, EndDate__c, ProjectScheduleOption__c, NumberOfDays__c FROM Project__c WHERE Id = :this.Project.Id];
                this.project = (Project__c) ctrler.getRecord();
                Integer jobCount = [SELECT count() FROM Job__c WHERE JobStatus__c != :CONSTANTS.JOB_STATUS_CANCELED AND Project__c = :this.Project.Id LIMIT 1];
                if(jobCount > 0 && (this.project.Startdate__c != oldRecord.StartDate__c || this.project.EndDate__c != oldRecord.EndDate__c || this.project.NumberOfDays__c != oldRecord.NumberOfDays__c || this.project.ProjectScheduleOption__c != oldRecord.ProjectScheduleOption__c)){
                    updateJobs = true;
                }
                if(this.project.Status__c == CONSTANTS.PROJECT_STATUS_PLANNING  && (this.project.Startdate__c != oldRecord.StartDate__c || this.project.EndDate__c != oldRecord.EndDate__c || this.project.NumberOfDays__c > oldRecord.NumberOfDays__c)){
                    clearScheduledDates = true;
                }

            }
            
            
            ctrler.save();

            
            this.project = (Project__c) ctrler.getRecord();
            system.debug('updateJobs:'+updateJobs);
            //system.debug('this.project.ProjectType__r.Name:'+this.project.ProjectType__r.Name);
            
            TriggerUtil.SkipAllTriggers();
            
            if(clearScheduledDates){
                Map<Id, ProjectLocation__c> plsMap = new Map<Id, ProjectLocation__c>([SELECT id,LocationScheduledDate__c FROM ProjectLocation__c WHERE Project__c = :this.project.id AND LocationScheduledDate__c != NULL]);
                List<ProjectLocation__c> pls = plsMap.values();
                for(ProjectLocation__c pl :pls){
                    pl.LocationScheduledDate__c = NULL;
                }
                update pls;
            }
            
            if(updateJobs){
                Project__c updatedProject = [SELECT Id, Name, StartDate__c, EndDate__c, Status__c, 
                                             ProjectType__c, ProjectType__r.Name, BudgetedLocationsCount__c, 
                                             LocationTotalCount__c,   BookBudgetedOnly__c, BatchProcessId__c, 
                                             ApexJobName__c, RecordTypeId FROM Project__c WHERE Id =: this.project.Id];
                SchedulingStrategy schedulingStrategyObject = SchedulingStrategyFactory.getSchedulingStrategy(updatedProject.ProjectType__r.Name);
                Boolean isBatchJob = schedulingStrategyObject.isBatchJob(updatedProject, '1');
                system.debug('isBatchJob:'+isBatchJob);
                if(isBatchJob){
                    ProjectScheduler batch = new ProjectScheduler(updatedProject, 'update jobs');
                    updatedProject.BatchProcessId__c = Database.ExecuteBatch(batch, 750);
                    updatedProject.ApexJobName__c = 'Job Updates';
                    //update updatedProject;
                }
                else {
                    Integer jobcount = [SELECT count() FROM Job__c WHERE Project__c = :updatedProject.ID AND JobStatus__c  != 'Canceled'];
                    system.debug('jobcount:'+jobcount);
                    if(jobcount > 0){
                        List<ProjectLocation__c> scope = Database.query(schedulingStrategyObject.getSchedulableLocationsQuery(updatedProject, 'update jobs'));
                        SchedulingStrategyObject.ScheduleLocations(scope, updatedProject.ID, 'update jobs');
                    }
                }
            }
            
          
           upsert project;   
            
            //save tags        
            list<project__tag> lstPT = new list<project__tag>();
            list<project__tag> deletelstPT = new list<project__tag>();
            
            project__tag PT;        
            
            //to identify the new tags 
            boolean isnew = true;
            system.debug ('   ~~newTags~~   ' + newTags);
            if(newTags!=null)
            { 
                if(newTags!='' )
                {
                    for(string s : newTags.split(',',0)){
                        isnew = true;
                        if(projtagsSet!=null){
                        if(!projtagsSet.isEmpty())
                        {
                            if(projtagsSet.contains(s))  //already exist 
                            {               
                                isnew =false;
                            }
                        }
                        }
                        
                        if(isnew)
                        {
                               PT= new project__tag();
                               PT.ItemId = this.project.id; 
                               PT.Name = s;
                               PT.Type = 'Public';
                               lstPT.Add(PT); 
                        }
                    }
                    system.debug ('   lstPT.size()    ' + lstPT.size());
                    if(lstPT.size()>0)
                    insert lstPT;
                }
                
                //to identify the tags theat were deleted
                system.debug ('   projTag    ' +projTag);
                if(projTag!=null){
                    for(project__tag projt: projTag)
                    {
                        if(!newTags.contains(projt.name))   
                        {               
                           deletelstPT.Add(projt); 
                        }        
                    }
                    system.debug ('   deletelstPT.size()    ' + deletelstPT.size());
                    if(deletelstPT.size()>0)
                    delete deletelstPT;   
                }
            }
            
            System.debug('project.id: '+this.project.Id);
            //PageReference projectView = Page.ProjectDetailsView;
            projectView.getParameters().put('id', this.project.id);
            projectView.setRedirect(true);
            
       }
       catch(Exception ex){
            System.debug(' ~~ex '+ ex);
            return null;
       }
       return projectView;
    } 


    public List < SelectOption > getProjectTypes() {
        List < SelectOption > projectTypeOptions = new List < SelectOption > ();
        List < ProjectType__c > projectTypeList = [SELECT id, name FROM ProjectType__c];
        for (ProjectType__c projectType: projectTypeList) {
            projectTypeOptions.add(new SelectOption(projectType.id, projectType.name));
        }
        return projectTypeOptions;
    }

    public PageReference next() {
        return NextPage();
    }
    
    public PageReference NextPage()
    {
        //String projectTypeId = project.ProjectType__c; 
        projectTypeId = project.ProjectType__c;       
        System.debug('ProjectTypeId :' + projectTypeId);
        if (project.ProjectType__c != null) {
            projType = [SELECT name,maxservicecount__c,minservicecount__c,AllowMultidays__c FROM ProjectType__c WHERE id = : projectTypeId];
            this.projectTypeName =projType.name;
            this.mode='new'; 
            captureNumberOfDays = projType.AllowMultidays__c;
        }
        return Page.ProjectAddEditView;
    }
    
    public PageReference redirect()
    {
        list<selectoption> projectTypes = getprojectTypes();     
        System.debug('    projectTypes    '+projectTypes.size());
        if(projectTypes.size()==1)
        {
            system.debug(' inside TransferNextPage ');
            project.ProjectType__c = projectTypes[0].getValue();
            return Nextpage();
        }        
        return null;
    

    }
    
    public void ChangeDate()
    {    
        try{
            if(this.project.ProjectCycle__c!=null)
            {
                cycle__c  cy = [SELECT Id, Name, CycleStartDate__c, CycleEndDate__c, CycleType__c, Retailer__c FROM Cycle__c where id=:this.project.ProjectCycle__c];
                this.project.startdate__C = cy.CycleStartDate__c;
                this.project.enddate__C = cy.CycleEndDate__c;
            }
        }
        catch(exception ex)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,ex.getmessage()));
        }
    }

    @RemoteAction
    global static list<location__c> getCycleDate(string projCycleID) 
    {  
        try{
            string qry;
            qry = ' SELECT Id, Name, format(CycleStartDate__c), format(CycleEndDate__c), CycleType__c, Retailer__c FROM Cycle__c where id =  \'' + projCycleID +'\'  '; 
            return Database.query(qry);
        }
        catch(exception ex)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,ex.getmessage()));
        }
        return null;
    }

    public void ScheduleOptionChange()
    {
        if(this.Project.ProjectScheduleOption__c!=null)
        {
            enableLocked  = enableLockedFunc(this.Project.ProjectScheduleOption__c);
        }
    }
    
    public boolean enableLockedFunc(id optionID)
    {
            string code = [select code__C from ScheduleOption__c where id =: optionID limit 1].code__C;
            return !(code == CONSTANTS.SCHEDULE_OPTION_EC);

    }

}