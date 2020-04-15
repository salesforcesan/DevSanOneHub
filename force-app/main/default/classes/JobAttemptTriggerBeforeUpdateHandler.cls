public with sharing class JobAttemptTriggerBeforeUpdateHandler implements ISobjectTriggerEventHandler {

//----<static methods and properties>----
    static ILogger DEBUG_LOGGER, DB_LOGGER;
    static final Map<String, Exception__c> EXCEPTION_CODES;
    static final Datetime CURRENT_DATETIME;
    static Set<String> entryTypeSet;
    
    static {
        DB_LOGGER = LoggerFactory.createLogger('JobAttemptTrigger', true);
        DEBUG_LOGGER = LoggerFactory.createLogger('JobAttemptTrigger', false);
        CURRENT_DATETIME = Datetime.now();
        EXCEPTION_CODES = new Map<String, Exception__c>();
        for(Exception__c e: [SELECT ExceptionCode__c, Name, Id FROM Exception__c]) {
            EXCEPTION_CODES.put(e.ExceptionCode__c, e);
        }
        
        entryTypeSet = new Set<String>{
            CONSTANTS.JOB_ATTEMPT_WORKER_TIME_ENTRY_TIME_ENTRY_TYPE_CHECK_IN, 
                CONSTANTS.JOB_ATTEMPT_WORKER_TIME_ENTRY_TIME_ENTRY_TYPE_CHECK_OUT
                };  
    }

//----<instance properties, constructor and factory method>----
    Map<ID, JobAttempt__c> newMap;
    Map<ID, JobAttempt__c> oldMap;
    Map<String, ID> contactMap;

    private JobAttemptTriggerBeforeUpdateHandler(Map<ID, JobAttempt__c> newMap, Map<ID, JobAttempt__c> oldMap) {
        this.newMap = newMap;
        this.oldMap = oldMap;
    }

    public static ISobjectTriggerEventHandler newInstance(Map<ID, JobAttempt__c> newMap, Map<ID, JobAttempt__c> oldMap) {
        return new JobAttemptTriggerBeforeUpdateHandler(newMap, oldMap);
    }

    public void execute() {
        DEBUG_LOGGER.debug('start of JobAttemptTriggerBeforeUpdateHandler');
        try {
            runBusinessLogics();
        }
        catch(Exception ex) {
            DB_LOGGER.error('beforeUpdate:' + ex.getLineNumber() + ';' + ex.getMessage());
        }

        try {
            DB_LOGGER.save();
        }
        catch(Exception ex) {
            DEBUG_LOGGER.error('beforeUpdate:' + ex.getLineNumber() + ';' + ex.getMessage());
        }

        DEBUG_LOGGER.debug('end of JobAttemptTriggerBeforeUpdateHandler');
        DEBUG_LOGGER.save();
    }

//----<scenario business logics>----
    private void runBusinessLogics() {
        String status;
        String previousstatus;
        JobAttempt__c old;
        List<JobAttempt__c> assignAttempts = new List<JobAttempt__c>();
        List<JobAttempt__c> reportAttempts = new List<JobAttempt__c>();
       
        for(JobAttempt__c current: newMap.values()) {
            old = oldMap.get(current.Id);
            if (false == old.IsActive__c) { continue; }

            handleScheduledDateBeforeUpdateLogic(current, old);
            
            //RN - Removed exception logic out of report attempts
            //as exceptions can happen before a job is reported
            //Example - Tasks in OneHub Mobile
            handleException(current, old);
            
            status = current.AttemptStatus__c;
            previousstatus = current.AttemptStatus__c;
            
            //RN - If previous status is closed, then make sure the status
            //is closed.
            if (CONSTANTS.JOB_ATTEMPT_STATUS_CLOSED.equalsIgnoreCase(previousstatus))
            {
                current.AttemptStatus__c = CONSTANTS.JOB_ATTEMPT_STATUS_CLOSED;
                continue;
            }
            
            
            if (CONSTANTS.JOB_ATTEMPT_STATUS_REPORTED.equalsIgnoreCase(status)) {
                reportAttempts.add(current);
                continue;
            } 
            //flush out report data if not in reported status
            flushReportRelatedData(current);

            if (CONSTANTS.JOB_ATTEMPT_STATUS_OPEN.equalsIgnoreCase(status)) {
                openJobAttemp(current, old);
                Continue;
            }
            if (CONSTANTS.JOB_ATTEMPT_STATUS_STARTED.equalsIgnoreCase(status)) {
                startJobAttempt(current, old);
                Continue;
            }
            if (CONSTANTS.JOB_ATTEMPT_STATUS_ASSIGNED.equalsIgnoreCase(status)) {
                assignAttempts.add(current);
                continue;
            }
           
        }
        initContactMap(assignAttempts, reportAttempts);
        assignJobAttempt(assignAttempts);
        reportJobAttempt(reportAttempts);
    }
    
    void handleException (JobAttempt__c current, JobAttempt__c old)
    {
        Exception__c exCode;
        String exceptionCode = current.ExceptionCode__c;
        if (String.isNotBlank(exceptionCode)) {
            exCode = getException(exceptionCode);
            if (exCode == null) {
                current.addError('The exception code:' + exceptionCode + ' is invalid.');
            }
            current.ExceptionReason__c = exCode.Name;
            current.Exception__c = exCode.Id;
        }
        else
        {
            current.ExceptionReason__c = '';
            current.Exception__c = null;
        }
    }

    void initContactMap(List<JobAttempt__c> assignAttempts, List<JobAttempt__c> reportAttempts) {
        
        Set<String> idSet = new Set<String>();
        if (assignAttempts.size() > 0) {
            idSet.addAll(SObjectListHelper.getStringSet(assignAttempts, 'AssignedContactId__c'));
        }
        if (reportAttempts.size() > 0){
            idSet.addAll(SObjectListHelper.getStringSet(reportAttempts, 'ReportedContactId__c'));
            idSet.addAll(SObjectListHelper.getStringSet(reportAttempts, 'AssignedContactId__c'));
        }
        contactMap = getContactMap(idSet);
    }

    static Map<String,ID> getContactMap(Set<String> contactIdSet) {
        Map<String,ID> result = new Map<String,ID>();
        if (0 == contactIdSet.size()) {
            return result;
        }
        for(Contact person: [SELECT Id, ContactId__c FROM CONTACT WHERE ContactId__c != '' AND ContactId__c IN :contactIdSet]) {
            result.put(person.ContactId__c, person.Id);
        }
        return result;
    }

//----<scenario: handle scheduleDate>----
    //OH220 handle schedule date logic
    //As a Product Owner, I want to define the rules for 
    //how the Job Schedule Date is set for a Job so that I have consistent functionality>
    void handleScheduledDateBeforeUpdateLogic(JobAttempt__c current, JobAttempt__c old){
        if (scheduleDataChanged(current, old)){
            current.AttemptScheduledDate__c = CURRENT_DATETIME;
            if (null != old.AttemptScheduleDate__c){
                current.NumberOfReschedules__c = parseInteger(old.NumberOfReschedules__c) + 1;
            }
        }
    }

    
    static Boolean scheduleDataChanged(JobAttempt__c current, JobAttempt__c old){
        return (null != current.AttemptScheduleDate__c && 
            current.AttemptScheduleDate__c != old.AttemptScheduleDate__c) ? true : false;
    }

    static Integer parseInteger(Object value) {
        return (null == value) ? 0 : Integer.valueOf(value);
    }

//----<scenario: open A job attempt>----
    //OH217: Remove Assignment on Job Attempt
    void openJobAttemp(JobAttempt__c current, JobAttempt__c old) {
               
        if (false == validateToReOpenJobAttempt(current, old)) {
            current.addError('A job attempt can be open only if it is assigned, started or open.');
            return;
        }
        current.AssignedContact__c = null;
        current.AssignedContactId__c = null;
        current.AttemptedDate__c = null;
        current.DateStarted__c = null;
        current.DateAssigned__c = null;
        current.DateReported__c = null;
        DEBUG_LOGGER.debug('job attempt status: Open');
    }


//----<scenario: start A job attempt>----
    //OH218 As a Product Owner, I want the Attempt Status set to STARTED when an Execution Company indicates 
    //that they have started working a Job so that I know that my Job has started as expected.
    void startJobAttempt(JobAttempt__c current, JobAttempt__c old) {
        //Only set the default time if date started is not
        //set by the execution company or 1HM
        if (current.DateStarted__c == null)
        {
        	current.DateStarted__c = CURRENT_DATETIME;    
        }
        
        DEBUG_LOGGER.debug('job attempt status: Started');
    }

//----<scenario: assign A job attempt>----
    //OH215: As a Product Owner, I want to set the status of an active attempt to ASSIGNED so 
    //that I know that a Job is currently staffed.

    void assignJobAttempt(List<JobAttempt__c> attempts) {
        JobAttempt__c old;
        if (0 == attempts.size()) {
            return;
        }

        for(JobAttempt__c current: attempts) {
            old = oldMap.get(current.Id);
            if (shouldSetAssignedDate(current, old)) {
                current.DateAssigned__c = CURRENT_DATETIME;
            }
            current.DateStarted__c = null;
            if(contactMap.size() > 0 && contactMap.containsKey(current.AssignedContactId__c)) {
                current.AssignedContact__c = contactMap.get(current.AssignedContactId__c);
            }
            
            //If the current assigned contact is not a valid contact
            //clear the assignment and set assignment to null;
            
            if (old.AssignedContactId__c != null && (contactMap.size() == 0 || 
                !contactMap.containsKey(current.AssignedContactId__c)))
            {
                current.AssignedContact__c = null;
            }
            //oh-735 clear report contact when in assigned status
            current.ReportedContact__c = null;
            
            DEBUG_LOGGER.debug('job attempt id:' + current.Id + ' status: Assigned');
        }
    }

    static Boolean shouldSetAssignedDate(JobAttempt__c current, JobAttempt__c old) {
        return (null != current.AssignedContactId__c &&
             current.AssignedContactId__c != old.AssignedContactId__c ) ? true : false;
    }

    static void flushReportRelatedData(JobAttempt__c current) {

        //Do not set DateReported to null if a value id already there.
        //even if the status moves from Reported to Assigned or something else
        //Only time Date Reported is set to null is when an attempt is open.
        
        //current.DateReported__c = null;
        current.ReportedContactId__c = null;
        current.ReportedContact__c = null;
        

        
    }

//----<scenario: report A job attempt>----
    //OH216: As a Product Owner, I want to the Job Attempt status set to REPORTED 
    //when an Execution Company reports an attempt so that I know that other actions should occure.
    void reportJobAttempt(List<JobAttempt__c> attempts) {
        String status;
        JobAttempt__c old;
        
        
       // Map<String, Boolean> serviceExceptions;
        Map<ID, Job__c> jobMap;
		jobMap = getJobs(attempts);
        
        
        if ( 0 == attempts.size() ) {
            return;
        }
        
		Set<ID> jobAttemptIds = new set<ID>(); 
       	Set<ID> projectLocationIds = new Set<ID>();
        
        //Get values only for one hub mobile jobs
        for (JobAttempt__c ja: attempts) {
            Job__c job = jobMap.get(ja.Job__c);
            if (job.IsShift__c){
            	jobAttemptIds.add(ja.ID);
                projectLocationIds.add(ja.ProjectLocation__c);
            }
        }
        
        // serviceExceptions = getServiceExeptions(jobMap.values());
        
        
        //OH-4636: Do not overpay for hours in overlapping Shifts
        // Gets job attempt workerTimeEntry for the current job attempts             
        MAP<ID,List<JobAttemptWorkerTimeEntryWrapper>> jobAttemptTimeEntryMap;         
        Set<String> contactIds;
        MAP<ID,Contact> contactMap;        
        
        List<JobAttempt__c> jobAttemptsForProjectLocations;
        
        //Get values only for one hub mobile jobs
        if (jobAttemptIds.size() > 0)
        {
            jobAttemptTimeEntryMap = JobAttemptHelper.GetTimeEntryMap(jobAttemptIds,entryTypeSet);
            contactIds = JobAttemptHelper.GetContactIdsForJobAttempts(jobAttemptIds,entryTypeSet);
            contactMap = JobAttemptHelper.GetContactMap(contactIds);     
                        
            jobAttemptsForProjectLocations = JobAttemptHelper.GetJobAttemptForProjectLocation(projectLocationIds);
        }

        for(JobAttempt__c current: attempts) {
            status = current.AttemptStatus__c;
            old = oldMap.get(current.Id);

            //1HM sets the datestarted from the app
            //set default date started only if the
            //value is not set
            if (current.DateStarted__c == null) {
                current.DateStarted__c = CURRENT_DATETIME;
            }
            //oh-2249;
            current.IsExecuted__c = true;

            //1HM sets the datereported from the app
            //set default date reported only if the
            //value is not set
            if (current.DateReported__c == null)
            {
            	current.DateReported__c = CURRENT_DATETIME;    
            }
            
            if (null == current.DateOriginallyReported__c) {
                current.DateOriginallyReported__c = current.DateReported__c;
            }
            handleContactIdWhenJobReported(current, old);
            
            system.debug('jobAttemptIds:::' + jobAttemptIds);

            if (jobAttemptIds.size() >0)
            {
                Job__c job = jobMap.get(current.Job__c);             
                
                //If the job has shift closure over ride true validation is not required
                if (job.IsShift__c && !boolean.valueOf(job.ShiftClosureOverride__c)){            
                    
                    system.debug('validatePreviousOpenShifts:::' + jobAttemptsForProjectLocations);
                    //JobAttemptHelper.validatePreviousOpenShifts(current, old, job);
                    JobAttemptHelper.validatePreviousOpenShifts(current, job, jobAttemptsForProjectLocations);
                                        
                    system.debug('validateOverlap:::' + jobAttemptTimeEntryMap.get(current.Id));
                    
                    //OH-4636: Do not overpay for hours in overlapping Shifts
                    JobAttemptHelper.validateOverlap(current, old,jobAttemptTimeEntryMap.get(current.Id),contactMap);
                    
                    
                }
            }
            
            //calculateExecutionStatus(current, jobMap, serviceExceptions);
            DEBUG_LOGGER.debug('job attempt id:' + current.Id + ' status: reported');
        }
    }    
     
    
    //OH-485: Date assigned, Date Originally assigned and Date Started 
    //are not updated/displayed for reported Job.

    void handleContactIdWhenJobReported(JobAttempt__c current, JobAttempt__c old) {
        if (0 == contactMap.size()) { return; }

        if (null != current.ReportedContactId__c && 
            current.ReportedContactId__c != old.ReportedContactId__c) {
            if (contactMap.containsKey(current.ReportedContactId__c)) {
                current.ReportedContact__c = contactMap.get(current.ReportedContactId__c);
            }
        } 
        if (shouldSetAssignedDate(current, old)) {
            if(contactMap.containsKey(current.AssignedContactId__c)) {
                current.AssignedContact__c = contactMap.get(current.AssignedContactId__c);
                current.DateAssigned__c = CURRENT_DATETIME;
                if (null == current.DateStarted__c) {
                    current.DateStarted__c = CURRENT_DATETIME;
                }
            }
        }
    }

    //OH261 Calculate Execution Status-
    //As a Product Owner, I want Execution Status to be set based upon the type of Job Exception 
    //or lack of an Exception so that I can measure my performance.
    void calculateExecutionStatus(JobAttempt__c attempt, Map<ID, Job__c> jobMap, Map<String, Boolean> serviceExceptions) {
        String key;
        Job__c job;
       
        if (null == attempt.Exception__c) {
            attempt.IsExecuted__c = true;
            return;
        } 

        job = jobMap.get(attempt.Job__c);
        if (null == job) { return; }

        key = genServiceExceptionKey(job.Service__c, attempt.Exception__c);
        if (true == serviceExceptions.containsKey(key) && 
            true == serviceExceptions.get(key)) {
            attempt.IsExecuted__c = true;
        } else {
            attempt.IsExecuted__c = false;
        }
    }

     static Boolean validateToReOpenJobAttempt(JobAttempt__c current, JobAttempt__c old) {
        String status = old.AttemptStatus__c;
         return (String.isBlank(status) || 
            CONSTANTS.JOB_ATTEMPT_STATUS_ASSIGNED.equalsIgnoreCase(status) || 
            CONSTANTS.JOB_ATTEMPT_STATUS_STARTED.equalsIgnoreCase(status) || 
            CONSTANTS.JOB_ATTEMPT_STATUS_OPEN.equalsIgnoreCase(status)) ? true : false;
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

    static Exception__c getException(String code) {        
        return (EXCEPTION_CODES.containsKey(code)) ? EXCEPTION_CODES.get(code) : null;
    }

    static String genServiceExceptionKey(ID serviceId, ID exceptionId) {
        return String.valueOf(serviceId) + ':' + String.valueOf(exceptionId);
    }

    static Map<String, Boolean> getServiceExeptions(List<Job__c> jobs) {
        Map<String, Boolean> result = new Map<String, Boolean>();
        Set<ID> idSet = new Set<ID>();
        if (0 == jobs.size()) { return result; }

        Set<ID> serviceSet = new Set<ID>();
        for(Job__c job: jobs) {
            serviceSet.add(job.Service__c);
        }

        for(ServiceException__c se : [SELECT Service__c, Exception__c, IsExecuted__c 
            FROM ServiceException__c WHERE Service__c IN :serviceSet]) {
            result.put(genServiceExceptionKey(se.Service__c,se.Exception__c), se.IsExecuted__c);
        }

        return result;
    }
}