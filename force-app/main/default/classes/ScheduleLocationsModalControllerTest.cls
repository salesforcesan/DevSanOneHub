@isTest
private class ScheduleLocationsModalControllerTest {
    static testMethod void test_validateReserve_MD() {
        
        Project__c project = TestUtil.generateFullTestProject(ProjectType.MD, Date.today().addDays(10), Date.today().addDays(20));
      
        
        PageReference vfPage = Page.ScheduleLocationsModal;
        Test.setCurrentPage(vfPage);
        System.currentPageReference().getParameters().put('projectid', project.Id);
        ScheduleLocationsModalController modalController = new ScheduleLocationsModalController();
        
        modalController.submitSchedulingBatchJob();
        List<Job__c> jobs = [SELECT Id FROM Job__c WHERE Project__c =: project.Id];
        //System.assertNotEquals(jobs.size(), 0);
        
    }
    
    static testMethod void test_batchjob() {
        
        Project__c project = TestUtil.generateFullTestProject(ProjectType.MD, Date.today().addDays(10), Date.today().addDays(20));
        
       
        
        PageReference vfPage = Page.ScheduleLocationsModal;
        Test.setCurrentPage(vfPage);
        System.currentPageReference().getParameters().put('projectid', project.Id);
        ScheduleLocationsModalController modalController = new ScheduleLocationsModalController();
        
        Test.startTest();
        modalController.submitSchedulingBatchJob();
        Test.stopTest();
        
        List<Job__c> jobs = [SELECT Id FROM Job__c WHERE Project__c =: project.Id];
        System.assertNotEquals(jobs.size(), 0);
        
    }
}