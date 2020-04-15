public class JobAttemptWorkerTimeEntryTriggerHandler extends TriggerHandler {
    
    
    public override void afterInsert(){
        
        Set<String> jawids = new Set<String>();
		Map<String, JobAttemptWorkerTimeEntry__c> checkincheckoutTimeEntries = new Map<String, JobAttemptWorkerTimeEntry__c>();
            
        for(JobAttemptWorkerTimeEntry__c jawte : (List<JobAttemptWorkerTimeEntry__c>) Trigger.New)
        {
            if (jawte.TimeEntryType__c == Constants.JOB_ATTEMPT_WORKER_TIME_ENTRY_TIME_ENTRY_TYPE_CHECK_IN ||
               jawte.TimeEntryType__c == Constants.JOB_ATTEMPT_WORKER_TIME_ENTRY_TIME_ENTRY_TYPE_CHECK_OUT)
            {
            	jawids.add(jawte.JobAttemptWorker__c);
                checkincheckoutTimeEntries.put(jawte.JobAttemptWorker__c + '-' + jawte.TimeEntryType__c, jawte);
            }
            
            
        }
        
        if (checkincheckoutTimeEntries.size() > 0)
        {
            List<JobAttemptWorker__c> jaws = [Select Id, CheckinTimeEntry__c, CheckinTimeEntry__r.StartTime__c, 
                                              CheckoutTimeEntry__c, CheckoutTimeEntry__r.StartTime__c, TotalInStoreTime__c 
                                              FROM JobAttemptWorker__c WHERE Id in :jawids];
        	for (JobAttemptWorker__c jaw : jaws)
            {
                DateTime checkinTime, checkoutTime;
                
				if (checkincheckoutTimeEntries.get(jaw.Id + '-' + Constants.JOB_ATTEMPT_WORKER_TIME_ENTRY_TIME_ENTRY_TYPE_CHECK_IN) != null)
                {
                    jaw.CheckinTimeEntry__c = checkincheckoutTimeEntries.get(jaw.Id + '-' + Constants.JOB_ATTEMPT_WORKER_TIME_ENTRY_TIME_ENTRY_TYPE_CHECK_IN).Id;
                	checkinTime = checkincheckoutTimeEntries.get(jaw.Id + '-' + Constants.JOB_ATTEMPT_WORKER_TIME_ENTRY_TIME_ENTRY_TYPE_CHECK_IN).StartTime__c;
                }
                else
                {
                    checkinTime = jaw.CheckinTimeEntry__r.StartTime__c;
                }
                
				if (checkincheckoutTimeEntries.get(jaw.Id + '-' + Constants.JOB_ATTEMPT_WORKER_TIME_ENTRY_TIME_ENTRY_TYPE_CHECK_OUT) != null)
                {
                    jaw.CheckoutTimeEntry__c = checkincheckoutTimeEntries.get(jaw.Id + '-' + Constants.JOB_ATTEMPT_WORKER_TIME_ENTRY_TIME_ENTRY_TYPE_CHECK_OUT).Id;
                    checkoutTime = checkincheckoutTimeEntries.get(jaw.Id + '-' + Constants.JOB_ATTEMPT_WORKER_TIME_ENTRY_TIME_ENTRY_TYPE_CHECK_OUT).StartTime__c;
                }
                else
                {
                    checkoutTime = jaw.CheckoutTimeEntry__r.StartTime__c;
                }
                
                if (checkinTime != null && checkoutTime != null)
                {
                    jaw.TotalInStoreTime__c = CalculateTotalInstoreTimeInMinutes(checkinTime, checkoutTime);
                }

            }
			update jaws;            
            
        }
       
    }
    
    public override void afterUpdate(){

	    Set<String> jawids = new Set<String>();        
        for(JobAttemptWorkerTimeEntry__c jawte : (List<JobAttemptWorkerTimeEntry__c>) Trigger.New)
        {
            JobAttemptWorkerTimeEntry__c oldjawte = (JobAttemptWorkerTimeEntry__c) System.Trigger.oldMap.get(jawte.Id);
            if (oldjawte.StartTime__c != jawte.StartTime__c && (jawte.TimeEntryType__c == Constants.JOB_ATTEMPT_WORKER_TIME_ENTRY_TIME_ENTRY_TYPE_CHECK_IN 
                                                                || jawte.TimeEntryType__c == Constants.JOB_ATTEMPT_WORKER_TIME_ENTRY_TIME_ENTRY_TYPE_CHECK_OUT))
            {

	        	jawids.add(jawte.JobAttemptWorker__c);        
                
            }
            
            
            List<JobAttemptWorker__c> jaws = [Select Id, CheckinTimeEntry__c, CheckinTimeEntry__r.StartTime__c, 
                                              CheckoutTimeEntry__c, CheckoutTimeEntry__r.StartTime__c, TotalInStoreTime__c 
                                              FROM JobAttemptWorker__c WHERE Id in :jawids];
        	for (JobAttemptWorker__c jaw : jaws)
            {
                if (jaw.CheckinTimeEntry__c != null && jaw.CheckoutTimeEntry__c != null && 
                    jaw.CheckinTimeEntry__r.StartTime__c != null && jaw.CheckoutTimeEntry__r.StartTime__c != null)
                {
                	jaw.TotalInStoreTime__c = CalculateTotalInstoreTimeInMinutes(jaw.CheckinTimeEntry__r.StartTime__c,jaw.CheckoutTimeEntry__r.StartTime__c);    
                }
            }   
            
            update jaws;
        }
    }
    
    private Integer CalculateTotalInstoreTimeInMinutes(DateTime checkinTime, DateTime checkoutTime)
    {
        return Integer.valueOf((checkoutTime.getTime() - checkinTime.getTime())/60000);
    }
    

}