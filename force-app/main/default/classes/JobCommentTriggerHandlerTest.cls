@isTest
public class JobCommentTriggerHandlerTest {
    
    @testSetup static void setup(){
        TriggerUtil.skipAllTriggers();
        TestDataUtil.init();
        TestDataUtil.initImageServiceSettings();
        TestProject.create('demo').addAll();
       
    }
    
    public static testMethod void Test_beforeInsert(){
        
        Project__c project = TestProject.getProjects().get(0);
        JobAttempt__c job = TestProject.getJobAttempts(project.Id).get(0);
        Test.startTest();   
        JobComment__c comment = new JobComment__c(
            Comment__c = 'Test Comment',
            JobAttempt__c = job.Id
        );
        insert comment;
        
        JobComment__c jcomment = [SELECT Id, Name,ProjectLocation__c,Project__c,Job__c FROM JobComment__c LIMIT 1];
      	system.assert(jcomment.Job__c != null );
        system.assert(jcomment.Project__c !=null );
        system.assert(jcomment.ProjectLocation__c !=null );
        
        Test.stopTest();
        
        
    }
    
}