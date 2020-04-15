@isTest
public class BatchReserveHandlerTest {
    static testMethod void test_submitSchedulingBatchJob() {
        Project__c p = TestUtil.generateFullTestProject(ProjectType.MD, Date.today().addDays(10), Date.today().addDays(20));
        Project__c project = [SELECT Name, StartDate__c, EndDate__c, ProjectType__c, Status__c, ProjectType__r.Name, BudgetedLocationsCount__c, LocationTotalCount__c  FROM Project__c WHERE ID = :p.id];
         
        TriggerUtil.skipProjectTrigger = true;
        
        update project; 
        
        Test.startTest();
        BatchReserveHandler batch = new BatchReserveHandler(project);
        Database.ExecuteBatch(batch, 500);
        Test.stopTest();
        
         List<Job__c> jobs = [SELECT Id FROM Job__c WHERE Project__c =: project.Id];
        System.assertNotEquals(jobs.size(), 0);
    }
}