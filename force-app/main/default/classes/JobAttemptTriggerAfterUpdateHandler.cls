public with sharing class JobAttemptTriggerAfterUpdateHandler implements ISobjectTriggerEventHandler {
    //----<static methods and properties>----
    static ILogger DB_LOGGER, DEBUG_LOGGER;
    static Set<String> entryTypeSet;
    static {
        DB_LOGGER = LoggerFactory.createLogger('JobAttemptTrigger', true);
        DEBUG_LOGGER = LoggerFactory.createLogger('JobAttemptTrigger', false);
        
        entryTypeSet = new Set<String>{
            CONSTANTS.JOB_ATTEMPT_WORKER_TIME_ENTRY_TIME_ENTRY_TYPE_CHECK_IN, 
                CONSTANTS.JOB_ATTEMPT_WORKER_TIME_ENTRY_TIME_ENTRY_TYPE_CHECK_OUT
                };          
                    }
    
    //----<instance properties, constructor and factory method>----
    Map<ID, JobAttempt__c> newMap, oldMap;
    Exception exceptionError;
    Savepoint databaseSavePoint;
    JobBulkHandler jobBulkHandler;
    
    private JobAttemptTriggerAfterUpdateHandler(Map<ID, JobAttempt__c> newMap, Map<ID, JobAttempt__c> oldMap) {
        this.databaseSavePoint = Database.setSavepoint();
        this.newMap = newMap;
        this.oldMap = oldMap;
        this.jobBulkHandler = new JobBulkHandler();
        this.exceptionError = null;
    }
    
    public static ISobjectTriggerEventHandler newInstance(Map<ID, JobAttempt__c> newMap, Map<ID, JobAttempt__c> oldMap) {
        return new JobAttemptTriggerAfterUpdateHandler(newMap,oldMap);
    }
    
    public void execute() {
        DEBUG_LOGGER.debug('start of JobAttemptTriggerAfterUpdateHandler');
        runBusinessLogics();
        updateJobStartedOntime();
        DEBUG_LOGGER.debug('end of JobAttemptTriggerAfterUpdateHandler');
        DEBUG_LOGGER.save();
        if (null != this.exceptionError) {
            throw new JobAttemptTriggerAfterUpdateException(this.exceptionError.getMessage());
        }
    }
    
    void updateJobStartedOntime()
    {
        
        List<JobAttempt__c> lstjobAttempt = [select Id,name,IsstartedOntime__c,IsActive__c,ProjectLocation__c,ScheduledDateTime__c, DateStarted__c from JobAttempt__c where Id IN :newMap.keySet() AND IsActive__c =true];
        Map<Id,Integer> maplocation = new Map<Id,Integer>();
        if(lstjobAttempt.size()>0)
        {
            for (JobAttempt__c ja: lstjobAttempt)
            {
                
                JobAttempt__c oldAttempt = oldMap.get(ja.Id);
                JobAttempt__c newAttempt = newMap.get(ja.Id);
                
                if(oldAttempt.IsstartedOntime__c != newAttempt.IsstartedOntime__c)
                {
                    
                    if( maplocation.containsKey(ja.ProjectLocation__c) )
                    {
                        integer existingvalue = maplocation.get(ja.ProjectLocation__c);
                        existingvalue= existingvalue + 1;
                        maplocation.put(ja.ProjectLocation__c,existingvalue);
                        
                    }
                    else
                    {
                        maplocation.put(ja.ProjectLocation__c,1);
                        
                    }
                }
                
            }
            list<ProjectLocation__c> lstProjectLocations = [select Id,NoofActiveJobsStartedOntime__c from ProjectLocation__c where Id in :maplocation.keySet() FOR UPDATE];
            if(lstProjectLocations.size()>0)
            {
                for(ProjectLocation__c pl:lstProjectLocations)
                {
                    if(pl.NoofActiveJobsStartedOntime__c == NULL)
                    {
                        pl.NoofActiveJobsStartedOntime__c = 0;                   
                    }
                    if(maplocation.containsKey(pl.Id))
                    {
                        Integer recentCount = maplocation.get(pl.Id);
                        pl.NoofActiveJobsStartedOntime__c =  pl.NoofActiveJobsStartedOntime__c + recentCount;
                    }
                    
                }
                update lstProjectLocations;
            }
        }
        
    }
    
    //----<scenario business logics>----
    public class JobAttemptTriggerAfterUpdateException extends Exception { }
    void runBusinessLogics() {
        String status;
        JobAttempt__c old;
        List<JobAttempt__c> scheduledDateAttempts = new List<JobAttempt__c>();
        List<JobAttempt__c> openAttempts = new List<JobAttempt__c>();
        List<JobAttempt__c> startAttempts = new List<JobAttempt__c>();
        List<JobAttempt__c> assignAttempts = new List<JobAttempt__c>();
        List<JobAttempt__c> reportAttempts = new List<JobAttempt__c>();
        
        Map<String, Job__c> jobMap;
        
        set<String> jobIds = new set<String>();
        
        for (JobAttempt__c jobAttempt: newMap.values()) {
            jobIds.add(jobAttempt.Job__c);
        }
        
        jobMap = JobAttemptHelper.getJobs(jobIds);
        
        try {
            for(JobAttempt__c current: newMap.values()) {
                old = oldMap.get(current.Id);
                if (false == old.IsActive__c ) { continue; }
                
                handleFirstAttemptLogic(current);
                
                if (isScheduleChanged(current, old)) {
                    scheduledDateAttempts.add(current);
                }
                
                status = current.AttemptStatus__c;
                
                Job__c job = jobMap.get(current.Job__c);
                
                //if (job.IsShift__c == true)
                //{
                    handleJobNumberOfWorkers(current,old);
                ///}   
                
                if (CONSTANTS.JOB_ATTEMPT_STATUS_OPEN.equalsIgnoreCase(status)) {
                    openAttempts.add(current);
                    Continue;
                }
                
                if (CONSTANTS.JOB_ATTEMPT_STATUS_STARTED.equalsIgnoreCase(status)) {
                    startAttempts.add(current);
                    Continue;
                }
                
                if (CONSTANTS.JOB_ATTEMPT_STATUS_ASSIGNED.equalsIgnoreCase(status)) {
                    assignAttempts.add(current);
                    continue;
                }
                
                if (CONSTANTS.JOB_ATTEMPT_STATUS_REPORTED.equalsIgnoreCase(status)) {
                    reportAttempts.add(current);
                    continue;
                }
            }
            handleScheduledDateLogic(scheduledDateAttempts);
            
            openJobAttempt(openAttempts);
            startJobAttempt(startAttempts);
            assignJobAttempt(assignAttempts);
            reportJobAttempt(reportAttempts);
            jobBulkHandler.doUpdate();
        }
        catch(Exception ex) {
            this.exceptionError = ex;
            Database.rollback(databaseSavePoint);
            DB_LOGGER.error('afterUpdate:' + ex.getLineNumber() + ';' + ex.getMessage());
        }
        try {
            DB_LOGGER.save();
        }
        catch(Exception ex) {
            DEBUG_LOGGER.error(ex.getLineNumber() + ':' + ex.getMessage());
        }
    }
    
    static Boolean isScheduleChanged(JobAttempt__c current, JobAttempt__c old) {
        return (current.AttemptScheduleDate__c != old.AttemptScheduleDate__c) ? true : false;
    }
    
    void handleJobNumberOfWorkers(JobAttempt__c current, JobAttempt__c old){
        if (old.ExpectedNumberofWorkers__c != current.ExpectedNumberofWorkers__c){          
            
            JobAttemptWorkerHelper.AdjustJobAttemptWorker(current,
                                                          integer.valueof(old.ExpectedNumberofWorkers__c),
                                                          integer.valueof(current.ExpectedNumberofWorkers__c));            
        }
    }
    
    
    
    //----<Handle 1st job attempt date logic>----
    //we always update the job first attempt date, the job trigger will handle if it is first or not.
    void handleFirstAttemptLogic(JobAttempt__c current) {
        if (null == current.AttemptedDate__c) { return; }
        Job__c job = jobBulkHandler.getJobInstance(current.Job__c);
        job.JobFirstAttemptDate__c = current.AttemptedDate__c;
        jobBulkHandler.add(job);
    }
    
    //----< scenario: handle scheduled date >----
    //OH220 handle schedule date logic
    //As a Product Owner, I want to define the rules for 
    //how the Job Schedule Date is set for a Job so that I have consistent functionality>
    void handleScheduledDateLogic(List<JobAttempt__c> attempts) {
        if (0 == attempts.size() ) { return; }
        
        Job__c job;
        for(JobAttempt__c current: attempts) {
            if (null != current.Job__c){
                job = jobBulkHandler.getJobInstance(current.Job__c);
                job.JobScheduledDate__c = current.AttemptScheduleDate__c;
                jobBulkHandler.add(job);
            }
        }
    }
    
    //----< scenario: open A job attempt >----
    //OH217: Remove Assignment on Job Attempt
    void openJobAttempt(List<JobAttempt__c> attempts) {
        if (attempts.size() == 0) { return; }
        
        Job__c job;
        for(JobAttempt__c current: attempts) {
            if (null != current.Job__c ) {
                job = jobBulkHandler.getJobInstance(current.Job__c);
                job.JobStatus__c = CONSTANTS.JOB_STATUS_OPEN;
                job.JobDateAssigned__c = null;
                handleOpenJobReattempt(current, job);
                jobBulkHandler.add(job);
            }
        }
    }
    
    //OH533:Date started and Date assigned are not removed for Job when Job is reattempted
    static void handleOpenJobReattempt(JobAttempt__c current, Job__c job) {
        if (CONSTANTS.JOB_ATTEMPT_TYPE_REATTEMPT.equalsIgnoreCase(current.AttemptType__c)) {
            job.JobDateStarted__c = null;
        }
    }
    
    //----< scenario: start A job attempt >----
    //OH218 ;As a Product Owner, I want the Attempt Status set to STARTED when an Execution Company indicates 
    //that they have started working a Job so that I know that my Job has started as expected.
    void startJobAttempt(List<JobAttempt__c> attempts) {
        if (attempts.size() == 0 ) { return; }
        
        Job__c job;
        List<Job__c> jobs = new List<Job__c>();
        for(JobAttempt__c current: attempts) {
            if(null != current.Job__c) {
                job = jobBulkHandler.getJobInstance(current.Job__c);
                job.JobStatus__c = CONSTANTS.JOB_STATUS_STARTED;
                job.JobDateStarted__c = current.DateStarted__c;
                jobBulkHandler.add(job);
            }
        }
    }
    
    //----< scenario: assign A job attempt >----
    //OH215: As a Product Owner, I want to set the status of an active attempt to ASSIGNED so 
    //that I know that a Job is currently staffed.
    void assignJobAttempt(List<JobAttempt__c> attempts) {
        if ( 0 == attempts.size() ) { return; }
        
        List<Job__c> jobs = new List<Job__c>();
        JobAttempt__c old;
        Job__c job;
        
        for(JobAttempt__c current: attempts) {
            old = oldMap.get(current.Id);
            if (null != current.Job__c) {
                job = jobBulkHandler.getJobInstance(current.Job__c);
                job.JobStatus__c = CONSTANTS.JOB_STATUS_ASSIGNED;
                job.JobDateAssigned__c = current.DateAssigned__c;
                jobBulkHandler.add(job);
            }
        }
    }
    
    //----< scenario: report A job attempt> >----
    //OH216: As a Product Owner, I want to the Job Attempt status set to REPORTED 
    //when an Execution Company reports an attempt so that I know that other actions should occure.
    void reportJobAttempt(List<JobAttempt__c> attempts) {
        
        system.debug('reportJobAttempt');
        if ( 0 == attempts.size() ) { return; }
        
        List<Job__c> jobs = new List<Job__c>();
        
        Set<ID> jobAttemptIds = new set<ID>(); 
        
        Map<ID, Job__c> jobMap;
        jobMap = getJobs(attempts);
        
        for (JobAttempt__c jobAttempt: attempts) {
            Job__c job = jobMap.get(jobAttempt.Job__c);
            
            system.debug('job:::' + job);
            
            if (job.IsShift__c){            	
                jobAttemptIds.add(jobAttempt.ID);
            }
        }
        
        MAP<ID,List<JobAttemptWorkerTimeEntryWrapper>> jobAttemptTimeEntryMap;
        Set<String> contactIds;
        MAP<ID,Contact> contactMap;
        
        //Get values only for one hub mobile jobs
        if (jobAttemptIds.size() > 0)
        {
            
            //OH-4636
            // Gets job attempt workerTimeEntry for the current job attempts             
            jobAttemptTimeEntryMap = JobAttemptHelper.GetTimeEntryMap(jobAttemptIds,entryTypeSet); 
            
            contactIds = JobAttemptHelper.GetContactIdsForJobAttempts(jobAttemptIds,entryTypeSet);
            
            if (contactIds.size() > 0){
                contactMap = JobAttemptHelper.GetContactMap(contactIds);    
            }        
        }
        
        List<Contact> contactsToUpdate = new List<Contact>();
        
        for(JobAttempt__c current : attempts) {
            if (null != current.Job__c) { 
                Job__c job = jobBulkHandler.getJobInstance(current.Job__c);
                job.JobStatus__c = CONSTANTS.JOB_STATUS_REPORTED;
                job.JobDateAssigned__c = current.DateAssigned__c;
                Job.JobDateStarted__c = current.DateStarted__c;
                job.IsExecuted__c = current.IsExecuted__c;
                if (true == job.IsExecuted__c && null != current.AttemptedDate__c) {
                    job.JobExecutedDate__c = current.AttemptedDate__c;
                }
                
                //OH-1415:Job Reported without Exception is showing Completion Status as Not Completed
                if (null == current.Exception__c) {
                    job.CompletionStatus__c = CONSTANTS.JOB_COMPLETION_STATUS_COMPLETED;
                    job.JobCompletedDate__c = job.JobExecutedDate__c;
                }
                jobBulkHandler.add(job);
                
                job = jobMap.get(current.Job__c);
                if (job.IsShift__c){
                    if (!boolean.valueOf(job.ShiftClosureOverride__c)){      
                        
                        //OH-4636: Do not overpay for hours in overlapping Shifts
                        //Set Max check in / checkout to validate overlapping
                        if (jobAttemptTimeEntryMap.get(current.Id) != null)
                        {
                            List<Contact> contacts= setMaxCheckInCheckOutForContact(current, jobAttemptTimeEntryMap.get(current.Id), contactMap);
                            contactsToUpdate.addAll(contacts);
                        }
                    }
                }
            }
        }
        
        if (contactsToUpdate.size() > 0)
        {   
            //To update contacts with max check in \ check out
            update contactsToUpdate;
        }
    }
    
    List<Contact> setMaxCheckInCheckOutForContact(JobAttempt__c current, 
                                                  List<JobAttemptWorkerTimeEntryWrapper> jobAttemptWorkerTimeEntries, 
                                                  Map<ID,Contact> contacts)
    { 
        system.debug('setMaxCheckInCheckOutForContact::');
        List<Contact> contactsToUpdate = new List<Contact>();
        
        JobAttempt__c old = oldMap.get(current.Id);
        
        if (current.AttemptStatus__c == CONSTANTS.JOB_ATTEMPT_STATUS_REPORTED && current.AttemptStatus__c != old.AttemptStatus__c){
            
            MAP<ID,List<JobAttemptWorkerTimeEntryWrapper>> contactMap = new MAP<ID,List<JobAttemptWorkerTimeEntryWrapper>>();
            
            
            if (null != jobAttemptWorkerTimeEntries)
            {
                for (JobAttemptWorkerTimeEntryWrapper jobAttemptWorkerTimeEntry : jobAttemptWorkerTimeEntries){            
                    
                    
                    if (jobAttemptWorkerTimeEntry.ContactId != null)
                    {
                        if (contactMap.containskey(jobAttemptWorkerTimeEntry.ContactId)){
                            
                            List<JobAttemptWorkerTimeEntryWrapper> jobAttemptWorkerTimeEntrys =  contactMap.get(jobAttemptWorkerTimeEntry.ContactId);
                            if (jobAttemptWorkerTimeEntrys != null)
                            {
                                jobAttemptWorkerTimeEntrys.add(jobAttemptWorkerTimeEntry);
                                contactMap.put(jobAttemptWorkerTimeEntry.ContactId,jobAttemptWorkerTimeEntrys);
                            }
                        }
                        else
                        {
                            List<JobAttemptWorkerTimeEntryWrapper> jobAttemptWorkerTimeEntrys = new List<JobAttemptWorkerTimeEntryWrapper>();
                            jobAttemptWorkerTimeEntrys.add(jobAttemptWorkerTimeEntry);
                            contactMap.put(jobAttemptWorkerTimeEntry.ContactId,jobAttemptWorkerTimeEntrys);                        
                        }
                    }
                }
            }
            
            Set<String> contactIdSet = new Set<String>();
            
            // To get contact id's
            for (ID key : contactMap.keySet()) {                  
                contactsToUpdate.add(contacts.get(key));
            }                        
            
            //update the contacts max check in and check out time
            for(Contact contact: contactsToUpdate) {     
                
                if (contact != null)                
                {
                    for (JobAttemptWorkerTimeEntryWrapper jobAttemptWorkerTimeEntry : contactMap.get(contact.ID))
                    {
                        if (jobAttemptWorkerTimeEntry.TimeEntryType == CONSTANTS.JOB_ATTEMPT_WORKER_TIME_ENTRY_TIME_ENTRY_TYPE_CHECK_IN)
                        {
                            contact.MaxCheckInTime__c = jobAttemptWorkerTimeEntry.StartTime ;
                        }
                        
                        if (jobAttemptWorkerTimeEntry.TimeEntryType == CONSTANTS.JOB_ATTEMPT_WORKER_TIME_ENTRY_TIME_ENTRY_TYPE_CHECK_OUT)
                        {
                            contact.MaxCheckOutTime__c = jobAttemptWorkerTimeEntry.StartTime ;
                        }
                    }
                }
            }    
        }        
        
        return contactsToUpdate;
    }
    
    static Map<ID, Job__c> getJobs(List<JobAttempt__c> attempts) {
        Set<ID> idSet = SObjectListHelper.getIdSet(attempts, 'Job__c');
        Map<ID, Job__c> jobs = new Map<ID, Job__c>();
        
        if (idSet.size() == 0 ) {
            return jobs;
        }
        
        jobs.putAll([SELECT Id, Service__c, IsExecuted__c,Project__r.ID ,Location__r.ID, ProjectService__r.ServiceRank__c ,IsShift__c, ShiftClosureOverride__c FROM Job__c WHERE Id in :idSet]);
        return jobs;
    }
    
}