@isTest
public class AppUtilTest {
    
    public static testMethod void test_All(){
        TriggerUtil.SkipAllTriggers();
        Project__c project = TestUtil.generateFullTestProject(ProjectType.MD, Date.today().addDays(10), Date.today().addDays(20));
        
        Test.startTest();
        ProjectScheduler batch = new ProjectScheduler([SELECT Id,Name, StartDate__c, EndDate__c, ProjectType__c,  ProjectType__r.Name, Status__c, BookBudgetedOnly__c FROM Project__c WHERE ID = :project.Id]);
        Database.executeBatch(batch);
        Test.stopTest();
        /*
        Boolean hasReserved = AppUtil.projectHasReserved(project);
        system.assertEquals(hasReserved, true);
        */
        project = [Select Id, UpdateSequence__c, Status__c from Project__c where Id =: project.Id];
        project.Status__c = 'Booked';
        update project;
        Decimal prevVersion = project.UpdateSequence__c;
        Set<id> projectIds = new Set<id>();
        projectIds.add(project.Id);
        AppUtil.UpdateProjectVersion(projectIds);
        project = [Select Id, UpdateSequence__c, Status__c from Project__c where Id =: project.Id];
        Decimal newVersion = project.UpdateSequence__c;
        
        //system.assertNotEquals(prevVersion, newVersion);
        
        Boolean hasLeadTime = AppUtil.hasProjectLeadTimeByProjectId(project.Id);
        system.assert(hasLeadTime != null);
        
        List<Retailer__c> retailers = AppUtil.getProfileRetailers();
        system.assert(retailers.size() > 0);
        
        
        Integer mcv = AppUtil.GetMaxContactVersion();
        system.assert(mcv != null);
        
        Boolean isloadTime = Apputil.isScheduledWithLoadTime(project.Id);
        system.assert(isloadTime != null);
        
        Boolean isLocked = Apputil.isProjectLocked(project);
        system.assert(isLocked != null);

        
    }

}