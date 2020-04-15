global class BatchProcessApplyPBCredit implements Database.Batchable<sObject>, Database.Stateful {
    boolean hasError = false;        
    List<Object> responses {get; set;}
    ApexJobTracker apexTracker {get; set;}
    String projecttypeid;
    global BatchProcessApplyPBCredit() {
        this.initTrackerAndProjectType();
    }
    
    void initTrackerAndProjectType() {
        this.responses = new List<Object>();        
        
        this.apexTracker = ApexJobTracker.create(projecttypeid, ApexJobTracker.TrackerTarget.ProjectInvoice,
                                                 ApexJobTracker.TrackerOperation.Apply_PB_Credit)
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
        
        // To get Pre Bill invoice for which credit is not applied            
        return Database.getQueryLocator([Select Id, Name, ProjectInvoice__c, ProjectInvoice__r.Name, Type__c, ServiceType__c, Product__c, Amount__c,
                                         Rate__c, AccrualAmount__c, ProjectInvoice__r.ProjectAccount__c,
                                         ProjectInvoice__r.ExternalInvoiceNumber__c, LawsonDivision__c,
                                         LawsonUnit2__c, LawsonAccount2__c, LawsonSubAccount2__c, ProjectInvoice__r.LawsonCompanyCode__c
                                         From ProjectInvoiceLineItem__c
                                         WHERE ProjectInvoice__r.Type__c = :Constants.PROJECT_INVOICE_TYPE_PREBILL
                                         AND ProjectInvoice__r.CreditApplied__c = false 
                                         AND ProjectInvoice__r.Status__c != :Constants.PROJECT_INVOICE_STATUS_CANCELED
                                        ]);
    }
    
    global void execute(Database.BatchableContext BC, List<ProjectInvoiceLineItem__c> scope) {
        
        List<Object> result = new List<Object>();
        try{
            
            List<ProjectInvoiceLineItem__c> newpiliList = new List<ProjectInvoiceLineItem__c>();
            List<ProjectInvoice__c> newpiList = new List<ProjectInvoice__c>();
            Map<string, ProjectInvoiceLineItem__c> preBillMap = new Map<string, ProjectInvoiceLineItem__c>();        
            
            Set<String> projectAccountIds = new Set<String>();
            Set<String> piNeededForprojectAccountIds = new Set<String>();
            List<string> preBillProjectInvoice = new List<string>();
            
            for(ProjectInvoiceLineItem__c Pili : scope){
                preBillMap.put(pili.ProjectInvoice__r.ProjectAccount__c, pili);
                projectAccountIds.add(Pili.ProjectInvoice__r.ProjectAccount__c);
            }
            
            List<ProjectInvoiceLineItem__c> piliList = [SELECT Id, Name,
                                                        ProjectInvoice__c, 
                                                        ProjectInvoice__r.ProjectAccount__c, 
                                                        ProjectInvoice__r.LawsonCompanyCode__c 
                                                        FROM ProjectInvoiceLineItem__c
                                                        WHERE ProjectInvoice__r.ProjectAccount__c IN :projectAccountIds AND
                                                        ProjectInvoice__r.Status__c = :CONSTANTS.PROJECT_INVOICE_STATUS_CREATED AND
                                                        ProjectInvoice__r.Type__c = :CONSTANTS.PROJECT_INVOICE_TYPE_POSTEXECUTION AND
                                                        ProjectInvoice__r.LawsonCompanyCode__c = :CONSTANTS.LAWSON_COMPANY_CODE_US AND
                                                        ServiceType__c = :CONSTANTS.PROJECT_INVOICE_LINEITEM_SERVICETYPE_LABOR];
            
            Set<String> piIds = new Set<String>();
            for(ProjectInvoiceLineItem__c pili : piliList){
                piIds.add(pili.ProjectInvoice__c);
            }
            
            List<ProjectInvoice__c> piList = [SELECT Id, Name, ProjectAccount__c, LawsonCompanyCode__c 
                                              FROM ProjectInvoice__c
                                              WHERE ID IN :piIds];
            
            /*                        
Map<string, ProjectInvoice__c> paProjectInvoiceMap = new Map<string, ProjectInvoice__c>();
for(ProjectInvoice__c pi : piList){
paProjectInvoiceMap.put(pi.ProjectAccount__c, pi);
}                                

for(ProjectInvoiceLineItem__c Pili : scope){                        
if (paProjectInvoiceMap.get(Pili.ProjectInvoice__r.ProjectAccount__c) == null) {
piNeededForprojectAccountIds.add(Pili.ProjectInvoice__r.ProjectAccount__c);                
}
}

List<ProjectAccount__c> projectAccountList = [SELECT Id, Account__c, Project__c
FROM ProjectAccount__c
WHERE
Id in :piNeededForprojectAccountIds];

for(ProjectAccount__c pa : projectAccountList){
newpiList.add(CreateProjectInvoice(pa, CONSTANTS.LAWSON_COMPANY_CODE_US));
}        

result.add(AppUtil.analyzeSaveResultList('insert ProjectInvoice for Credit', Database.Insert(newpiList)));

piList.addAll(newpiList);
*/
            
            for(ProjectInvoice__c newpi : piList){
                
                ProjectInvoiceLineItem__c preBillPiliForPa = preBillMap.get(newpi.ProjectAccount__c);
                
                ProjectInvoiceLineItem__c pili = new ProjectInvoiceLineItem__c();
                pili.ProjectInvoice__c = newpi.Id;
                pili.Type__c = Constants.PROJECT_INVOICE_LINEITEM_TYPE_LUMPSUM;
                pili.ServiceType__c = Constants.PROJECT_INVOICE_LINEITEM_SERVICETYPE_PB_APPLIED;
                pili.Product__c = preBillPiliForPa.Product__c;
                pili.Amount__c = preBillPiliForPa.Amount__c != null ? preBillPiliForPa.Amount__c * -1 : preBillPiliForPa.Amount__c;
                pili.Rate__c = preBillPiliForPa.Rate__c != null ? preBillPiliForPa.Rate__c * -1 : preBillPiliForPa.Rate__c;
                pili.AccrualAmount__c = preBillPiliForPa.AccrualAmount__c;
                pili.QuantityOverride__c = 1;
                pili.Description__c = preBillPiliForPa.ProjectInvoice__r.ExternalInvoiceNumber__c == null ? 'External Invoice Number Not Available' : 
                'Less Pre-bill invoice ' + preBillPiliForPa.ProjectInvoice__r.ExternalInvoiceNumber__c;
                pili.LawsonDivision__c = Constants.LAWSON_DIVISION;
                pili.LawsonUnit2__c = Constants.LAWSON_UNIT;
                pili.LawsonAccount2__c = Constants.LAWSON_ACCOUNT;
                pili.LawsonSubAccount2__c = Constants.LAWSON_SUB_ACCOUNT;
                
                pili.LineItemOrder__c = AppUtil.CreditLineItemOrder;
                newpiliList.add(pili);        
                preBillProjectInvoice.add(preBillPiliForPa.ProjectInvoice__c);
            }
            
            result.add(AppUtil.analyzeSaveResultList('Insert Project Invoice Line Item for Credit', Database.Insert(newpiliList)));
            
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
        } catch (Exception ex) {
            result.add(genError(ex));
            this.responses.add(result);
            hasError = true;
        }
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
    
    Map<String, Object> genError(Exception ex) {
        Map<String, Object> err = new Map<String, Object>();
        err.put('topic', 'exception');
        err.put('messages', new Object[] {ex.getMessage(), ex.getLineNumber(), ex.getStackTraceString()});
        return err;
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
//Test