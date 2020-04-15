//#OH-4439
public class JobAttemptWorkerHelper {
    public static void Create(List<JobAttempt__c> jobAttempts) {
        
        List<JobAttempt__c> jas = [Select Id, Job__r.AccountableExecutionCompany__c, ExpectedNumberofWorkers__c from JobAttempt__c where Id in :jobAttempts];
        Map<Id, JobAttempt__c> jaMap = new Map<Id, JobAttempt__c>(jas);
        
        List<JobAttemptWorker__c> jobAttemptWorkers = new List<JobAttemptWorker__c>();
        Map<ID,JobAttempt__c> jobAttemptMap = new Map<ID,JobAttempt__c>();           
            
        for (JobAttempt__c jobAttempt : jobAttempts)
        {            
            jobAttempt = jaMap.get(jobAttempt.Id);                
                
            for(Integer i=0; i < jobAttempt.ExpectedNumberofWorkers__c; i++){
                
                jobAttemptMap.put(jobAttempt.Id, jobAttempt);
                    
                JobAttemptWorker__c jobAttemptWorker = new JobAttemptWorker__c();
                jobAttemptWorker.JobAttempt__c = jobAttempt.Id;  
                jobAttemptWorker.ExecutionCompany__c = jobAttempt.Job__r.AccountableExecutionCompany__c;
                jobAttemptWorker.WorkerType__c = (i == 0) ? CONSTANTS.JOB_ATTEMPT_WORKER_WORKER_TYPE_TEAM_LEAD : CONSTANTS.JOB_ATTEMPT_WORKER_WORKER_TYPE_TEAM_MEMBER;
                jobAttemptWorker.Status__c = CONSTANTS.JOB_ATTEMPT_WORKER_STATUS_OPEN;
                jobAttemptWorkers.add(jobAttemptWorker);
            }
        }
        
        insert jobAttemptWorkers;
        
        List<JobAttempt__c> jobAttemptWithPrimaryWorkerLists = new List<JobAttempt__c>();
        
        for (JobAttemptWorker__c jobAttemptWorker: jobAttemptWorkers)        
        {            
            if (jobAttemptWorker.WorkerType__c == CONSTANTS.JOB_ATTEMPT_WORKER_WORKER_TYPE_TEAM_LEAD )
            {          
                JobAttempt__c jobAttempt = jobAttemptMap.get(jobAttemptWorker.JobAttempt__c);                    
                jobAttempt.PrimaryJobAttemptWorker__c = jobAttemptWorker.Id;
                jobAttemptWithPrimaryWorkerLists.add(jobAttempt);
            }
        }       
        
        update jobAttemptWithPrimaryWorkerLists;
        
    }
   
    public static void AdjustJobAttemptWorker(JobAttempt__c jobAttempt,Integer previousNumberOfWorkers,Integer currentNumberOfWorkers)
    {
        
        // In case of increased number.
        if (previousNumberOfWorkers < currentNumberOfWorkers){
            AddJobAttemptWorker(jobAttempt ,(currentNumberOfWorkers - previousNumberOfWorkers));
        } else if (previousNumberOfWorkers > currentNumberOfWorkers){
            CancelJobAttemptWorker(jobAttempt ,(previousNumberOfWorkers - currentNumberOfWorkers));
        }
    }
    
   static void AddJobAttemptWorker(JobAttempt__c jobAttempt, Integer noOfWorkersToBeAdded){
        
        List<JobAttemptWorker__c> jobAttemptWorkers = new List<JobAttemptWorker__c>();
        
        for(Integer i=0; i < noOfWorkersToBeAdded; i++){
            JobAttemptWorker__c jobAttemptWorker = new JobAttemptWorker__c();
            jobAttemptWorker.JobAttempt__c = jobAttempt.Id;                            
            jobAttemptWorker.WorkerType__c = CONSTANTS.JOB_ATTEMPT_WORKER_WORKER_TYPE_TEAM_MEMBER;
            jobAttemptWorker.Status__c = CONSTANTS.JOB_ATTEMPT_WORKER_STATUS_OPEN;
            jobAttemptWorkers.add(jobAttemptWorker);
        }  
        
        insert jobAttemptWorkers;
    }
    
   static void CancelJobAttemptWorker(JobAttempt__c jobAttempt, Integer noOfWorkersToBeAdjusted){
                
        List<JobAttemptWorker__c> jobAttemptWorkers =[SELECT Id, Status__c FROM JobAttemptWorker__c 
                                                      	WHERE JobAttempt__c =: jobAttempt.Id 
                                                      	AND WorkerType__c != :CONSTANTS.JOB_ATTEMPT_WORKER_WORKER_TYPE_TEAM_LEAD 
                                                      	AND Status__c != :CONSTANTS.JOB_ATTEMPT_WORKER_STATUS_CANCELED 
                                                      	ORDER BY DateAssigned__c DESC
                                                     	LIMIT :noOfWorkersToBeAdjusted];
        
        for (JobAttemptWorker__c jobAttemptWorker: jobAttemptWorkers){
            jobAttemptWorker.Status__c = CONSTANTS.JOB_ATTEMPT_WORKER_STATUS_CANCELED;
        }
        
        update jobAttemptWorkers;
    }
    
    
    /*
     public static JobAttemptWorker__c getJobAttemptWorker(Id jobAttemptId)
     {
           return Database.query(
            TestUtil.genQuery('JobAttemptWorker__c') + ' WHERE JobAttempt__c=:jobAttemptId Limit 1'
            );
     
     }    
    */
    
    //sankar added
    // approvalStatus : Approve or Reject
    public static void CancelPending3PLRequest(List<string> jawList)    	
    {
        
        List<ProcessInstance> piList  = [SELECT Id, TargetObject.Name, TargetObjectId, Status, SubmittedById, CompletedDate, CreatedDate 
                                         FROM ProcessInstance 
                                         Where TargetObjectId in : jawList];
        
        ApprovePending3PLRequest(jawList,'Reassigned to CMK',CONSTANTS.APPROVAL_STATUS_REMOVED);
        
    }
    
    
    public static List<JobAttemptWorker__c> Get3PLAgencyPendingApprovalList(){
        
        //Set<ID> jwIdList = [select ProcessInstance.TargetObjectId from ProcessInstanceWorkitem where ProcessInstance.TargetObject.type = 'JobAttemptWorker__c'];
        Set<ID> jwIdList = new Set<ID>();
        
        List<ProcessInstanceWorkitem> instanceWorker = [Select ProcessInstance.TargetObjectId From ProcessInstanceWorkitem 
                                                        where ProcessInstance.TargetObject.type =: CONSTANTS.CURRENTNAMESPACEPREFIX + 'JobAttemptWorker__c'];
        for(ProcessInstanceWorkitem pi : instanceWorker)
        {
            jwIdList.add(pi.ProcessInstance.TargetObjectId);
        }
        
        List<JobAttemptWorker__c> jawList = [Select Id, Name,ScheduledDate__c, LocationName__c, LocationNumber__c, LocationCity__c, LocationState__c, EstimatedMinutes__c 
                                             From JobAttemptWorker__c 
                                             Where ThirdPartyAgencyStatus__c =:CONSTANTS.JOB_ATTEMPT_WORKER_3PL_STATUS_PENDING_3PL_AGENCY_APPROVAL
                                             AND My3PLWork__c = true                                             
                                             And Id in : jwIdList];
        
        return jawList;
    }
    
    // approvalStatus : Approve or Reject or Removed
    public static void ApprovePending3PLRequest(List<string> jawList, String reqComments, string approverReqStatus)    	
    {
        
        List<ProcessInstance> piList  = [SELECT Id, TargetObject.Name, TargetObjectId, Status, SubmittedById, CompletedDate, CreatedDate 
                                         FROM ProcessInstance 
                                         Where TargetObjectId in : jawList];
        
        Set<Id> reservationIds = new Set<Id>();
        Set<Id> processInstanceIds = new Set<Id>();
        
        for(ProcessInstance obj: piList){            
            processInstanceIds.add(obj.TargetObjectId);                                    
        }
        
        //Getting Work Item Id
        List<ProcessInstanceWorkitem> pItemList = [Select Id from ProcessInstanceWorkitem 
                                                   where ProcessInstance.TargetObjectId in: processInstanceIds];
        
        for(ProcessInstanceWorkitem pItem: pItemList){  
            if (pItemList != null && pItemList.size() > 0)
            {
                
                Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
                req.setComments(reqComments);
                
                //Approve / Reject / Removed Record
                req.setAction(approverReqStatus);            
                
                req.setWorkitemId(pItem.Id);
                
                // Submit the request for approval
                Approval.ProcessResult result = Approval.process(req);
            }  
        }
    }  
    //end sankar
}