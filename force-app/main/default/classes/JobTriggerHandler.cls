public class JobTriggerHandler extends TriggerHandler {
    static ILogger appLogger, debugLogger;

    static final Date CURRENT_DATE;
    static final Datetime CURRENT_DATETIME;
    static final Blob cryptoIv;
    static final Blob cryptoKey;
    // Static Variable Initializer: It runs only once
    static {
        CURRENT_DATE = Datetime.now().Date();
        CURRENT_DATETIME = Datetime.now();
        SurveyPhotoViewerSetting__c setting  = SurveyPhotoViewerSetting__c.getOrgDefaults();
        cryptoIv = Blob.ValueOf(String.valueOf(setting.Iv__c == null? '': setting.Iv__c));
        //system.debug('cryptoIv+++++++++++++'+ cryptoIv);
        cryptoKey = Blob.ValueOf(String.valueOf(setting.Key__c == null? '': setting.Key__c));
        // system.debug('cryptoKey++++++++++++++++'+ cryptoKey);
        appLogger = LoggerFactory.createLogger('JobTrigger', true);
        debugLogger = LoggerFactory.createLogger('JobTrigger', false);
    }

    static void debugMessage(String msg) {
        debugLogger.debug(msg);
    }

    static void dumpLogs() {
        try {
            appLogger.save();
        }
        catch(Exception ex) {
            debugLogger.error('Failed to save logs to DB:' + ex.getLineNumber() + ':' + ex.getMessage());
        }
        debugLogger.save();
    }

    // boilerplate code, don't change unless you want to override temlplate method> ----
    public override void beforeUpdate() {
        if (true == TriggerUtil.skipJobTrigger) {
            return;
        }

        Map<string, JobAttempt__c> activeAttempts = new Map<string, JobAttempt__c>();
        List<JobAttempt__c> jas = [SELECT Id, Name, Job__c, DateOriginallyReported__c from JobAttempt__c WHERE
                               IsActive__c = true and Job__c in :Trigger.new];
        for (JobAttempt__c ja : jas)
        {
            activeAttempts.put(ja.Job__c, ja);
        }


        debugMessage('job: enter beforeUpdate');
        for(Job__c job: (List<Job__c>) Trigger.new) {
            try {
                handleBeforeEachUpdate(job, activeAttempts);
                handleJobExceptionStatus(job);
            }
            catch(Exception ex) {
                appLogger.error('beforeUpdate:' + ex.getLineNumber() + ';' + ex.getMessage());
            }
        }
        debugMessage('job: exit beforeUpdate');
        dumpLogs();
    }

    public override void afterInsert(){

        set<Id> projJobIds = new set<Id>();
        for(job__c pj : (List<job__c >)trigger.new)
        {
            projJobIds.add(pj.Id);			
        }
        //system.debug('projJobIds'+projJobIds);

        list<Job__c> p = new list<Job__c>();
        for(job__c pj: [select Id,name,SurveyPhotoViewerEncodedId__c from job__c where Id in :projJobIds])
        {
            pj.SurveyPhotoViewerEncodedId__c = processEncryption(pj.Id);
            p.add(pj);			
        }

        if(p.size()>0)
        {
            update p;
        }

    }
    
    public override void beforeInsert(){
        for(job__c pj : (List<job__c >)trigger.new)
        {
			handleJobExceptionStatus(pj);
        }
    }

    private static string processEncryption(Id recId){
        System.debug('Process Encryption' +recId );
        Blob cipherText = Crypto.encrypt('AES128',cryptoKey, cryptoIv, Blob.valueOf(recId));
        string encodedrecId = EncodingUtil.base64Encode(cipherText);
        system.debug('encodedrecId+++++++++++++++++++++'+ encodedrecId);
        return encodedrecId;
    }

    public override void afterUpdate() {
           
        if (true == TriggerUtil.skipJobTrigger || TriggerUtil.SkipJobUpdateTrigger == true){
                return;
        }
        
        Map<String, Date> jobsSchedMap = new Map<String,Date>();
        Map<String, Job__c> jobsNOWMap = new Map<String, Job__c>();

        List<User> us = [select Id, username from User where Id = :UserInfo.getUserId() LIMIT 1];
        string username = !us.IsEmpty()?us[0].Username:'';

        for(Job__c current: (List<Job__c>) Trigger.new) {
            try
            {                
                Job__c old = getOld(current.Id);
                if (current.JobScheduledDate__c != old.JobScheduledDate__c)
                {
                    //Process scheduled date changes only if the action was triggered by Porject Builder
                    //Prevent this field update and triggering a axis update when a schedule date
                    //update is coming from the field
                    //Integration user salesforce.integration
                    //This is a HACK for a quick hotfix, may need to change it!!
                    if (!username.toLowerCase().contains('integration'))
                    {
                    	jobsSchedMap.put(current.Id, current.JobScheduledDate__c);
                    }
                }
                if (current.NumberOfWorkers__c != old.NumberOfWorkers__c)
                {
                    jobsNOWMap.put(current.ActiveJobAttempt__c, current);
                }
            }
            catch(Exception ex) {
                appLogger.error('afterUpdate:' + ex.getLineNumber() + ';' + ex.getMessage());
            }
        }
        if (!jobsSchedMap.isEmpty())
        {
            JobActionsHelper.setScheduledDate(jobsSchedMap, 'job');
        }

        if (!jobsNOWMap.isEmpty())
        {
			List<JobAttempt__c> jasNOW = [SELECT Id, Name, ExpectedNumberOfWorkers__c
                        		   		FROM JobAttempt__c WHERE Id in :jobsNOWMap.keySet() FOR UPDATE];
            for (JobAttempt__c jaNOW : jasNOW)
            {
                jaNOW.ExpectedNumberOfWorkers__c = jobsNOWMap.get(jaNOW.Id).NumberOfWorkers__c;

            }
            update jasNOW;

        }


        dumpLogs();
    }

    // before each update logic
    //OH261
    //if IsExecuted is false, jobExecDate must be null
    /////////////////////////////////////////////////////////////
    void handleBeforeEachUpdate(Job__c current, Map<string, JobAttempt__c> activeAttempts) {
        Job__c old = getOld(current.Id);
        handleStartDateChange(current, old);
        handleJobFirstAttemptLogic(current, old);
        handleJobScheduleLogic(current, old);
        handleJobExecutionLogic(current, old);
        handleJobStartedLogic(current, old);
        handleJobAssignedLogic(current, old);
        handleJobReportedLogic(current, old, activeAttempts);        
    }


    //OH-5411
    void handleScheduleDateChange(Job__c current, Job__c old) {
        if ((old.JobScheduledDate__c != current.JobScheduledDate__c)
            && old.JobScheduledDate__c != null
            && current.JobScheduledDate__c != null)
        {
            List<ProjectLocation__c> projectLocations = [SELECT Id, Location__c, ReservationLocation__c, LocationScheduledDate__c
                                                         FROM ProjectLocation__c
                                                         WHERE Project__c =: current.Project__c];
            SET<Id> reservationIds = new SET<Id>();
            SET<Id> locationIds = new SET<Id>();

            // Update job Schedule Date on project Location obj
            for (ProjectLocation__c projectLocation: projectLocations)
            {
                if (projectLocation.ReservationLocation__c != null)
                {
                    reservationIds.add(projectLocation.Id);
                    locationIds.add(projectLocation.Location__c);
                    projectLocation.LocationScheduledDate__c = current.JobScheduledDate__c;
                }
            }
            update projectLocations;

            // Update job Schedule Date on reservation Location obj
            List<ReservationLocation__c> reservationLocations = [SELECT Id, ReservedDate__c FROM ReservationLocation__c
                                                                 WHERE Id in : reservationIds];
            for (ReservationLocation__c reservationLocation: reservationLocations)
            {
                reservationLocation.ReservedDate__c = current.JobScheduledDate__c;
            }

            update reservationLocations;


            //Reduce the capacity to the new scheduled date
            List<LocationAssetCapacity__c> locationAssetCapacities = [SELECT Id, Location__c, Date__c, AvailableCapacity__c, AssetType__c, AssetCapacity__c
                                                                      FROM LocationAssetCapacity__c
                                                                      WHERE Date__c =: current.JobScheduledDate__c
                                                                      AND Location__c in :locationIds];

            for(LocationAssetCapacity__c locationAssetCapacity :locationAssetCapacities){
                locationAssetCapacity.AvailableCapacity__c = locationAssetCapacity.AvailableCapacity__c - 1;
            }
            update locationAssetCapacities;

            //Increase the capacity to the old scheduled date if its greater then todays date
            if (old.JobScheduledDate__c >  system.today()){
                locationAssetCapacities = [SELECT Id, Location__c, Date__c, AvailableCapacity__c, AssetType__c, AssetCapacity__c
                                           FROM LocationAssetCapacity__c
                                           WHERE Date__c =: old.JobScheduledDate__c
                                           AND Location__c in :locationIds];

                for(LocationAssetCapacity__c locationAssetCapacity :locationAssetCapacities){
                    locationAssetCapacity.AvailableCapacity__c = locationAssetCapacity.AvailableCapacity__c + 1;
                }
                update locationAssetCapacities;
            }
        }
    }

    //Added by RN - 11/15/2017 - If StartDate is changed, recalculate End Date
    void handleStartDateChange(Job__c current, Job__c old) {
        if ((old.JobStartDate__c != current.JobStartDate__c)
            && old.JobStartDate__c != null)
        {
            if (current.JobStartDate__c != null) {
                Integer numDays = Integer.ValueOf(current.NumberOfDays__c == null? 1:current.NumberOfDays__c - 1);
                current.JobEndDate__c = current.JobStartDate__c.addDays(numDays);
            }
        }
    }


    //--OH580: Fields First attempt date and Last attempt date for Job are not updated.
    void handleJobFirstAttemptLogic(Job__c current, Job__c old) {
        if (null != old.JobFirstAttemptDate__c) {
            if (null != current.JobFirstAttemptDate__c) {
                current.JobFirstAttemptDate__c = old.JobFirstAttemptDate__c;
            }
        }
    }

    //--OH261
    //if IsExecuted is false, jobExecDate must be null
    void handleJobExecutionLogic(Job__c current, Job__c old) {
        if (false == CONSTANTS.JOB_COMPLETION_STATUS_COMPLETED.equalsIgnoreCase(current.CompletionStatus__c)) {
            current.JobCompletedDate__c = null;
        } else {
            if (null == current.JobCompletedDate__c) {
                current.JobCompletedDate__c = CURRENT_DATE;
            }
        }

        if (false == current.IsExecuted__c) {
            current.JobExecutedDate__c = null;
            return;
        }
    }

    //--OH280 Setting Job Committed Date
    void handleJobScheduleLogic(Job__c current, Job__c old) {
        handleJobRescheduleLogic(current, old);
        handleJobCommittedDateLogic(current, old);
    }

    //--OH220 Set Job Schedule Date
    void handleJobRescheduleLogic(Job__c current, Job__c old) {
        if (null == current.JobScheduledDate__c) { return; }

        if (current.JobScheduledDate__c < old.ProjectStartDate__c) {
           throw new CustomException('The job schedule date can not be less than project start date.');
        }
        
        if (current.JobScheduledDate__c != old.JobScheduledDate__c ) {
            if (null != old.JobScheduledDate__c ) {
                current.IsRescheduled__c = true;
            }
        }
    }

    //--OH280 Setting Job Committed Date
    void handleJobCommittedDateLogic(Job__c current, Job__c old) {
        if (jobShouldHaveCommittedDate(current)) {
            setJobCommittedDate(current, old);
        }
    }

    static Boolean jobShouldHaveCommittedDate(Job__c job) {
        if (CONSTANTS.SCHEDULE_OPTION_EC.equalsIgnoreCase(job.ProjectScheduleOptionCode__c)) {
            return CONSTANTS.PROJECT_STATUS_INPROGRESS.equalsIgnoreCase(job.ProjectStatus__c);
        }

        if (CONSTANTS.SCHEDULE_OPTION_USER.equalsIgnoreCase(job.ProjectScheduleOptionCode__c)) {
            return CONSTANTS.PROJECT_STATUS_LAUNCHED.equalsIgnoreCase(job.ProjectStatus__c);
        }
        return false;
    }

    void setJobCommittedDate(Job__c current, Job__c old) {
        if (null == old.JobCommittedDate__c &&
            null != current.JobScheduledDate__c) {
                current.JobCommittedDate__c = current.JobScheduledDate__c;
            }
    }

    //--OH211 handleJobStartedLogic
    //Verify that a Job in a status of STARTED has a Job Started Date specified
    void handleJobStartedLogic(Job__c current, Job__c old) {
        if (CONSTANTS.JOB_STATUS_STARTED.equalsIgnoreCase(current.JobStatus__c) &&
            false == CONSTANTS.JOB_STATUS_STARTED.equalsIgnoreCase(old.JobStatus__c)) {
                setJobStartDateIfNeeded(current);
            }
    }

    void setJobStartDateIfNeeded(Job__c current) {
        if (null == current.JobDateStarted__c) {
            current.JobDateStarted__c = CURRENT_DATETIME;
        }
    }

    //--OH210 Verify that a Job with a status of ASSIGNED has a Job Assigned Date populated.
    void handleJobAssignedLogic(Job__c current, Job__c old) {
        if (CONSTANTS.JOB_STATUS_ASSIGNED.equalsIgnoreCase(current.JobStatus__c)) {
            if (null ==current.JObDateAssigned__c) {
                current.JObDateAssigned__c = CURRENT_DATETIME;
            }

            if (null == current.JobDateOriginallyAssigned__c) {
                current.JobDateOriginallyAssigned__c = current.JObDateAssigned__c;
            }
        }
    }

    //--OH212 A Job is REPORTED when a Worker has reported the Job.
    void handleJobReportedLogic(Job__c current, Job__c old, Map<string, JobAttempt__c> activeAttempts) {
        if (false == CONSTANTS.JOB_STATUS_REPORTED.equalsIgnoreCase(current.JobStatus__c)) {
            return;
        }

        setJobStartDateIfNeeded(current);

        if (false == CONSTANTS.JOB_STATUS_REPORTED.equalsIgnoreCase(old.JobStatus__c)) {
          	current.JobDateOriginallyReported__c = activeAttempts.get(current.Id).DateOriginallyReported__c;

            if (null == current.JobDateOriginallyReported__c) {
                current.JobDateOriginallyReported__c = CURRENT_DATETIME;
            }
        }
    }
    static Boolean allowReportedJobTobeUpdated(Job__c job) {
        if (CONSTANTS.PROJECT_STATUS_INPROGRESS.equalsIgnoreCase(job.ProjectStatus__c) ||
            CONSTANTS.PROJECT_STATUS_ENDED.equalsIgnoreCase(job.ProjectStatus__c)) {
                return true;
            }
        return false;
    }

    // helper method > ----
    static Job__c getOld(Id jobId) {
        return (Job__c) Trigger.oldMap.get(jobId);
    }
    
    //handle Attempt status
    void handleJobExceptionStatus(Job__c current) {
        system.debug('~~~~~~handleJobExceptionStatus~~~~~~');
        system.debug('~~~~~~current.ProjectScheduleOptionCode__c~~~~~~'+ current.ProjectScheduleOptionCode__c);
        system.debug('~~~~~~CONSTANTS.SCHEDULE_OPTION_EC~~~~~~'+ CONSTANTS.SCHEDULE_OPTION_EC);
        system.debug('~~~~~~current.JobScheduledDate__c~~~~~~'+ current.JobScheduledDate__c);
        
        if(CONSTANTS.SCHEDULE_OPTION_EC.equalsIgnoreCase(current.ProjectScheduleOptionCode__c)){
            current.IsAttemptable__c = true;
            current.CreateAttemptException__c = CONSTANTS.JOB_ATTEMPT_COMMENT_SUCCESS; 
        }
        else if(CONSTANTS.SCHEDULE_OPTION_USER.equalsIgnoreCase(current.ProjectScheduleOptionCode__c)){
            if(current.JobScheduledDate__c!=null){
                current.IsAttemptable__c = true;
                current.CreateAttemptException__c = CONSTANTS.JOB_ATTEMPT_COMMENT_SUCCESS; 
            }else{
                current.IsAttemptable__c = false;
                current.CreateAttemptException__c = CONSTANTS.JOB_ATTEMPT_COMMENT_SCHEDULEDATE;                
            }
        }
        if (CONSTANTS.JOB_STATUS_CANCELED.equalsIgnoreCase(current.JobStatus__c) || CONSTANTS.JOB_STATUS_CLOSED.equalsIgnoreCase(current.JobStatus__c)) {
            current.IsAttemptable__c = false;
            current.CreateAttemptException__c = CONSTANTS.JOB_ATTEMPT_COMMENT_CANCEL;
        }
        if(current.NumberOfDays__c>1){
            current.IsAttemptable__c = false;
            current.CreateAttemptException__c = CONSTANTS.JOB_ATTEMPT_COMMENT_MULTIDAY;            
        }
        
    }
}