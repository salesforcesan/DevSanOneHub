public class JobAttemptHelper {
          
    public static void validateOverlap(JobAttempt__c current, 
                                       JobAttempt__c old,
                                       List<JobAttemptWorkerTimeEntryWrapper> jobAttemptWorkerTimeEntries,
                                       Map<ID,Contact> contacts){
                
        // Validate only when the status is changed to reported.
        if (current.AttemptStatus__c == CONSTANTS.JOB_ATTEMPT_STATUS_REPORTED && current.AttemptStatus__c != old.AttemptStatus__c){
            
            
            for(JobAttemptWorkerTimeEntryWrapper jobAttemptWorkerTimeEntry : jobAttemptWorkerTimeEntries)
            {                                    
                Contact vContact = new Contact();
                vContact = contacts.get(jobAttemptWorkerTimeEntry.ContactId);
                
                if (vContact.MaxCheckOutTime__c >= jobAttemptWorkerTimeEntry.StartTime)
                {                    
                    current.addError('Shift not closed. ' + vContact.FirstName + ' ' + vContact.LastName + ' has check in / check out overlap');
                }
            }
        }
    }  
    
    public static void validatePreviousOpenShifts(JobAttempt__c current, JobAttempt__c old, Job__c job){

        // When job attempt status change to reported
        if ((old.AttemptStatus__c != current.AttemptStatus__c) && (current.AttemptStatus__c == CONSTANTS.JOB_ATTEMPT_STATUS_REPORTED)){
            

                List<JobAttempt__c> jobAttempts = [SELECT Id,Name FROM JobAttempt__c 
                                                   WHERE Job__r.Project__r.ID = :job.Project__r.ID 
                                                   AND Job__r.Location__r.Id = :job.Location__r.ID
                                                   AND Job__r.IsShift__c = true 
                                                   AND (AttemptScheduleDate__c < :current.AttemptScheduleDate__c OR 
                                                        (AttemptScheduleDate__c =: current.AttemptScheduleDate__c 
                                                         AND Job__r.ProjectService__r.ServiceRank__c < :job.ProjectService__r.ServiceRank__c)
                                                       )
                                                   AND AttemptStatus__c != :CONSTANTS.JOB_ATTEMPT_STATUS_CANCELED
                                                   AND AttemptStatus__c != :CONSTANTS.JOB_ATTEMPT_STATUS_CLOSED
                                                   AND AttemptScheduleDate__c != null            
                                                  ];
                
                if (jobAttempts.size() > 0){
                    current.AttemptStatus__c.addError('Please close the previous open jobs.');
                }            
        }
    }   
    
    public static void validatePreviousOpenShifts(JobAttempt__c current, Job__c job,List<JobAttempt__c> jobAttempts){
        boolean isJobsOpen = false;
        system.debug('validatePreviousOpenShifts' + jobAttempts);
        system.debug('jobServiceRank__c' + job.ProjectService__r.ServiceRank__c);
        
        for(JobAttempt__c jobAttempt : jobAttempts) {
            if ((jobAttempt.ID != current.ID) &&
                (jobAttempt.ProjectLocation__c == current.ProjectLocation__c) &&               
                //(jobAttempt.AttemptScheduleDate__c < current.AttemptScheduleDate__c) //&&                    
                ((jobAttempt.AttemptScheduleDate__c < current.AttemptScheduleDate__c) || 
                (jobAttempt.AttemptScheduleDate__c == current.AttemptScheduleDate__c &&  jobAttempt.Job__r.ProjectService__r.ServiceRank__c < job.ProjectService__r.ServiceRank__c))
               )
            {                    
                
                system.debug('jobAttempt.Job__r.ProjectService__r.ServiceRank__c' + jobAttempt.Job__r.ProjectService__r.ServiceRank__c + ':::' + job.ProjectService__r.ServiceRank__c);
                isJobsOpen = true;
                break;
            }
        }
        
        if (isJobsOpen){
            current.AttemptStatus__c.addError('Please close the previous open jobs.');
        }   
        
    } 
    
    public static Set<String> GetContactIdsForJobAttempts(Set<ID> jobAttemptIds, Set<String> timeEntryType){
        Set<String> contactIds = new Set<String>();
        
        for (JobAttemptWorkerTimeEntry__c jobAttemptWorkerTimeEntry : [SELECT Name, Id, StartTime__c,TimeEntryType__c, JobAttemptWorker__c, JobAttemptWorker__r.Contact__c, JobAttemptWorker__r.JobAttempt__c ,Duration__c,IsBillable__c, TeamLeadUserId__c  
                                                                       FROM JobAttemptWorkerTimeEntry__c 
                                                                       WHERE JobAttemptWorker__r.JobAttempt__c in :jobAttemptIds                                                                       
                                                                       AND TimeEntryType__c in :timeEntryType
                                                                      ])
        {
            
            // To collect contactId's
            contactIds.add(jobAttemptWorkerTimeEntry.JobAttemptWorker__r.Contact__c);                                                                          
            
        }
        
        return contactIds;
    }
    
    public static MAP<ID,Contact> GetContactMap(Set<String> contactIdSet)
    {
		MAP<ID,Contact> contactMap = new MAP<ID,Contact>();
        
        for (Contact c: [SELECT Id, LastName, FirstName , MaxCheckInTime__c, MaxCheckOutTime__c FROM CONTACT WHERE ID IN :contactIdSet])
        {
            contactMap.put(c.Id, c);
        }
        
        return contactMap;
    }
    
    public static MAP<ID,List<JobAttemptWorkerTimeEntryWrapper>> GetTimeEntryMap(Set<ID> jobAttemptIds, Set<String> timeEntryType){
    
        MAP<ID,List<JobAttemptWorkerTimeEntryWrapper>> jobAttemptTimeEntryWrapperMap = new MAP<ID,List<JobAttemptWorkerTimeEntryWrapper>>();
        
        for (JobAttemptWorkerTimeEntry__c jobAttemptWorkerTimeEntry : [SELECT Name, Id, StartTime__c,TimeEntryType__c, JobAttemptWorker__c, JobAttemptWorker__r.Contact__c, JobAttemptWorker__r.JobAttempt__c ,Duration__c,IsBillable__c, TeamLeadUserId__c  
                                                                       FROM JobAttemptWorkerTimeEntry__c 
                                                                       WHERE JobAttemptWorker__r.JobAttempt__c in :jobAttemptIds                                                                       
                                                                       AND TimeEntryType__c in :timeEntryType
                                                                      ])
        {                                                                          
            
            //To collect job attempt time entry per job attempt
            if (jobAttemptTimeEntryWrapperMap.containskey(jobAttemptWorkerTimeEntry.JobAttemptWorker__r.JobAttempt__c)){
                
                List<JobAttemptWorkerTimeEntryWrapper> jobAttemptWorkerTimeEntrys =  jobAttemptTimeEntryWrapperMap.get(jobAttemptWorkerTimeEntry.JobAttemptWorker__r.JobAttempt__c);
                
                jobAttemptWorkerTimeEntrys.add(new JobAttemptWorkerTimeEntryWrapper(jobAttemptWorkerTimeEntry, jobAttemptWorkerTimeEntry.JobAttemptWorker__r.Contact__c));
                
                jobAttemptTimeEntryWrapperMap.put(jobAttemptWorkerTimeEntry.JobAttemptWorker__r.JobAttempt__c,jobAttemptWorkerTimeEntrys);
                
            }
            else
            {   
                List<JobAttemptWorkerTimeEntryWrapper> jobAttemptWorkerTimeEntrys = new List<JobAttemptWorkerTimeEntryWrapper>();
                
                jobAttemptWorkerTimeEntrys.add(new JobAttemptWorkerTimeEntryWrapper(jobAttemptWorkerTimeEntry, jobAttemptWorkerTimeEntry.JobAttemptWorker__r.Contact__c));
                
                jobAttemptTimeEntryWrapperMap.put(jobAttemptWorkerTimeEntry.JobAttemptWorker__r.JobAttempt__c,jobAttemptWorkerTimeEntrys);                                                                              
            }
        }
        return jobAttemptTimeEntryWrapperMap;
    }
    
    public static List<JobAttempt__c> GetJobAttemptForProjectLocation(Set<ID> projectLocationIds)
    {
        List<JobAttempt__c> result = [SELECT ID, ProjectLocation__c,Job__r.Project__r.ID,Job__r.Location__r.ID, AttemptStatus__c,AttemptScheduleDate__c,Job__r.ProjectService__r.ServiceRank__c FROM JobAttempt__c 
                                      WHERE ProjectLocation__c IN :projectLocationIds
                                      AND Job__r.IsShift__c = true 
                                      AND AttemptStatus__c NOT IN ('Reported','Canceled','Closed') 
                                      AND AttemptScheduleDate__c != null
                                     ];
        return result;
    }
 
	public static Map<String,Job__c> getJobs(Set<String> jobIdSet) {
        Map<String,Job__c> result = new Map<String,Job__c>();
        if (0 == jobIdSet.size()) {
            return result;
        }
            
        for(Job__c job: [SELECT Id,Project__r.ID ,Location__r.ID, ProjectService__r.ServiceRank__c ,IsShift__c, ShiftClosureOverride__c FROM Job__c WHERE Id IN :jobIdSet]) {
            result.put(job.Id, job);
        }
        return result;
    }
}