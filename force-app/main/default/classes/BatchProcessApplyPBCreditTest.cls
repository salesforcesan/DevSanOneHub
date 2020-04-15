@isTest
private class BatchProcessApplyPBCreditTest {
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
        Project__c p = TestProject.getProjects()[0];
        createPreBillProjectInvoice(p);
        
        
        //setupPriBill(pId);
    }

    static void setupProjectLocation(String pId) {
        ProjectLocation__c pl = TestProject.getLocations(pId)[0];
        pl.LocationExecutedDate__c = Date.today();
        pl.Invoiced__c = false;
        pl.BillingStatus__c = CONSTANTS.BILLING_STATUS_BILLABLE;        
        update pl;
    }

    
    
    static void setupOpportunity(String pId) {
        
        Product2 Prod =  new Product2();
        Prod.Name='NewProd';        
        Prod.IsActive=True;
        Prod.PreBillPercent__c = 60;
        insert Prod;
        
        PricebookEntry pbe = new PricebookEntry();
        pbe.Product2Id=Prod.Id;
        pbe.IsActive=True;
        pbe.UnitPrice=70;
        pbe.Pricebook2Id = Test.getStandardPricebookId();
        pbe.UseStandardPrice=false;
        insert pbe;    
        
        
        Opportunity opp = new Opportunity();
        opp.Name = 'demo';
        opp.Project__c = pId;
        opp.ProjectType__c = [SELECT Id FROM ProjectType__c][0].Id;
        opp.StageName = 'Proposal/Price Quote';
        opp.CloseDate = Date.today().addDays(10);
        opp.PreBill__c = true;
        opp.NumberOfLocations__c = 5;
        insert opp;
        
        OpportunityLineItem opli = new OpportunityLineItem();
        opli.UnitPrice = 70;
        opli.Quantity = 12;
        opli.Product2Id = Prod.id;
        opli.OpportunityId=opp.Id;
        opli.PricebookEntryId=pbe.id;
        //opli.TotalPrice = 60;
        
        insert opli;

        List<ProjectAccount__c> accts = [Select id, Opportunity__c from ProjectAccount__c 
            where Project__c = :pId];
        for(ProjectAccount__c a: accts) {
            a.Opportunity__c = opp.Id;
        }
        update accts;
     }

    
     static void createPreBillProjectInvoice(Project__c project)
    {
        String account = '';
        List<String> oppIds = new List<String>();
        List<OpportunityLineItem> olList = new List<OpportunityLineItem>();
        Map<String, List<OpportunityLineItem>> oppToOppLImap = new Map<String, List<OpportunityLineItem>>();
        List<ProjectInvoiceLineItem__c> pils = new List<ProjectInvoiceLineItem__c>();
        
        List<ProjectAccount__c> projectaccounts = [Select Id, PONumber__c, Opportunity__r.RequestedDate__c, Opportunity__r.NumberOfLocations__c, 
                                                   Opportunity__r.ResponsibleParty__c, Opportunity__c, Opportunity__r.PreBill__c, 
                                                   ResponsibleParty__c, Account__c, BillToContact__c from ProjectAccount__c WHERE Project__c = :project.Id
                                                  AND Opportunity__c != null AND Opportunity__r.PreBill__c = true];

		if (projectaccounts.IsEmpty())
            return;
        

        for (ProjectAccount__c pa : projectaccounts)
        {
            if (pa.Opportunity__c != null)
            	oppIds.add(pa.Opportunity__c);
            
        }
        
        
        if (!oppIds.IsEmpty())
        {
            olList = [Select Id, Opportunity.NumberOfLocations__c, Opportunity.Id, UnitPrice, TotalPrice, Product2.PreBillPercent__c 
                      FROM OpportunityLineItem 
                      WHERE OpportunityId IN :oppIds AND Product2.PreBillPercent__c > 0 and TotalPrice > 0];
            
            
            for (OpportunityLineItem ol : olList)
            {
                if (oppToOppLImap.get(ol.Opportunity.Id) != null)
                {
                    oppToOppLImap.get(ol.Opportunity.Id).add(ol);
                }
                else
                {
                    List<OpportunityLineItem> firstolList = new List<OpportunityLineItem>();
                    firstolList.add(ol);
                    oppToOppLImap.put(ol.Opportunity.Id, firstolList);
                }
                
            }
            
        }

        for (ProjectAccount__c pa : projectaccounts)
        {
            if (oppToOppLImap.get(pa.Opportunity__c) == null) 
                continue;

            ProjectInvoice__c pi = new ProjectInvoice__c();
            pi.Project__c = project.Id;
            pi.Status__c = Constants.PROJECT_INVOICE_STATUS_CREATED;
            pi.Type__c = Constants.PROJECT_INVOICE_TYPE_PREBILL;
            pi.LawsonProcessType__c = Constants.LAWSON_PROCESS_TYPE_PB;
            pi.Account__c = pa.Account__c;
            pi.BillToContact__c = pa.BillToContact__c;
            pi.ProjectAccount__c = pa.Id;
            pi.PONumber__c = pa.PONumber__c;
            if (project.StartDate__c != null){
                
                Date duedate = project.StartDate__c.addDays(AppUtil.ProjectInvoiceDueDateThreshold * -1);

                //OH2-924
                pi.DueDate__c = (duedate > datetime.now().date()) ? duedate : datetime.now().date();
            }
            
            pi.ResponsibleParty__c = pa.Opportunity__r.ResponsibleParty__c;
            insert pi;

            for (OpportunityLineItem li : oppToOppLImap.get(pa.Opportunity__c))
            {
                ProjectInvoiceLineItem__c pil = new ProjectInvoiceLineItem__c();
                pil.ProjectInvoice__c = pi.Id;
                pil.Type__c = Constants.PROJECT_INVOICE_LINEITEM_TYPE_LUMPSUM;
                pil.Amount__c = li.TotalPrice * li.Product2.PreBillPercent__c;
                pil.Description__c = 'PP ' + li.Product2.PreBillPercent__c * 100 + '% ' + 'of ' + pa.Opportunity__r.NumberOfLocations__c + ' clubs ' + '@ $' + li.UnitPrice;
                pils.add(pil);
                
            }
        } 
        insert pils;                
    }
    
    
    static void setupPriBill(String pId) {
        ProjectLocation__c pl = TestProject.getLocations(pId)[0];
        pl.LocationExecutedDate__c = Date.today();
        pl.Invoiced__c = false;
        pl.BillingStatus__c = CONSTANTS.BILLING_STATUS_BILLABLE;        
        update pl;
    }

    
    static List<ApexJobTracker__c> getTrackers() {
        return [SELECT Status__c, Operation__c, Object__c, Response__c from ApexJobTracker__c];
    }

    @isTest
    static void testApplyCredit() {
        // Given
        Project__c p = TestProject.getProjects()[0];
        
        List<ApexJobTracker__c> trackers = getTrackers();
        QA.isTrue(trackers.isEmpty(), 'no trackers before test');

        // When
        test.startTest();
        BatchProcessApplyPBCredit pbInvoice = new BatchProcessApplyPBCredit();
        Database.executeBatch(pbInvoice);
        test.stopTest();

        // Then
        trackers = getTrackers();
        QA.isTrue(!trackers.isEmpty(), 'tracker is created');
        QA.EQ(1, trackers.size(), 'one tracker created.');
        ApexJobTracker__c tracker = trackers[0];
        QA.EQ('Success', tracker.Status__c, 'should succeed:' + tracker.Response__c);
        QA.EQ('ProjectInvoice', tracker.Object__c, 'project Invoice');
        QA.EQ('Apply PB Credit', tracker.Operation__c, 'Apply PB Credit');
    }

}