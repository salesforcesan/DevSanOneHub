@isTest
public class CreateEditProjectExtTest {
    
    public static testMethod void test_editProject()
    {
        Project__c project = TestUtil.generateFullTestProject(ProjectType.MD, Date.today().addDays(10), Date.today().addDays(20));
        PageReference aPage = Page.ProjectTypeSelectView;       
        Test.setCurrentPage(aPage);
        ApexPages.currentPage().getParameters().put('Id', project.Id);
        ApexPages.StandardController controller = new ApexPages.StandardController(project);        
        CreateEditProjectExt projextExtCtrl = new CreateEditProjectExt(controller);
        system.assert(projextExtCtrl!= null);
        project.Name = 'Test Name';
        //projextExtCtrl.newTags = 'aaa,bbbb';
        system.debug('projextExtCtrl:::'+projextExtCtrl);
        String redirectUrl = projextExtCtrl.save().getUrl();
        system.debug('redirectpage:'+redirectUrl);
        system.assertEquals(new PageReference('/apex/projectdetailsview?id=' + project.Id).getUrl().toLowerCase(), redirectUrl.toLowerCase());
        
        PageReference pageRef = projextExtCtrl.redirect();
        //system.assertNotEquals(null, pageRef);
	}
    
    public static testMethod void test_next()
    {
        // Project__c project = TestUtil.generateSingleProject('Test Project',Date.today(),Date.today().addDays(2));
        TestUtil.initBaseData();
        Project__c project = new Project__c();        
        PageReference aPage = Page.ProjectTypeSelectView;       
        Test.setCurrentPage(aPage);
        
        ApexPages.StandardController controller = new ApexPages.StandardController(project);        
        CreateEditProjectExt ext= new CreateEditProjectExt(controller);
        
        system.assert(ext!= null);
        //List <ProjectType__c > projectTypes=TestUtil.generateProjectTypes(1);
        List <ProjectType__c> projectTypes  = [SELECT Id FROM ProjectType__c];
        List <SelectOption> projectTypesOpptions=ext.getProjectTypes();
        system.assert(projectTypesOpptions.size() >= 1);
        project.ProjectType__c=projectTypes.get(0).Id;
        String redirectUrl = ext.next().getUrl();
        system.debug('redirectUrl:'+redirectUrl);
        system.assertEquals(new PageReference('/apex/projectaddeditview').getUrl().toLowerCase(), redirectUrl.toLowerCase());
        
        
    }    
}