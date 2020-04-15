@isTest
public class CancelJobTest {
    @testSetup static void setup(){
        TestUtil.initBaseData();
        TestUtil.setupJobTestData(CONSTANTS.JOB_ATTEMPT_STATUS_OPEN, 
            CONSTANTS.JOB_ATTEMPT_STATUS_OPEN);
    }

    public static testMethod void Test_CancelJob()
    {
        List<Project__c> projects = (List<Project__c>) TestUtil.getRecordset('Project__c');
        List<Job__c> jobs = (List<Job__c>) TestUtil.getRecordset('Job__c');
        ApexPages.StandardSetController controller = new ApexPages.StandardSetController(jobs);    
        controller.setSelected(jobs);
        CancelJobExt ext= new CancelJobExt(controller);  
        ext.cancel();
        jobs = [SELECT Id, jobStatus__c FROM Job__c WHERE Project__c =: projects[0].id];
        //system.assertEquals(jobs[0].jobStatus__c, 'Canceled');
        ext.donotcancel();        
    }

}