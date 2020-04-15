public without sharing class BaseSchedulingStrategy extends SchedulingStrategy {
    
    Project__c project;
    List<ProjectService__c> psList;
    List<Account> ecList;
    List<ProjectLocation__c> scheduledLocations, failedLocations, skippedLocations;
    //Integer maxReserveLimit = 10000;
    Set<String> locationAssignments;
    
    public override Integer scheduleLocations(List<ProjectLocation__c> batch, String projectID, String operation) {
        ecList = [select Id from Account where type = 'Execution Company' LIMIT 2];
        initData(batch, projectID);
        for (ProjectLocation__c projLoc: (List<ProjectLocation__c> ) batch) {
            if(!validateLocation(projLoc)) {
                continue;   
            }
            scheduleLocation(projLoc);
        }
        
        TriggerUtil.SkipProjectLocationTrigger = true;
        if(operation != 'update jobs'){
            update scheduledLocations;
            update failedLocations;
        }
        createJobs(project, psList, scheduledLocations, operation, ecList);
        
        return scheduledLocations.size();
        
    }
    
    public override Integer scheduleLocations(List<ProjectLocation__c> batch, String projectID) {
        return scheduleLocations(batch, projectID, '');
    }
    
    private void initData(List<ProjectLocation__c> batch, String projectID){
        Set<Id> batchProjectLocationIds = (new Map<Id, ProjectLocation__c>(batch)).keySet();
        Set<Id> batchLocationIds = (new Map<Id, Location__c> ([SELECT Id FROM Location__c WHERE Id IN (SELECT Location__c FROM ProjectLocation__c WHERE id IN :batchProjectLocationIds)])).keySet();
        project = [SELECT Name, StartDate__c, EndDate__c, ProjectType__c, Retailer__c,   Status__c,  BudgetedLocationsCount__c, 
                   Retailer__r.Name, Retailer__r.User__c,  BookBudgetedOnly__c, LocationTotalCount__c,UpdateJobsFlag__c, OwnerId, 
                   ProjectScheduleOption__r.Name FROM Project__c WHERE ID = : projectID];
        psList = [SELECT Id, Name, Project__c, Project__r.ProjectScheduleOptionCode__c, Service__r.Name,Service__r.Specialization__c, 
                  Service__c, ResponsibleForExecution__c, NumberOfDays__c, NumberOfWorkers__c, StartTime__c, EndTime__c,
                  StartDayNumber__c, DayNumbers__c FROM ProjectService__c WHERE project__c  = :projectID AND Status__c != :CONSTANTS.PROJECT_SERVICE_STATUS_CANCELED];
        locationAssignments = getLocationAssignments(project, batchLocationIds);
        scheduledLocations = new List<ProjectLocation__c>();
        failedLocations = new List<ProjectLocation__c>();
    }
    
    public static void createJobs(Project__c project, List<ProjectService__c> psList, List<ProjectLocation__c> scheduledLocations, String operation, List<Account> ecList) {
        TriggerUtil.skipJobTrigger = true;
        Map<ID, String> locCSMs = new Map<ID, String>();
        Map<ID, String> locExecutionCompanies = new Map<ID, String>();
        Id[] setScheduleDateIds = new Id[] {};
        
        String locExecutionCompany = null;

        //This flag is checked for existing projects for which project lcoations
        //have already been created but will not have execution company.
        //For these locations we will still use the existing method of
        //getting the exec company.
        
        /*
        Boolean ecExistsinPL = false;
        if (scheduledLocations[0].ExecutionCompany__c != null)
            ecExistsinPL = true;
        
		if (!ecExistsinPL)        
        {
            if(ecList.size() == 1){
                locExecutionCompany = ecList[0].Id;
                system.debug('locExecutionCompany: ' + locExecutionCompany);
            }
            else{
                for (LocationAssignment__c assignment : [SELECT Location__c, AccountableExecutionCompany__c FROM LocationAssignment__c WHERE ProjectType__c =: project.ProjectType__c AND AccountableExecutionCompany__c != NULL AND Location__c IN (SELECT Location__C FROM ProjectLocation__c WHERE Project__c =: project.Id)]) {
                    system.debug('NOT in locExecutionCompany: ');
                    if(!locExecutionCompanies.containsKey(assignment.Location__c)){
                        locExecutionCompanies.put(assignment.Location__c, assignment.AccountableExecutionCompany__c);
                    }
                }
            }
        }
	*/
        
        
        Boolean ecExistsinPL = false;
        //if (scheduledLocations[0].ExecutionCompany__c != null)
        //    ecExistsinPL = true;
            
        system.debug('scheduledLocations:::' + scheduledLocations);
        
        boolean isDefaultExecutionCompanyNeeded = false;
        for (ProjectLocation__c projLoc: scheduledLocations) {            
            system.debug('projLoc:::' + projLoc);
            system.debug('projLoc.ExecutionCompany__c:::' + projLoc.ExecutionCompany__c);
            if (projLoc.ExecutionCompany__c == null){
                isDefaultExecutionCompanyNeeded = true;          
                break;
            }
        }
        
        if (isDefaultExecutionCompanyNeeded){
            
            if(ecList.size() == 1 ){
                locExecutionCompany = ecList[0].Id;
            }
            else{
                for (LocationAssignment__c assignment : [SELECT Location__c, AccountableExecutionCompany__c FROM LocationAssignment__c 
                                                         WHERE ProjectType__c =: project.ProjectType__c 
                                                         AND AccountableExecutionCompany__c != NULL 
                                                         AND Location__c IN (SELECT Location__C FROM ProjectLocation__c WHERE Project__c =: project.Id)]) {
                                                             system.debug('NOT in locExecutionCompany: ');
                                                             if(!locExecutionCompanies.containsKey(assignment.Location__c)){
                                                                 locExecutionCompanies.put(assignment.Location__c, assignment.AccountableExecutionCompany__c);
                                                             }
                                                         }                
            }
        
          // system.debug('locExecutionCompanies:::' + locExecutionCompanies.size());
        }     
        
            
        Set<Id> plIds = new Set<Id>();
        for (ProjectLocation__c pl: scheduledLocations) {
            plIds.add(pl.Id);
        }
        system.debug('plIds::::::'+plIds);
        List<Job__c> existingJobs = [SELECT Id, ProjectLocation__c, ProjectService__c, ProjectScheduleOptionName__c, ProjectScheduleOptionCode__c, ProjectLocation__r.LocationScheduledDate__c,
                                     JobStartDate__c, JobEndDate__c, JobScheduledDate__c, NumberOfDays__c, NumberOfWorkers__c, JobStartTime__c, JobEndTime__c,
                                     AccountableExecutionCompany__c, ResponsibleExecutionCompany__c, ResponsibleForExecution__c, 
                                     LocationTimezoneOffset__c, JobUTCStartTime__c, JobUTCEndTime__c, DayNumber__c  
                                     FROM Job__c WHERE ProjectLocation__c IN :plIds];
        Map<String,Job__c> existingJobsMap = new Map<String,Job__c>();
        
        for(Job__c job:existingJobs){
            if (job.DayNumber__c != null)
            {
                existingJobsMap.put(job.ProjectLocation__c + '-' + job.ProjectService__c + '-' + job.DayNumber__c, job);    
            }
            else
            {
                existingJobsMap.put(job.ProjectLocation__c + '-' + job.ProjectService__c, job);    
            }
            
        }

        List<Job__c> jobsToInsert = new List <Job__c>();
        for (ProjectLocation__c projLoc: scheduledLocations) {
            String locCSM = locCSMs.get(projLoc.Location__c);
            if(locExecutionCompanies.size() > 0){
                locExecutionCompany = locExecutionCompanies.get(projLoc.Location__c);
            }
            for (ProjectService__c ps: psList) {
                
                
                String[] daynumberArray = String.isBlank(ps.DayNumbers__c)?new String[]{'-1'}: ps.DayNumbers__c.split(';');
                
                for (string daynumber : daynumberArray)
                {
                    string jobkey = daynumber == '-1'? projLoc.Id + '-' + ps.Id : projLoc.Id + '-' + ps.Id + '-' + daynumber;
                    if(!existingJobsMap.containsKey(jobkey))
                    {
                        if(operation == 'update jobs'){
                            continue;
                        }
                        Job__c job = new Job__c();
                        job.ProjectLocation__c = projLoc.ID;
                        job.Location__c = projLoc.Location__c;
                        job.ProjectService__c = ps.ID;
                        job.Service__c = ps.Service__c;
                        job.ServiceName__c = ps.Service__r.Name;
                        job.Project__c = projLoc.Project__c;
                        job.JobStartDate__c = project.StartDate__c;
                        job.JobEndDate__c = project.EndDate__c; 
                        job.ProjectScheduleOptionName__c = project.ProjectScheduleOption__r.Name;
                        job.LocationTimezoneOffset__c = projLoc.Location__r.PostalCode__r.TimezoneOffset__c;  
                        
                        job.AccountableExecutionCompany__c = (projLoc.ExecutionCompany__c == null ? locExecutionCompany : projLoc.ExecutionCompany__c );
                       	job.ResponsibleExecutionCompany__c = (projLoc.ExecutionCompany__c == null ? locExecutionCompany : projLoc.ExecutionCompany__c);
                        
                        /*
                        if (ecExistsinPL)
                        {
                            job.AccountableExecutionCompany__c = projLoc.ExecutionCompany__c;
                            job.ResponsibleExecutionCompany__c = projLoc.ExecutionCompany__c;
                        }
                        else
                        {
                            job.AccountableExecutionCompany__c = locExecutionCompany;
                            job.ResponsibleExecutionCompany__c = locExecutionCompany;
                        }
						*/
                        if(CONSTANTS.SCHEDULE_OPTION_EC.equalsIgnoreCase(job.ProjectScheduleOptionCode__c)){
                            job.IsAttemptable__c = true;
                            job.CreateAttemptException__c = CONSTANTS.JOB_ATTEMPT_COMMENT_SUCCESS; 
                        }
                        else if(CONSTANTS.SCHEDULE_OPTION_USER.equalsIgnoreCase(job.ProjectScheduleOptionCode__c)){
                            if(job.JobScheduledDate__c!=null){
                                job.IsAttemptable__c = true;
                                job.CreateAttemptException__c = CONSTANTS.JOB_ATTEMPT_COMMENT_SUCCESS; 
                            }else{
                                job.IsAttemptable__c = false;
                                job.CreateAttemptException__c = CONSTANTS.JOB_ATTEMPT_COMMENT_SCHEDULEDATE;                
                            }
                        }
                        
                        job.ResponsibleForExecution__c = ps.ResponsibleForExecution__c;
                        job.JobStatus__c = CONSTANTS.JOB_STATUS_PENDING;
                        job.NumberOfDays__c = 1;
                        job.NumberOfWorkers__c = (ps.NumberOfWorkers__c==null ? 1 : ps.NumberOfWorkers__c);
                        job.DayNumber__c = (daynumber == '-1' ? null : Integer.valueOf(daynumber));
                        job.AllowTeamManagement__c = projLoc.AllowTeamManagement__c;
                        job.OwnerId = project.OwnerId;
                        job.JobStartTime__c = projLoc.StartTime__c;
                        job.JobEndTime__c = projLoc.EndTime__c;
                        
                        if(projLoc.StartTime__c!=null){
                            job.JobUTCStartTime__c = CalculateUTCtime(project.StartDate__c,String.valueof(projLoc.StartTime__c) , integer.valueof(projloc.Location__r.PostalCode__r.TimezoneOffset__c));                 
                        }
                        if(projLoc.EndTime__c!=null){
                            job.JobUTCEndTime__c = CalculateUTCtime(project.EndDate__c,String.valueof(projLoc.EndTime__c), integer.valueof(projloc.Location__r.PostalCode__r.TimezoneOffset__c));    
                        }
                        
                        Integer startDayNumber;
                        Integer numberOfDays;
                        
                        if(ps.Project__r.ProjectScheduleOptionCode__c == CONSTANTS.SCHEDULE_OPTION_USER && 
                           projLoc.LocationScheduledDate__c != NULL) 
                        {
                            if (daynumber == '-1')
                            {
                                startDayNumber = Integer.valueOf((ps.StartDayNumber__c == null || ps.StartDayNumber__c == 0) ? 1 : ps.StartDayNumber__c);
                                numberOfDays = Integer.valueOf((ps.NumberOfDays__c == null || ps.NumberOfDays__c == 0) ? 1 : ps.NumberOfDays__c);
                            }
                            else
                            {
                                startDayNumber = Integer.valueOf(daynumber);
                                numberOfDays = 1;
                            }
                            
                            job.JobStartDate__c = projLoc.LocationScheduledDate__c.addDays(startDayNumber - 1);
                            job.JobEndDate__c = job.JobStartDate__c.addDays(numberOfDays - 1);
                            job.JobScheduledDate__c = job.JobStartDate__c;
                            if(job.ActiveJobAttempt__c == null && 
                               (job.ProjectStatus__c == CONSTANTS.PROJECT_STATUS_LAUNCHED || 
                                job.ProjectStatus__c == CONSTANTS.PROJECT_STATUS_INPROGRESS))
                            {
                                job.CreateAttempt__c = true;
                                job.IsAttemptable__c = true;
                            }
                        }
                        jobsToInsert.add(job);
                    }                    
                }
            }
        }

        if(operation != 'update jobs'){
            insert jobsToInsert;
            Id[] jobsToInsertIds = new List<Id>(new Map<Id, Job__c>(jobsToInsert).keySet());
            if(project.Status__c == CONSTANTS.PROJECT_STATUS_LAUNCHED || project.Status__c == CONSTANTS.PROJECT_STATUS_INPROGRESS){
                JobActionsHelper.CreateAttempts(jobsToInsertIds, null, ''); 
            }
            
            //Insert materials for new jobs if the project status
            //is booked or later
            if(project.Status__c != CONSTANTS.PROJECT_STATUS_PLANNING){
                for(ProjectService__c ps:psList){
                    List<ProjectServiceMaterial__c> psmList = [SELECT Id, Material__c,ProjectService__c FROM ProjectServiceMaterial__c WHERE ProjectService__r.Status__c != :CONSTANTS.PROJECT_SERVICE_CANCELED AND ProjectService__c =: ps.Id];
                    if(psmList.size()>0){
                        JobUpdatesHelper.createJobMaterials(jobsToInsert, psmList);
                    }
                }
            }
        }
        system.debug('jobsToInsert.size():::::::::::::'+ jobsToInsert.size());
    }
    
    private Boolean validateLocation(ProjectLocation__c projLoc){
        if(ecList.size() > 1 && !validateLocationAssignments(projLoc)){
            setFailedLoaction(projLoc, 'Jobs not created', 'Missing location assignment');
            return false;
        }
        return true;
    }
    
    public Boolean validateLocationAssignments(ProjectLocation__c projLoc) {
        system.debug('locationAssignments: '+locationAssignments);
        if(locationAssignments != null && !locationAssignments.contains(projLoc.Location__c)){
            return false;
        }
        return true;
    }
    
    private void scheduleLocation(ProjectLocation__c projLoc){
        
        if(!projLoc.Location__r.IsActive__c) {
            setFailedLoaction(projLoc, 'Jobs not created', 'Inactive Location');
            return;
        }
        reserveLocation(projLoc);
    }
        
    private void reserveLocation(ProjectLocation__c projLoc){
        projLoc.Status__c = '';
        projLoc.StatusComments__c = '';
        scheduledLocations.add(projLoc);
    }
    
    private void setFailedLoaction(ProjectLocation__c projLoc, String status, String statusReason){
        projLoc.Status__c = 'Failed';
        projLoc.StatusComments__c = statusReason;
        failedLocations.add(projLoc);
    }
    
    //obsolete
    public override String getSchedulableLocationsQuery(Project__c project) {
        return '';
    }
    
    public override String getSchedulableLocationsQuery(Project__c project,  String operation) {
        String locSOQL = 'SELECT Id, Name, AllowTeamManagement__c, Project__c, StartTime__c, EndTime__c, Location__c, Location__r.Name, Location__r.Retailer__r.Name, Location__r.State__c, Location__r.LocationNumber__c, Location__r.IsActive__c, Status__c, Project__r.Status__c, Location__r.PostalCode__r.TimezoneOffset__c, LocationScheduledDate__c, ExecutionCompany__c FROM ProjectLocation__c WHERE Project__c = \''+ project.id + '\' AND Status__c != \'Canceled\' ';

        return locSOQL;
    }
    
    public override Boolean deallocateLocations(List<ProjectLocation__c> projLocs) {
        for (ProjectLocation__c projLoc: projLocs) {
           
            projLoc.Status__c = null;

        }
        TriggerUtil.SkipProjectLocationTrigger = true;
        update projLocs;
        
        TriggerUtil.SkipJobDeleteTrigger = true;
        Set < Id > projLocIds = (new Map < Id, ProjectLocation__c > (projLocs)).keySet();
        List <Job__c> jobs = [SELECT Id FROM Job__c WHERE ProjectLocation__c IN :projLocIds];
        delete jobs;
        
        return true;
    }
    
    public override Boolean isBatchJob(Project__c p, String exceedBudgeted){
        return true;
        
    }
    
    public static  datetime CalculateUTCtime(Date dtime,String strTime,Integer offsetHr)
    {
        //calculate UTC time
        if(offsetHr == null){
            offsetHr = -6;
        }
        list<string> splitStr = strTime.split(':');
        system.debug('~~~~'+   splitStr[0]);
        system.debug('~~~~'+   splitStr[1].substring(0,2)  );
        system.debug('~~~~'+   splitStr[1].substring(2,4)  );
        
        integer hour = integer.valueof(splitStr[0]);
        integer min = integer.valueof(splitStr[1].substring(0,2));
        if(splitStr[1].substring(2,4).tolowercase()=='pm')
            hour = hour+12;
         else{
            if(hour==12)
                hour=0;
        }
        hour = hour + integer.valueof(offsetHr*-1);
        return datetime.newInstanceGMT(dtime.year(), dtime.month(),dtime.day(),hour,min,0);
        
    }
}