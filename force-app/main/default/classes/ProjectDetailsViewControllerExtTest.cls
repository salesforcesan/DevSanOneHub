@isTest
public class ProjectDetailsViewControllerExtTest {
    public static testMethod void genericTest(){ 
        Project__c project = TestUtil.generateFullTestProject(ProjectType.MD, System.today().addDays(60), System.today().addDays(70));
        
        ProjectLocation__c projLoc = [SELECT Id FROM ProjectLocation__c LIMIT 1];
        ApexPages.currentPage().getParameters().put('Id', project.Id);
        ApexPages.StandardController controller = new ApexPages.StandardController(project);        
        ProjectDetailsViewControllerExt ctrl = new ProjectDetailsViewControllerExt(controller); 
        ApexPages.currentPage().getParameters().put('projLocIds', projLoc.Id);
   /*     PageReference pageRef = ctrl.UnreserveLocations();	
        system.debug('pageRef.UnreserveLocations'+pageRef.getUrl());
        system.assertEquals(new PageReference('/apex/ProjectDetailsView?id=' + project.Id).getUrl(), pageRef.getUrl());
    //     pageRef = ctrl.unreserve();
    //    pageRef = ctrl.submitProject();
        system.assertEquals(new Pagereference('/apex/SubmitProject?id=' + project.Id).getUrl(), pageRef.getUrl());*/
        
    } 
}