@isTest
public class BatchUpdateJobsTest {
	static testMethod void test_submitSchedulingBatchJob() {    
        Project__c project = TestUtil.generateProjectwithJobs(ProjectType.MD, Date.today().addDays(10), Date.today().addDays(20));
        
        
        /*
        Test.startTest();
        string query = 'SELECT Id FROM Job__c' ;
        List<Job__c> jobs = [SELECT Id, ExecutionCompany__c ExecutionCompany__c		 FROM Job__c];
        System.assertEquals(1, jobs.size());
        system.debug('jobs.size()'+jobs.size());
    	BatchUpdateJobs batchJobs = new BatchUpdateJobs(query);
    	Database.ExecuteBatch(batchJobs, 2000);
        Test.stopTest();
        
        jobs = [SELECT Id FROM Job__c];
        System.assertEquals(0, jobs.size());
        */
    }
}