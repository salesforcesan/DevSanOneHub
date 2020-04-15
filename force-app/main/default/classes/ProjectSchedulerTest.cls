@isTest
public class ProjectSchedulerTest {
    
    static testMethod void test_submitSchedulingBatchJob_MDStrategy() {
        Project__c project = TestUtil.generateFullTestProject(ProjectType.MD, System.today(), System.today().addDays(10));
        Test.startTest();
        ProjectScheduler batch = new ProjectScheduler([SELECT Name, StartDate__c, EndDate__c, ProjectType__c, ProjectType__r.Name, Status__c FROM Project__c WHERE ID = :project.Id]);
        Database.executeBatch(batch);
        Test.stopTest();
        
        List<ProjectLocation__c> projLocs = [SELECT Location__r.Name,status__c, Location__r.IsActive__c FROM ProjectLocation__c WHERE Project__c = :project.Id];
        //System.debug(projLocs.size());
        //System.assert(projLocs.get(0).StartDate__c != null);
    }
    
}