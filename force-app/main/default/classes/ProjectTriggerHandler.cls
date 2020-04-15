public class ProjectTriggerHandler extends TriggerHandler {
    
    public override void beforeInsert() {
        if (TriggerUtil.SkipProjectTrigger) return;
        TriggerUtil.SkipProjectTrigger = true;
        
        List<Retailer__c> retailers = [Select Id, name from Retailer__c LIMIT 2];
        
        Map<Id, ProjectType__c> projectType = new Map<Id, ProjectType__c>([select Id, GracePeriodDuration__c, LaunchLeadTime__c, MaxServiceCount__c, 
                                                                           MinServiceCount__c, AllowBundlingOfServices__c,AllowTeamManagement__c, DefaultRetailerAccount__c
                                                                           FROM ProjectType__c]);
        for (Project__c p: (List <Project__c> ) Trigger.new) {
            p.status__c = CONSTANTS.PROJECT_STATUS_PLANNING;
            p.MaxServiceCount__c = ((ProjectType__c)projectType.get(p.ProjectType__c)).MaxServiceCount__c;
            p.MinServiceCount__c = ((ProjectType__c)projectType.get(p.ProjectType__c)).MinServiceCount__c;
            p.BundleServices__c = ((ProjectType__c)projectType.get(p.ProjectType__c)).AllowBundlingOfServices__c;
            p.AllowTeamManagement__c = ((ProjectType__c)projectType.get(p.ProjectType__c)).AllowTeamManagement__c;
            p.RetailerAccount__c = ((ProjectType__c)projectType.get(p.ProjectType__c)).DefaultRetailerAccount__c;
            
            if (retailers != null && retailers.size() == 1)
            {
                p.Retailer__c = retailers[0].Id;
            }
            
            if (p.NumberOfDays__c == null)
            {
                p.NumberOfDays__c = 1;
            }
            
            if (p.ProjectBuilderId__c != null)
            {
                p.OwnerId = p.ProjectBuilderId__c;
                
            }
            
            if(projectType == null || projectType.size() == 0){
                throw new CustomException('Project Type is not defined');
            }
            if(((ProjectType__c)projectType.get(p.ProjectType__c)).GracePeriodDuration__c == null){
                throw new CustomException('Project Type Grace Period Duration is not defined');
            }
            else{
                p.ProjectGracePeriodDuration__c = ((ProjectType__c)projectType.get(p.ProjectType__c)).GracePeriodDuration__c;    
            }
            if(((ProjectType__c)projectType.get(p.ProjectType__c)).LaunchLeadTime__c == null){
                throw new CustomException('Project Type Launch Lead Time is not defined');
            }
            if (p.ProjectLaunchDate__c == null){
                Integer launchLeadtime = ((ProjectType__c)projectType.get(p.ProjectType__c)).LaunchLeadTime__c.intValue();
                if(launchLeadtime < 0){
                    launchLeadtime = 0;
                }
                p.ProjectLaunchDate__c = p.StartDate__c.addDays( launchLeadtime * -1);
            }
        }
    }
    
    //Insert project attributes from project type when project is created (Murali)
    //davidzhao: add default value if defined.
    public override void afterInsert(){
        //bulkified
        //
        
        if (TriggerUtil.skipProjectAfterInsertTrigger) return;
        TriggerUtil.skipProjectAfterInsertTrigger = true;
        
        List<Project__c> newProjectList = (List<Project__c>) Trigger.new;
        List<Project__c> updatedProjectList = new List<Project__c>();        
        
        Set<Id> projectTypeIds = new Set<Id>();
        for (Project__c newProject : newProjectList) {
            projectTypeIds.add(newProject.ProjectType__c);
            Project__c cProject = new Project__c(id = newProject.id, ProjectType__c = newProject.ProjectType__c, 
                                                 Status__c = newProject.Status__c, RecordTypeId = newProject.RecordTypeId);
            system.debug('After Insert: ' + cProject.Status__c + ':' + cProject.ProjectType__c + ':' + cProject.ProjectTypeName__c);
            cProject.Status__c = CONSTANTS.PROJECT_STATUS_PLANNING;
            cProject.ChangeRecordType__c = True;
            updatedProjectList.add(cProject);
            
        }
        update updatedProjectList;
        
        Map<Id,List<ProjectTypeAttribute__c>> ptaMap = new Map<Id,List<ProjectTypeAttribute__c>>();
        for (ProjectTypeAttribute__c pta : [SELECT Id,Name,ProjectType__c,AttributeName__c,AttributeOrder__c,AttributeType__c,Attribute__c, AttributeValue__c FROM ProjectTypeAttribute__c WHERE ProjectType__c IN :projectTypeIds and IsActive__c = true]) {
            List<ProjectTypeAttribute__c> ptaList = ptaMap.get(pta.ProjectType__c);
            if (ptaList == null) {
                ptaList = new List<ProjectTypeAttribute__c>{ pta };
                    }
            else {
                ptaList.add(pta); 
            }
            ptaMap.put(pta.ProjectType__c, ptaList);
        }
        
        List<ProjectAttribute__c> paList = new List<ProjectAttribute__c>();
        for (Project__c p: newProjectList) {
            if(ptaMap.get(p.ProjectType__c) != null){
                for(ProjectTypeAttribute__c pta : ptaMap.get(p.ProjectType__c)){
                    ProjectAttribute__c pa = new ProjectAttribute__c();
                    pa.Project__c = p.Id;
                    pa.AttributeValue__c = pta.AttributeValue__c;
                    pa.Attribute__c = pta.Attribute__c;
                    pa.ProjectTypeAttribute__c = pta.Id;
                    paList.add(pa);
                }    
            }
        }
        if(paList.size() > 0){
            insert paList;    
        }
    }
    
    public override void beforeUpdate() {
        
        Boolean changeRecordType = false;
        
        for (Project__c newProject : (Project__c[]) Trigger.new) {  
            Project__c oldProject = (Project__c) Trigger.oldMap.get(newProject.Id);
            
            if ((oldProject.ApexJobName__c != newProject.ApexJobName__c) ||
                (oldProject.Status__c != newProject.Status__c) || newProject.ChangeRecordType__c)
            {
                changeRecordType = true;
                break;
            }
        }
        
        if (changeRecordType)
        {
            rtInfo rti = GetRTInfo();
            String defaultRTId = rti.drtid;
            String projectrtPattern = rti.rtpattern;
            String lockedrtId = rti.lrtid;
            Map<String, String> rtmap = rti.rtmap;
            
            for (Project__c newProject : (Project__c[]) Trigger.new) {  
                Project__c oldProject = (Project__c) Trigger.oldMap.get(newProject.Id);
                
                system.debug('Before Update: ' + oldProject.Status__c + '-' + newProject.Status__c);
                
                if ((oldProject.ApexJobName__c != null && newProject.ApexJobName__c == null) ||
                    (oldProject.Status__c != newProject.Status__c) || newProject.RecordTypeId == defaultRTId)
                {
                    system.debug('Before Update: ' + newProject.Status__c + ':' + newProject.ProjectType__c + ':' + newProject.ProjectTypeName__c);
                    ProjectActionsHelper.SetRecordType(newproject, rtmap, projectrtPattern);
                }
                
                if (oldProject.ApexJobName__c == null && newProject.ApexJobName__c != null)
                {
                    newProject.RecordTypeId = lockedrtId;
                }
                
                if (newProject.ChangeRecordType__c)
                    newProject.ChangeRecordType__c = false;
            }
        }
        
        
        
        
        if (TriggerUtil.SkipProjectTrigger) return;
        TriggerUtil.SkipProjectTrigger = true;
        
        Project__c[] newProjectList = (Project__c[]) Trigger.new;
        Set<Id> projectIds = new Set<Id>();
        Set<Id> allprojectIds = new Set<Id>();
        Map<String, Opportunity> projectOppsMap = new Map<String, Opportunity>();
        
        List<EntityChangeType__c> ects = [Select Id, Field__c from EntityChangeType__c WHERE Entity__c = 'Project'];
        
        Integer latestSequence = getLatestVersion();
        Project__c[] projectsForJobMaterialsBatchUpdate = new Project__c[]{};      
            
        for (Project__c newProject : newProjectList) {
        	allprojectids.add(newProject.Id);
        }
        
        List<Opportunity> opps = [Select Id, Project__c, PreBill__c from Opportunity WHERE Project__c IN :allprojectids];
        for (Opportunity opp : opps)
        {
            projectOppsMap.put(opp.Project__c, opp);
            
        }
        
        for (Project__c newProject : newProjectList) {
            
            Project__c oldProject = (Project__c) Trigger.oldMap.get(newProject.Id);            
            
            //skip trigger if the project is updated with archive flags or skip validation rules falg is on
            if(newProject.SkipValidationRules__c == true|| newProject.ArchiveStatus__c == CONSTANTS.ARCHIVE_STATUS_PENDING || 
               newProject.ArchiveStatus__c == CONSTANTS.ARCHIVE_STATUS_ARCHIVED)
            {
            	return;
            }
            
            //non bulk scenario. to handle project edits on ui
            if(newProjectList.size() == 1){
                AggregateResult[] result = [SELECT MAX(NumberOfDays__c) maxdays, MAX(DayNumber__c) maxdaynumber FROM ProjectService__c WHERE Project__c =: newProject.Id];
                Integer maxServiceDays = Integer.valueOf(result[0].get('maxdays'));
                Integer maxDayNumber = Integer.valueOf(result[0].get('maxdaynumber'));
                
                if((maxServiceDays != null && maxServiceDays > newProject.NumberOfDays__c) ||
                   (maxDayNumber != null && maxdaynumber > newProject.NumberOfDays__c))
                {
                    newProject.addError('Project number of days cannot be less than number of days at the services');
                    return;                    
                }
                
                //Check if project has chantged and isChanged flag needs to be set
                
                if (!newProject.IsPendingChanges__c)
                {
                    newProject.IsPendingChanges__c = IsProjectChanged(newProject, oldProject, ects);
                }
                
                Integer jobCount = [SELECT count() FROM Job__c WHERE  Project__c = :newProjectList[0].Id LIMIT 1];
                if(jobCount > 0 && (newProject.Startdate__c > oldProject.StartDate__c || newProject.EndDate__c < oldProject.EndDate__c))
                {            
                    newProject.addError('Cannot shorten the project window after jobs have been created. Please remove jobs and try again.');
                    return;                    
                }
                
                if(jobCount > 0  && (newProject.NumberOfDays__c < oldProject.NumberOfDays__c))
                {            
                    newProject.addError('Cannot reduce project number of days after jobs have been created. Please remove jobs and try again.');
                    return;                    
                } 

				//Veirfy the pl scheduled date are inside the project window.
				//OH-6055                
                AggregateResult[] result2 = [SELECT MAX(LocationScheduledDate__c) maxldate, MIN(LocationScheduledDate__c) minldate FROM ProjectLocation__c WHERE Project__c =: newProject.Id];
				
                Date maxldate = result2[0].get('maxldate') == null? null : Date.valueOf(result2[0].get('maxldate'));
                Date minldate = result2[0].get('minldate') == null? null : Date.valueOf(result2[0].get('minldate'));
                
                
                if(newProject.ProjectScheduleOptionCode__c == Constants.SCHEDULE_OPTION_USER && maxldate != null && minldate != null && 
                   											(maxldate < newProject.Startdate__c || maxldate > newProject.EndDate__c 
                                                            || minldate < newProject.Startdate__c || minldate > newProject.EndDate__c ))
                {  
                    
                    newProject.addError('One or more project locations have scheduled date that falls outside the project window. Please verify and retry.');
                    return;                    
                }                
                
                if(newProject.Status__c == CONSTANTS.PROJECT_STATUS_BOOKED && oldProject.Status__c != CONSTANTS.PROJECT_STATUS_BOOKED) {
                    newproject.BookedProjectStartDate__c = oldProject.StartDate__c;
                    newproject.BookedProjectEndDate__c = oldProject.Enddate__c;
                    projectsForJobMaterialsBatchUpdate.add(newProject);
                    projectIds.add(newProject.Id);
                    createPreBillProjectInvoice(newProject);
                }                
            }            

            if (oldProject.ProjectBuilderId__c != newProject.ProjectBuilderId__c)
            {
                newProject.OwnerId = newProject.ProjectBuilderId__c;
            }
            
            if(oldProject.Status__c == CONSTANTS.PROJECT_STATUS_ENDED && newProject.Enddate__c > oldProject.Enddate__c 
               && newProject.Enddate__c >= Date.today()) 
            {
                ProjectActionsHelper.ChangeStatus(newProject, CONSTANTS.PROJECT_STATUS_INPROGRESS);
            }            
        }
        
        
        if (projectsForJobMaterialsBatchUpdate.size() > 0) {
            
            rtInfo rti = GetRTInfo();
            String lockedrtId = rti.lrtid;
            
            Integer psmCount = [Select COUNT() FROM ProjectServiceMaterial__c WHERE ProjectService__r.Project__c IN :projectIds];
            if(psmCount > 0){
                JobUpdateBatcher batch = new JobUpdateBatcher(projectsForJobMaterialsBatchUpdate);
                Database.ExecuteBatch(batch, JobUpdatesHelper.getJobUpdateBatchHandlerBatchSize(projectsForJobMaterialsBatchUpdate));
                for(Project__c p:projectsForJobMaterialsBatchUpdate){
                    
                    ApexJobTracker__c ajt = new   ApexJobTracker__c();
                    ajt.Object__c = 'Project';
                    ajt.Operation__c = 'Create Job Materials';
                    ajt.Project__c = p.Id;
                    ajt.Status__c = 'In Progress';
                    ajt.StartDateTime__c = DateTime.Now();
                    ajt.Id1__c = String.ValueOf(p.Id);
                    insert ajt;
                    
                    ProjectActionsHelper.LockProject(p, 'Create Job Materials','');
                    p.RecordTypeId = lockedrtId;

                }
            }
        }
        
    }
    
    public override void afterUpdate() {
        
        Set<Id> lockedProjectIds = new Set<Id>();
        Set<Id> changedProjectIds = new Set<Id>();
        
        for (Project__c newProject : (Project__c[]) Trigger.new) {  
            Project__c oldProject = (Project__c) Trigger.oldMap.get(newProject.Id);
            
            if ((oldProject.ApexJobName__c != null && newProject.ApexJobName__c == null) ||
                (oldProject.Status__c != newProject.Status__c) ||
                (oldProject.ApexJobName__c == null && newProject.ApexJobName__c != null))
            {
                changedProjectIds.add(newproject.Id);
            }
        }

        System.debug('-----' + JSON.serialize(changedProjectIds));
        
        if (changedProjectIds.size() > 0)
        {
            List<ProjectService__c> pss = [Select Id, ChangeRecordType__c from ProjectService__c WHERE Project__c IN :changedProjectIds];
            for (ProjectService__c ps : pss)            
            {
                ps.ChangeRecordType__c = true;
                
                
            }
            update pss;
        }
        
        //non bulk scenario. handle project edits on ui
        List<Project__c> newProjectList = (List<Project__c>) Trigger.new;
        if(newProjectList.size() == 1){
            Project__c newRecord = newProjectList[0];
            Project__c oldRecord = (Project__c) Trigger.oldMap.get(newRecord.Id);
            
            if (oldRecord.NumberOfDays__c != newRecord.NumberOfDays__c || 
               oldRecord.RetailerAccount__c != newRecord.RetailerAccount__c)
            {
                
                List<ProjectService__c> pss = [Select Id, ProjectNumberOfDays__c from ProjectService__c WHERE Project__c = :oldRecord.Id];
                for (ProjectService__c ps : pss)
                {
                    if (oldRecord.NumberOfDays__c != newRecord.NumberOfDays__c)
                    {
                    	ps.ProjectNumberofDays__c = String.ValueOf(newRecord.NumberOfDays__c);    
                    }
                    if (oldRecord.RetailerAccount__c != newRecord.RetailerAccount__c)
                    {
                    	ps.RetailerAccount__c = newRecord.RetailerAccount__c;    
                    }
                }
            	update pss;
            }
        }
    }
    
    public override void beforeDelete() {
        if(TriggerUtil.skipProjectDeleteTrigger == true) {
            return;
        }
        for (Project__c p: (List < Project__c > ) Trigger.old) {
            //skip trigger if the project is delete with archivd status
            if(p.ArchiveStatus__c == CONSTANTS.ARCHIVE_STATUS_ARCHIVED){
                return;
            }
            p.addError('Insufficient Privileges. Please contact support.');
        }
    }
    
    /**********************/
    /*** HELPER METHODS ***/
    /**********************/
    
    public static Integer incrementVersion(Project__c newProject, Project__c oldProject, Integer latestVersion) {
        //INCREASE VERSION ONLY IF IT IS RELEASED OR IT IS SCHEDULED FOR FIRST TIME
        if(newProject.Status__c != CONSTANTS.PROJECT_STATUS_PLANNING && newProject.Status__c != CONSTANTS.PROJECT_STATUS_PENDING)
        {   
            newProject.UpdateSequence__c = ++latestVersion;
        }
        return latestVersion;
    }
    
    public static Integer getLatestVersion() {
        
        Project__c[] latestSequenceList = [SELECT UpdateSequence__c FROM Project__c WHERE UpdateSequence__c != null ORDER BY UpdateSequence__c DESC LIMIT 1];
        return latestSequenceList.isEmpty() ? 0 : Integer.valueOf(latestSequenceList[0].UpdateSequence__c);
    }
    
    public static Boolean IsProjectChanged(Project__c newproject, Project__c oldproject, List<EntityChangeType__c> ects) {
        
        
        for (EntityChangeType__c ect : ects)
        {
            if (newproject.get(ect.Field__c) != oldproject.get(ect.Field__c) && newproject.DateLaunched__c != null)
            {
                return true;
            }
        }
        
        return false;
    }    
    
    private void createPreBillProjectInvoice(Project__c project)
    {
        String account = '';
        List<String> oppIds = new List<String>();
        List<OpportunityLineItem> olList = new List<OpportunityLineItem>();
        Map<String, List<OpportunityLineItem>> oppToOppLImap = new Map<String, List<OpportunityLineItem>>();
        List<ProjectInvoiceLineItem__c> pils = new List<ProjectInvoiceLineItem__c>();
        
        List<ProjectAccount__c> projectaccounts = [Select Id, PONumber__c, Opportunity__r.RequestedDate__c, Opportunity__r.NumberOfLocations__c, 
                                                   Opportunity__r.ResponsibleParty__c, Opportunity__c, Opportunity__r.PreBill__c,Account__r.AccountOverRide__c, 
                                                   ResponsibleParty__c, Account__c, BillToContact__c from ProjectAccount__c WHERE Project__c = :project.Id
                                                  AND Opportunity__c != null AND Opportunity__r.PreBill__c = true];

		if (projectaccounts.IsEmpty())
            return;
        

        for (ProjectAccount__c pa : projectaccounts)
        {
            if (pa.Opportunity__c != null)
            	oppIds.add(pa.Opportunity__c);
            
        }
        
        
        if (!oppIds.IsEmpty())
        {
            olList = [Select Id, Opportunity.NumberOfLocations__c, Opportunity.Id, UnitPrice, TotalPrice, Service__c, 
                      Service__r.Name, Product2.PreBillPercent__c 
                      FROM OpportunityLineItem 
                      WHERE OpportunityId IN :oppIds AND Product2.PreBillPercent__c > 0 and TotalPrice > 0];
            
            
            for (OpportunityLineItem ol : olList)
            {
                if (oppToOppLImap.get(ol.Opportunity.Id) != null)
                {
                    oppToOppLImap.get(ol.Opportunity.Id).add(ol);
                }
                else
                {
                    List<OpportunityLineItem> firstolList = new List<OpportunityLineItem>();
                    firstolList.add(ol);
                    oppToOppLImap.put(ol.Opportunity.Id, firstolList);
                }
                
            }
            
        }

        for (ProjectAccount__c pa : projectaccounts)
        {
            if (oppToOppLImap.get(pa.Opportunity__c) == null) 
                continue;

            ProjectInvoice__c pi = new ProjectInvoice__c();
            pi.Project__c = project.Id;
            pi.Status__c = Constants.PROJECT_INVOICE_STATUS_CREATED;
            pi.Type__c = Constants.PROJECT_INVOICE_TYPE_PREBILL;
            pi.LawsonProcessType__c = Constants.LAWSON_PROCESS_TYPE_PB;
            pi.Account__c = pa.Account__c;
            pi.BillToContact__c = pa.BillToContact__c;
            pi.ProjectAccount__c = pa.Id;
            pi.PONumber__c = pa.PONumber__c;
            if (project.StartDate__c != null){
                
                Date duedate = project.StartDate__c.addDays(AppUtil.ProjectInvoiceDueDateThreshold * -1);

                //OH2-924
                pi.DueDate__c = (duedate > datetime.now().date()) ? duedate : datetime.now().date(); //pa.Opportunity__r.RequestedDate__c;
            }
            
            pi.ResponsibleParty__c = pa.Opportunity__r.ResponsibleParty__c;
            insert pi;

            for (OpportunityLineItem li : oppToOppLImap.get(pa.Opportunity__c))
            {
                ProjectInvoiceLineItem__c pil = new ProjectInvoiceLineItem__c();
                pil.ProjectInvoice__c = pi.Id;
                pil.Type__c = Constants.PROJECT_INVOICE_LINEITEM_TYPE_LUMPSUM;
                pil.Amount__c = pa.Account__r.AccountOverRide__c!=null? (li.TotalPrice * pa.Account__r.AccountOverRide__c) / 100 : li.TotalPrice * li.Product2.PreBillPercent__c;
                if(pa.Account__r.AccountOverRide__c!=null)
                {
                     pil.Description__c = 'PP ' + pa.Account__r.AccountOverRide__c + '% ' + 'of ' + pa.Opportunity__r.NumberOfLocations__c + ' clubs ' + '@ $' + li.UnitPrice;
                }
                else
                {
                    pil.Description__c = 'PP ' + li.Product2.PreBillPercent__c * 100 + '% ' + 'of ' + pa.Opportunity__r.NumberOfLocations__c + ' clubs ' + '@ $' + li.UnitPrice;
                }
                
                pils.add(pil);
                
            }
        } 
        insert pils;
        
        
    }
    
    private class rtInfo {
        
        private string rtpattern {get; set;}
        private string lrtname {get; set;}
        private string lrtid {get; set;}
        private string drtname {get; set;}
        private string drtid {get; set;}
        private Map<String, String> rtmap {get; set;}
    }
    
    private rtInfo GetRTInfo() {
        
        rtInfo ret = new rtInfo();
        
        
        string projectrtPattern = 'Status__c,ProjectTypeName__c'; //Default
        
        List<UIConfiguration__c> usettings = [SELECT ProjectLockedRecordType__c, ProjectRecordtypePattern__c, 
                                              ProjectServiceRecordtypePattern__c, DefaultProjectRecordType__c
                                              FROM UIConfiguration__c LIMIT 1];
        
        if(usettings == null || usettings.size() == 0 || usettings[0] == null || usettings[0].ProjectRecordtypePattern__c == null){
            projectrtPattern = 'Status__c,ProjectTypeName__c';
        }
        else
        {
            projectrtPattern = usettings[0].ProjectRecordtypePattern__c;
        }
        Map<String, String> rtmap = AppUtil.GetRecordTypeIds(CONSTANTS.CURRENTNAMESPACEPREFIX + 'Project__c');
        
        string lockedRTName;
        if(usettings == null || usettings.size() == 0 || usettings[0] == null || 
           usettings[0].ProjectLockedRecordType__c == null){
               lockedRTName = 'Locked';
           }
        else
        {
            lockedRTName = usettings[0].ProjectLockedRecordType__c;
            
        }
        String lockedrtId = rtmap.get(lockedRTName);
        
        
        string defaultRTName;
        if(usettings == null || usettings.size() == 0 || usettings[0] == null || usettings[0].DefaultProjectRecordType__c == null){
            defaultRTName = 'Draft';
        }
        else
        {
            defaultRTName = usettings[0].DefaultProjectRecordType__c;
            
        }
        String defaultRTId = rtmap.get(defaultRTName);
        
        ret.rtpattern = projectrtPattern;
        ret.lrtname = lockedRTName;
        ret.lrtid = lockedrtId;
        ret.drtname = defaultRTName;
        ret.drtid = defaultRTId;
        ret.rtmap = rtmap;
        return ret;
    }
    
    
    
    
    
}