@isTest
private class ManageJobLocationsBtnCtrlTest {
   /* 
    @isTest 
    static void testnavigateToManageJobLocations() {
        Project__c project = TestUtil.generateFullTestProject(ProjectType.MD, System.today(), System.today().addDays(10));
        Test.startTest();
            list<Project__c> lstprojects = new list<Project__c>();
            lstprojects.add(project);
            PageReference pageRef = Page.ManageJobLocationsBtn;
            Test.setCurrentPage(pageRef);
            // Add parameters to page URL
            ApexPages.currentPage().getParameters().put('id', project.Id);
            ManageJobLocationsBtnCtrl controller = new ManageJobLocationsBtnCtrl(new ApexPages.StandardSetController(lstprojects));
            pagereference pagereferenceurl = controller.navigateToManageJobLocations();
            system.assert(pagereferenceurl != null);
        Test.stopTest();
    }

    @isTest 
    static void testnavigateToJobLocations() {
        Project__c project = TestUtil.generateFullTestProject(ProjectType.MD, System.today(), System.today().addDays(10));
        Test.startTest();
            list<Project__c> lstprojects = new list<Project__c>();
            lstprojects.add(project);
            PageReference pageRef = Page.ManageJobsLocationsFromJobBtn;
            Test.setCurrentPage(pageRef);
            // Add parameters to page URL
            ApexPages.currentPage().getParameters().put('id', project.Id);
            ManageJobLocationsBtnCtrl controller = new ManageJobLocationsBtnCtrl(new ApexPages.StandardSetController(lstprojects));
            pagereference pagereferenceurl = controller.navigateToJobLocations();
            system.assert(pagereferenceurl != null);
        Test.stopTest();
    }

   

    @isTest 
    static void testnavigateToUploadLocations() {
        Project__c project = TestUtil.generateFullTestProject(ProjectType.MD, System.today(), System.today().addDays(10));
        Test.startTest();
            list<Project__c> lstprojects = new list<Project__c>();
            lstprojects.add(project);
            PageReference pageRef = Page.UploadLocationsBtn;
            Test.setCurrentPage(pageRef);
            // Add parameters to page URL
            ApexPages.currentPage().getParameters().put('id', project.Id);
            ManageJobLocationsBtnCtrl controller = new ManageJobLocationsBtnCtrl(new ApexPages.StandardSetController(lstprojects));
            pagereference pagereferenceurl = controller.navigateToUploadLocations();
            system.assert(pagereferenceurl != null);
        Test.stopTest();
    }
    */
}