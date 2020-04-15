@isTest
public class ProjectServiceDetailsExtTest {
    public static testMethod void Test_controller()
    {
        Project__c project = TestUtil.generateFullTestProject(ProjectType.MD, System.today().addDays(60), System.today().addDays(70));
        ProjectService__c ps  = [SELECT Id FROM ProjectService__c LIMIT 1];
        ApexPages.currentPage().getParameters().put('Id', ps.Id);
        
        
        ApexPages.StandardController controller = new ApexPages.StandardController(ps);    
        ProjectServiceDetailsExt ctrl = new ProjectServiceDetailsExt(controller);  
        system.assertEquals(true, ctrl.showEditProjectServiceButton);
        
    }
}