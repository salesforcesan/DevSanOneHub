global class BatchProcessLaborInvoice implements Database.Batchable<sObject>, Database.Stateful {
    
    Date invoicecutoffdate;
    Date invoicestartdate;
    String projecttypeid;
    boolean hasError = false;
    List<Object> responses {get; set;}
    ApexJobTracker apexTracker {get; set;}
    
    global BatchProcessLaborInvoice(Date pinvoicecutoffdate) {
        this.initTrackerAndProjectType();
    }
    
    global BatchProcessLaborInvoice(Date pinvoicecutoffdate, Date pinvoicestartdate) {
        
        if (pinvoicestartdate != null)
            invoicestartdate = pinvoicestartdate;
        
        if (pinvoicecutoffdate != null)
            invoicecutoffdate = pinvoicecutoffdate;
        
        this.initTrackerAndProjectType();
    }
    
    global BatchProcessLaborInvoice(Date pinvoicecutoffdate, Date pinvoicestartdate, string pprojecttypeid) {
        
        if (pinvoicestartdate != null)
            invoicestartdate = pinvoicestartdate;
        
        if (pinvoicecutoffdate != null)
            invoicecutoffdate = pinvoicecutoffdate;
        
        
        projecttypeid = pprojecttypeid;
        this.initTrackerAndProjectType();
    }
    
    void initTrackerAndProjectType() {
        this.responses = new List<Object>();
        
        if (String.isBlank(projecttypeid)) {
            projecttypeid = getInvoiceProjectTypeId();
        }
        
        this.apexTracker = ApexJobTracker.create(projecttypeid, ApexJobTracker.TrackerTarget.ProjectLocation,
                                                 ApexJobTracker.TrackerOperation.Create_Labor_Invoice)
            .save();
    }
    
    String getInvoiceProjectTypeId() {
        List<ProjectType__c> pts = [Select Id FROM ProjectType__c WHERE CreateInvoice__c = true];
        if (pts.size() > 0) {
            return pts[0].Id;
        }
        throw new CustomException('The project type that can create invoice is not defined.');
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        
        if (this.apexTracker.Status != ApexJobTracker.TrackerStatus.In_Progress) {
            this.apexTracker.setStatus(ApexJobTracker.TrackerStatus.In_Progress)
                .save();
        }
        
        if (invoicestartdate == null) {
            invoicestartdate = Date.valueOf('2019-01-26');
        }
        
        return Database.getQueryLocator([SELECT Id, Project__c, State__c,  Invoiced__c, Location__r.LaborTaxLawsonID__c, Location__r.LaborTaxRate__c, ExecutedDate__c
                                         FROM ProjectLocation__c
                                         WHERE
                                         LocationExecutedDate__c >= :invoicestartdate AND
                                         LocationExecutedDate__c <= :invoicecutoffdate AND
                                         Invoiced__c = false AND
                                         BillingStatus__c = :CONSTANTS.BILLING_STATUS_BILLABLE AND
                                         Project__r.ProjectType__r.CreateInvoice__c = true
                                        ]);
        
    }
    
    global void execute(Database.BatchableContext BC, List<ProjectLocation__c> scope) {
        List<Object> result = new List<Object>();
        try {
            
            Set<String> projectids = new Set<String>();
            Set<String> projectaccountids = new Set<String>();
            Set<String> opportunityids = new Set<String>();
            Set<String> invoicedpls = new Set<String>();
            
            Map<String, List<ProjectAccount__c>> ptopalistmap = new Map<String, List<ProjectAccount__c>>();
            Map<String, List<ProjectLocation__c>> ptopllistmap = new Map<String, List<ProjectLocation__c>>();
            Map<String, List<ProjectLocation__c>> projectToPRStateProjInvoicelistmap = new Map<String, List<ProjectLocation__c>>();
            
            
            Map<String, List<ProjectLocation__c>> patopllistmap = new Map<String, List<ProjectLocation__c>>();
            Map<String, List<ProjectLocation__c>> paToPRStateProjInvoicelistmap = new Map<String, List<ProjectLocation__c>>();
            Map<String, List<OpportunityLineItem>> otoolilistmap = new Map<String, List<OpportunityLineItem>>();
            Map<String, ProjectInvoice__c> patopimap = new Map<String, ProjectInvoice__c>();
            Map<String, ProjectInvoice__c> patoPRStatepimap = new Map<String, ProjectInvoice__c>();
                       
            
            List<ProjectInvoice__c> newpis = new List<ProjectInvoice__c>();
            List<ProjectInvoiceLineItem__c> newpilis = new List<ProjectInvoiceLineItem__c>();
            List<ProjectInvoiceLineItemDetail__c> pilidetaillist = new List<ProjectInvoiceLineItemDetail__c>();
            
            for (ProjectLocation__c pl : scope) {
                projectids.add(pl.Project__c);
                
                if (pl.State__c == constants.STATE_CODE_PR) {
                    List<ProjectLocation__c> plList = new List<ProjectLocation__c>();
                    plList.add(pl);
                    if (projectToPRStateProjInvoicelistmap.get(pl.Project__c) != null) {
                        plList.addall(projectToPRStateProjInvoicelistmap.get(pl.Project__c));
                    }
                    projectToPRStateProjInvoicelistmap.put(pl.Project__c, plList);
                } else {
                    List<ProjectLocation__c> plList = new List<ProjectLocation__c>();
                    plList.add(pl);
                    if (ptopllistmap.get(pl.Project__c) != null) {
                        plList.addall(ptopllistmap.get(pl.Project__c));
                    }
                    ptopllistmap.put(pl.Project__c, plList);
                }     
            }
            
            List<ProjectAccount__c> pas = [Select Id, Project__c, Account__c, Opportunity__c FROM ProjectAccount__c
                                           WHERE Project__c IN :projectids];
            if (!pas.isEmpty()) {
                for (ProjectAccount__c pa : pas) {
                    projectaccountids.add(pa.Id);
                    opportunityids.add(pa.Opportunity__c);
                    List<ProjectAccount__c> paList = new List<ProjectAccount__c>();
                    paList.add(pa);
                    if (ptopalistmap.get(pa.Project__c) != null) {
                        paList.addall(ptopalistmap.get(pa.Project__c));
                    }
                    ptopalistmap.put(pa.Project__c, paList);
                    
                    if (ptopllistmap.get(pa.Project__c) != null) {
                        patopllistmap.put(pa.Id, ptopllistmap.get(pa.Project__c));
                    }
                    
                    if (projectToPRStateProjInvoicelistmap.get(pa.Project__c) != null) {
                        paToPRStateProjInvoicelistmap.put(pa.Id, projectToPRStateProjInvoicelistmap.get(pa.Project__c));
                    }
                    
                }
            }
            
            List<OpportunityLineItem> olList = [Select Id, Opportunity.NumberOfLocations__c, OpportunityId,
                                                UnitPrice, TotalPrice, Service__c,
                                                Service__r.Name, Product2.PreBillPercent__c, AccrualAmount__c
                                                FROM OpportunityLineItem
                                                WHERE OpportunityId IN :opportunityids and Product2.Billable__c = true and
                                                Product2.BillType__c = :Constants.PRODUCT_BILLTYPE_USAGE];
            
            List<OpportunityLineItem> oliList;
            for (OpportunityLineItem oli : olList) {
                oliList = (otoolilistmap.get(oli.OpportunityId) != null)
                    ?  otoolilistmap.get(oli.OpportunityId)
                    : new List<OpportunityLineItem>();
                oliList.add(oli);
                otoolilistmap.put(oli.OpportunityId, oliList);
            }
            
            
            List<ProjectInvoice__c> pis = [SELECT Id, Name, ProjectAccount__c, LawsonCompanyCode__c FROM ProjectInvoice__c
                                           WHERE Project__c IN :projectids AND
                                           Status__c = :CONSTANTS.PROJECT_INVOICE_STATUS_CREATED AND
                                           Type__c = :CONSTANTS.PROJECT_INVOICE_TYPE_POSTEXECUTION];
            if (!pis.isEmpty()) {
                for (ProjectInvoice__c pi : pis) {
                    if (pi.LawsonCompanyCode__c == CONSTANTS.LAWSON_COMPANY_CODE_PR) {
                        patoPRStatepimap.put(pi.ProjectAccount__c, pi);
                    } else {
                        patopimap.put(pi.ProjectAccount__c, pi);
                    }
                }
            }
            
            
            //Check if there's already a Project Invoice that can be used
            for (ProjectAccount__c pa : pas) {
                
                if (otoolilistmap.get(pa.Opportunity__c) == null)
                    continue;
                
                List<ProjectLocation__c> projectLocationList = projectToPRStateProjInvoicelistmap.get(pa.Project__c);
                
                //Check if Project Location has PR State
                boolean hasPRStateLocation = projectLocationList != null && projectLocationList.size() > 0 ? true : false;
                
                //Check if Project Location has US States (Other then PR)
                projectLocationList = ptopllistmap.get(pa.Project__c);
                boolean hasUSStateLocation = projectLocationList != null && projectLocationList.size() > 0 ? true : false;
                
                // Check if Project has US States (Other then PR) in project location and has no project invoice created for it
                if (hasUSStateLocation && patopimap.get(pa.Id) == null) {
                    //Check if the project account has an oppli that
                    //requires a project invoice to be created
                    //If no product in oppli that is of billtype usage
                    newpis.add(CreateProjectInvoice(pa, CONSTANTS.LAWSON_COMPANY_CODE_US));
                }
                
                // Check if Project has PR State in project location and has no project invoice created for it
                if (hasPRStateLocation && patoPRStatepimap.get(pa.Id) == null) {
                    //Check if the project account has an oppli that
                    //requires a project invoice to be created
                    //If no product in oppli that is of billtype usage
                    newpis.add(CreateProjectInvoice(pa, CONSTANTS.LAWSON_COMPANY_CODE_PR));
                }                
            }
            
            //Insert all the new project invoices
            result.add(AppUtil.analyzeSaveResultList('insert ProjectInvoice', Database.insert(newpis)));
            
            newpis = [SELECT Id, Name, ProjectAccount__c, ProjectAccount__r.Opportunity__c, LawsonCompanyCode__c FROM ProjectInvoice__c
                      WHERE Project__c IN :projectids AND
                      Status__c = :CONSTANTS.PROJECT_INVOICE_STATUS_CREATED AND
                      Type__c = :CONSTANTS.PROJECT_INVOICE_TYPE_POSTEXECUTION];
            /*
            // To get Pre Bill invoice for which credit is not applied
            List<ProjectInvoiceLineItem__c> preBillPili = [Select Id, Name, ProjectInvoice__r.Name, ProjectInvoice__c, Type__c, ServiceType__c, Product__c, Amount__c,
                                                           Rate__c, AccrualAmount__c, ProjectInvoice__r.ProjectAccount__c,
                                                           ProjectInvoice__r.ExternalInvoiceNumber__c, LawsonDivision__c,
                                                           LawsonUnit2__c, LawsonAccount2__c, LawsonSubAccount2__c, ProjectInvoice__r.LawsonCompanyCode__c
                                                           From ProjectInvoiceLineItem__c
                                                           WHERE ProjectInvoice__r.ProjectAccount__c in :projectaccountids
                                                           AND ProjectInvoice__r.Type__c = :Constants.PROJECT_INVOICE_TYPE_PREBILL
                                                           AND ProjectInvoice__r.CreditApplied__c = false];
            */
            Map<String, ProjectInvoiceLineItem__c> piToPILIMap = new Map<String, ProjectInvoiceLineItem__c>();
            List<ProjectInvoiceLineItem__c> piliLabourList = [SELECT Id, name,
                                                              ProjectInvoice__c,
                                                              ProjectInvoice__r.ProjectAccount__c,
                                                              Rate__c,
                                                              Amount__c
                                                              FROM ProjectInvoiceLineItem__c
                                                              WHERE ProjectInvoice__r.Project__c in : projectIds
                                                              AND ServiceType__c = :constants.PROJECT_INVOICE_LINEITEM_SERVICETYPE_LABOR
                                                              AND ProjectInvoice__r.Status__c = :constants.PROJECT_INVOICE_STATUS_CREATED];
            
            for (ProjectInvoiceLineItem__c pili : piliLabourList) {
                piToPILIMap.put(pili.ProjectInvoice__c, pili);
            }
            
            List<ProjectInvoiceLineItem__c> newLawsonPiliList = new List<ProjectInvoiceLineItem__c>();
            
            Map<String, ProjectInvoiceLineItem__c> piToLawsonPILIMap = new Map<String, ProjectInvoiceLineItem__c>();
            List<ProjectInvoiceLineItem__c> piliLawsonList = [SELECT Id, name,
                                                              ProjectInvoice__c,
                                                              ProjectInvoice__r.ProjectAccount__c,
                                                              Rate__c,
                                                              Amount__c
                                                              FROM ProjectInvoiceLineItem__c
                                                              WHERE ProjectInvoice__r.Project__c in : projectIds
                                                              AND ServiceType__c = :constants.PROJECT_INVOICE_LINEITEM_SERVICETYPE_LAWSON
                                                              AND ProjectInvoice__r.Status__c = :constants.PROJECT_INVOICE_STATUS_CREATED];
            
            
            for (ProjectInvoiceLineItem__c pili : piliLawsonList) {
                piToLawsonPILIMap.put(pili.ProjectInvoice__c, pili);
            }
            
            
            /*
            Map<string, ProjectInvoiceLineItem__c> preBillMap = new Map<string, ProjectInvoiceLineItem__c>();
            
            for (ProjectInvoiceLineItem__c pili : preBillPili) {
                preBillMap.put(pili.ProjectInvoice__r.ProjectAccount__c, pili);
            }
            
            List<string> preBillProjectInvoice = new List<string>();
            */
            
            
            //Create a Invoice Line Item for all the newly created project invoices.
            //Create a line item for every product
            for (ProjectInvoice__c newpi : newpis) {
                
                 if (!piToLawsonPILIMap.containsKey(newpi.Id)) {
                    ProjectInvoiceLineItem__c pili = new ProjectInvoiceLineItem__c();
                    pili.ProjectInvoice__c = newpi.Id;
                    pili.ServiceType__c = Constants.PROJECT_INVOICE_LINEITEM_SERVICETYPE_LAWSON;
                    newLawsonPiliList.add(pili);
                }
                
                if (!piToPILIMap.containsKey(newpi.Id)) {
                    List<OpportunityLineItem> opplis = otoolilistmap.get(newpi.ProjectAccount__r.Opportunity__c);
                    boolean isPiliToBeCreatedForProjectAccount = false;
                    
                    // create project invoice line items
                    if (opplis != null) {
                        for (OpportunityLineItem oppli : opplis) {
                            ProjectInvoiceLineItem__c pili = new ProjectInvoiceLineItem__c();
                            pili.ProjectInvoice__c = newpi.Id;
                            pili.Type__c = Constants.PROJECT_INVOICE_LINEITEM_TYPE_USAGE;
                            pili.ServiceType__c = Constants.PROJECT_INVOICE_LINEITEM_SERVICETYPE_LABOR;
                            pili.Product__c = oppli.Product2Id;
                            pili.Amount__c = 0;
                            pili.Rate__c = oppli.UnitPrice;
                            pili.AccrualAmount__c = oppli.AccrualAmount__c;
                            newpilis.add(pili);
                            isPiliToBeCreatedForProjectAccount = true;
                        }
                    } else {
                        result.add(genDataMessage(newpi.ProjectAccount__r.Opportunity__c, 'This opportunity has no lineitems.'));
                    }
                    
                    /*
                    // To create a credit line item
                    // Credit is applied only to US project (Non PR)
                    if (isPiliToBeCreatedForProjectAccount && newpi.LawsonCompanyCode__c != constants.LAWSON_COMPANY_CODE_PR) {
                        ProjectInvoiceLineItem__c preBillPiliForPa = preBillMap.get(newpi.ProjectAccount__c);
                        if (preBillPiliForPa != null) {
                            ProjectInvoiceLineItem__c pili = new ProjectInvoiceLineItem__c();
                            pili.ProjectInvoice__c = newpi.Id;
                            pili.Type__c = Constants.PROJECT_INVOICE_LINEITEM_TYPE_LUMPSUM;
                            pili.ServiceType__c = Constants.PROJECT_INVOICE_LINEITEM_SERVICETYPE_CREDIT;
                            pili.Product__c = preBillPiliForPa.Product__c;
                            pili.Amount__c = preBillPiliForPa.Amount__c;
                            pili.Rate__c = preBillPiliForPa.Rate__c;
                            pili.AccrualAmount__c = preBillPiliForPa.AccrualAmount__c;
                            pili.QuantityOverride__c = -1;
                            pili.Description__c = 'Less Pre-bill invoice ' + preBillPiliForPa.ProjectInvoice__r.ExternalInvoiceNumber__c;
                            pili.LawsonDivision__c = Constants.LAWSON_DIVISION;
                            pili.LawsonUnit2__c = Constants.LAWSON_UNIT;
                            pili.LawsonAccount2__c = Constants.LAWSON_ACCOUNT;
                            pili.LawsonSubAccount2__c = Constants.LAWSON_SUB_ACCOUNT;
                            
                            newpilis.add(pili);
                            preBillProjectInvoice.add(preBillPiliForPa.ProjectInvoice__c);
                        }
                    }

					*/		
                }
                
            }
            
            result.add(AppUtil.analyzeSaveResultList('insert ProjectInvoiceLineItem', Database.Insert(newpilis)));
            
            result.add(AppUtil.analyzeSaveResultList('insert ProjectInvoiceLineItem', Database.Insert(newLawsonPiliList)));
            
            /*
            // To set credit applied flag as true for prebill invoice
            List<ProjectInvoice__c> preBillProjectInvoiceToUpdate = [SELECT Id, Name, CreditApplied__c
                                                                     FROM ProjectInvoice__c
                                                                     WHERE Id IN :preBillProjectInvoice];
            
            if (preBillProjectInvoiceToUpdate != null) {
                for (ProjectInvoice__c preBillPi : preBillProjectInvoiceToUpdate) {
                    preBillPi.CreditApplied__c = true;
                }
            }
            
            result.add(AppUtil.analyzeSaveResultList('PreBillProjectInvoice', Database.Update(preBillProjectInvoiceToUpdate)));
            */
            List<ProjectInvoiceLineItem__c> piliLaborList = [SELECT Id, name, ProjectInvoice__c, ProjectInvoice__r.ProjectAccount__c,
                                                             ProjectInvoice__r.LawsonCompanyCode__c, Rate__c, Amount__c
                                                             FROM ProjectInvoiceLineItem__c
                                                             WHERE ProjectInvoice__r.ProjectAccount__c in :projectaccountids
                                                             AND ServiceType__c = :Constants.PROJECT_INVOICE_LINEITEM_SERVICETYPE_LABOR
                                                             AND ProjectInvoice__r.Status__c = :Constants.PROJECT_INVOICE_STATUS_CREATED];
            
            for (ProjectInvoiceLineItem__c laborpilineitem : piliLaborList) {
                List<ProjectLocation__c> pllist = new List<ProjectLocation__c>();
                String projectaccount = laborpilineitem.ProjectInvoice__r.ProjectAccount__c;
                
                //if (patopllistmap.get(projectaccount) != null) {
                pllist = laborpilineitem.ProjectInvoice__r.LawsonCompanyCode__c == constants.LAWSON_COMPANY_CODE_PR ?
                    paToPRStateProjInvoicelistmap.get(projectaccount) : patopllistmap.get(projectaccount);
                //}
                //
                
                if (pllist != null) {
                    for (ProjectLocation__c pl : pllist) {
                        ProjectInvoiceLineItemDetail__c pilid = new ProjectInvoiceLineItemDetail__c();
                        pilid.ProjectInvoiceLineItem__c = laborpilineitem.Id;
                        pilid.ProjectLocation__c = pl.Id;
                        pilid.Rate__c = laborpilineitem.Rate__c;
                        pilid.Date__c = (pl.ExecutedDate__c != null) ? (pl.ExecutedDate__c).date() : null;
                        pilid.LaborTaxLawsonID__c = pl.Location__r.LaborTaxLawsonID__c;
                        pilid.LaborTaxRate__c = pl.Location__r.LaborTaxRate__c;
                        pilid.EntryType__c = Constants.PROJECT_INVOICE_ENTRY_TYPE_CHARGE;
                        pilidetaillist.add(pilid);
                        invoicedpls.add(pl.Id);
                    }
                }
            }
            
            //Set the project locations to invoiced
            for (ProjectLocation__c pl : scope) {
                if (invoicedpls.contains(pl.Id))
                    pl.Invoiced__c = true;
            }
            
            result.add(AppUtil.analyzeSaveResultList('insert ProjectInvoiceLineItemDetail', Database.insert(pilidetaillist)));
            result.add(AppUtil.analyzeSaveResultList('update ProjectLocation', Database.update(scope)));
            this.responses.add(result);
            
        } catch (Exception ex) {
            result.add(genError(ex));
            this.responses.add(result);
            hasError = true;
        }
        
    }
    
    Map<String, Object> genError(Exception ex) {
        Map<String, Object> err = new Map<String, Object>();
        err.put('topic', 'exception');
        err.put('messages', new Object[] {ex.getMessage(), ex.getLineNumber(), ex.getStackTraceString()});
        return err;
    }
    
    @testVisible
    static Map<String, Object>  genDataMessage(object dataId, String dataMessage) {
        Map<String, Object> msgMap = new Map<String, Object>();
        
        msgMap.put('id', dataId);
        msgMap.put('message', dataMessage);
        
        return msgMap;
    }
    
    global void finish(Database.BatchableContext BC) {
        this.apexTracker
            .setStatus(ApexJobTracker.TrackerStatus.Success)
            .setResponse(JSON.serialize(this.responses));
        
        List<AsyncApexJob> aList = [SELECT NumberOfErrors FROM AsyncApexJob WHERE Id = :BC.getJobId()];
        if (!aList.isEmpty() && aList[0].NumberOfErrors > 0 || this.hasError) {
            this.apexTracker.setStatus(ApexJobTracker.TrackerStatus.Failure);
        }
        
        this.apexTracker.save();        
             
        //to clear batch processed
        EndProcess('ProjectInvoice');   
    }
    
     public static void EndProcess(String entity){
        
        List<ProcessLastSyncTime__c> plsts = [Select Id, CurrentProcessId__c 
                                                         From ProcessLastSyncTime__c 
                                                         WHERE ProcessName__c =: entity LIMIT 1];                
        if (!plsts.isEmpty()){
            plsts[0].CurrentProcessId__c = '';            
            update plsts[0];
        }
    }
    
    public ProjectInvoice__c CreateProjectInvoice(ProjectAccount__c pa, String lawsonCountryCode) {
        ProjectInvoice__c pi = new ProjectInvoice__c();
        pi.Project__c = pa.Project__c;
        pi.Status__c = Constants.PROJECT_INVOICE_STATUS_CREATED;
        pi.Type__c = Constants.PROJECT_INVOICE_TYPE_POSTEXECUTION;
        pi.LawsonProcessType__c = Constants.LAWSON_PROCESS_TYPE_PE;
        pi.LawsonCompanyCode__c = lawsonCountryCode;
        pi.Account__c = pa.Account__c;
        pi.ProjectAccount__c = pa.Id;
        return pi;
    }
    
}