@isTest
public class CancelLocationExtTest {
    @testSetup static void setup(){
        TestUtil.initBaseData();
        TestUtil.setupJobTestData(CONSTANTS.JOB_ATTEMPT_STATUS_OPEN, 
            CONSTANTS.JOB_ATTEMPT_STATUS_OPEN);
    }
   public static testMethod void Test_CancelLocation()
    {
        List<ProjectLocation__c> plocs = (List<ProjectLocation__c>) TestUtil.getRecordset('ProjectLocation__c');
        ApexPages.StandardSetController controller = new ApexPages.StandardSetController(plocs);    
        controller.setSelected(plocs);
        CancelLocationExt ext= new CancelLocationExt(controller);  
        ext.cancel();
        ext.donotcancel();
        //plocs = [SELECT Id, Status__c FROM ProjectLocation__c WHERE Project__c =: projects[0].id];
        //system.assertEquals(plocs[0].Status__c, 'Canceled');
    }
}