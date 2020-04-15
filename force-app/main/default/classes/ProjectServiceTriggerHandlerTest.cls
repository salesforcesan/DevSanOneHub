@isTest
public class ProjectServiceTriggerHandlerTest {

    static testMethod void test_beforeUpdate() {
        Project__c project = TestUtil.generateFullTestProject(ProjectType.MD, Date.today().addDays(10), Date.today().addDays(20));
        Test.startTest();
        ProjectScheduler batch = new ProjectScheduler([SELECT Name, StartDate__c, EndDate__c, ProjectType__c, ProjectType__r.Name, Status__c FROM Project__c WHERE ID = :project.Id]);
        Database.executeBatch(batch);
        Test.stopTest();
        List<ProjectService__c> projServ = [SELECT Id, LastModifiedDate FROM ProjectService__c WHERE Project__c =: project.Id];
        //update assert
       
        TriggerUtil.SkipProjectServiceTrigger = false;
        update projServ;
    }
    /*
     static testMethod void test_afterInsert() {
        Project__c project = TestUtil.generateFullTestProject(ProjectType.MD, Date.today().addDays(10), Date.today().addDays(20));
        
         Test.startTest();
        ProjectScheduler batch = new ProjectScheduler([SELECT Name, StartDate__c, EndDate__c, ProjectType__c, ProjectType__r.Name, Status__c FROM Project__c WHERE ID = :project.Id]);
        Database.executeBatch(batch);
        Test.stopTest();
         
        List<ProjectService__c> ps = TestUtil.generateProjectServices(1,project.id);

    }*/
    
    static testMethod void test_beforeDelete() {
        Project__c project = TestUtil.generateFullTestProject(ProjectType.MD, Date.today().addDays(10), Date.today().addDays(20));
        
        Test.startTest();
        ProjectScheduler batch = new ProjectScheduler([SELECT Name, StartDate__c, EndDate__c, ProjectType__c, ProjectType__r.Name, Status__c FROM Project__c WHERE ID = :project.Id]);
        Database.executeBatch(batch);
        Test.stopTest();
        //projLocs[0].Status__c = 'Booked';
        //update projLocs;
        List<Job__c> jobs = [SELECT ID FROM Job__c WHERE Project__c = :project.Id];
        System.assert(jobs.size() > 0);
        List<ProjectService__c> projServ = [SELECT ID FROM ProjectService__c WHERE Project__c = :project.Id];
        TriggerUtil.SkipProjectServiceTrigger = false;
        delete projServ;
        jobs = [SELECT ID FROM Job__c WHERE Project__c = :project.Id];
        //System.assertEquals(jobs.size(), 0);
    }
}