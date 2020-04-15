@isTest
public class ProjectInvoiceActionHelperTest {
 @testSetup static void setup(){
        TriggerUtil.skipAllTriggers();
        TestDataUtil.init();
        TestProject.create('demo').addAll();
    }    
    
    @isTest
    public static void test_ProjectInvoiceClone(){        
               
        //GIVEN
        Project__c p = TestProject.getProjects()[0];
        ProjectAccount__c pa = TestProject.getAccounts(p.Id)[0];
        ProjectService__c ps = TestProject.getServices(p.Id)[0];
        JobAttempt__c attempt = TestProject.getJobAttempts(p.Id)[0];

        
		AccountBudget__c ab = new AccountBudget__c();
        ab.Name = 'AB 1';
        ab.ExecutedAgainstBudget__c = 500;
        ab.Amount__c = 500;
        ab.BudgetType__c = 'Annual';
        ab.PeriodStartDate__c = Date.today();
        ab.PeriodEndDate__c = Date.today().addDays(10);        
 		ab.Account__c = pa.Account__c;
        ab.SubCategory__c = 'test';
        insert ab;
                
        Opportunity opp = new Opportunity();
        opp.Name = 'test opp 1';
        opp.AccountId = pa.Account__c;
        opp.StageName = 'Closed Won';
        opp.AccountBudget__c = ab.Id; 
        opp.CloseDate = date.today();
        insert opp;        
        
        pa.Opportunity__c =opp.Id;        
        update pa;
        
        Contact uContact = [SELECT Id, AccountId from Contact LIMIT 1];
        
        ProjectInvoice__c pi = new ProjectInvoice__c();
        pi.Project__c = p.Id;
        pi.BillToContact__c = uContact.Id;
        pi.Account__c = pa.Account__c;
        pi.Status__c = Constants.PROJECT_INVOICE_STATUS_CREATED;
        pi.Type__c = Constants.PROJECT_INVOICE_TYPE_POSTEXECUTION;
        pi.LawsonCompanyCode__c = Constants.LAWSON_COMPANY_CODE_US;
        pi.ProjectAccount__c = pa.Id;
        insert pi;
        
        ProjectInvoicelineItem__c pili = new ProjectInvoicelineItem__c() ;
        pili.ProjectInvoice__c = pi.Id;
        pili.Rate__c = 1000;
        pili.QuantityOverride__c = 1;
        pili.ServiceType__c = Constants.PROJECT_INVOICE_LINEITEM_SERVICETYPE_LABOR;
        insert pili;
        test.startTest();
        
        //WHEN                                
       	string newPi = ProjectInvoiceActionHelper.CloneProjectInvoice(pi.Id,'Product Re-bill','test');
        system.debug('newPi::' + newPi);
        
		test.stopTest();        
        
        //THEN
        List<ProjectInvoice__c> abList = [Select Id,Name from ProjectInvoice__c where id = : newPi];
        System.assertEquals(true, abList.size() == 1);

    }
}