@isTest
public class UploadLocationsExtTest {
    @testSetup static void setup(){
        TestUtil.initBaseData();
        TestUtil.generateFullTestProject(ProjectType.MD, System.today().addDays(60), System.today().addDays(70));
    }

    public static testMethod void test_importCSVFile(){ 
        Project__c project = (Project__c) TestUtil.getRecord('Project__c');
        List<Location__c> locs = [SELECT Id,LocationNumber__c FROM Location__c];
        ApexPages.currentPage().getParameters().put('projectid', project.Id);
        
        ApexPages.StandardController controller = new ApexPages.StandardController(new ProjectLocation__c());        
        UploadLocationsExt ctrl = new UploadLocationsExt(controller); 
        ctrl.csvFileBody = locs[0].LocationNumber__c;
        ctrl.importCSVFile();
        ApexPages.Message[] pageMessages = ApexPages.getMessages();
		System.assertEquals(0, pageMessages.size());
        
        ctrl.csvFileBody = locs[0].LocationNumber__c;
        ctrl.importCSVFile();
        pageMessages = ApexPages.getMessages();
		System.assertEquals(0, pageMessages.size());
        
        ctrl.csvFileBody = '-9999';
        ctrl.importCSVFile();
        pageMessages = ApexPages.getMessages();
		System.assertEquals(0, pageMessages.size());
	} 
}