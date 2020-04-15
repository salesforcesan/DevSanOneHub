@isTest
public class JobUpdateBatchHandlerTest {
    @testSetup static void setup(){
        TestUtil.initBaseData();
        TestUtil.generateFullTestProject(ProjectType.MD, Date.today().addDays(10), Date.today().addDays(20));
    }

    public static testMethod void test_Handler(){
        Project__c project = (Project__c) TestUtil.getRecord('Project__c');
        
        List<Material__c> mts = (List<Material__c>) TestUtil.getRecordset('Material__c');
        List<ProjectService__c> psLsit = [SELECT Id FROM ProjectService__c WHERE Project__c =:project.Id ];
        TestUtil.generateProjectServiceMaterial(psLsit[0].Id, mts[0]);
        
        ProjectScheduler batch = new ProjectScheduler([SELECT Name, StartDate__c, EndDate__c, ProjectType__c, ProjectType__r.Name, Status__c FROM Project__c WHERE ID = :project.Id]);
        Database.executeBatch(batch);
        
        project = [SELECT Id, Status__c FROM Project__c WHERE Id =: project.Id];
        Integer jobMateralCount = [SELECT Count() FROM JobMaterial__c WHERE Job__c IN (SELECT ID FROM JOB__c WHERE Project__c =: project.Id)];
        system.assertEquals(jobMateralCount, 0);
        
        /*
        jobMateralCount = [SELECT Count() FROM JobMaterial__c WHERE Job__c IN (SELECT ID FROM JOB__c WHERE Project__c =: project.Id)];
        project = [SELECT Id, Name, Status__c, ProjectType__c, ProjectType__r.Name, FulfillmentLeadTime__c, ProjectCancelLeadTime__c,StartDate__c,EndDate__c,retailer__r.isMaterialReqd__c, OriginID__c, BudgetedLocationsCount__c, UpdateJobsFlag__c FROM Project__c WHERE Id =: project.Id];
        project.Status__c = 'Booked';
        update project;
        
        Test.startTest();
        JobUpdateBatchHandler jobupdatebatch = new JobUpdateBatchHandler(project);
        Database.ExecuteBatch(jobupdatebatch, 100);
        Test.stopTest();
        
        jobMateralCount = [SELECT Count() FROM JobMaterial__c WHERE Job__c IN (SELECT ID FROM JOB__c WHERE Project__c =: project.Id)];
        
        system.assertNotEquals(jobMateralCount, 0);
        */
    }
}