@isTest
public class SubmitProjectExtTest {
    @testSetup static void setup(){
        TestUtil.initBaseData();
        TestUtil.setupJobTestData(CONSTANTS.JOB_ATTEMPT_STATUS_OPEN, 
            CONSTANTS.JOB_ATTEMPT_STATUS_OPEN);
    }

    public static testMethod void Test_SubmitProject()
    {
        Project__c project = (Project__c) TestUtil.getRecord('Project__c');
        List<ProjectService__c> projServs = (List<ProjectService__c>) TestUtil.getRecordset('ProjectService__c');

        ApexPages.StandardController controller = new ApexPages.StandardController(project);
        ApexPages.currentPage().getParameters().put('id', project.Id);
        ApexPages.currentPage().getParameters().put('stage','submit');

        Test.startTest();
        projServs[0].TargetType__c=null;
        update projServs[0];
        project.StartDate__c = System.Today();
        project.approvaldate__c = System.Today().adddays(-10);
        project.ProjectLaunchDate__c = project.StartDate__c;
        update project;
        
        // now pass it to the extension
        SubmitProjectExt ext= new SubmitProjectExt(controller);
        ext.init();
        Test.stopTest();
        
        system.assert(ext != null);
        system.assert(ext.project != null);
        
        //system.assert(ext.invalidps.size() > 0);
        
        //system.assert(ext.leadtime == false);
        //system.assert(ext.invalidsq.size() > 0);
        //system.assert(ext.reservedLocation == false);
        //system.assert(ext.invalidjobsps.size() == 0);       
    }
    
    public static testMethod void Test_SubmitProjectwithJobs(){
        Project__c newproject = (Project__c) TestUtil.getRecord('Project__c');
        newproject.StartDate__c = System.Today();
        newproject.EndDate__c = System.Today().addDays(31);
        update newproject;
        
        List<ProjectService__c> newprojServs = (List<ProjectService__c>) TestUtil.getRecordset('ProjectService__c');
        //List<ProjectServiceQuestion__c> newsurveyQuestions = TestUtil.generateSurveyQuestions(1, newprojServs.get(0).Id, 'Multi-Select List');
        
        List<ProjectLocation__c> newpl = (List<ProjectLocation__c>) TestUtil.getRecordset('ProjectLocation__c');
        List<job__c> jobs = (List<job__c>) TestUtil.getRecordset('Job__c');

        Test.startTest();
        ApexPages.StandardController controller = new ApexPages.StandardController(newproject);
        ApexPages.currentPage().getParameters().put('id', newproject.Id);
        SubmitProjectExt ext= new SubmitProjectExt(controller);
        ext.init();
        Test.stopTest();

        system.assert(ext != null);
        system.assert(ext.project != null);
        
        system.assert(ext.invalidps.size() == 0);
        
        system.assert(ext.leadtime == true);
        
        
        //system.assert(ext.reservedLocation == true);
        
        //system.assert(ext.project.Status__c == 'Pending Approval');              
        
    }
}