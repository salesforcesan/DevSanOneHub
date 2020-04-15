global without sharing class JobActionsHelper {

    global static Integer JOB_BATCH_SIZE = 500;
    global static Integer JOB_BATCH_DECISION_COUNT = 500;
    global static Integer JOB_BATCH_DELETE_DECISION_COUNT = 500;
    global static Integer JOB_BATCH_CANCEL_DECISION_COUNT = 500;
    global static Integer JOB_BATCH_CLOSE_DECISION_COUNT = 500;
    global static Integer JOB_BATCH_LAUNCH_DECISION_COUNT = 500;
    global static Integer JOB_BATCH_SCHEDULEDATE_DECISION_COUNT = 500;

    global static void RunCreateAttempts() {

        Id[] jobIds = new Id[] {};
        Set<Id> projectIds = new Set<Id>();
        Integer createAttemptSize = getCreateAttemptSize();
        Integer jobCount = 0;
        List<Job__c> jobs = [Select Id, name, Project__c from Job__c WHERE CreateAttempt__c = true and
                             ProjectStatus__c IN (:CONSTANTS.PROJECT_STATUS_LAUNCHED, :CONSTANTS.PROJECT_STATUS_INPROGRESS)
                             AND JobStatus__c != :Constants.JOB_STATUS_CANCELED
                             ORDER BY ProjectLocation__c LIMIT :createAttemptSize
                            ];

        for (Job__c job : jobs) {
            jobIds.add(job.Id);
        }

        if (jobIds.size() > 0) {
            CreateAttempts(jobIds, null, '', false);
        }
    }

    global static void RunJobHistoryGetter() {

        DateTime lastSyncTime;
        List<ProcessLastSyncTime__c> plsts = [Select Id, CurrentProcessId__c, SyncTime__c from ProcessLastSyncTime__c WHERE ProcessName__c = 'JobChangeTracking' LIMIT 1];

        if (plsts.isEmpty()) {
            ProcessLastSyncTime__c plst = new ProcessLastSyncTime__c();
            plst.SyncTime__c = DateTime.Now().addSeconds(-10);
            plst.CurrentProcessId__c = '';
            plst.ProcessName__c = 'JobChangeTracking';
            plsts.add(plst);
            insert plsts;
        }

        lastSyncTime = plsts[0].SyncTime__c ;
        //If there's an existing process running, return
        if (!string.isBlank(plsts[0].CurrentProcessId__c))
            return;

        BatchGetJobHistoryChanges batch = new BatchGetjobHistoryChanges(lastSyncTime);
        Id batchJobId = Database.ExecuteBatch(batch, 9000);

        plsts[0].CurrentProcessId__c = string.valueOf(batchJobId);
        update plsts[0];

    }


    global static void ProcessJobHistoryChanges(List<Job__History> jhs) {

        Set<Id> projectIds = new Set<Id>();
        Set<Id> jobIds = new Set<Id>();
        Map<string, string> mapChangeTypes = new Map<string, string>();

        for (Job__History jh : jhs) {
            jobIds.add(jh.ParentId);
        }

        List<Job__c> jobs = [Select Id, Name, Project__r.DateLaunched__c, ProjectNumber__c, ProjServiceName__c, Project__c, ProjectService__c from Job__c WHERE Id IN :jobIds];
        List<EntityChangeType__c> ects = [Select Id, Name, Field__c, Value__c, ChangeType__c from EntityChangeType__c WHERE Entity__c = 'Job'];

        for (EntityChangeType__c ect : ects) {
            //Check for changes looking for a particular value or any
            if (ect.Value__c == null)
                mapChangeTypes.put(ect.Field__c.toLowerCase(), ect.ChangeType__c);
            else
                mapChangeTypes.put(ect.Field__c.toLowerCase() + '-' + ect.Value__c.toLowerCase(), ect.ChangeType__c);
        }

        Map<Id, Job__c> mapProjectLaunchedDate = new Map<Id, Job__c>(jobs);
        Map<string, string> newchanges = new Map<string, string>();

        List<EntityChangeLog__c> ecls = new List<EntityChangeLog__c>();
        EntityChangeLog__c ecl;

        for (Job__History jh : jhs) {
            //Check if this is a field of interest to the system
            //Else ignore the change
            //Check with changes looking for a particular value or any
            string newValue = jh.NewValue == null ? '' : string.valueof(jh.NewValue).toLowerCase();

            if (mapChangeTypes.get(string.valueof(jh.Field).toLowerCase()) == null &&
                    mapChangeTypes.get(string.valueof(jh.Field).toLowerCase() + '-' + newValue) == null )
                continue;

            if (jh.CreatedDate > mapProjectLaunchedDate.get(jh.ParentId).Project__r.DateLaunched__c) {
                string changeType = mapChangeTypes.get(string.valueof(jh.Field).toLowerCase() + '-' + string.valueof(newValue).toLowerCase()) == null ?
                                    mapChangeTypes.get(string.valueof(jh.Field).toLowerCase()) : mapChangeTypes.get(string.valueof(jh.Field).toLowerCase() + '-' + string.valueof(newValue).toLowerCase());
                //INSERT UNIQUE CHANGES ONLY for the object and change type

                if (!newchanges.containskey(string.valueof(jh.ParentId) + changeType )) {
                    ecl = new EntityChangeLog__c();
                    ecl.Entity__c = 'Job';
                    ecl.ChangeDateTime__c = jh.CreatedDate;
                    ecl.ChangeType__c = changeType;
                    ecl.EntityId__c = mapProjectLaunchedDate.get(jh.ParentId).Name;
                    ecl.Job__c = mapProjectLaunchedDate.get(jh.ParentId).Id;
                    ecl.Project__c = mapProjectLaunchedDate.get(jh.ParentId).Project__c;
                    ecl.ProjectService__c = mapProjectLaunchedDate.get(jh.ParentId).ProjectService__c;
                    ecl.Status__c = 'Hold';
                    ecls.add(ecl);
                    newchanges.put(string.valueof(jh.ParentId) + changeType, string.valueof(jh.ParentId) + changeType);
                }
            }
        }

        if (ecls.size() > 0) {
            insert ecls;
        }
    }
    
    global static List<ActionResponse> cancelJobs(Id[] jobIds, string cancelReason, string cancelComments) {

        return cancelJobs(jobIds, cancelReason, cancelComments, false);

    }

    global static List<ActionResponse> deleteJobs(Id[] jobIds) {

        return deleteJobs(jobIds, false);
    }

    global static List<ActionResponse> CreateAttempts(Id[] jobIds, Date scheduledDate, string attemptReason) {
        system.debug('__####-----' + scheduledDate);
        return CreateAttempts(jobIds, scheduledDate, attemptReason, false);
    }


    global static List<ActionResponse> CreateAttempts(Id[] jobIds, Date scheduledDate, string attemptReason, Boolean isBatchCall) {

        Set<Id> projectIds = new Set<Id>();
        Set<Id> projectServiceIds = new Set<Id>();
        List<ActionResponse> responses = new  List<ActionResponse>();
        Id[] attemptableJobIds = new Id[] {};

        if (jobIds.size() > JOB_BATCH_SIZE && !isBatchCall) {
            ActionResponse response = new ActionResponse(jobIds[0], false, 'Please use a batch call for jobs size > ' + string.valueof(JOB_BATCH_SIZE));
            responses.add (response);
            return responses;
        }
        
        

        List<Job__c> jobs = [SELECT Id, Name, JobStatus__c, TotalJobAttempts__c, AccountableExecutionCompany__c,
                             AccountableExecutionCompany__r.name, JobScheduledDate__c, JobStartDate__c, JobEndDate__c,
                             ProjectScheduleOptionName__c, ProjectScheduleOptionCode__c, Project__c,
                             ProjectService__c, ProjectStatus__c, JobDateOpened__c, NumberOfWorkers__c, NumberOfDays__c,
                             ActiveJobAttempt__c, ActiveJobAttempt__r.AssignedContactId__c, CreateAttempt__c,IsAttemptable__c,
                             JobCommittedDate__c, ProjectEndDate__c, KeepAssignment__c, JobStartTime__c, JobEndTime__c, ProjectLocation__c,CreateAttemptException__c /*, TeamJob__c*/
                             FROM Job__c WHERE Id in :jobIds FOR UPDATE];


        List<Job__c> attemptableJobs = new List<Job__c>();
        List<Job__c> UnAttemptable_cancelJob = new List<Job__c>();
        List<Job__c> UnAttemptable_multiDayJob = new List<Job__c>();
        List<Job__c> UnAttemptable_unschDateJob = new List<Job__c>();
        List<Job__c> UnAttemptable = new List<Job__c>();
        
		boolean isCleanState;
        for (Job__c job : jobs ) {

            /* Not sure if we need this validation. ReAttempt may not need all the days.
            Date jobStartDate = scheduledDate == null? job.JobStartDate__c: scheduledDate;
            Integer numDays = job.NumberOfDays__c == null ? 0 : Integer.ValueOf(job.NumberOfDays__c);
            Date endDate = job.JobStartDate__c.addDays(numDays - 1);

            if (endDate > job.ProjectEndDate__c)
            {
                ActionResponse response = new ActionResponse(job.Id, false, job.Name + ': Job cannot be scheduled outside project window.' );
                responses.add(response);
            }
            else
            */
			isCleanState = true;
            if (job.JobStatus__c == CONSTANTS.JOB_STATUS_CANCELED || job.JobStatus__c == CONSTANTS.JOB_STATUS_CLOSED) {
                isCleanState = false;
                UnAttemptable_cancelJob.add(job);
                ActionResponse response = new ActionResponse(job.Id, false, job.Name + ': Cannot create attempt. Invalid job status.' );
                responses.add(response);
            }  
            if ((job.ProjectStatus__c == CONSTANTS.PROJECT_STATUS_LAUNCHED || job.ProjectStatus__c == CONSTANTS.PROJECT_STATUS_BOOKED) && job.ActiveJobAttempt__c != null && job.NumberOfDays__c > 1) {
                isCleanState = false;
                UnAttemptable_multiDayJob.add(job);
                ActionResponse response = new ActionResponse(job.Id, false, job.Name + ': Cannot create attempt. Cannot reattempt Multiday jobs.');
                responses.add(response);

            } 
            if ((job.ProjectStatus__c == CONSTANTS.PROJECT_STATUS_LAUNCHED || job.ProjectStatus__c == CONSTANTS.PROJECT_STATUS_BOOKED) && job.ProjectScheduleOptionCode__c != CONSTANTS.SCHEDULE_OPTION_EC && job.JobScheduledDate__c == null) {
                isCleanState = false;
                UnAttemptable_unschDateJob.add(job);
                system.debug('schedule date:::' + ' : Cannot create attempt. Scheduled Date is required.');
                ActionResponse response = new ActionResponse(job.Id, false, job.Name + ': Cannot create attempt. Scheduled Date is required.');
                responses.add(response);
            }
            if ((job.ProjectStatus__c == CONSTANTS.PROJECT_STATUS_LAUNCHED || job.ProjectStatus__c == CONSTANTS.PROJECT_STATUS_BOOKED) && (job.ActiveJobAttempt__c != null ||job.TotalJobAttempts__c > 0 )) {
				isCleanState = false;
                UnAttemptable.add(job);
            } 
            if(isCleanState) {
                attemptableJobIds.add(job.Id);
                attemptableJobs.add(job);
            }

        }

        List<JobAttempt__c> oldactiveAttempts = [SELECT Id, IsActive__c, AttemptStatus__c, DateCanceled__c, DateClosed__c
                                                FROM JobAttempt__c where Job__c in :attemptableJobIds
                                                AND IsActive__c = true FOR UPDATE];

        List<JobAttempt__c> newAttempts =  new  List<JobAttempt__c>();


        Boolean success = true;
        Savepoint sp = Database.setSavepoint();

        //try {

            TriggerUtil.SkipAllTriggers();

            oldactiveAttempts = UpdateOldActiveAttemptsOnNewAttemptCreation(oldactiveAttempts);
            newAttempts = InsertNewAttempts(attemptableJobs, scheduledDate, attemptReason);


            update oldactiveAttempts;
            insert newAttempts;

            //OH-4439
            JobAttemptWorkerHelper.Create(newAttempts);

            //SET JOBS ACTIVE ATTEMPT
            Map<Id, Id> mapJobIdActiveAttemptId = new Map<Id, Id>();
            for (JobAttempt__c nja : newAttempts) {
                mapJobIdActiveAttemptId.put(nja.Job__c, nja.Id);
            }

            for (Job__c job : attemptableJobs) {
                job.JobStatusPrevious__c = job.JobStatus__c;
                job.JobStatus__c = CONSTANTS.JOB_STATUS_OPEN;
                if (job.JobDateOpened__c == null)
                    job.JobDateOpened__c = DateTime.Now();
                job.JobDateStarted__c = null;
                job.JobDateAssigned__c = null;
                job.ActiveJobAttempt__c = mapJobIdActiveAttemptId.get(job.Id);

                if (scheduledDate != null ) {
                    job.JobScheduledDate__c = scheduledDate;

                    if (job.ProjectScheduleOptionCode__c == CONSTANTS.SCHEDULE_OPTION_USER) {
                        Integer numDays = job.NumberOfDays__c == null || job.NumberOfDays__c == 0 ? 1 : Integer.ValueOf(job.NumberOfDays__c);
                        job.JobStartDate__c = job.JobScheduledDate__c;
                        job.JobEndDate__c = job.JobStartDate__c.addDays(numDays - 1);
                    }
                }

                if (job.JobCommittedDate__c == null && job.JobScheduledDate__c != null) {
                    job.JobCommittedDate__c = job.JobScheduledDate__c;
                }


                job.CreateAttempt__c = false;
                job.IsAttemptable__c = true;
                job.CreateAttemptException__c = CONSTANTS.JOB_ATTEMPT_COMMENT_SUCCESS; 
                projectIds.add(job.Project__c);
                projectServiceIds.add(job.ProjectService__c);

            }

            update attemptableJobs;

            for (Job__c job : UnAttemptable_cancelJob)
            {
                job.IsAttemptable__c = false;
                job.CreateAttemptException__c = CONSTANTS.JOB_ATTEMPT_COMMENT_CANCEL;
            }
            
            for (Job__c job : UnAttemptable_multiDayJob)
            {
                job.IsAttemptable__c = false;
                job.CreateAttemptException__c = CONSTANTS.JOB_ATTEMPT_COMMENT_MULTIDAY;
            }
            
            for (Job__c job : UnAttemptable_unschDateJob)
            {
                job.IsAttemptable__c = false;
                job.CreateAttemptException__c = CONSTANTS.JOB_ATTEMPT_COMMENT_SCHEDULEDATE;
            }
            
            update UnAttemptable_cancelJob;
            update UnAttemptable_multiDayJob;
            update UnAttemptable_unschDateJob;
        
            /*
            List<Job__c> jobsWithTeamJob = new List<Job__c>();

            //To filter "OneHub Mobile" jobs
            for (Job__c job : attemptableJobs)
            {
                if (job.TeamJob__c == true){
                    jobsWithTeamJob.add(job);
                }
            }

            //To create Job Worker for "OneHub Mobile" projects
            //JobWorkerHelper.Create(jobsWithTeamJob);
            */

        /*} 
        catch (Exception e) {
            Database.rollback(sp);
            success = false;
        }*/

        if (success) {
            for (Job__c job : attemptableJobs ) {
                ActionResponse response = new ActionResponse(job.Id, true, job.Name + ': Successfully created attempt.');
                responses.add(response);
            }
        } else {
            for (Job__c job : attemptableJobs ) {
                ActionResponse response = new ActionResponse(job.Id, false, job.Name + ': Cannot create attempt, please check rules.');
                responses.add(response);
            }

        }


        return responses ;

    }

    global static List<ActionResponse> cancelJobs(Id[] jobIds, string cancelReason, string cancelComments, Boolean isBatchCall) {

        List<ActionResponse> responses = new  List<ActionResponse>();

        //Implementation

        Id[] cancellableJobIds = new Id[] {};
        Set<Id> projectIds = new Set<Id>();
        Set<Id> projectServiceIds = new Set<Id>();


        if (jobIds.size() == 0) {
            ActionResponse response = new ActionResponse(null, false, 'No jobs in the list to cancel.');
            responses.add(response);
            return responses;

        }

        if (cancelReason.toLowerCase() == 'other' && String.IsEmpty(cancelComments)) {
            ActionResponse response = new ActionResponse(null, false, 'Please provide cancel comments when cancel reason is Other.');
            responses.add(response);
            return responses;

        }


        List<Job__c> jobs = [select id, name, JobStatus__c, Jobcanceledreason__c, JobCanceledComments__c, ProjectLocation__c, ProjectService__c, JobStartDate__c,
                             ProjectStatus__c, IsCancellable__c, Project__c from job__c where Id in :jobIds FOR UPDATE];
        
        system.debug('List of Cancel Jobs Count:::::::::::::::::::::++++++' +jobs.size() );
        List<Job__c> cancellableJobs = new List<Job__c>();

        for (Job__c job : jobs ) {
            if (!job.IsCancellable__c) {
                ActionResponse response = new ActionResponse(job.Id, false, 'Cannot cancel job. Invalid Project status or not enough lead time.');
                responses.add(response);
            } else {
                cancellableJobIds.add(job.Id);
                cancellableJobs.add(job);

            }

        }

        if (cancellableJobs.size() == 0)
            return responses;

        system.debug('Cancellable Size: ' + cancellableJobIds.size());

        //UPDATE JOB ATTEMPTS
        List<JobAttempt__c> jobAttempts = [select Id, attemptstatus__c, datecanceled__c, dateclosed__c from
                                           JobAttempt__c where job__c in :cancellableJobIds  and AttemptStatus__c not in
                                           (:CONSTANTS.JOB_ATTEMPT_STATUS_CLOSED, :CONSTANTS.JOB_ATTEMPT_STATUS_CANCELED) FOR UPDATE];
        //todo: bug need fixing
        jobAttempts = UpdateJobAttemptsOnJobCancel(jobAttempts);
        set<string> JaIds = new set<string>();
        for(JobAttempt__c ja:jobAttempts)
        {
            JaIds.add(ja.Id);
            
        }
      

        List<JobAttemptWorker__c> jaWorkers = [Select Id from JobAttemptWorker__c WHERE JobAttempt__c in :JaIds AND IsCancellable__c = true];
        CancelWorkersOnJobAttemptCancel(jaWorkers);

        system.debug('Job Att Size: ' + jobAttempts.size());

        //UPDATE JOBS

        List<JobMaterial__c> jobMaterials = [select id, Status__c from JobMaterial__c where Job__c in :cancellableJobIds FOR UPDATE];

        for (Job__c job : cancellablejobs ) {
            job.Jobcanceledreason__c = cancelReason;
            job.JobCanceledComments__c = cancelComments;

            job.JobStatusPrevious__c = job.JobStatus__c;
            if ((job.jobstatus__c == CONSTANTS.JOB_STATUS_PENDING || job.jobstatus__c == CONSTANTS.JOB_STATUS_OPEN ||
                    job.jobstatus__c == CONSTANTS.JOB_STATUS_ASSIGNED || job.jobstatus__c == CONSTANTS.JOB_STATUS_STARTED) && !job.IsExecuted__c) {
                job.jobstatus__c = CONSTANTS.JOB_STATUS_CANCELED;
                job.jobdatecanceled__c = DateTime.Now();
            } else if (job.jobstatus__c == CONSTANTS.JOB_STATUS_REPORTED || job.IsExecuted__c) {
                job.jobstatus__c = CONSTANTS.JOB_STATUS_CLOSED;
                job.jobdateclosed__c = DateTime.Now();

            }
            projectIds.add(job.Project__c);
            projectServiceIds.add(job.ProjectService__c);
        }


        for (JobMaterial__c jm : jobMaterials ) {
            jm.Status__c = CONSTANTS.JOB_STATUS_CANCELED;
        }

        Boolean success = true;
        system.debug('JA Size: ' + jobAttempts.size());
        Savepoint sp = Database.setSavepoint();
        system.debug('CJ Size: ' + cancellablejobs.size());
        system.debug('PR Size: ' + projectIds.size());

        try {
            TriggerUtil.SkipAllTriggers();
            update jobAttempts;
            update cancellablejobs;
            update jobMaterials;
        } catch (Exception e) {
            success = false;
            Database.rollback(sp);
            //Test purposes
            throw e;
        }

        if (success) {
            for (Job__c job : cancellablejobs ) {

                ActionResponse response = new ActionResponse(job.Id, true, 'Successfully canceled job.');
                responses.add(response);
            }
        } else {
            for (Job__c job : cancellablejobs ) {
                ActionResponse response = new ActionResponse(job.Id, false, 'Cannot cancel job, please check rules.');
                responses.add(response);
            }

        }

        return responses;
    }


    global static List<ActionResponse> deleteJobs(Id[] jobIds, Boolean isBatchCall) {

        List<ActionResponse> responses = new  List<ActionResponse>();
        Id[] deletableJobIds = new Id[] {};
        Set<Id> projectServiceIds = new Set<Id>();


        if (jobIds.size() == 0) {
            ActionResponse response = new ActionResponse(null, false, 'No jobs in the list to delete.');
            responses.add(response);
            return responses;

        }

        List<Job__c> jobs = [SELECT Id, JobStatus__c, TotalJobAttempts__c, AccountableExecutionCompany__c,
                             JobScheduledDate__c, ProjectScheduleOptionName__c, Project__c, ProjectService__c, ProjectStatus__c  from Job__c WHERE Id in :jobIds];

        List<Job__c> deletableJobs = new List<Job__c>();
        for (Job__c job : jobs ) {
            if (job.ProjectStatus__c != CONSTANTS.PROJECT_STATUS_PLANNING &&
                    job.ProjectStatus__c != CONSTANTS.PROJECT_STATUS_CLOSED) {
                ActionResponse response = new ActionResponse(job.Id, false, 'Invalid Project status. Cannot delete job. Jobs can be deleted only in Planning or Closed status.');
                responses.add(response);
            } else {
                deletableJobIds.add(job.Id);
                deletableJobs.add(job);
                projectServiceIds.add(job.ProjectService__c);

            }

        }

        if (deletableJobs.size() == 0)
            return responses;


        Boolean success = true;

        try {
            TriggerUtil.SkipAllTriggers();
            delete deletablejobs;

        } catch (Exception e) {
            success = false;
        }

        if (success) {
            for (Job__c job : deletablejobs) {
                ActionResponse response = new ActionResponse(job.Id, true, 'Successfully deleted job.');
                responses.add(response);
            }
        } else {
            for (Job__c job : deletablejobs) {
                ActionResponse response = new ActionResponse(job.Id, false, 'Cannot delete job, please check rules.');
                responses.add(response);
            }

        }



        return responses ;
    }



    global static List<ActionResponse> closeJobs(Id[] jobIds, Boolean isBatchCall) {

        List<ActionResponse> responses = new  List<ActionResponse>();
        Id[] closableJobIds = new Id[] {};
        Set<Id> projectServiceIds = new Set<Id>();
        Set<Id> projectIds = new Set<Id>();


        if (jobIds.size() == 0) {
            ActionResponse response = new ActionResponse(null, false, 'No jobs in the list to close.');
            responses.add(response);
            return responses;

        }

        List<Job__c> jobs = [SELECT Id, JobStatus__c, TotalJobAttempts__c, AccountableExecutionCompany__c,
                             JobScheduledDate__c, ProjectScheduleOptionName__c, Project__c, ProjectService__c,
                             ProjectStatus__c  from Job__c WHERE Id in :jobIds FOR UPDATE];
        List<Job__c> closableJobs = new List<Job__c>();

        for (Job__c job : jobs ) {
            if (job.JobStatus__c == CONSTANTS.JOB_STATUS_CLOSED || job.JobStatus__c == CONSTANTS.JOB_STATUS_CANCELED) {
                ActionResponse response = new ActionResponse(job.Id, false, 'Job already in closed/canceled status. Cannot close job.');
                responses.add(response);
            } else {
                closableJobIds.add(job.Id);
                projectServiceIds.add(job.ProjectService__c);
                projectIds.add(job.Project__c);
                closableJobs.add(job);

            }

        }

        if (closableJobs.size() == 0)
            return responses;


        List<JobAttempt__c> closableAttempts = [SELECT Id, AttemptStatus__c, DateClosed__c from JobAttempt__c WHERE
                                                IsActive__c = true and Job__c in :closableJobIds and AttemptStatus__c
                                                        not in (:CONSTANTS.JOB_ATTEMPT_STATUS_CLOSED, :CONSTANTS.JOB_ATTEMPT_STATUS_CANCELED) FOR UPDATE];

        Savepoint sp = Database.setSavepoint();

        Boolean success = true;

        try {
            TriggerUtil.SkipAllTriggers();
            for (Job__c job : closableJobs) {
                job.JobStatusPrevious__c = job.JobStatus__c;
                job.JobStatus__c = CONSTANTS.JOB_STATUS_CLOSED;
                job.JobDateClosed__c = Datetime.now();
            }

            for (JobAttempt__c ja : closableAttempts ) {
                ja.AttemptStatus__c = CONSTANTS.JOB_ATTEMPT_STATUS_CLOSED;
                ja.DateClosed__c = DateTime.Now();

            }

            update closableJobs;
            update closableAttempts;

        } catch (Exception e) {
            success = false;
            Database.rollback(sp);
            //Test purposes
            throw e;

        }

        if (success) {
            for (Job__c job : closableJobs) {
                ActionResponse response = new ActionResponse(job.Id, true, 'Successfully closed job.');
                responses.add(response);
            }
        } else {
            for (Job__c job : closableJobs) {
                ActionResponse response = new ActionResponse(job.Id, false, 'Cannot close job, please check rules.');
                responses.add(response);
            }

        }



        return responses ;
    }

    //This method now uses the new setScheduledDate(Map<String, Date> jobscheduledDateMap)
    //going forward.
    global static List<ActionResponse> setScheduledDate(Id[] jobIds, Date scheduledDate) {
        TriggerUtil.SkipAllTriggers();
        Map<String, Date> jobscheduledDateMap = new Map<String, Date>();
        for (Id jobId : jobIds) {
            jobscheduledDateMap.put(jobId, scheduledDate);
        }
        return setScheduledDate(jobscheduledDateMap);
    }


    global static List<ActionResponse> setScheduledDate(Map<String, Date> jobscheduledDateMap) {

        return setScheduledDate(jobscheduledDateMap, '');
    }

   
    //This method is only for reschedules that are triggered from OH not from Execution Company
	public static List<ActionResponse> setScheduledDate(Map<String, Date> jobscheduledDateMap, String caller)
    {
        TriggerUtil.SkipAllTriggers();
        List<ActionResponse> responses = new  List<ActionResponse>();

        Id[] jobIds = new Id[] {};
        for (String key : jobscheduledDateMap.keySet() ) {
            jobIds.add(key);
        }

        if (jobIds.size() == 0) {
            ActionResponse response = new ActionResponse(null, false, 'No jobs in the list to set scheduled date.');
            responses.add(response);
            return responses;
        }

        Map<Id, Job__c> jobsMap = new Map<Id, Job__c>([SELECT Id, Name, Project__c, CreateAttempt__c, ActiveJobAttempt__c, ProjectStatus__c, DayNumber__c,
                JobStartDate__c, JobEndDate__c, JobScheduledDate__c, ProjectService__r.NumberOfDays__c,
                ProjectLocation__c, ProjectService__r.StartDayNumber__c, Project__r.ProjectScheduleOptionCode__c,
                ProjectLocation__r.LocationScheduledDate__c, (SELECT Id, Name, AttemptScheduleDate__c,
                        NumberOfReschedules__c, AttemptScheduledDate__c  FROM Job_Attempts__r WHERE IsActive__c = true),
                IsRescheduled__c
                FROM Job__c WHERE  ProjectScheduleOptionCode__c = :CONSTANTS.SCHEDULE_OPTION_USER AND
                        Id in :jobIds FOR UPDATE] );
        if (jobsMap.size() == 0) {
            ActionResponse response = new ActionResponse(null, false, 'No valid jobs found.');
            responses.add(response);
            return responses;
        }
        List<Job__c> jobs = jobsMap.values();
        if (jobs[0].Project__r.ProjectScheduleOptionCode__c.toLowerCase() != CONSTANTS.SCHEDULE_OPTION_SYSTEM.toLowerCase() &&
                jobs[0].Project__r.ProjectScheduleOptionCode__c.toLowerCase() != CONSTANTS.SCHEDULE_OPTION_USER.toLowerCase()) {
            ActionResponse response = new ActionResponse(null, false, 'Cannot set scheduled date on a project that has a schedule option EC.');
            responses.add(response);
            return responses;
        }
        
        
        List<JobAttempt__c> jobAttempts = new List<JobAttempt__c>();

        for (Job__c job : jobs ) {
            Integer startDayNumber;
            Integer numberOfDays;

            if (job.DayNumber__c == null) {
                startDayNumber = Integer.valueOf((job.ProjectService__r.StartDayNumber__c == null || job.ProjectService__r.StartDayNumber__c == 0) ? 1 : job.ProjectService__r.StartDayNumber__c);
                numberOfDays = Integer.valueOf((job.ProjectService__r.NumberOfDays__c == null || job.ProjectService__r.NumberOfDays__c == 0) ? 1 : job.ProjectService__r.NumberOfDays__c);
            } else {
                //HACK - need this information for job import. should
                //not set the scheduled date based on daynumber when a scheduled
                //date is set on a job. Need a better way to do this but
                //putting this in for short term.
                if (caller.toLowerCase() == 'job') {
                    startDayNumber = 1;
                } else {
                    startDayNumber = Integer.valueOf(job.DayNumber__c);
                }
                numberOfDays = 1;
            }

            Date scheduledDate = jobscheduledDateMap.get(job.Id);
            job.JobStartDate__c = scheduledDate.addDays(startDayNumber - 1);
            //if schedule date changed and has an active attempt
            if (job.ActiveJobAttempt__c != null && job.Job_Attempts__r.size() > 0 && job.Job_Attempts__r[0].AttemptScheduleDate__c != job.JobStartDate__c) {
                job.Job_Attempts__r[0].NumberOfReschedules__c = (job.Job_Attempts__r[0].NumberOfReschedules__c == null) ? 1 : (Integer.valueOf(job.Job_Attempts__r[0].NumberOfReschedules__c) + 1);
                job.Job_Attempts__r[0].AttemptScheduleDate__c = job.JobStartDate__c;
                job.Job_Attempts__r[0].AttemptScheduledDate__c = datetime.now();
                jobAttempts.add(job.Job_Attempts__r[0]);
            }

            job.JobEndDate__c = job.JobStartDate__c.addDays(numberOfDays - 1);
            if (job.JobScheduledDate__c != null && job.JobStartDate__c != null && job.JobScheduledDate__c != job.JobStartDate__c) {
                job.IsRescheduled__c = true;
            }

            job.JobScheduledDate__c = job.JobStartDate__c;
            job.LastPBScheduledDateChangeDateTime__c = DateTime.now();
            if (job.ActiveJobAttempt__c == null && (job.ProjectStatus__c == CONSTANTS.PROJECT_STATUS_LAUNCHED || job.ProjectStatus__c == CONSTANTS.PROJECT_STATUS_INPROGRESS)) {
                job.CreateAttempt__c = true;
            }
			
            job.IsAttemptable__c = true;
            job.CreateAttemptException__c = CONSTANTS.JOB_ATTEMPT_COMMENT_SUCCESS; 
            
            ActionResponse response = new ActionResponse(job.Id, true, 'Successfully set scheduled date.');
            responses.add(response);

        }


        Database.SaveResult[] results = Database.update(jobs, false);


        for (Integer i = 0; i < jobs.size(); i++) {
            Database.SaveResult result = results[i];

            if (!result.isSuccess()) {
                for (Database.Error err : result.getErrors()) {
                    String jobName = jobs[i].Name;
                    ActionResponse response = new ActionResponse(null, false, jobName + ': ' + err.getMessage() );
                    responses.add(response);
                }
            }
        }

        results = Database.update(jobAttempts, false);
        if (jobAttempts.size() > 0) {

            for (Integer i = 0; i < jobAttempts.size(); i++) {
                Database.SaveResult result = results[i];

                if (!result.isSuccess()) {
                    for (Database.Error err : result.getErrors()) {
                        String jobattName = jobAttempts[i].Name;
                        ActionResponse response = new ActionResponse(null, false, jobattName + ': ' + err.getMessage() );
                        responses.add(response);
                    }
                }
            }
        }

        Project__c project =  [SELECT Id, DateLocationsScheduled__c FROM Project__c WHERE Id = :jobs[0].Project__c FOR UPDATE];
        project.DateLocationsScheduled__c = DateTime.Now();
        update project;

        return responses ;


    }

    //Not being used. Verify and Deprecate.
    //This should be deprecated
    global static List<ActionResponse> resetScheduledDate(Id[] jobIds) {
        TriggerUtil.SkipAllTriggers();
        List<ActionResponse> responses = new  List<ActionResponse>();
        if (jobIds.size() == 0) {
            ActionResponse response = new ActionResponse(null, false, 'No jobs in the list to set scheduled date.');
            responses.add(response);
            return responses;
        }
        Map<Id, Job__c> jobsMap = new Map<Id, Job__c>([SELECT Id, Project__c, CreateAttempt__c, ActiveJobAttempt__c, ProjectStatus__c, JobStartDate__c, JobEndDate__c, JobScheduledDate__c, ProjectService__r.NumberOfDays__c,
                ProjectService__r.StartDayNumber__c, Project__r.ProjectScheduleOptionCode__c, ProjectLocation__r.LocationScheduledDate__c, (SELECT Id, AttemptScheduleDate__c, NumberOfReschedules__c, AttemptScheduledDate__c  FROM Job_Attempts__r WHERE IsActive__c = true)
                from Job__c WHERE ProjectLocation__r.LocationScheduledDate__c != null AND ProjectScheduleOptionCode__c = :CONSTANTS.SCHEDULE_OPTION_USER AND  Id in :jobIds FOR UPDATE]);
        if (jobsMap.size() == 0) {
            ActionResponse response = new ActionResponse(null, false, 'No valid jobs found.');
            responses.add(response);
            return responses;
        }
        List<Job__c> jobs = jobsMap.values();
        if (jobs[0].Project__r.ProjectScheduleOptionCode__c.toLowerCase() != CONSTANTS.SCHEDULE_OPTION_SYSTEM.toLowerCase() &&
                jobs[0].Project__r.ProjectScheduleOptionCode__c.toLowerCase() != CONSTANTS.SCHEDULE_OPTION_USER.toLowerCase()) {
            ActionResponse response = new ActionResponse(null, false, 'Cannot set scheduled date on a project that has a schedule option EC.');
            responses.add(response);
            return responses;
        }
        List<JobAttempt__c> jobAttempts = new List<JobAttempt__c>();
        for (Job__c job : jobs ) {
            Integer startDayNumber = Integer.valueOf((job.ProjectService__r.StartDayNumber__c == null || job.ProjectService__r.StartDayNumber__c == 0) ? 1 : job.ProjectService__r.StartDayNumber__c);
            Integer numberOfDays = Integer.valueOf((job.ProjectService__r.NumberOfDays__c == null || job.ProjectService__r.NumberOfDays__c == 0) ? 1 : job.ProjectService__r.NumberOfDays__c);

            job.JobStartDate__c = job.ProjectLocation__r.LocationScheduledDate__c.addDays(startDayNumber - 1);
            //if schedule date changed and has an active attempt
            if (job.ActiveJobAttempt__c != null && job.Job_Attempts__r.size() > 0 && job.JobScheduledDate__c != job.JobStartDate__c) {
                job.Job_Attempts__r[0].NumberOfReschedules__c = (job.Job_Attempts__r[0].NumberOfReschedules__c == null) ? 1 : (Integer.valueOf(job.Job_Attempts__r[0].NumberOfReschedules__c) + 1);
                job.Job_Attempts__r[0].AttemptScheduleDate__c = job.JobStartDate__c;
                job.Job_Attempts__r[0].AttemptScheduledDate__c = datetime.now();
                job.IsRescheduled__c = true;
                jobAttempts.add(job.Job_Attempts__r[0]);
            }

            job.JobEndDate__c = job.JobStartDate__c.addDays(numberOfDays - 1);
            job.JobScheduledDate__c = job.JobStartDate__c;

            if (job.ActiveJobAttempt__c == null && (job.ProjectStatus__c == CONSTANTS.PROJECT_STATUS_LAUNCHED || job.ProjectStatus__c == CONSTANTS.PROJECT_STATUS_INPROGRESS)) {
                job.CreateAttempt__c = true;
            }

            ActionResponse response = new ActionResponse(job.Id, true, 'Successfully set scheduled date.');
            responses.add(response);
        }
        update jobs;
        if (jobAttempts.size() > 0) {
            update jobAttempts;
        }

        Project__c project =  [SELECT Id, DateLocationsScheduled__c FROM Project__c WHERE Id = :jobs[0].Project__c];
        project.DateLocationsScheduled__c = DateTime.Now();
        update project;

        return responses ;
    }


    global static void invokeJobImportBatch(String projectId) {
        BatchManageImportAttachments batch = new BatchManageImportAttachments(projectId, 'jobs');
        string batchProcessId = Database.ExecuteBatch(batch, 1);

    }

    global static List<ActionResponse> updateBulkJobsFromFile(List<String> jobscsv, String projectId) {


        List<Job__c> jobstoupdate = new List<Job__c>();
        String fieldstoupdate = '';
        Set<String> jobIds = new Set<String>();
        Map<String, Job__c> jobsMap = new Map<String, Job__c>();
        Map<String, String> jobsNamebyIdMap = new Map<String, String>();
        Map<Integer, String> jobupdatemapbyindex = new Map<Integer, String>();
        Map<String, Integer> jobupdatemapbyfield = new Map<String, Integer>();
        String nsprefix = Constants.CURRENTNAMESPACEPREFIX.toLowerCase();




        //system.debug('jobscsv: ' + jobscsv);
        List<ActionResponse> responses = new  List<ActionResponse>();
        if (jobscsv.size() == 0) {
            ActionResponse response = new ActionResponse(null, false, 'No jobs in the list to update. Contact Administrator.');
            responses.add(response);
            return responses;
        }

        // 'Name-0,JobStartDate__c-3,NumberOfWorkers__c-6,JobStartTime__c-7,PurchaseOverRideAmount__c-8'
        String jobupdatefields = AppUtil.JobImportFields == null ? '' : AppUtil.JobImportFields.toLowerCase();
        if (String.isBlank(jobupdatefields)) {
            ActionResponse response = new ActionResponse(null, false, 'Missing value for custom setting JobImportFields. Contact Administrator.');
            responses.add(response);
            return responses;
        }


        Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        Schema.SObjectType jobSchema = schemaMap.get(Constants.CURRENTNAMESPACEPREFIX + 'job__c');
        Map<String, Schema.SObjectField> fieldMap = jobSchema.getDescribe().fields.getMap();


        String[] jobupdatefieldsarray = jobupdatefields.split(',');
        for (String jobupdatefield : jobupdatefieldsarray) {

            jobupdatemapbyindex.put(Integer.ValueOf(jobupdatefield.split('-')[1]), jobupdatefield.split('-')[0]);
            jobupdatemapbyfield.put(jobupdatefield.split('-')[0], Integer.ValueOf(jobupdatefield.split('-')[1]));
            fieldstoupdate = fieldstoupdate + jobupdatefield.split('-')[0] + ',';

            //If override field, get the formula field also.
            //Example, EstimatedMinutesOverride__c will also include EstimatedMinutes__c
            if (jobupdatefield.containsIgnoreCase('override')) {
                system.debug('inside override');
                string[] ffarray = jobupdatefield.replace('override', '').split('-');
                if (ffarray.size() > 0) {
                    string formulafield = ffarray[0];
                    fieldstoupdate = fieldstoupdate + formulafield + ',';

                }
            }

        }

        if (!String.isBlank(fieldstoupdate))
            fieldstoupdate = fieldstoupdate + 'id, ' + Constants.CURRENTNAMESPACEPREFIX + 'project__c ' ;

        for (String jobcsv : jobscsv) {
            String[] jobcsvarray = jobcsv.split(',');
            system.debug('jobdata: ' + jobcsv);
            Integer indexofname = jobupdatemapbyfield.get('name');
            jobIds.add(jobcsvarray[indexofname]);
        }

        String query = 'SELECT ' + fieldstoupdate + ' FROM job__c WHERE name in :jobIds AND project__c = :projectId';

        system.debug('query: ' + query);

        jobstoupdate = Database.query(query);
        for (Job__c job : jobstoupdate) {
            jobsMap.put(job.Name, job);
            jobsNameByIdMap.put(job.Id, job.Name);
        }


        Map<String, Date> jobsSchedMap = new Map<String, Date>();

        for (String jobcsv : jobscsv) {
            String[] jobcsvarray = jobcsv.split(',');
            Integer indexofname = jobupdatemapbyfield.get('name');
            Schema.DisplayType fielddataType;

            for (String fieldname : jobupdatemapbyfield.keySet()) {

                fielddataType = Schema.DisplayType.anytype;

                try {

                    //Do not set the Name field as it is auto generated
                    //Name is the here for the purposes of Key
                    if (fieldname.containsIgnoreCase('name')  || fieldname.containsIgnoreCase('project__c'))
                        continue;


                    Integer fieldindex = jobupdatemapbyfield.get(fieldname);

                    if (String.isBlank(jobcsvarray[fieldindex]))
                        continue;

                    fielddataType = fieldMap.get(fieldname).getDescribe().getType();
                    if (isOverrideValueEqual(jobcsvarray[fieldindex],
                        jobsMap.get(jobcsvarray[indexofname]).get(fieldname.replace('override', '')),
                        fielddataType)) {
                        continue;
                    }
                    
                    if (fielddataType == Schema.DisplayType.Date)
                        jobsMap.get(jobcsvarray[indexofname]).put(fieldname, DateUtil.ToDate(jobcsvarray[fieldindex]));
                    if (fielddataType == Schema.DisplayType.DateTime)
                        jobsMap.get(jobcsvarray[indexofname]).put(fieldname, DateUtil.ToDateTime(jobcsvarray[fieldindex]));
                    else if (fielddataType == Schema.DisplayType.String)
                        jobsMap.get(jobcsvarray[indexofname]).put(fieldname, jobcsvarray[fieldindex]);
                    else if (fielddataType == Schema.DisplayType.Integer)
                        jobsMap.get(jobcsvarray[indexofname]).put(fieldname, Integer.ValueOf(jobcsvarray[fieldindex]));
                    else if (fielddataType == Schema.DisplayType.Currency)
                        jobsMap.get(jobcsvarray[indexofname]).put(fieldname, Decimal.ValueOf(jobcsvarray[fieldindex]));
                    else if (fielddataType == Schema.DisplayType.Double)
                        jobsMap.get(jobcsvarray[indexofname]).put(fieldname, Double.ValueOf(jobcsvarray[fieldindex]));
                } catch (Exception err) { //Catch any data type issues
                    //ActionResponse response = new ActionResponse(null, false, jobsMap.get(jobcsvarray[indexofname]).Name + ': ' + fieldname + ': ' + err.getMessage() );
                    ActionResponse response = new ActionResponse(null, false, fieldname + ': ' + fielddataType + ':' + err.getMessage() );
                    responses.add(response);
                }
            }
        }

        Database.SaveResult[] results = Database.update(jobstoupdate, false);


        for (Integer i = 0; i < jobstoupdate.size(); i++) {
            Database.SaveResult result = results[i];

            if (!result.isSuccess()) {
                for (Database.Error err : result.getErrors()) {
                    String jobName = jobstoupdate[i].Name;
                    ActionResponse response = new ActionResponse(null, false, jobName + ': ' + err.getMessage() );
                    responses.add(response);
                }
            }
        }

        if (!responses.isEmpty())
            return responses;
        else
            return null;


    }

    static Boolean isOverrideValueEqual(String value, Object valueToCompare, DisplayType type) {
        if (type == Schema.DisplayType.Date)
            return DateUtil.ToDate(value) == valueToCompare;
        if (type == Schema.DisplayType.DateTime)
            return DateUtil.ToDateTime(value) == valueToCompare;
        else if (type == Schema.DisplayType.String)
            return value == valueToCompare;
        else if (type == Schema.DisplayType.Integer)
            return Integer.ValueOf(value) == Integer.valueOf(valueToCompare);
        else if (type == Schema.DisplayType.Currency)
            return Decimal.ValueOf(value) == valueToCompare;
        else if (type == Schema.DisplayType.Double)
            return Double.ValueOf(value) == valueToCompare;
        
        return false;
    }



    //Needs to be deprecated
    global static List<ActionResponse> updateBulkJobsFromFile(List<String> jobscsv) {

        return null;
    }

    //PRIVATE METHODS

    private static List<JobAttempt__c> InsertNewAttempts(List<Job__c> jobs, Date scheduledDate, string attemptReason) {

        system.debug('InsertNewAttempts' + jobs);
        
        List<JobAttempt__c> newAttempts = new List<JobAttempt__c>();

        for (Job__c job : jobs) {
            JobAttempt__c nja = new JobAttempt__c();
            nja.Job__c = job.Id;
            if (job.TotalJobAttempts__c > 0) {
                nja.AttemptType__c = 'Re-Attempt';
            } else {
                nja.AttemptType__c = 'Original';
            }
            nja.AttemptStatus__c = CONSTANTS.JOB_ATTEMPT_STATUS_OPEN;

            nja.IsActive__c = true;
            nja.AttemptSequence__c = (job.TotalJobAttempts__c == null ? 0 : job.TotalJobAttempts__c) + 1;
            nja.AttemptResponsibleExecutionCompany__c = job.AccountableExecutionCompany__r.Name;
            nja.AttemptReason__c = attemptReason;

            //#OH-4439
            ////
            nja.ExpectedNumberofWorkers__c = job.NumberOfWorkers__c;
            nja.StartTime__c = job.JobStartTime__c;
            nja.EndTime__c = job.JobEndTime__c;
            nja.ProjectLocation__c  = job.ProjectLocation__c;
            //

            if (job.ProjectScheduleOptionCode__c !=  CONSTANTS.SCHEDULE_OPTION_EC) {
                if (scheduledDate != null) {
                    nja.AttemptScheduleDate__c = scheduledDate;
                } else {
                    nja.AttemptScheduleDate__c = job.JobScheduledDate__c;
                }

                nja.AttemptScheduledDate__c = DateTime.now();
            }
            if (job.KeepAssignment__c && job.ActiveJobAttempt__c != null &&
                    job.ActiveJobAttempt__r.AssignedContactId__c != null) {
                nja.AssignedContactId__c = job.ActiveJobAttempt__r.AssignedContactId__c;

            }

            newAttempts.Add(nja);
        }

        return newAttempts;
    }

    private static List<JobAttempt__c>  UpdateOldActiveAttemptsOnNewAttemptCreation(List<JobAttempt__c> oldactiveAttempts) {

        for (JobAttempt__c oaja : oldactiveAttempts ) {
            oaja.IsActive__c = false;

            if (oaja.AttemptStatus__c == CONSTANTS.JOB_ATTEMPT_STATUS_OPEN || oaja.AttemptStatus__c == CONSTANTS.JOB_ATTEMPT_STATUS_ASSIGNED ||
                    oaja.AttemptStatus__c == CONSTANTS.JOB_ATTEMPT_STATUS_STARTED ) {
                oaja.AttemptStatus__c = CONSTANTS.JOB_ATTEMPT_STATUS_CANCELED;
                oaja.DateCanceled__c = DateTime.Now();
            } else if (oaja.AttemptStatus__c == CONSTANTS.JOB_ATTEMPT_STATUS_REPORTED) {
                oaja.AttemptStatus__c = CONSTANTS.JOB_ATTEMPT_STATUS_CLOSED;
                oaja.DateClosed__c = DateTime.Now();

            }
        }

        return oldactiveAttempts;
    }

    private static List<JobAttempt__c> UpdateJobAttemptsOnJobCancel(List<JobAttempt__c> jobAttempts) {


        for (JobAttempt__c ja : jobAttempts) {
            if (ja.attemptstatus__c == CONSTANTS.JOB_ATTEMPT_STATUS_OPEN || ja.attemptstatus__c == CONSTANTS.JOB_ATTEMPT_STATUS_ASSIGNED || ja.attemptstatus__c == CONSTANTS.JOB_ATTEMPT_STATUS_STARTED) {
                ja.attemptstatus__c = CONSTANTS.JOB_ATTEMPT_STATUS_CANCELED;
                ja.datecanceled__c = DateTime.Now();
            } else if (ja.attemptstatus__c == CONSTANTS.JOB_ATTEMPT_STATUS_REPORTED) {
                ja.attemptstatus__c = CONSTANTS.JOB_ATTEMPT_STATUS_CLOSED;
                ja.dateclosed__c = DateTime.Now();

            }
        }

        return jobAttempts;

    }

    private static void CancelWorkersOnJobAttemptCancel(List<JobAttemptWorker__c> jobAttemptWorkers) {


        for (JobAttemptWorker__c jaw : jobAttemptWorkers) {
            jaw.Status__c = CONSTANTS.JOB_ATTEMPT_WORKER_STATUS_CANCELED;
        }

        update jobAttemptWorkers;
    }


    private static Integer getCreateAttemptSize() {
        List<OrgCustomSettings__c> settings = [SELECT CreateAttemptSize__c FROM OrgCustomSettings__c LIMIT 1];
        if (settings == null || settings.size() == 0 || settings[0] == null || settings[0].CreateAttemptSize__c == null) {
            return 1000;
        }
        return integer.valueOf(settings[0].CreateAttemptSize__c);
    }



}