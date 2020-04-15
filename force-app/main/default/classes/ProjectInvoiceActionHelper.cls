public class ProjectInvoiceActionHelper {
    
    public static string GetActiveGroupedInvoices() {
        
        List<ProjectInvoice__c> pis = [SELECT Id, Name, AccountName__c, Description__c, LawsonCompanyCode__c 
                                       FROM ProjectInvoice__c WHERE IsGroupedInvoice__c = true AND
                                       Status__c IN (:Constants.PROJECT_INVOICE_STATUS_CREATED)];
        
        String pistring = JSON.serialize(pis);
        String pisstringsansuuc = pistring.replace('__c', '');
        String pistringsamsns = pisstringsansuuc.replace(CONSTANTS.CURRENTNAMESPACEPREFIX,'');
        
        return pistringsamsns;         
    }
    
    public static string GetInvoiceInfo(String invoiceId) {
        
        List<ProjectInvoiceWrapper> invoiceWrapperList = new List<ProjectInvoiceWrapper>();  
        
        
        List<ProjectInvoice__c> pis = [SELECT Id, Name, Status__c, AccountName__c, Description__c, LawsonCompanyCode__c, 
                                       TotalProjectInvoiceAmountCalculated__c,CreatedDate, GroupedProjectInvoice__c, 
                                       BillToContact__r.Name, Project__c, Project__r.ProjectNumber__c, Project__r.Name, 
                                       Project__r.OperationsTitle__c, Project__r.StartDate__c, DueDate__c, PONumber__c                                            
                                       FROM ProjectInvoice__c WHERE ID = : invoiceId];
        
        
        for (ProjectInvoice__c invoices : pis) {
            ProjectInvoiceWrapper piw = new ProjectInvoiceWrapper();
            piw.Id = invoices.Id;
            
            piw.AccountName = invoices.AccountName__c;
            piw.InvoiceTotalAmount = invoices.TotalProjectInvoiceAmountCalculated__c;            
            piw.CreatedDate = invoices.CreatedDate;
            piw.DueDate = invoices.DueDate__c;
            //piw.BillToContactName = invoices.BillToContact__r.Name;
            piw.BillToContactName = (invoices.BillToContact__c == null) ? '' : invoices.BillToContact__r.Name;
            
            if (invoices.Project__c != null){
                piw.ProjectStartDate = invoices.Project__r.StartDate__c;       
                piw.ProjectId = invoices.Project__c;
                piw.ProjectTitle = invoices.Project__r.OperationsTitle__c;
                piw.ProjectNumber = invoices.Project__r.ProjectNumber__c;
            }
            
            piw.LawsonCompanyCode = invoices.LawsonCompanyCode__c;
            piw.Name = invoices.Name; 
            piw.PONumber = invoices.PONumber__c;
            piw.Status = invoices.Status__c;
            invoiceWrapperList.add(piw);
        }        
        
        string ret = JSON.serialize(invoiceWrapperList);     
        
        return ret;  
        
    }
    
    
    public static string GetInvoices(String groupedpiid) {
        
        List<ProjectInvoiceWrapper> invoiceWrapperList = new List<ProjectInvoiceWrapper>();  
        
        if(String.isBlank(groupedpiid))
        {
            return JSON.serialize(invoiceWrapperList);
        }  
        
        
        String sObjName = '';
        try {
            Id recordId = Id.valueOf(groupedpiid);            
            sObjName = recordId.getSObjectType().getDescribe().getName();
            
        } catch (System.StringException ex){}
        
        
        
        List<ProjectInvoice__c> pis = [SELECT Id, Name, AccountName__c, Description__c, LawsonCompanyCode__c, 
                                       TotalProjectInvoiceAmountCalculated__c,CreatedDate, GroupedProjectInvoice__c, 
                                       BillToContact__r.Name, Project__c, Project__r.ProjectNumber__c, Project__r.Name, 
                                       Project__r.OperationsTitle__c, Project__r.StartDate__c, DueDate__c, PONumber__c                                            
                                       FROM ProjectInvoice__c WHERE GroupedProjectInvoice__c = : groupedpiid];
        
        
        for (ProjectInvoice__c invoices : pis) {
            ProjectInvoiceWrapper piw = new ProjectInvoiceWrapper();
            piw.Id = invoices.Id;
            piw.AccountName = invoices.AccountName__c;
            piw.InvoiceTotalAmount = invoices.TotalProjectInvoiceAmountCalculated__c;            
            piw.CreatedDate = invoices.CreatedDate;
            piw.DueDate = invoices.DueDate__c;
            piw.BillToContactName = (invoices.BillToContact__c == null) ? '' : invoices.BillToContact__r.Name;
            
            if (invoices.Project__c != null){
                piw.ProjectId = invoices.Project__c;
                piw.ProjectTitle = invoices.Project__r.OperationsTitle__c;
                piw.ProjectNumber = invoices.Project__r.ProjectNumber__c;
                piw.ProjectStartDate = invoices.Project__r.StartDate__c;        
            }
            
            piw.LawsonCompanyCode = invoices.LawsonCompanyCode__c;
            piw.Name = invoices.Name; 
            piw.PONumber = invoices.PONumber__c;
            piw.sObjectAPIName = sObjName;
            invoiceWrapperList.add(piw);
        }        
        
        string ret = JSON.serialize(invoiceWrapperList);     
        
        return ret;  
        
    }
    
    public static string GetAvailableInvoicesforGroupedInvoice(string jsonSearch) {
        
        
        List<SerachProjectInvoiceWrapper> serachList = (List<SerachProjectInvoiceWrapper>) System.JSON.deserialize(jsonSearch, List<SerachProjectInvoiceWrapper>.class);
        
        SerachProjectInvoiceWrapper serach = serachList[0];
        
        List<ProjectInvoiceWrapper> invoiceWrapperList = new List<ProjectInvoiceWrapper>();   
        
        if(String.isNotBlank(serach.InvoiceId)) {
            List<ProjectInvoice__c> gpis = [SELECT Id, Name, Account__c, BillToContact__c, Description__c, LawsonCompanyCode__c,
                                            GroupedProjectInvoice__c
                                            FROM ProjectInvoice__c WHERE Id = : serach.InvoiceId];            
            if (gpis.isEmpty())
            {
                throw new CustomException('Project Invoice not found');
            }            
            
            ProjectInvoice__c gpi = gpis[0];
            serach.BillToContact = (gpi.BillToContact__c == null) ? '' : gpi.BillToContact__c;
            serach.Account = (gpi.Account__c == null) ? '' : gpi.Account__c;
            serach.LawsonCompnanyCode = (gpi.LawsonCompanyCode__c == null) ? '' : gpi.LawsonCompanyCode__c;
        }       
        
        String query = 'SELECT Id, Name' 
            + ' , AccountName__c, Description__c, LawsonCompanyCode__c, TotalProjectInvoiceAmountCalculated__c,CreatedDate, '
            + 'GroupedProjectInvoice__c, BillToContact__r.Name, Project__c, Project__r.ProjectNumber__c, Type__c, ' 
            + ' Project__r.Name, Project__r.OperationsTitle__c, Project__r.StartDate__c, DueDate__c, PONumber__c'
            + ' FROM ProjectInvoice__c '
            + ' WHERE IsGroupedInvoice__c = false' 
            + ' AND GroupedProjectInvoice__c = NULL'
            + ' AND Type__c = \'' + Constants.PROJECT_INVOICE_TYPE_POSTEXECUTION + '\''
            + ' AND BillToContact__c = \'' + serach.BillToContact  + '\''            
            + ' AND Account__c = \'' + serach.Account + '\''
            + ' AND LawsonCompanyCode__c = \'' + serach.LawsonCompnanyCode + '\''
            + ' AND (Status__c = \'' + Constants.PROJECT_INVOICE_STATUS_CREATED + '\''
            + ' OR Status__c = \'' + Constants.PROJECT_INVOICE_STATUS_REVIEWED + '\')'
            + ' AND Status__c != \'' + Constants.PROJECT_INVOICE_STATUS_CANCELED + '\'';        
        
        if(String.isNotBlank(serach.FilterDateRange) && String.isNotBlank(serach.FromDate) && String.isNotBlank(serach.ToDate)) {
            DateTime fromDateTime = (DateTime)Json.deserialize('"'+serach.FromDate+'"', DateTime.class);
            DateTime toDateTime = (DateTime)Json.deserialize('"'+serach.ToDate+'"', DateTime.class);
            if (toDateTime != null){
                toDateTime = toDateTime.AddDays(1);
            }

            Date fromDate = fromDateTime.date();
            Date toDate = toDateTime.date();            
                       
            if(serach.FilterDateRange == 'CreatedDate') {
                query = query + ' and CreatedDate >= :fromDateTime and CreatedDate < :toDateTime';
            }
            else if (serach.FilterDateRange == 'ProjectStartDate'){          
                
                query = query + ' and Project__r.StartDate__c >= :fromDate and Project__r.StartDate__c < :toDate';
            }
            else if (serach.FilterDateRange == 'DueDate'){
                query = query + ' and DueDate__c >= :fromDate and DueDate__c < :toDate';
            }
        }        
        
        system.debug('query:::' + query.replace(' , AccountName__c, Description__c, LawsonCompanyCode__c, TotalProjectInvoiceAmountCalculated__c,CreatedDate, GroupedProjectInvoice__c, BillToContact__r.Name, Project__c, Project__r.ProjectNumber__c, Type__c,  Project__r.Name, Project__r.OperationsTitle__c, Project__r.StartDate__c, DueDate__c, PONumber__c', ''));
        
        
        if(String.isNotBlank(serach.PONumber)){
            String[] PONumberSet = serach.PONumber.split(',');   
            List<String> PONumbers =  new List<String>();
            
            for(string str :PONumberSet){
                str = str.trim();
                PONumbers.add(str);
            }            
            query = query + ' and  PONumber__c in :PONumbers';
        }                         
        
        if(String.isNotBlank(serach.ProjectNumber)){            
            
            String[] projectNumberSet = serach.ProjectNumber.split(',');
            List<String> projectNumbers =  new List<String>();
            for(string str :projectNumberSet){
                str = str.trim();
                projectNumbers.add(str);                
            }                        
            query = query + ' and  ProjectNumber__c in :projectNumbers';
        }         
        
        if(String.isNotBlank(serach.ProjectName)){
            query = query + ' and Project__r.Name LIKE \'%' + serach.ProjectName + '%\'';
        } 
        
        query = query + ' Order By LastModifiedDate Desc';
        
        List<ProjectInvoice__c> pis = Database.query(query);                           
        
        for (ProjectInvoice__c invoices : pis) {
            ProjectInvoiceWrapper piw = new ProjectInvoiceWrapper();
            piw.Id = invoices.Id;
            piw.Type = invoices.Type__c;
            piw.AccountName = invoices.AccountName__c;
            piw.InvoiceTotalAmount = invoices.TotalProjectInvoiceAmountCalculated__c;            
            piw.CreatedDate = invoices.CreatedDate;
            piw.DueDate = invoices.DueDate__c;
            piw.LawsonCompanyCode = invoices.LawsonCompanyCode__c;
            piw.Name = invoices.Name; 
            piw.PONumber = invoices.PONumber__c;                
            
            if (invoices.Project__c != null){
                piw.ProjectId = invoices.Project__c;                
                piw.ProjectTitle = invoices.Project__r.OperationsTitle__c;
                piw.ProjectNumber = invoices.Project__r.ProjectNumber__c;
                piw.ProjectStartDate = invoices.Project__r.StartDate__c; 
            }
            
            piw.BillToContactName = (invoices.BillToContact__c == null) ? '' : invoices.BillToContact__r.Name;
            
            invoiceWrapperList.add(piw);
        }
        
        if(String.isNotBlank(serach.InvoiceToInclude)) {
            List<ProjectInvoiceWrapper> invoiceToInclude = GetInvoicesByName(jsonSearch);
            
            invoiceWrapperList.addAll(invoiceToInclude);
        }
        
        string ret = JSON.serialize(invoiceWrapperList);       
        return ret;  
    }
    
    public static List<ProjectInvoiceWrapper> GetInvoicesByName(string jsonSearch) {
        
        List<SerachProjectInvoiceWrapper> serachList = (List<SerachProjectInvoiceWrapper>) System.JSON.deserialize(jsonSearch, List<SerachProjectInvoiceWrapper>.class);
        
        SerachProjectInvoiceWrapper serach = serachList[0];
        
        List<ProjectInvoiceWrapper> invoiceWrapperList = new List<ProjectInvoiceWrapper>();  
        
        List<String> invoiceToInclude = serach.InvoiceToInclude.split(',');
        
        if(String.isNotBlank(serach.InvoiceToInclude)) {
            List<ProjectInvoice__c> gpis = [SELECT Id, Name, Account__c, BillToContact__c, Description__c, LawsonCompanyCode__c,
                                            GroupedProjectInvoice__c
                                            FROM ProjectInvoice__c WHERE Name IN : invoiceToInclude];
            
            if (gpis.isEmpty())
            {
                throw new CustomException('Project Invoice not found');
            }            
            
            ProjectInvoice__c gpi = gpis[0];
            serach.BillToContact = gpi.BillToContact__c;
            serach.Account = gpi.Account__c;
            serach.LawsonCompnanyCode = gpi.LawsonCompanyCode__c;
        }       
        
        
        String query = 'SELECT Id, Name, ' 
            + 'AccountName__c, Description__c, LawsonCompanyCode__c, TotalProjectInvoiceAmountCalculated__c,CreatedDate, '
            + 'GroupedProjectInvoice__c, BillToContact__r.Name, Project__c, Project__r.ProjectNumber__c,' 
            + ' Project__r.Name, Project__r.OperationsTitle__c, Project__r.StartDate__c, DueDate__c, PONumber__c'
            + ' FROM ProjectInvoice__c '
            + ' WHERE IsGroupedInvoice__c = false'
            + ' AND Name IN :invoiceToInclude';
        
        
        if(String.isNotBlank(serach.FilterDateRange) && String.isNotBlank(serach.FromDate) && String.isNotBlank(serach.ToDate)) {
            DateTime fromDateTime = (DateTime)Json.deserialize('"'+serach.FromDate+'"', DateTime.class);
            DateTime toDateTime = (DateTime)Json.deserialize('"'+serach.ToDate+'"', DateTime.class);
            if (toDateTime != null){
                toDateTime = toDateTime.AddDays(1);
            }

            Date fromDate = fromDateTime.date();
            Date toDate = toDateTime.date();            
                       
            if(serach.FilterDateRange == 'CreatedDate') {
                query = query + ' and CreatedDate >= :fromDateTime and CreatedDate < :toDateTime';
            }
            else if (serach.FilterDateRange == 'ProjectStartDate'){          
                
                query = query + ' and Project__r.StartDate__c >= :fromDate and Project__r.StartDate__c < :toDate';
            }
            else if (serach.FilterDateRange == 'DueDate'){
                query = query + ' and DueDate__c >= :fromDate and DueDate__c < :toDate';
            }
        }        
        
        system.debug('query:::' + query.replace(' , AccountName__c, Description__c, LawsonCompanyCode__c, TotalProjectInvoiceAmountCalculated__c,CreatedDate, GroupedProjectInvoice__c, BillToContact__r.Name, Project__c, Project__r.ProjectNumber__c, Type__c,  Project__r.Name, Project__r.OperationsTitle__c, Project__r.StartDate__c, DueDate__c, PONumber__c', ''));
        
        
        
        
        if(String.isNotBlank(serach.PONumber)){
            String[] PONumberSet = serach.PONumber.split(',');   
            List<String> PONumbers =  new List<String>();
            
            for(string str :PONumberSet){
                str = str.trim();
                PONumbers.add(str);
            }            
            query = query + ' and  PONumber__c in :PONumbers';
        }                         
        
        if(String.isNotBlank(serach.ProjectNumber)){            
            
            String[] projectNumberSet = serach.ProjectNumber.split(',');
            List<String> projectNumbers =  new List<String>();
            for(string str :projectNumberSet){
                str = str.trim();
                projectNumbers.add(str);                
            }                        
            query = query + ' and  ProjectNumber__c in :projectNumbers';
        }         
        
        if(String.isNotBlank(serach.ProjectName)){
            query = query + ' and Project__r.Name LIKE \'%' + serach.ProjectName + '%\'';
        } 
        
        List<ProjectInvoice__c> pis = Database.query(query);                           
        system.debug('pis:::' + pis.size());
        
        
        for (ProjectInvoice__c invoices : pis) {
            ProjectInvoiceWrapper piw = new ProjectInvoiceWrapper();
            piw.Id = invoices.Id;
            piw.ProjectId = invoices.Project__c;
            piw.ProjectTitle = invoices.Project__r.OperationsTitle__c;
            piw.ProjectNumber = invoices.Project__r.ProjectNumber__c;
            piw.AccountName = invoices.AccountName__c;
            piw.InvoiceTotalAmount = invoices.TotalProjectInvoiceAmountCalculated__c;            
            piw.CreatedDate = invoices.CreatedDate;
            piw.DueDate = invoices.DueDate__c;
            //piw.BillToContactName = invoices.BillToContact__r.Name;
            piw.BillToContactName = (invoices.BillToContact__c == null) ? '' : invoices.BillToContact__r.Name;
            piw.ProjectStartDate = invoices.Project__r.StartDate__c;            
            piw.LawsonCompanyCode = invoices.LawsonCompanyCode__c;
            piw.Name = invoices.Name; 
            piw.PONumber = invoices.PONumber__c;
            invoiceWrapperList.add(piw);
        }
        
        
        
        
        return invoiceWrapperList;  
    }
    
    
    
    
    public static string GetAvailableInvoicesforGroupedInvoice(String billToContact,String account,String lawsonCompanyCode) {
        
        List<ProjectInvoiceWrapper> invoiceWrapperList = new List<ProjectInvoiceWrapper>();        
        List<ProjectInvoice__c> pis = [SELECT Id, Name, AccountName__c, Description__c, LawsonCompanyCode__c, 
                                       TotalProjectInvoiceAmountCalculated__c,CreatedDate,
                                       GroupedProjectInvoice__c, BillToContact__r.Name, Project__c, Project__r.OperationsTitle__c, Project__r.StartDate__c
                                       FROM ProjectInvoice__c 
                                       WHERE IsGroupedInvoice__c = false 
                                       AND BillToContact__c = :billToContact  
                                       AND Account__c = :account 
                                       AND LawsonCompanyCode__c = :lawsonCompanyCode 
                                       AND (Status__c = :Constants.PROJECT_INVOICE_STATUS_CREATED 
                                            OR Status__c = :Constants.PROJECT_INVOICE_STATUS_REVIEWED)
                                       AND Type__c = :Constants.PROJECT_INVOICE_TYPE_POSTEXECUTION];
        
        for (ProjectInvoice__c invoices : pis) {
            ProjectInvoiceWrapper piw = new ProjectInvoiceWrapper();
            piw.Id = invoices.Id;
            piw.ProjectId = invoices.Project__c;
            piw.ProjectTitle = invoices.Project__r.OperationsTitle__c;
            piw.AccountName = invoices.AccountName__c;
            piw.InvoiceTotalAmount = invoices.TotalProjectInvoiceAmountCalculated__c;            
            piw.CreatedDate = invoices.CreatedDate;
            piw.DueDate = invoices.DueDate__c;
            //piw.BillToContactName = invoices.BillToContact__r.Name;
            piw.BillToContactName = (invoices.BillToContact__c == null) ? '' : invoices.BillToContact__r.Name;
            piw.ProjectStartDate = invoices.Project__r.StartDate__c;            
            piw.LawsonCompanyCode = invoices.LawsonCompanyCode__c;
            piw.Name = invoices.Name; 
            piw.PONumber = invoices.PONumber__c;
            invoiceWrapperList.add(piw);
        }
        
        string ret = JSON.serialize(invoiceWrapperList);       
        return ret;  
    }
    
    public static Boolean GroupInvoices(List<String> piids, String groupedpiid) {
        
        List<ProjectInvoiceLineItem__c> newpilis = new List<ProjectInvoiceLineItem__c>();
        Map<string,string> lawsonsubaccounttoplid = new Map<string,string>();
        
        
        UnGroupInvoice(groupedpiid);
        
        AggregateResult[] lpsaggresults = [SELECT LawsonSubAccount2__c, ServiceType__c, SUM(AmountCalculated__c) totalamount FROM ProjectInvoiceLineItem__c 
                                           WHERE ProjectInvoice__c IN :piids  AND LawsonSubAccount2__c!= null
                                           AND ServiceType__c IN 
                                           (:CONSTANTS.PROJECT_INVOICE_LINEITEM_SERVICETYPE_LABOR,:CONSTANTS.PROJECT_INVOICE_LINEITEM_SERVICETYPE_PRODUCT, :CONSTANTS.PROJECT_INVOICE_LINEITEM_SERVICETYPE_SALESTAX) 
                                           GROUP BY LawsonSubAccount2__c, ServiceType__c];
        for (AggregateResult ar : lpsaggresults)  {
            
            ProjectInvoiceLineItem__c newpili = new ProjectInvoiceLineItem__c();
            newpili.ProjectInvoice__c = groupedpiid;
            newpili.Type__c = Constants.PROJECT_INVOICE_LINEITEM_TYPE_LUMPSUM;
            newpili.ServiceType__c = String.valueOf(ar.get('ServiceType__c'));
            newpili.Amount__c = ar.get('totalamount') == null? 0:Decimal.valueOf(String.valueof(ar.get('totalamount')));
            newpili.Description__c = String.valueof(ar.get('LawsonSubAccount2__c'));
            newpili.LawsonSubAccount2__c = String.valueof(ar.get('LawsonSubAccount2__c'));
            newpilis.add(newpili);
        }  
        system.debug('new line items: ' + newpilis);
        insert newpilis;
        
        for (ProjectInvoiceLineItem__c pili : newpilis)
        {
            lawsonsubaccounttoplid.put(pili.LawsonSubAccount2__c, pili.Id);
        }
        
        //Update all the source pi and pilis with grouped pi and pili values
        List<ProjectInvoice__c> epis = [Select Id, GroupedProjectInvoice__c FROM ProjectInvoice__c WHERE Id IN :piids ];
        for (ProjectInvoice__c epi : epis)
        {
            epi.GroupedProjectInvoice__c = groupedpiid;
            
        }
        update epis;  
        
        
        List<ProjectInvoiceLineItem__c> epilis = [SELECT Id, LawsonSubAccount2__c, GroupedProjectInvoiceLineItem__c FROM ProjectInvoiceLineItem__c 
                                                  WHERE ProjectInvoice__c IN :piids AND LawsonSubAccount2__c != null
                                                  AND ServiceType__c IN 
                                                  (:CONSTANTS.PROJECT_INVOICE_LINEITEM_SERVICETYPE_LABOR,:CONSTANTS.PROJECT_INVOICE_LINEITEM_SERVICETYPE_PRODUCT, :CONSTANTS.PROJECT_INVOICE_LINEITEM_SERVICETYPE_SALESTAX)];
        for (ProjectInvoiceLineItem__c epili: epilis)
        {
            epili.GroupedProjectInvoiceLineItem__c = lawsonsubaccounttoplid.get(epili.LawsonSubAccount2__c);
        }
        
        return true;
    }
    
    public static void UnGroupInvoice(String groupedpiid) {
        
        //Delete all the lineitems if any, so this can be run multiple times
        //This will also remove the groupedprojectinvoicelineitem from the project invoice line items
        delete [Select Id FROM ProjectInvoiceLineItem__c WHERE ProjectInvoice__c = :groupedpiid];
        
        //Remove the Grouped Project Invoice for the existing Project invoices
        //We are setting this to null initially as the exiisting group could be different
        //from new group. More pis in the first group.
        List<ProjectInvoice__c> epis = [Select Id, GroupedProjectInvoice__c FROM ProjectInvoice__c WHERE GroupedProjectInvoice__c = :groupedpiid ];
        for (ProjectInvoice__c epi : epis)
        {
            epi.GroupedProjectInvoice__c = null;
            
        }
        update epis;
        
    }
    
    //If new group needs to be created "invoiceId" parameter needs to be blank
    //"groupInvoiceToGroup" will have the list of invoice that needs to be in the group
    //
    public static string ManageGroupInvoice(string invoiceId, string groupInvoiceToGroup){
        
        List<ProjectInvoiceWrapper> projectInvoiceList = (List<ProjectInvoiceWrapper>) System.JSON.deserialize(groupInvoiceToGroup, List<ProjectInvoiceWrapper>.class);
        Set<String> invoiceNameList = new Set<String>();
        
        for(ProjectInvoiceWrapper piWrapper :projectInvoiceList){
            
            invoiceNameList.add(piWrapper.Name);
        }        
        
        List<ProjectInvoice__c> gpis = [SELECT Id, Name, Account__c, BillToContact__c, Description__c, LawsonCompanyCode__c, 
                                        GroupedProjectInvoice__c,IsGroupedInvoice__c, Project__c
                                        FROM ProjectInvoice__c 
                                        WHERE Name = :invoiceNameList];
        
        
        if(invoiceId == '' && gpis.size() > 0){
            ProjectInvoice__c pi = gpis[0];
            ProjectInvoice__c newGroupedPi = new ProjectInvoice__c();
            newGroupedPi.Account__c = pi.Account__c;
            newGroupedPi.BillToContact__c = pi.BillToContact__c;
            newGroupedPi.LawsonCompanyCode__c = pi.LawsonCompanyCode__c;
            newGroupedPi.IsGroupedInvoice__c = true;
            newGroupedPi.Project__c = AppUtil.DefaultGroupProject;
            
            newGroupedPi.Status__c = Constants.PROJECT_INVOICE_STATUS_CREATED;
            insert newGroupedPi;
            
            invoiceId = newGroupedPi.Id;
        }
        
        List<ProjectInvoice__c> existingGroupedPIList = [SELECT Id, Name, Account__c, BillToContact__c, Description__c, 
                                                         LawsonCompanyCode__c, GroupedProjectInvoice__c
                                                         FROM ProjectInvoice__c 
                                                         WHERE GroupedProjectInvoice__c =: invoiceId 
                                                         AND GroupedProjectInvoice__c != null];
        
        Map<String, ProjectInvoice__c> objMap1 = new Map<String, ProjectInvoice__c>();
        Map<String, ProjectInvoice__c> objMap2 = new Map<String, ProjectInvoice__c>();
        List<ProjectInvoice__c> toBeRemovedFromGroupList = new List<ProjectInvoice__c>();
        List<ProjectInvoice__c> toBeAddedGroupList = new List<ProjectInvoice__c>();
        
        for(ProjectInvoice__c o : gpis) {
            objMap1.put(o.Id, o);
        }
        
        for(ProjectInvoice__c o : existingGroupedPIList) {
            objMap2.put(o.Id, o);
        }
        
        Set<String> piliToBeAddedGroupList = new Set<String>();
        for (string newObj : objMap1.keySet()){
            if(!objMap2.containsKey(newObj)){
                ProjectInvoice__c pi = objMap1.get(newObj);
                toBeAddedGroupList.add(pi);
                piliToBeAddedGroupList.add(newObj);
            }
        }
        
        Set<String> piliToBeRemovedFromGroupList = new Set<String>();
        for (string newObj : objMap2.keySet()){
            if(!objMap1.containsKey(newObj)){
                ProjectInvoice__c pi = objMap2.get(newObj);
                toBeRemovedFromGroupList.add(pi);
                piliToBeRemovedFromGroupList.add(newObj);
            }
        }
        
        for(ProjectInvoice__c pi : toBeRemovedFromGroupList) {
            pi.GroupedProjectInvoice__c = NULL;
            pi.Status__c = CONSTANTS.PROJECT_INVOICE_STATUS_CREATED;
        }
        
        List<ProjectInvoiceLineItem__c> piLineItemToBRemoved = [select Id, ProjectInvoice__c,  GoverningProjectInvoice__c 
                                                                From ProjectInvoiceLineItem__c 
                                                                Where GoverningProjectInvoice__c in: piliToBeRemovedFromGroupList];
        
        for(ProjectInvoiceLineItem__c pili : piLineItemToBRemoved){
            pili.ProjectInvoice__c = pili.GoverningProjectInvoice__c;
            pili.GoverningProjectInvoice__c = NULL;
        }
        
        update toBeRemovedFromGroupList;
        update piLineItemToBRemoved;        
        
        for(ProjectInvoice__c pi : toBeAddedGroupList) {
            pi.GroupedProjectInvoice__c = invoiceId;
            pi.Status__c = CONSTANTS.PROJECT_INVOICE_STATUS_GROUPED;
        }
        
        List<ProjectInvoiceLineItem__c> piLineItemToBeAdded = [select Id, ProjectInvoice__c, GoverningProjectInvoice__c
                                                               From ProjectInvoiceLineItem__c 
                                                               Where ProjectInvoice__c in: piliToBeAddedGroupList];
        
        for(ProjectInvoiceLineItem__c pili : piLineItemToBeAdded){
            pili.GoverningProjectInvoice__c = pili.ProjectInvoice__c;
            pili.ProjectInvoice__c = invoiceId;
        }
        
        update toBeAddedGroupList;
        update piLineItemToBeAdded;
        
        //To check if any invoice is available in the group
        List<ProjectInvoice__c> groupedPIList = [SELECT Id, Name, Account__c, BillToContact__c, Description__c, 
                                                 LawsonCompanyCode__c, GroupedProjectInvoice__c
                                                 FROM ProjectInvoice__c 
                                                 WHERE GroupedProjectInvoice__c =: invoiceId 
                                                 AND GroupedProjectInvoice__c != null];
        
        if(groupedPIList.size() == 0 ){
            
            ProjectInvoice__c groupedPI = [SELECT Id, Name, Account__c, BillToContact__c, Description__c, 
                                           LawsonCompanyCode__c, GroupedProjectInvoice__c
                                           FROM ProjectInvoice__c 
                                           WHERE ID =: invoiceId];
            
            delete groupedPI;
        }
        
        return invoiceId;
    }
    
    
    
    // Returns a dynamic SOQL statement for the whole object, includes only creatable fields since we will be inserting a cloned result of this query
    public static list<string> getCreatableFieldsSOQL(String objectName){
        
        // Get a map of field name and field token
        Map<String, Schema.SObjectField> fMap = Schema.getGlobalDescribe().get(objectName.toLowerCase()).getDescribe().Fields.getMap();
        list<string> selectFields = new list<string>();
        system.debug('fMap>>' + fMap);
        
        if (fMap != null){
            for (Schema.SObjectField ft : fMap.values()){ // loop through all field tokens (ft)
                Schema.DescribeFieldResult fd = ft.getDescribe(); // describe each field (fd)
                if (fd.isCreateable()){ // field is creatable
                    selectFields.add(fd.getName());
                }
            }
        }
        return selectFields;
    }
    
    public static string FieldNames(string objectName, string fieldsToRemove){
        
        String selects ='';   
        List<String> fieldsToRemoveList = new List<String>();
        
        if (fieldsToRemove != null && fieldsToRemove != ''){
            fieldsToRemoveList = fieldsToRemove.split(',');    
        }
       
        list<string> allFields = getCreatableFieldsSOQL(objectName);        
        list<string> selectFields =  new list<string>();       
        
        for (string fieldName: allFields){
            if(!fieldsToRemoveList.contains(fieldName)){  
                selectFields.add(fieldName);
            }
        }               
        
        if (!selectFields.isEmpty()){
            for (string s:selectFields){
                selects += s + ',';
            }
            if (selects.endsWith(',')){selects = selects.substring(0,selects.lastIndexOf(','));}             
        }
        
        
        return selects;
    }    
    
    
    public static ProjectInvoiceWrapper GetProjectInvoiceDetail(string piId) 
    {
        ProjectInvoiceWrapper piw = new ProjectInvoiceWrapper();
        
        ProjectInvoice__c piList = [SELECT Id, Name, CloneReasonCode__c, Status__c, 
                                    ClonedFrom__c,CloneComment__c, Account__c,Project__c,
                                    Type__c,LawsonCompanyCode__c, Description__c  
                                    FROM ProjectInvoice__c 
                                    WHERE Id =: piId];            
        if (piList != null){
            piw = new ProjectInvoiceWrapper(piList);
        }
        return piw;
    }
    
    public static string CloneProjectInvoice(string piId, string reasonCode, string comments) 
    {
        
        system.debug('CloneProjectInvoice:::');
        
        string objectName = CONSTANTS.CURRENTNAMESPACEPREFIX + 'ProjectInvoice__c';
        string fieldNames = FieldNames(objectName, AppUtil.PI_FieldsToExcludeWhileCloning);        
        
        string query = 'SELECT Id, Name,' + fieldNames + ' FROM ' + objectName + ' WHERE  Id = \'' + piId + '\'';
        system.debug('query:::' + query);
        
        ProjectInvoice__c piList = Database.query(query);        
        
        Map<ProjectInvoiceLineItem__c,List<ProjectInvoiceLineItemDetail__c>> pilidMappingExternalString = new Map<ProjectInvoiceLineItem__c,List<ProjectInvoiceLineItemDetail__c>>();
        Map<string,List<ProjectInvoiceLineItemDetail__c>> pilidMapping  = new Map<string,List<ProjectInvoiceLineItemDetail__c>>();
        Map<string,ProjectInvoiceLineItem__c> piliMap  = new Map<string,ProjectInvoiceLineItem__c>();
        
        List<ProjectInvoiceLineItem__c> newpiliList = new List<ProjectInvoiceLineItem__c>();
        
        string piliObjectName = CONSTANTS.CURRENTNAMESPACEPREFIX + 'ProjectInvoiceLineItem__c';
        string piliFieldNames = FieldNames(piliObjectName, AppUtil.PILI_FieldsToExcludeWhileCloning);
        
        string pilidObjectName = CONSTANTS.CURRENTNAMESPACEPREFIX + 'ProjectInvoiceLineItemDetail__c';
        string pilidFieldNames = FieldNames(pilidObjectName,AppUtil.PILID_FieldsToExcludeWhileCloning);
        
        string piliQuery = 'Select Id, Name, ' + piliFieldNames +', (Select Id, Name, ' + pilidFieldNames +' from Project_Invoice_Line_Items_Detail__r) From ProjectInvoiceLineItem__c Where ProjectInvoice__c = \'' + piId + '\' And Status__c !=\'' +  CONSTANTS.PROJECT_INVOICE_LINEITEM_STATUS_CANCELED  + '\'';
        
        system.debug('piliQuery:::' + piliQuery);
        
        List<ProjectInvoiceLineItem__c> piliList = Database.query(piliQuery);    
        
        ProjectInvoice__c newPi = piList.clone(false, true); //do a deep clone
        newPi.ExternalId__c  = piList.Name + Datetime.now();
        newPi.Status__c = CONSTANTS.PROJECT_INVOICE_STATUS_CREATED;
        newPi.ClonedFrom__c = piId;
        insert newPi;
        
        for(ProjectInvoiceLineItem__c pili : piliList){
            ProjectInvoiceLineItem__c newpili = pili.clone(false, true); //do a deep clone
            newpili.ProjectInvoice__c = newPi.Id;
            newpili.ExternalId__c = pili.Name + Datetime.now();
            newpili.Status__c = '';
            newPiliList.add(newpili);
            piliMap.put(newpili.ExternalId__c, newpili);
            pilidMapping.put(newpili.ExternalId__c,pili.Project_Invoice_Line_Items_Detail__r.deepClone(false,false,false));            
        }        
        
        insert newPiliList;
        
        for(string pili :pilidMapping.keySet()){            
            for(ProjectInvoiceLineItemDetail__c piliLineItem : pilidMapping.get(pili)){   
                
                piliLineItem.ProjectInvoiceLineItem__c = piliMap.get(pili).Id;                                   
            }
        }
        
        List<ProjectInvoiceLineItemDetail__c> newPilidList = new List<ProjectInvoiceLineItemDetail__c>();
        
        for (List<ProjectInvoiceLineItemDetail__c> collection : pilidMapping.values())
            newPilidList.addAll(collection);
        
        insert newPilidList;
        
        piList.CloneReasonCode__c = reasonCode;
        piList.CloneComment__c = comments;
        
        update piList;
        return newPi.Id;
    }
    
    
    public static void CloneProjectInvoiceWithExternalId(string piId){
        List<ProjectInvoice__c> pis = new List<ProjectInvoice__c>{};
            List<ProjectInvoiceLineItem__c> pilis = new List<ProjectInvoiceLineItem__c>{};
                List<ProjectInvoiceLineItemDetail__c> pilids = new List<ProjectInvoiceLineItemDetail__c>{};
                    
                    //ProjectInvoice__c pi = [Select Id,Name,Project__c,Account__c,ExternalId__c from ProjectInvoice__c where Id =: piId];
                    
                    String selects = ''; 
        string objectName = CONSTANTS.CURRENTNAMESPACEPREFIX + 'ProjectInvoice__c';
        list<string> selectFields = getCreatableFieldsSOQL(objectName);
        system.debug('selectFields>>' + selectFields);
        
        
        if (!selectFields.isEmpty()){
            for (string s:selectFields){
                selects += s + ',';
            }
            if (selects.endsWith(',')){selects = selects.substring(0,selects.lastIndexOf(','));}             
        }
        
        system.debug('selects>>' + selects);
        
        
        string query = 'SELECT Id, Name,' + selects + ' FROM ' + objectName + ' WHERE  Id = \'' + piId + '\'';
        ProjectInvoice__c pi = Database.query(query);
        
        ProjectInvoice__c piNew = pi.clone(false, true); //See sObject Clone Method
        piNew.ExternalId__c  = pi.Name + Datetime.now(); //set unique external Id
        pis.add(piNew);
        
        query = 'Select Id, Name, ExternalId__c, ServiceType__c , (Select Id, Name, ProjectInvoiceLineItem__c, ExternalId__c from Project_Invoice_Line_Items_Detail__r) from ProjectInvoiceLineItem__c where ProjectInvoice__c = \'' + piId + '\'';
        List<ProjectInvoiceLineItem__c> piliList = Database.query(query);
        
        //for(ProjectInvoiceLineItem__c pili : [Select Id, Name, (Select Id,ProjectInvoiceLineItem__c from Project_Invoice_Line_Items_Detail__r) from ProjectInvoiceLineItem__c where ProjectInvoice__c = :piId]){
        
        for(ProjectInvoiceLineItem__c pili : piliList){
            ProjectInvoiceLineItem__c newpili = pili.clone(false, true);
            newpili.ExternalId__c = pili.Name + Datetime.now();
            newpili.ProjectInvoice__r = new ProjectInvoice__c(ExternalId__c = piNew.ExternalId__c); //set parent ref            
            pilis.add(newpili);
            
            for(ProjectInvoiceLineItemDetail__c pilid : pili.Project_Invoice_Line_Items_Detail__r){
                
                ProjectInvoiceLineItemDetail__c pilidNew = pilid.clone(false, true);                
                //pilidNew.ExternalId__c = pilid.Name + Datetime.now();
                //pilidNew.ProjectInvoiceLineItem__c = newpili.Id;
                pilidNew.ProjectInvoiceLineItem__r = new ProjectInvoiceLineItem__c(ExternalId__c = newpili.ExternalId__c); //set parent ref// new ProjectInvoiceLineItem__c(ExternalId__c = newpili.ExternalId__c);
                
                pilids.add(pilidNew);
            }            
        }   
        
        insert pis;
        upsert pilis; //upsert matches to accounts using external id
        upsert pilids; //upsert matches to opportunities using external id
        
    }
    
    
}