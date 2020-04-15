@isTest
public class CancelProjectServiceExtTest {

    @testSetup static void setup(){
        TestUtil.initBaseData();
        TestUtil.setupJobTestData(CONSTANTS.JOB_ATTEMPT_STATUS_OPEN, 
            CONSTANTS.JOB_ATTEMPT_STATUS_OPEN);
    }

    public static testMethod void Test_CancelProjectService()
    {
        List<Project__c> projects = (List<Project__c>) TestUtil.getRecordset('Project__c');
        List<ProjectService__c> projServs = (List<ProjectService__c>) TestUtil.getRecordset('ProjectService__c');
        List<ProjectLocation__c> plocs = (List<ProjectLocation__c>) TestUtil.getRecordset('ProjectLocation__c');
        list<job__c> jobs = (List<job__c>) TestUtil.getRecordset('Job__c');
        
        ApexPages.StandardSetController controller = new ApexPages.StandardSetController(projServs);    
        ApexPages.currentPage().getParameters().put('psids', projServs[0].Id);
        ApexPages.currentPage().getParameters().put('id', projects[0].Id);
        controller.setSelected(projServs);
        CancelProjectServiceExt ext= new CancelProjectServiceExt(controller);  
        //ext.CancelService();
        ext.donotcancel();
        //projServs = [SELECT Id, Status__c FROM ProjectService__c WHERE Project__c =: projects[0].id];
        //system.assertEquals(projServs[0].Status__c, 'Canceled');
    }
}