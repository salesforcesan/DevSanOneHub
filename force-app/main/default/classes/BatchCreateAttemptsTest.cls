@isTest
public class BatchCreateAttemptsTest {
    public static testMethod void test_BatchCreateProjectAttempts(){
        Project__c project = TestUtil.generateProjectwithJobs(ProjectType.MD, Date.today().addDays(10), Date.today().addDays(20));
        
        Id[] ids = new Id[]{};
        Date scheduledDate;
        String attemptReason;
        
        ids.add(project.id);
       // scheduledDate = Date.today().addDays(12);
        attemptReason = 'Test';
        
       	Test.startTest();    
		BatchCreateAttempts batch = new BatchCreateAttempts(ids, scheduledDate, attemptReason);
		Database.executeBatch(batch);     
        Test.stopTest();
    }

    
    public static testMethod void test_BatchCreateJobAttempts(){
        Project__c project = TestUtil.generateProjectwithJobs(ProjectType.MD, Date.today().addDays(10), Date.today().addDays(20));
		Job__c job = [SELECT Id FROM Job__c WHERE Project__c = :project.Id LIMIT 1];
        
        Id[] ids = new Id[]{};
        Date scheduledDate;
        String attemptReason;
        
        ids.add(job.id);
      //  scheduledDate = Date.today().addDays(12);
        attemptReason = 'Test';
        
       	Test.startTest();    
		BatchCreateAttempts batch = new BatchCreateAttempts(ids, scheduledDate, attemptReason);
		Database.executeBatch(batch);     
        Test.stopTest();
    }    
}