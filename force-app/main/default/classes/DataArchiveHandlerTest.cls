@isTest
public class DataArchiveHandlerTest {
    
    @testSetup static void init(){
        TestUtil.initBaseData();
        
        OrgCustomSettings__c settings = [SELECT Id, ClosedProjectRetentionDays__c FROM OrgCustomSettings__c LIMIT 1];
        settings.ClosedProjectPendingArchiveDays__c = -100;
        settings.ClosedProjectRetentionDays__c = -100;
        update settings;
        
    }
    
    @isTest static void test_SetProjectArchiveStatusToPending(){
        //arrange
        Project__c project = TestUtil.generateFullTestProject(ProjectType.MD, Date.today().addDays(20),Date.today().addDays(30));
        DataArchiveHandler daHandler = new DataArchiveHandler();
        project.Status__c = CONSTANTS.PROJECT_STATUS_CLOSED;
        project.ProjectGracePeriodDuration__c = 0;
        update project;
        
        //act
        Test.startTest();
        daHandler.archive();
        Test.stopTest();
        
        //assert
        Integer count  = [SELECT count() FROM Project__c WHERE ArchiveStatus__c = :CONSTANTS.ARCHIVE_STATUS_PENDING];
        system.assertEquals(1, count, 'look for project archive status: pending');
        
    }    
    
    
    @isTest static void test_DeleteProject(){
        //arrange
        Project__c project = TestUtil.generateFullTestProject(ProjectType.MD, Date.today().addDays(20),Date.today().addDays(30));
        DataArchiveHandler daHandler = new DataArchiveHandler();
        project.Status__c = CONSTANTS.PROJECT_STATUS_CLOSED;
        project.ProjectGracePeriodDuration__c = 0;
        project.ArchiveStatus__c = CONSTANTS.ARCHIVE_STATUS_ARCHIVED;
        update project;
        
        system.debug('update project '+project);
        //act
        Test.startTest();
        daHandler.archive();
        Test.stopTest();
        
        //assert
        //This is no longer valid as we don't delete project
        //for now we just delete the jobs and attempts
        //Integer count  = [SELECT count() FROM Project__c];
        //system.assertEquals(0, count, 'project should be deleted');

        
    }      
}