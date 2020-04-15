@isTest
private class ProjectApprovalEmailTemplateControllTest {

    @testSetup static void setup(){
        TestUtil.initBaseData();
        TestUtil.generateProjects(1, System.today(), System.today().addDays(10));
    }

    static testmethod void testController() {
        //Create Test data.  
        List < Project__c > projects = (List < Project__c >) TestUtil.getRecordset('Project__c');
        List < ProjectLocation__c > projLocs = (List < ProjectLocation__c >) TestUtil.getRecordset('ProjectLocation__c');
        List < ProjectService__c > projServs = (List < ProjectService__c >) TestUtil.getRecordset('ProjectService__c');
        Test.startTest();

        ProjectApprovalEmailTemplateController controller = new ProjectApprovalEmailTemplateController();
        //set the project Id
        controller.projectId = projects.get(0).id;

        Project__c project = controller.project;
        //Assert Start Date and End date
        System.assertEquals(System.today(), project.StartDate__c);
        System.assertEquals(System.today().addDays(10), project.EndDate__c);

        Integer reservedLocations = controller.reservedLocations;

        //Assert Reserved Locations
        System.assertEquals(0, reservedLocations);

        String ServicesPerformed = controller.ServicesPerformed;


        List < ProjectServiceTarget__c > items = controller.items;
        List < Job__c > locations = controller.locations;
          //Assert Locations
        System.assertEquals(0, locations.size());
        
        Test.stopTest();


    }
}