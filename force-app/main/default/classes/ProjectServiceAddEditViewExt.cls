public without sharing class ProjectServiceAddEditViewExt {
    private Map<ID, Attribute__c> attributeMap {get;set;}    
    public ID projectid {get;set;}
    public Project__c project {get;set;}
    public service__c ServiceObj{get;set;}
    public ProjectService__c ps{get;set;}
    public List<SelectOption> AvlServices{get;set;}
    public List<SelectOption> AvlLanguages{get;set;}    
    public String serviceImageName {get;set;}  
    public Blob serviceImageBody {get;set;} 
    public List<ProjectServiceAttribute__c> pscAttributes{get; set;}
    public String selectedServ {get;set;}
    public String selectedLang {get;set;}    
    public String serviceid {get;set;}
    public List<AttributeWrapper> allAttributes {get; set;}
    public Integer allAttributesSize {get; set;}   
    public String mode {get; set;}
    public String EstDurInMin{get; set;}   
    public String attachmentId {get; set;}
    public String attachmentQstnId {get; set;}
    public Boolean showDelete {get; set;}
    public Boolean isExternalProject {get; set;}
    public Blob customManual{get; set;}
    public String contentType {get; set;}
    public String fileName {get; set;}
    public Boolean disableFields{get;set;}
    public string DefaultPriorityDates{get;set;}
    public string ProjectPriorityDates{get;set;}    
    public Boolean isStartTimeEditable{get;set;}
    public string[] ECValues{get;set;}
    public string responsibleForExecution_ec {get; set;}
    public List<SelectOption> numberOfDaysList{get;set;}
    public Boolean isNoOfWorkersRequired {get;set;}
    public string IEProjectType{get;set;}
    public boolean captureNumberOfDays {get;set;}
    public Map<String,Boolean> editableMap {get;set;}
    public Boolean isDistRequired {get;set;}
    public List<SelectOption> getJobManualTemplates()
    {
        List<SelectOption> options = new List<SelectOption>();
        Schema.DescribeFieldResult fieldResult = RetailerService__c.JobManualTemplate__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        options.add(new SelectOption('', '--None--'));
        for( Schema.PicklistEntry f : ple)
        {
            options.add(new SelectOption(f.getLabel(), f.getValue()));
        }
        return options;
    }
    
    public List<SelectOption> getEventManualTemplates()
    {
        List<SelectOption> options = new List<SelectOption>();
        Schema.DescribeFieldResult fieldResult = RetailerService__c.JobManualTemplate__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        options.add(new SelectOption('', '--None--'));
        for( Schema.PicklistEntry f : ple)
        {
            options.add(new SelectOption(f.getLabel(), f.getValue()));
        }
        return options;
    }
    
    
    public List<SelectOption> getECValuesOption()
    {
        List<SelectOption> options = new List<SelectOption>();
        for(string f : ECValues)
        {
            options.add(new SelectOption(f, f));
        }
        return options;
    }
    
    
    public ProjectServiceAddEditViewExt(ApexPages.StandardController sc) 
    {
        
        attributeMap = new Map<ID, Attribute__c>();
        //String[] EC = AppUtil.getAppSetting('ResponsibleForExecution').split(',');
        string selectedServiceId = ApexPages.currentPage().getParameters().get('selectedServiceId');
        serviceid = ApexPages.currentPage().getParameters().get('id');
        responsibleForExecution_ec = CONSTANTS.RESPONSIBLE_FOR_EXECUTION_EXECUTIONCOMPANY;
        ECValues = AppUtil.getAppSetting('ResponsibleForExecution').split(',');
        Boolean isSelectService = selectedServiceId != null ? true : false;
        if(!isSelectService && serviceid != null &&  serviceid !='')    
        {
            mode = 'edit';
            ps = [SELECT Id, Name, Project__c,project__r.retailer__c, Service__r.Name, TargetType__c,
                  Status__c, StartTime__c, EndTime__c, Service__c,ResponsibleForExecution__c, JobManualURL__c,JobManualFileName__c,
                  ExternalService__c, Project__r.IsExternalProject__c,
                  IncludeAutoGenManual__c, PurchaseAmount__c, JobManual__c,
                  VariantLanguage__c,EstimatedMinutes__c, PopulateTargetQuestions__c, refreshSummary__c, ServiceTitle__c, NumberOfDays__c, StartDayNumber__c,
                  NumberOfWorkers__c, Service__r.IsNumberOfWorkersRequired__c, ShippingPreference__c, Project__r.ProjectScheduleOption__r.Code__c,CheckDistribution__c,Service__r.AllowDistribution__c
                  FROM ProjectService__c where id =:serviceid ];
            filename = ps.JobManualFileName__c;
            isNoOfWorkersRequired = ps.Service__r.IsNumberOfWorkersRequired__c;
            ps.NumberOfWorkers__c = (ps.NumberOfWorkers__c==null?1:ps.NumberOfWorkers__c);
            
            if(ps.Project__r.IsExternalProject__c == true && ps.ExternalService__c == false){
                showDelete = true;
            }
            else{
                showDelete = false;
            }
            system.debug( '~~~~~DefaultPriorityDates~~~~'+DefaultPriorityDates);
            
            selectedServ = ps.Service__c;
            projectid =  ps.Project__c; 
            PopulateAttributes(selectedServ);            
        }
        else
        {
            mode = 'add';
            system.debug(' ~~~~  serviceid  ~~~~ ' + serviceid );
            projectid =  ApexPages.currentPage().getParameters().get('projectid');            
            system.debug(' ~~~~  projectid  ~~~~ ' + projectid );
            
            ps = new ProjectService__c();  //this.controller.getRecord();
            //ps.ResponsibleForExecution__c = 'Execution Company';
            ps.ResponsibleForExecution__c = CONSTANTS.RESPONSIBLE_FOR_EXECUTION_EXECUTIONCOMPANY;
            ps.IncludeAutoGenManual__c = true;
            
            
            if(ps.Project__c==null )  
            { 
                ps.Project__c = projectid;
            }
            
            if(ps.service__c!=null)
            {  
                ServiceObj = (service__C) ps.service__r; 
            }
            else
            {  
                ServiceObj =  new service__C(); 
                
            }
            ps.PopulateTargetQuestions__c=true;
            ps.NumberOfDays__c = 1;
            ps.NumberOfWorkers__c = 1;
        }
        
        project = [SELECT Id, Name,Retailer__c, OneHubRetailerId__c, 
                   ProjectType__c, ProjectType__r.name,StartDate__c,EndDate__c,ResponsibleForExecution__c, Status__c,  IsExternalProject__c, ProjectNumber__c,IsJobManualRegenReqd__c, NumberOfDays__c, ProjectType__r.AllowMultidays__c FROM Project__c where id =: projectid ];
        disableFields = false;
        List<String> perms = new List<String>();
        perms.add('Retailer_Solution_Edit_Weekday_Start_Times');
        perms.add('Retailer_Solution_Super_Developer');
        isStartTimeEditable = false;
        if (project.Status__c == CONSTANTS.PROJECT_STATUS_PLANNING ){
            
            isStartTimeEditable = hasPermissionSet(perms);
        }
        if (project.Status__c == CONSTANTS.PROJECT_STATUS_BOOKED   && AppUtil.hasProjectLeadTimeByProjectId(project.Id))
        {
            disableFields = true;    
            //isStartTimeEditable = Schema.sObjectType.ProjectService__c.fields.StartTimes__c.isUpdateable();
            isStartTimeEditable = hasPermissionSet(perms);
        }
        
        if(project.IsExternalProject__c == true){
            isExternalProject = true;
        }
        else{
            isExternalProject = false;
        }
        
        
        
        //get available services
        
        AvlServices = new list<SelectOption>();
        AvlServices.add(new SelectOption('None','None'));
        
        
        if (AppUtil.getAppSetting('ServiceSelector').toLowerCase() == 'onehub')
        {
            list<ProjectTypeService__c> lstProjSrvc = [SELECT Service__r.id,  Service__r.name FROM ProjectTypeService__c where ProjectType__r.name =: project.ProjectType__r.name and  Service__c  in (SELECT Service__c FROM RetailerService__c where retailer__c =: project.Retailer__c ) order by Service__r.name  ];    
            for(ProjectTypeService__c Obj:lstProjSrvc) {
                AvlServices.add(new SelectOption(Obj.Service__r.id, Obj.Service__r.name));
            }
        }
        
        AvlLanguages = new list<SelectOption>();
        list<language__c> lstlangs = [select id, name from language__c order by name];
        for(language__c lang:lstlangs) {
            AvlLanguages.add(new SelectOption(lang.id, lang.name));
        }
        
        selectedLang = 'English';
        
        numberOfDaysList = new list<SelectOption>();
        Integer days =  Integer.valueOf(project.NumberOfDays__c);
        for(Integer day = 1; day <= days; day++){
            numberOfDaysList.add(new SelectOption(string.valueof(day ), string.valueof(day )));
        }
        Set<String> editableFields = new Set<String> {
            'ProjectService__c.ServiceTitle__c'
                };
                    String projectStatus= project.Status__c; 
        editableMap = UIConfig.isEditale(projectStatus, editableFields);
        
        if (isSelectService) {
            selectedServ = selectedServiceId;
        }
    }
    
    public PageReference  save()
    {
        try{
            //delManual(ps.id);
            Boolean updateManual = false;
            Boolean updateJobs = false;
            Boolean resetJobScheduleDates = false;
            
            if(mode != 'add'){
                ProjectService__c oldRecord  = [SELECT Id, NumberOfDays__c, StartDayNumber__c, StartTime__c, Endtime__c, NumberOfWorkers__c FROM ProjectService__c WHERE Id = :this.ps.Id];
                Integer jobCount = [SELECT count() FROM Job__c WHERE JobStatus__c != :CONSTANTS.JOB_STATUS_CANCELED AND ProjectService__c = :this.ps.Id LIMIT 1];
                if(jobCount > 0 && (this.ps.Project__r.ProjectScheduleOption__r.Code__c == CONSTANTS.SCHEDULE_OPTION_USER) && (this.ps.NumberOfDays__c != oldRecord.NumberOfDays__c || this.ps.StartDayNumber__c != oldRecord.StartDayNumber__c)){
                    resetJobScheduleDates = true;
                }
                system.debug('DIFF:this.ps.NumberOfDays__c::'+this.ps.NumberOfDays__c + '|' + oldRecord.NumberOfDays__c);
                system.debug('DIFF:this.ps.StartTime__c::'+this.ps.StartTime__c + '|' + oldRecord.StartTime__c);
                system.debug('DIFF:this.ps.Endtime__c::'+this.ps.Endtime__c + '|' + oldRecord.Endtime__c);
                system.debug('DIFF:this.ps.NumberOfWorkers__c::'+this.ps.NumberOfWorkers__c + '|' + oldRecord.NumberOfWorkers__c);
                //Murali - TODO: Fix improper js handling of end time
                //end time is returned as empty string rather than null, this is triggering  end time field change
                //temp fix, made old record Endtime__c to empty if null
                if(this.ps.Endtime__c == '' && oldRecord.Endtime__c == null){
                    oldRecord.Endtime__c = '';
                }
                system.debug('DIFF:AFTER:this.ps.Endtime__c::'+this.ps.Endtime__c + '|' + oldRecord.Endtime__c);
                if(this.ps.Project__r.ProjectScheduleOption__r.Code__c == CONSTANTS.SCHEDULE_OPTION_USER && jobCount > 0 && (this.ps.NumberOfDays__c != oldRecord.NumberOfDays__c || this.ps.StartTime__c != oldRecord.StartTime__c || this.ps.Endtime__c != oldRecord.Endtime__c || this.ps.NumberOfWorkers__c != oldRecord.NumberOfWorkers__c)){
                    updateJobs = true;
                }
                system.debug('updateJobs::'+updateJobs);
            }
            
            //if(project.ResponsibleForExecution__c != CONSTANTS.RESPONSIBLE_FOR_EXECUTION_EXECUTIONCOMPANY){
            //  ps.ResponsibleForExecution__c = project.ResponsibleForExecution__c;
            //}
            system.debug(' ---- selectedServ  ---- ' + selectedServ+'_______'+ps.JobManual__c);
            
            ps.Service__c = selectedServ;
            List<variant__c> variants = [select id, name from variant__c where language__c =:selectedLang LIMIT 1];
            if (variants.size() > 0)
            {
                ps.Variant__c = variants[0].Id;
            }
            
            ps.OneHubRetailerId__c = project.OneHubRetailerId__c;
            string urlData;
            
            if(ps.JobManual__c == CONSTANTS.JOB_MANUAL_CUSTOM_TEMPLATE){
                //for custom pdf
                system.debug(' ---- Custom Template ---- ' );    
                ps.IncludeAutoGenManual__c = false;
                system.debug(' ---- customManual ---- ' +customManual + ' --------------------------------' + fileName); 
                
                //blob bl = blob.valueof('test');
                system.debug(' ---- bl bl  bl ---- ' +ps.JobManualFileName__c );
                if(ps.JobManualFileName__c!=fileName && fileName!=null)  
                {
                    ps.JobManualFileName__c = fileName;
                    urlData = AttachmentUrlGenerator.callImageServiceToPostAttachment(customManual);
                    //system.debug(' ---- urlData ---- '+urlData);    
                    AttachmentUrlGenerator.updateDetails(ps,urlData);
                    updateManual = true;            
                }
            }
            else{
                ps.IncludeAutoGenManual__c = true;
                ps.JobManualFileName__c = ''; 
                ps.JobManualURL__c = '';
                customManual= Blob.valueof('');
            }
            upsert ps;
            
            
            //Added this condition as SurveyQuestions need not be deleted
            //every time the ps is saved. Only done once when
            //ps is created.
            
            if (mode == 'add')
            {
                list<ServiceQuestion__c> tempQnsList = [SELECT Id, Name, Question__c, QuestionNumber__c, QuestionText__c, QuestionType__c FROM ServiceQuestion__c 
                                                        Where service__c = : ps.service__c and Question__r.Active__c = true]; 
                
                Map<Id, Id> mqv = new Map<Id, Id>();
                Map<Id, Id> mqdrv = new Map<Id, Id>();
                
                if (ps.Variant__c != null)
                {
                    Set<Id> qids = new Set<Id>();
                    for(integer j=0;j<tempQnsList.size();j++)
                    {
                        qids.add(tempQnsList[j].Question__c);
                        
                    }
                    list<questionvariant__c> qvs = [select id, name, question__c, questiontext__c from questionvariant__c where Question__c in :qids and variant__c = :ps.variant__c];
                    
                    for (questionvariant__c qv : qvs)
                    {
                        mqv.put(qv.Question__c, qv.id);
                    }
                    
                    
                    list<questiondefinedresponsevariant__c> qdrvs = [select id, name, questiondefinedresponse__c from questiondefinedresponsevariant__c where variant__c = :ps.variant__c and questiondefinedresponse__c in (select id from questiondefinedresponse__c where Question__c in :qids)];
                    for (questiondefinedresponsevariant__c qdrv : qdrvs)
                    {
                        mqdrv.put(qdrv.questiondefinedresponse__c, qdrv.id);
                    }
                }                                
                
                list<ProjectServiceQuestionDefinedResponse__c> definedResponses = new list<ProjectServiceQuestionDefinedResponse__c>();
                for(integer j=0;j<tempQnsList.size();j++)
                {
                    ProjectServiceQuestion__c surveyQn = new ProjectServiceQuestion__c();
                    surveyQn.QuestionNumber__c = tempQnsList[j].QuestionNumber__c;            
                    surveyQn.ServiceQuestion__c = true;
                    surveyQn.ProjectService__c = ps.id;  
                    surveyQn.Question__c = tempQnsList[j].Question__c;
                    surveyQn.QuestionVariant__c = mqv.get(tempQnsList[j].Question__c);
                    insert surveyQn;
                    
                    ProjectServiceQuestionDefinedResponse__c defResp;
                    List<ServiceQuestionDefinedResponse__c> sqDefResList = [ SELECT Id, Name, QuestionDefinedResponse__c, JumpToQuestion__c, EndOfQuestions__c  FROM ServiceQuestionDefinedResponse__c where ServiceQuestion__c = :tempQnsList[j].Id]  ;
                    for(integer i=0;i<sqDefResList.size();i++)
                    {
                        defResp =  new ProjectServiceQuestionDefinedResponse__c();
                        defResp.ProjectServiceQuestion__c = surveyQn.id;
                        defResp.QuestionDefinedResponse__c = sqDefResList[i].QuestionDefinedResponse__c;
                        defResp.JumpToQuestion__c = sqDefResList[i].JumpToQuestion__c;
                        defResp.EndOfQuestions__c = sqDefResList[i].EndOfQuestions__c;
                        defResp.QuestionDefinedResponseVariant__c = mqdrv.get(sqDefResList[i].QuestionDefinedResponse__c);
                        definedResponses.add(defResp);
                    } 
                }
                
                insert definedResponses;
                //save project location
                list<projectlocation__c> plList = [select id from projectlocation__c where project__c=: project.id];
                for(projectlocation__c pl : plList){
                    pl.status__c = null;
                }
                update plList;
                //Murali - Removed this behavor, added a check at submit
                /*SchedulingStrategy schedulingStrategyObject = SchedulingStrategyFactory.getSchedulingStrategy(project.ProjectType__r.Name);
List<ProjectLocation__c> scope = Database.query(schedulingStrategyObject.getSchedulableLocationsQuery(project));
SchedulingStrategyObject.ScheduleLocations(scope, project.ID);*/                
            }
            
            saveAttributes();
            
            if(updateManual)
            {
                system.debug(' ----final urlData ---- '+urlData);    
                AttachmentUrlGenerator.updateDetails(ps,urlData);        
            }           
            
            if(updateJobs){
                Map<id,Job__c> jobMap = new Map<id,Job__c>([SELECT Id, NumberOfDays__c, NumberOfWorkers__c, JobStartTime__c, JobEndTime__c FROM Job__c WHERE ProjectService__c  = :this.ps.Id AND JobStatus__c != :CONSTANTS.JOB_STATUS_CANCELED limit 10000 FOR UPDATE]);
                List<Job__c> existingJobs = jobMap.values();
                for(Job__c job:existingJobs){
                    job.NumberOfDays__c = this.ps.NumberOfDays__c;
                    job.NumberOfWorkers__c = this.ps.NumberOfWorkers__c;
                    job.JobStartTime__c = this.ps.StartTime__c;
                    job.JobEndTime__c = this.ps.EndTime__c;
                }
                TriggerUtil.skipAllTriggers();
                update existingJobs;
            }
            
            Boolean redirectToProjectPage = false;
            if(resetJobScheduleDates){
                Integer jobCount = [SELECT count() FROM Job__c WHERE ProjectService__c =:ps.Id AND JobStatus__c != :CONSTANTS.JOB_STATUS_CANCELED LIMIT :JobActionsHelper.JOB_BATCH_SCHEDULEDATE_DECISION_COUNT];
                if(jobCount > 0){
                    List<ActionResponse> responses = ProjectServiceActionsHelper.resetScheduleDate(ps.Id);
                    if (jobCount == JobActionsHelper.JOB_BATCH_SCHEDULEDATE_DECISION_COUNT){
                        redirectToProjectPage = true;
                    }
                    else if(!responses[0].IsSuccessful){
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Error, rescheduling jobs'));
                    }
                }
            }
            
            if(redirectToProjectPage){
                PageReference projectPage = new ApexPages.StandardController(project).view();
                projectPage.setRedirect(true);
                return projectPage;    
            }
            
            PageReference psPage = new ApexPages.StandardController(ps).view();
            psPage.setRedirect(true);
            return psPage;    
            //Comment Versioning Code
            //Apputil.UpdateProjectVersion(project.ID);
            
        }
        catch (exception ex)
        {
            if(!ex.getmessage().contains('FIELD_CUSTOM_VALIDATION_EXCEPTION'))
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Error: ' + ex.getmessage()));
            return null;
        }
        return null;
    }
    /*
HTTP action: when a new service is selected 
during the new service provision process. 
*/
    void parseFormData() {
        selectedServ = ApexPages.currentPage().getParameters().get('selectedServiceId');
        projectid = ApexPages.currentPage().getParameters().get('projectid');
    }
    
    public pageReference readServiceData()
    {
        parseFormData();
        allAttributes = new List<AttributeWrapper>();
        ServiceObj = new service__c ();
        string param = selectedServ; // System.currentPagereference().getParameters().get('paramVal');                
        system.debug(' ---- selectedServ    ---- ' + selectedServ + ' ---- param ---- ' + param );
        
        
        if(param== null ||  param =='') 
        {
            param = ps.service__c;
        }
        system.debug('param-------- '+param );
        if(param.toLowerCase() == 'none') 
        {
            return null;
        }
        
        ServiceObj = [Select Id, TargetType__c,duration__c, IsNumberOfWorkersRequired__c,AllowDistribution__c From service__c 
                      Where Id = : param  limit 1];
        
        isNoOfWorkersRequired = ServiceObj.IsNumberOfWorkersRequired__c;
        isDistRequired = ServiceObj.AllowDistribution__c;
        
        
        assignRetailerServiceRelatedAttributes(param, project.Retailer__c);
        
        system.debug(' ---- ServiceObj.TargetType__c  ---- ' + ServiceObj.TargetType__c );
        // make product the default value        
        if(ServiceObj.TargetType__c.contains('Product'))
        {
            ps.TargetType__c='Product';
        }
        
        //Add non-repeatable values here
        PopulateAttributes(param);        
        system.debug ('allAttributes Size: ' + allAttributes.size());
        return null;
    } 
    
    private void assignRetailerServiceRelatedAttributes(id serviceID, id retailerID){
        system.debug('~~~~'+serviceID+'~~~~'+retailerID);
        RetailerService__c[] rs = [Select JobManualTemplate__c, Monday__c,Tuesday__c,Wednesday__c, Thursday__c,Friday__c, Saturday__c,Sunday__c From RetailerService__c Where Service__c = : serviceID AND Retailer__c = :retailerID  limit 1];
        if(rs.size() < 1 ) { return; }
        
        if(rs[0].JobManualTemplate__c!= null){
            ps.JobManual__c = rs[0].JobManualTemplate__c; 
        }
        assignPriorityDates(rs[0]);        
        assignStartEndTimes(rs[0]);       
    }
    
    private void assignStartEndTimes(RetailerService__c rs) {
    }
    private String stringOf(Object startTime) {
        String test = String.valueOf(startTime);
        return String.isEmpty(test) ? '' : test;      
    }
    
    private void assignPriorityDates(RetailerService__c rs) {
        Map<Integer,Integer> tempMap = new Map<Integer,Integer>();
        
        if(!String.isEmpty(string.valueof(rs.Monday__c)) && rs.Monday__c!=0)
        {
            tempMap.put(integer.valueof(rs.Monday__c),1);
        }        
        
        if(!String.isEmpty(string.valueof(rs.Tuesday__c)) && rs.Tuesday__c!=0)
        {
            tempMap.put(integer.valueof(rs.Tuesday__c),2);
        }        
        
        if(!String.isEmpty(string.valueof(rs.Wednesday__c)) && rs.Wednesday__c!=0)
        {
            tempMap.put(integer.valueof(rs.Wednesday__c),3);
        }        
        
        if(!String.isEmpty(string.valueof(rs.Thursday__c)) && rs.Thursday__c!=0)
        {
            tempMap.put(integer.valueof(rs.Thursday__c),4);
        }        
        
        if(!String.isEmpty(string.valueof(rs.Friday__c)) && rs.Friday__c!=0)
        {
            tempMap.put(integer.valueof(rs.Friday__c),5);
        }        
        
        if(!String.isEmpty(string.valueof(rs.Saturday__c)) && rs.Saturday__c!=0)
        {
            tempMap.put(integer.valueof(rs.Saturday__c),6);
        }        
        
        if(!String.isEmpty(string.valueof(rs.Sunday__c)) && rs.Sunday__c!=0)
        {
            tempMap.put(integer.valueof(rs.Sunday__c),0);
        }     
        
        
        DefaultPriorityDates='';
        List<integer> aList = new List<integer>();
        aList.addAll(tempMap.keySet());
        aList.sort();
        system.debug('aList' + aList);
        for(integer a: aList)
        {
            DefaultPriorityDates += tempMap.get(a) + ',' ;
        }
        
        system.debug('DefaultPriorityDates    ' + DefaultPriorityDates);
    }
    
    private void saveAttributes()
    {
        String attachmentId;
        
        UpdatePSCAttributes();
        
        system.debug('Bfr Res Count: ' + pscAttributes.size());
        system.debug('   URL mapping   ');
        
        //Generate URLs
        for(ProjectServiceAttribute__c psca : pscAttributes){                                           
            //String attributeType =  psca.AttributeType__c;  //getAttributeType(psca);
            String attributeType = [select AttributeType__c from ProjectServiceAttribute__c where id=:psca.id].AttributeType__c;  
            
            system.debug('  insert url '+ psca.AttributeValue__c + '     ---      '+ psca.id+ '     ---      '+ attributeType );
            
            if ((attributeType == 'Photo' || attributeType == 'File') && !String.isEmpty(psca.AttributeValue__c))
            {
                system.debug('   psca.idg   '+psca.id);
                attachmentId = parseAttachmentId(psca.AttributeValue__c);
                system.debug(' --attachmentId--  '+ attachmentId);
                if(psca.AttachmentURL__c!=null){  //update url
                    
                    system.debug('  update url '+ psca.AttachmentURL__c + '             '+ attachmentId);
                    GenerateURL.UpdateURL(psca.id,psca.AttachmentURL__c, psca.AttributeValue__c);
                }
                else{ //generate url for first time
                    system.debug('  insert url first '+ attachmentId + '    ----       '+ psca.id);
                    GenerateURL.GenerateNewURL(psca.id, attachmentId);                    
                }
            }
        }
        system.debug('Upsert Success');
    }
    
    private String parseAttachmentId(String attributeValue) {
        if (String.isNotBlank(attributeValue)) {
            return attributeValue.split('=')[0];    
        }
        return '';
        
    }
    
    
    private void UpdateAttributeResponse(Id atId, string value,string imageName)
    {
        Boolean found = false;
        
        system.debug ('Attribute Id: ' + atId);
        for(ProjectServiceAttribute__c psca : pscAttributes)
        { 
            if (psca.Attribute__c == atId)
            {
                system.debug ('Attribute Id Matched: ' + atId);
                psca.AttributeValue__c  = value;
                psca.AttchFileName__c = imageName;
                found = true;
                break;
            }
        }
        
        //New rsponses, insert only if they are not empty
        if (found == false)
        {
            ProjectServiceAttribute__c newpsca = new ProjectServiceAttribute__c();
            newpsca.Attribute__c = atId;                          
            newpsca.AttributeValue__c  = value;
            newpsca.AttchFileName__c = imageName;
            if (selectedServ != null && selectedServ != '')
            {
                newpsca.Service__c = selectedServ ;
            }
            else
            {
                newpsca.Service__c = ServiceObj.Id;
            }
            
            ServiceAttribute__c sa = [Select Id, name, AttributeOrder__c from ServiceAttribute__c where Attribute__c = :atId and Service__c = :newpsca.Service__c LIMIT 1]; 
            //newpsca.AttributeOrder__c = sa.AttributeOrder__c;
            newpsca.ServiceAttribute__c = sa.id;
            newpsca.ProjectService__c = ps.Id;    
            system.debug('newpsca: '+newpsca);
            pscAttributes.Add(newpsca);
            system.debug('pscAttributes: 0 '+pscAttributes);
        }
    }
    
    private void UpdatePSCAttributes()
    {
        string answer = '';
        String attachmentId;
        system.debug ('in process attributes');
        
        for (AttributeWrapper att : allAttributes)
        {
            system.debug('questiontext: ' + att.attributeName + ' - answer: ' + att.attributeValue);            
            if (att.renderFile == 'true' && att.imagebody!= null && att.imageName != null)
            {
                Attachment myAttachment  = new Attachment();  
                myAttachment.Body = att.imagebody;  
                myAttachment.Name = att.imageName;  
                myAttachment.ParentId = projectid;  
                insert myAttachment;  
                System.debug('*****Select Image Attachment Id: ' + String.ValueOf(myAttachment.Id) + ' :' + att.imageFlag); 
                att.AttributeValue = String.isNotBlank(att.imageFlag) ? (String.ValueOf(myAttachment.Id) + '=' + att.imageFlag) : String.ValueOf(myAttachment.Id);                
                system.debug('Service Response Image inserted');           
            }
            
            UpdateAttributeResponse(att.id, att.attributeValue,att.imageName);
            
        }
        system.debug('pscAttributes.size: ' + pscAttributes.size());
        upsert pscAttributes;
    }
    
    
    
    public void PopulateAttributes(Id serviceId)
    {
        
        //Clear the pscAttributes list
        pscAttributes = new List<ProjectServiceAttribute__c>();
        allAttributes = new List<AttributeWrapper>();
        
        system.debug('~~~ get attributes ps.id ~~~~~ '+ps.Id);
        if (ps != null && ps.Id != null)    
        {
            pscAttributes = [Select Id, Name, ServiceAttribute__c, AttributeTitle__c, AttributeType__c, Attribute__c, ProjectService__c, AttachmentURL__c,AttachmentExt__c, Service__c, AttributeValue__c  from ProjectServiceAttribute__c WHERE ProjectService__c = :ps.Id Order By AttributeOrder__c];
        }
        
        Map<Id, Boolean> invibleAttMap = new Map<Id, Boolean>();
        List<ServiceAttribute__c> satts = [Select Name,Attribute__c, IsVisible__c, AttributeTitle__c, AttributeType__c, AttributeOrder__c, DefaultAttributeValue__c from ServiceAttribute__c where Service__c =:serviceId order by AttributeOrder__c];        
        for(ServiceAttribute__c sa:satts){
            invibleAttMap.put(sa.Attribute__c, sa.isvisible__c);
        }
        
        List<ServiceAttribute__c> satList;                                                            
        if (pscAttributes == null || pscAttributes.size() == 0)
        {
            
            for (ServiceAttribute__c satt : satts)
            {
                string defaultValue = String.IsBlank(satt.DefaultAttributeValue__c)?'':satt.DefaultAttributeValue__c;
                
                AttributeWrapper attObj = AttributeWrapper.newInstance(satt, defaultValue);
                attObj.isVisible = invibleAttMap.get(satt.Attribute__c);
                allAttributes.add(attObj);
            }
        } 
        else{
            satList = [Select Id, Name, Attribute__c, AttributeTitle__c, AttributeType__c, AttributeOrder__c from ServiceAttribute__c where Id IN (Select ServiceAttribute__c from ProjectServiceAttribute__c where ProjectService__c =:ps.Id) order by AttributeOrder__c ];                
            Map<Id, ServiceAttribute__c> saMap = new Map<Id, ServiceAttribute__c>(satList);
            for(ProjectServiceAttribute__c pscAttribute : pscAttributes)
            { 
                AttributeWrapper attObj = AttributeWrapper.newInstance(saMap.get(pscAttribute.ServiceAttribute__c), pscAttribute.AttributeValue__c );
                attObj.isVisible = invibleAttMap.get(pscAttribute.Attribute__c);
                allAttributes.add(attObj);
            }
        }
        allAttributesSize = allAttributes.size();
    }    
    
    
    private void notifyProjectServiceAttributeValueFlushed(String attributeId) {
        for(AttributeWrapper attr: allAttributes) {
            if (attr.id == attributeId) {
                attr.flushValue();
            }
        }
    }
    
    // handle the action of the commandButton
    public PageReference deleteAttachment() {
        System.debug('attachmentId: '+attachmentId);
        System.debug('attachmentQstnId : '+attachmentQstnId );
        List<Attachment> a = [select id from attachment where id = :attachmentId];
        if(a.size() > 0){
            delete a;
            
            List<ProjectServiceAttribute__c> pscaList = [SELECT Id,AttributeValue__c FROM ProjectServiceAttribute__c where Attribute__c = :attachmentQstnId AND ProjectService__c = :ps.Id LIMIT 1];
            if(pscaList.size() > 0){
                pscaList[0].AttributeValue__c = null;
                update pscaList;
                notifyProjectServiceAttributeValueFlushed(attachmentQstnId);
            }
            //todo need to update allaatribues for this specific attribute.
        }
        String url = Apexpages.currentPage().getUrl();
        System.debug('current url: ' + url);
        PageReference pageRef = new PageReference(url);
        pageRef.setRedirect(false);
        return pageRef;
    }
    
    public Boolean hasPermissionSet(List<String> setName){
        List<PermissionSetAssignment> perms = [select PermissionSet.Name from PermissionSetAssignment where Assignee.Id = :userinfo.getUserId() AND PermissionSet.Name IN:setName];
        system.debug('###perms: '+perms);
        system.debug('###perms.size(): '+perms.size());
        if(perms.size()>0){
            return true;
        }
        return false;
    }
    
    public List<SelectOption> getShippingPreference()
    {
        List<SelectOption> options = new List<SelectOption>();        
        Schema.DescribeFieldResult fieldResult = ProjectService__c.ShippingPreference__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        options.add(new SelectOption('', '--SELECT--'));
        for(Schema.PicklistEntry f : ple)
        {
            options.add(new SelectOption(f.getLabel(), f.getValue()));
        }       
        return options;
    }
    
}