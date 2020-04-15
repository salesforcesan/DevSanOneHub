@isTest
public class ProjectInvoiceLineItemTriggerHandlerTest {

    @testSetup static void setup(){
        TriggerUtil.skipAllTriggers();
        TestDataUtil.init();
        TestProject.create('demo').addAll();
    }

    @isTest
    public static void test_didorderincrease(){
        //GIVEN
        Project__c p = TestProject.getProjects()[0];
        ProjectService__c ps = TestProject.getServices(p.Id)[0];
        JobAttempt__c attempt = TestProject.getJobAttempts(p.Id)[0];

        //WHEN
        test.startTest();
        ProjectInvoice__c pi = new ProjectInvoice__c();
        pi.Project__c = p.Id;
        pi.Status__c = Constants.PROJECT_INVOICE_STATUS_CREATED;
        insert pi;
        
        ProjectInvoicelineItem__c pili = new ProjectInvoicelineItem__c() ;
        pili.ProjectInvoice__c = pi.Id;
        pili.ServiceType__c = Constants.PROJECT_INVOICE_LINEITEM_SERVICETYPE_LABOR;
        insert pili;
        test.stopTest();

        //THEN
        System.assertEquals(false, pili.LineItemOrder__c > 0);
    }

}