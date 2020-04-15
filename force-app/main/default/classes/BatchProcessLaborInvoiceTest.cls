@isTest
private class BatchProcessLaborInvoiceTest {
    @testSetup
    static void setup() {
        TriggerUtil.skipAllTriggers();

        TestDataUtil.init();
        TestProject tP = TestProject.create('demo')
                         .addAll();
        initTestData(tP.getInstance().Id);
    }

    static void initTestData(String pId) {
        setupProjectLocation(pId);
        setupOpportunity(pId);
    }

    static void setupProjectLocation(String pId) {
        ProjectLocation__c pl = TestProject.getLocations(pId)[0];
        pl.LocationExecutedDate__c = Date.today();
        pl.Invoiced__c = false;
        pl.BillingStatus__c = CONSTANTS.BILLING_STATUS_BILLABLE;        
        update pl;
    }

    static void setupOpportunity(String pId) {
        Opportunity opp = new Opportunity();
        opp.Name = 'demo';
        opp.Project__c = pId;
        opp.ProjectType__c = [SELECT Id FROM ProjectType__c][0].Id;
        opp.StageName = 'Proposal/Price Quote';
        opp.CloseDate = Date.today().addDays(10);
        insert opp;

        List<ProjectAccount__c> accts = [Select id, Opportunity__c from ProjectAccount__c 
            where Project__c = :pId];
        for(ProjectAccount__c a: accts) {
            a.Opportunity__c = opp.Id;
        }
        update accts;
     }

    static List<ApexJobTracker__c> getTrackers() {
        return [SELECT Status__c, Operation__c, Object__c, Response__c from ApexJobTracker__c];
    }

    @isTest
    static void itShouldCreateAnInvoice() {
        // Given
        Project__c p = TestProject.getProjects()[0];
        Date cutoffDate = Date.today().addDays(15);
        List<ApexJobTracker__c> trackers = getTrackers();
        QA.isTrue(trackers.isEmpty(), 'no trackers before test');

        // When
        test.startTest();
        BatchProcessLaborInvoice laborInvoice = new BatchProcessLaborInvoice(cutoffDate);
        Database.executeBatch(laborInvoice);
        test.stopTest();

        // Then
        trackers = getTrackers();
        QA.isTrue(!trackers.isEmpty(), 'tracker is created');
        QA.EQ(1, trackers.size(), 'one tracker created.');
        ApexJobTracker__c tracker = trackers[0];
        QA.EQ('Success', tracker.Status__c, 'should succeed:' + tracker.Response__c);
        QA.EQ('ProjectLocation', tracker.Object__c, 'project location');
        QA.EQ('Create Labor Invoice', tracker.Operation__c, 'Create Labor Invoice');
    }

    @isTest static void itShouldGenDataMessage() {
        // GIVEN
        Id oId = null;
        String msg = 'test';

        // WHEN
        test.startTest();
        Map<String, Object> result = BatchProcessLaborInvoice.genDataMessage(oId, msg);
        test.stopTest();

        // THEN
        QA.EQ(oId, result.get('id'), 'null id');
        QA.EQ(msg, result.get('message'), 'msg is test');
    }
}