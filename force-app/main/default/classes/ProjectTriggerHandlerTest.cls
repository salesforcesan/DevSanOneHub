@isTesT
public class ProjectTriggerHandlerTest {
       
    @testSetup static void setup(){
        TestUtil.initBaseData();
    } 
    static testMethod void test_beforeInsert() {

        Test.startTest();
        Project__c[] projects = TestUtil.generateProjects(2);
        Test.stopTest();

        for (Project__c project : [SELECT Status__c FROM Project__c WHERE Id = :projects]) {
            System.assertEquals('Planning', project.Status__c);
        }

        
    }
    
    static testMethod void test_beforeUpdate() {

        Project__c[] projects = TestUtil.generateProjects(2);

        Map<Id, Boolean> projectIdToHasReserved = AppUtil.getProjectIdToHasReserved(projects);
        Map<Id, Location__c> retailerIdToLocation = new Map<Id, Location__c>();
        for (Project__c project : [SELECT Retailer__c FROM Project__c WHERE Id IN :projects]) {

            //System.assertEquals(false, project.IsEventManualRegenReqd__c);
            System.assertEquals(false, projectIdToHasReserved.get(project.Id));
           

            if (!retailerIdToLocation.containsKey(project.Retailer__c)) retailerIdToLocation.put(project.Retailer__c, TestUtil.buildLocation(project.Retailer__c));
        }
        insert retailerIdToLocation.values();

        ProjectLocation__c[] testProjectLocations = new ProjectLocation__c[]{};
        for (Project__c project : projects) {
            testProjectLocations.add(new ProjectLocation__c(
                Project__c = project.Id
                , Location__c = retailerIdToLocation.get(project.Retailer__c).Id
                , Status__c = 'Booked'
            ));
        }
        insert testProjectLocations;

        Test.startTest();

        TriggerUtil.SkipProjectTrigger = false;

        for (Project__c project : projects) {
            project.Name = 'Test Updated Name ' + project.Id;
            project.Status__c = 'Booked';
        }
        update projects;

        projectIdToHasReserved = AppUtil.getProjectIdToHasReserved(projects);
        for (Project__c project : [SELECT Id FROM Project__c WHERE Id IN :projects]) {
            //System.assertEquals(true, project.IsEventManualRegenReqd__c);
            //System.assertEquals(true, projectIdToHasReserved.get(project.Id));
            /*System.assertEquals(true, project.RereserveFlag__c);*/
        }

        Test.stopTest();
    }

    /* TODO: Complete this test */
    /*static testMethod void test_beforeUpdateWithApprovalRequest() {

        Project__c[] projects = TestUtil.generateProjects(2);

        System.assertEquals(0, [SELECT count() FROM Project__c WHERE Id IN :projects AND Status__c = 'Pending Approval']);

        Test.startTest();

        TriggerUtil.SkipProjectTrigger = false;

        for (Project__c project : projects) {
            project.Status__c = 'Pending Approval';
        }
        update projects;

        Set<Id> projectIdsWithWorkItem = new Set<Id>();
        for (ProcessInstanceWorkItem workItem : [SELECT ProcessInstance.TargetObjectId FROM ProcessInstanceWorkItem WHERE ProcessInstance.TargetObjectId IN :projects]) projectIdsWithWorkItem.add(workItem.ProcessInstance.TargetObjectId);

        for (Project__c project : projects) {
            System.assertEquals(true, projectIdsWithWorkItem.contains(project.Id));
        }

        Test.stopTest();
    }*/
    }