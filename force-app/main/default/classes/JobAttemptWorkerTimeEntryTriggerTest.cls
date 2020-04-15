@isTest
private class JobAttemptWorkerTimeEntryTriggerTest {
        
    @testSetup 
    static void setup() 
    {
        TestUtil.initBaseData();
        JobAttempt__c attempt = TestUtil.setupJobTestData(CONSTANTS.JOB_ATTEMPT_STATUS_OPEN, CONSTANTS.JOB_STATUS_PENDING);
        TestUtil.generateJobAttemptWorkers(attempt, 3);
        
    }
    
    @isTest
    static void testTimeEntriesforJobWorker ()
    {
    	List<JobAttemptWorker__c> jaws = [Select Id, CheckinTimeEntry__c, CheckoutTimeEntry__c from JobAttemptWorker__c LIMIT 1];
        System.assert(jaws.size() > 0, 'No job attempt workers found');
        
        System.assert(jaws[0].CheckinTimeEntry__c == null);
        System.assert(jaws[0].CheckoutTimeEntry__c == null);
        
        //Insert a checkin time entry
        TestUtil.createJobAttemptWorkerTimeEntry(jaws[0], 'Check in');
        TestUtil.createJobAttemptWorkerTimeEntry(jaws[0], 'Check out');
        

    	List<JobAttemptWorkerTimeEntry__c> jawtes = [Select Id, TimeEntryType__c, StartTime__c from JobAttemptWorkerTimeEntry__c];
        System.assert(jawtes.size() > 0, 'No time entries found for the job attempt worker');
        

    	List<JobAttemptWorker__c> jaws2 = [Select Id, CheckinTimeEntry__c, CheckoutTimeEntry__c, TotalInStoreTime__c from JobAttemptWorker__c WHERE Id = :jaws[0].Id];
        System.assert(jaws2.size() > 0, 'No job attempt workers found');
		        
        System.assert(jaws2[0].CheckinTimeEntry__c != null);
        System.assert(jaws2[0].CheckoutTimeEntry__c != null);
        
        
        
    }	    

}