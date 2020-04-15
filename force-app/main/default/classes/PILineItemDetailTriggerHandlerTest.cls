@isTest
public class PILineItemDetailTriggerHandlerTest {
    
    static void triggersOff(){
        TriggerUtil.skipAllTriggers();        
    }
    
    @testSetup
    static void init(){
        TriggerUtil.skipAllTriggers();
        TestDataUtil.init();
        TestProject testP = TestProject.create('demo');
        testP.addAccount();
        testP.addAttributes();
        testP.addService();
    }
            
    @isTest
    public static void Test_beforeUpdate(){
        
        //GIVEN
        Project__c p = TestProject.getProjects()[0];
        ProjectService__c ps = TestProject.getServices(p.Id)[0];
        
        List<ProjectAccount__c> accounts = TestProject.getAccounts(p.Id);   
        List<Account> acctList = TestDataUtil.getAccounts();
        
        ProjectAccount__c account1 = accounts[0];
        Account acc1  = acctList[0];
        
        test.startTest();
        
        ProjectInvoice__c pi = new ProjectInvoice__c();
        pi.Project__c = p.Id;
        pi.ProjectAccount__c = account1.Id;
		pi.Account__c = acc1.Id;
        
        pi.Status__c = Constants.PROJECT_INVOICE_STATUS_CREATED;
        insert pi;
        
        ProjectInvoice__c piUnreconciled = new ProjectInvoice__c();
        piUnreconciled.Project__c = p.Id;        
        piUnreconciled.Status__c = Constants.PROJECT_INVOICE_STATUS_CREATED;
        insert piUnreconciled;
                
        ProjectInvoicelineItem__c pili = new ProjectInvoicelineItem__c() ;
        pili.ProjectInvoice__c = piUnreconciled.Id;
        pili.ServiceType__c = Constants.PROJECT_INVOICE_LINEITEM_SERVICETYPE_UNRECONCILED;
        insert pili;
        
        ProjectInvoicelineItem__c piliProduct = new ProjectInvoicelineItem__c() ;
        piliProduct.ProjectInvoice__c = pi.Id;            
        piliProduct.ServiceType__c = Constants.PROJECT_INVOICE_LINEITEM_SERVICETYPE_PRODUCT;
        insert piliProduct;
        
        ProjectInvoiceLineItemDetail__c pilid = new ProjectInvoiceLineItemDetail__c() ;
        pilid.ProjectInvoicelineItem__c = pili.Id;       
        insert pilid;        
        
        pilid.ProjectInvoicelineItem__c = piliProduct.Id;
        pilid.Account__c = acc1.Id;
        update pilid;
        
        pilid.ProjectInvoicelineItem__c = pili.Id;
        update pilid;  
        
        test.stopTest();
    }  
    
}