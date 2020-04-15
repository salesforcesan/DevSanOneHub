public class PILineItemDetailTriggerHandler extends TriggerHandler{
    
    public override void beforeUpdate() {      
        
        Map<id,ProjectInvoiceLineItemDetail__c> pilidAccountChangedList = new Map<id,ProjectInvoiceLineItemDetail__c>();
        
        if (TriggerUtil.skipProjectInvoiceLineItemDetailTrigger) return;        
        
        for (ProjectInvoiceLineItemDetail__c pilid: (List<ProjectInvoiceLineItemDetail__c> ) Trigger.new) {
            
            sObject obj = Trigger.oldMap.get(pilid.Id);
            
            if (obj == null){ continue; }
            
            ProjectInvoiceLineItemDetail__c oldPilid = (ProjectInvoiceLineItemDetail__c)obj;
            
            if (pilid.Account__c != oldPilid.Account__c) 
            {
                pilidAccountChangedList.put(pilid.Id,pilid);                
            }
        }       
        
        saveAccountChange(pilidAccountChangedList);
    }
    
    public void saveAccountChange(Map<id,ProjectInvoiceLineItemDetail__c> pilidAccountChangedList){
        
        set<id> projectIds = new set<id>();
        set<String> locationNumbers = new set<String>();
        List<ProjectInvoiceLineItem__c> newpilis = new List<ProjectInvoiceLineItem__c>();
        set<id> projectInvoiceLineItemDetailIds = new Set<id>();
        Map<string, ProjectAccount__c> projectAccountMap = new Map<string, ProjectAccount__c>();
        map<String,ProjectInvoice__c> piMap = new map<String,ProjectInvoice__c>();		
        List<ProjectInvoice__c> newPiList= new List<ProjectInvoice__c>();
        map<string,ProjectInvoiceLineItem__c> projectInvoiceToLineItemMap = new map<string,ProjectInvoiceLineItem__c>();
        Map<String, ProjectInvoiceLineItem__c> piliMap =new Map<String, ProjectInvoiceLineItem__c>(); 
        
        List<Location__c> locationList = new List<Location__c>();
        Map<String,Location__c> locationMap = new Map<String,Location__c>();
                
        for (ProjectInvoiceLineItemDetail__c pilid: pilidAccountChangedList.values()) {            
            projectIds.add(pilid.ProjectId__c);
            
            // In case if there is no project location attached
            if (pilid.ProjectLocation__c == null && pilid.LocationNumber__c != null){
                locationNumbers.add(pilid.LocationNumber__c);
            }
        }
        
        if (locationNumbers.size() > 0)
        {
            locationList = [select Id,LocationNumber__c, State__c from Location__c where LocationNumber__c in :locationNumbers];    
            if (locationList != null && locationList.size() > 0)
            {
                for(Location__c loc :locationList){
                    locationMap.put(loc.LocationNumber__c, loc);
                }
            }            
        }
        

        List<ProjectAccount__c> paList = [Select Id, Project__c, Account__c 
                                          From ProjectAccount__c 
                                          where Project__c in: projectIds];
        
        for(ProjectAccount__c pa : paList){
            projectAccountMap.put(string.valueOf(pa.Project__c) + string.valueOf(pa.Account__c), pa);
        }        
        
        List<ProjectInvoice__c> piList = [Select Id, Account__c, Project__c, ProjectAccount__c, LawsonCompanyCode__c  
                                          From ProjectInvoice__c 
                                          Where Project__c in :projectIds
                                          AND Status__c = :CONSTANTS.PROJECT_INVOICE_STATUS_CREATED 
                                          AND Type__c = :CONSTANTS.PROJECT_INVOICE_TYPE_POSTEXECUTION];       
        
        for(ProjectInvoice__c pi : piList){
            piMap.put(string.valueOf(pi.Project__c) + string.valueOf(pi.Account__c) + string.valueOf(pi.LawsonCompanyCode__c), pi);
        }
        
        for (ProjectInvoiceLineItemDetail__c pilid: pilidAccountChangedList.values()) {
            
            ProjectAccount__c pa;           
            
            //If no project account is found for the account selected then raise error
            if (pilid.Account__c != null){                         
                pa = projectAccountMap.get(pilid.ProjectId__c + string.valueOf(pilid.Account__c));
                if (pa == null) { 
                    
                    system.debug('error with pilid.Account__c:' + pilid.Account__c);
                    pilid.addError('selected account is not mapped to this project');
                    continue;
                }
            }
            
            string lawsonCompanyCode = (pilid.ProjectLocationState__c == CONSTANTS.STATE_CODE_PR ? CONSTANTS.LAWSON_COMPANY_CODE_PR : CONSTANTS.LAWSON_COMPANY_CODE_US);
            if (pilid.ProjectLocation__c == null){
                Location__c loc = locationMap.get(pilid.LocationNumber__c);
                if (loc != null){
                    lawsonCompanyCode = (loc.State__c == CONSTANTS.STATE_CODE_PR ? CONSTANTS.LAWSON_COMPANY_CODE_PR : CONSTANTS.LAWSON_COMPANY_CODE_US);
                }
                
            }
            
            // To create project invoice if project invoice does not exist for the account \ un reconciled
            if (!(piMap.containsKey(pilid.ProjectId__c + string.valueOf(pilid.Account__c) + lawsonCompanyCode))){
                
                ProjectInvoice__c pi = new ProjectInvoice__c();
                pi.Project__c = pilid.ProjectId__c;
                pi.Status__c = CONSTANTS.PROJECT_INVOICE_STATUS_CREATED;
                pi.Type__c = CONSTANTS.PROJECT_INVOICE_TYPE_POSTEXECUTION;
                pi.LawsonCompanyCode__c = lawsonCompanyCode;
                if (pilid.Account__c != null) { pi.Account__c = pilid.Account__c; }
                
                if (pa != null) { pi.ProjectAccount__c = pa.Id; }
                
                newPiList.add(pi);
                
                // Add the newly created project invoice to the map
                piMap.put(string.valueOf(pi.Project__c) + string.valueOf(pi.Account__c) + string.valueOf(pi.LawsonCompanyCode__c), pi);
                
            }            
        }
        
        insert newPiList;
        
        //To get the id of the new project invoice 
        newPiList = [Select Id, Account__c, Project__c, ProjectAccount__c 
                     From ProjectInvoice__c 
                     Where Id in :newPiList];                  
        
        //Adding to existing list of project invoice
        piList.addall(newPiList);
        
        //To get all project invoice line item for the projects where account has been changed in line item details
        List<ProjectInvoiceLineItem__c> piliList = [SELECT 
                                                    Id, 
                                                    ProjectInvoice__c,
                                                    ProjectInvoice__r.Project__c,                                                    
                                                    ProjectInvoice__r.Account__c,
                                                    ProjectInvoice__r.LawsonCompanyCode__c,
                                                    ServiceType__c
                                                    FROM ProjectInvoiceLineItem__c 
                                                    WHERE ProjectInvoice__r.Project__c in :projectIds
                                                    AND ProjectInvoice__r.Status__c = :CONSTANTS.PROJECT_INVOICE_STATUS_CREATED 
                                                    AND ProjectInvoice__r.Type__c = :CONSTANTS.PROJECT_INVOICE_TYPE_POSTEXECUTION
                                                    And ServiceType__c =: CONSTANTS.PROJECT_INVOICE_LINEITEM_SERVICETYPE_PRODUCT];               
        
        for(ProjectInvoiceLineItem__c pili : piliList)
        {
            projectInvoiceToLineItemMap.put(pili.ProjectInvoice__c,pili);
        }
        
        //Check if all project invoice has corresponding project invoice line item if not create one
        for(ProjectInvoice__c pi : piList){
            if (!(projectInvoiceToLineItemMap.containsKey(pi.id))){
                ProjectInvoiceLineItem__c pili = new ProjectInvoiceLineItem__c();
                pili.ProjectInvoice__c = pi.Id;
                pili.Type__c = Constants.PROJECT_INVOICE_LINEITEM_TYPE_USAGE;
                pili.ServiceType__c = Constants.PROJECT_INVOICE_LINEITEM_SERVICETYPE_PRODUCT;    
                pili.Amount__c = 0;
                newpilis.add(pili);  
            }
        }
        
        insert newpilis;
        
        List<ProjectInvoiceLineItem__c> newPiliList = [Select 
                                                       Id, 
                                                       ProjectInvoice__c,
                                                       ProjectInvoice__r.Project__c,                    
                                                       ProjectInvoice__r.Account__c,
                                                       ProjectInvoice__r.LawsonCompanyCode__c,
                                                       ServiceType__c
                                                       From ProjectInvoiceLineItem__c 
                                                       where Id in : newpilis];               
        
        piliList.addall(newPiliList);        
        
        
        // create a map project invoice line item
        for(ProjectInvoiceLineItem__c pili : piliList){
            piliMap.put(string.valueOf(pili.ProjectInvoice__r.Project__c) + string.valueOf(pili.ProjectInvoice__r.Account__c) + string.valueOf(pili.ProjectInvoice__r.LawsonCompanyCode__c), pili);
        }
        
        // To assign ProjectInvoiceLineItemDetail to approriate ProjectInvoiceLineItem
        for (ProjectInvoiceLineItemDetail__c pilid: pilidAccountChangedList.values()) {
            
            string lawsonCompanyCode = (pilid.ProjectLocationState__c == CONSTANTS.STATE_CODE_PR ? CONSTANTS.LAWSON_COMPANY_CODE_PR : CONSTANTS.LAWSON_COMPANY_CODE_US);
            
            if (pilid.ProjectLocation__c == null){
               	Location__c loc = locationMap.get(pilid.LocationNumber__c);				
                if (loc != null){
                    lawsonCompanyCode = (loc.State__c == CONSTANTS.STATE_CODE_PR ? CONSTANTS.LAWSON_COMPANY_CODE_PR : CONSTANTS.LAWSON_COMPANY_CODE_US);
                }
            }
            
            ProjectInvoiceLineItem__c piliObj = piliMap.get(string.valueOf(pilid.ProjectId__c) + string.valueOf(pilid.Account__c) + lawsonCompanyCode);
            
            if (piliObj != null){
                pilid.ProjectInvoiceLineItem__c = piliObj.Id;
            }
        }        
    }    
}