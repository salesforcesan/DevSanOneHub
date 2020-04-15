public with sharing class LightningProjectAccountsController {
    
    @AuraEnabled
    public static list<Object> GetProjectAccount(String projectId) {
        checkProjectId(projectId);
        try{
            return  ProjectAccountModel.create(projectId).getList();
        }
        catch(CustomException cust){
            throw new AuraHandledException(cust.getStackTraceString());
        }
        catch(Exception ex){
            throw new AuraHandledException(ex.getStackTraceString());
        }
        
    }
    
    static void checkProjectId(String projectId){
        if (String.isBlank(projectId)){
            throw new AuraHandledException('The project Id is required.');
        }
    }
    
    @AuraEnabled
    public static list<Object> GetAccounts(String searchText, String projectid, Boolean getAll) {
        
        String accountQuery = '';
        
        if (getAll) {
            accountQuery = 'SELECT Name, Id, Owner.name, Phone, IsApproved__c, OneHubAccountType__c ' 
                + ' FROM Account '
                + 'WHERE CanRequestProjects__c = true';
        } else {
            accountQuery = 'SELECT Name, Id, Owner.name, Phone, IsApproved__c, OneHubAccountType__c ' 
                + ' FROM Account '
                + 'WHERE CanRequestProjects__c = true and name like \'%' + searchText + '%\'';
        }        
        
        if (projectid != null && projectid != '')
        {
            accountQuery = accountQuery + ' AND Id not in ( Select Account__c from ProjectAccount__c WHERE Project__c = \'' + projectid + '\')';
            
        }
        
        accountQuery = accountQuery + ' LIMIT 20';
        
        list<Account> accounts = Database.query(accountQuery); 
        
        list<AccountWrapper> awList = new list<AccountWrapper>();
        AccountWrapper ac;
        for(Account acct : accounts)
        {            
            awList.add(new AccountWrapper(acct));
        }
        
        Return awList;
    }
    
    @AuraEnabled
    public static string AddAccount(List<string> accounts, String projectId) {
        
        ResponseWrapper rw;
        List<ProjectAccount__c> ProjectAccounts = new List<ProjectAccount__c>();
        boolean isPrimarySet = false;
        
        Integer temp = [select count() from ProjectAccount__c where project__c =: projectId and IsPrimary__c=true];
        isPrimarySet = temp>0;
        
        for(string account : accounts)
        {
            ProjectAccount__c newProjectAccount = new ProjectAccount__c(Account__c = account, project__c = projectId);
            if(!isPrimarySet){
                newProjectAccount.IsPrimary__c=true;
                isPrimarySet=true;
            }
            
            ProjectAccounts.add(newProjectAccount);     
        }      
        try{
            insert ProjectAccounts;  
            rw = ResponseWrapper.getInstance(CONSTANTS.RESPONSE_STATE_SUCCESS, 'Successfully added account to project', 'SUCCESS');
        }
        catch(System.DmlException e) {
            String dmlMessage = e.getDmlMessage(0);
            if(e.getDmlType(0) == StatusCode.FIELD_FILTER_VALIDATION_EXCEPTION){
                dmlMessage = 'The selected account does not have approval to be added to a project. ';
                
            }
            throw new System.AuraHandledException(e.getDmlMessage(0)); 
        }
        
        catch(Exception ex) {
            throw new System.AuraHandledException(ex.getMessage()); 
        }
        
        return JSON.serialize(rw);
        
    }  
        
    @AuraEnabled
    public static string RemoveAccountsFromProject(string ProjectAccountId) {
        ResponseWrapper rw;
        system.debug(ProjectAccountId);
        ProjectAccount__c ProjectAccount = [Select Id, Project__c, Account__c from ProjectAccount__c where id =: ProjectAccountId ];
        
        system.debug(ProjectAccount.Id);
        //oh-2961
        ValidateBeforeRemoveAccount(ProjectAccount.Project__c, ProjectAccount.Account__c);
        id projID = ProjectAccount.Project__c;
        try{  
            delete ProjectAccount;
            //check if only one account exist
            list<ProjectAccount__c> ProjAcctList = getAccountList(projID);
            system.debug('~~ProjAcctList.size()~~'+ProjAcctList.size());
            if(ProjAcctList.size()==1){                
                list<ProjectServiceTarget__c> PSTList = [Select Id, ProjectAccount__c From ProjectServiceTarget__c where ProjectService__r.Project__c =: projID And ProjectAccount__c = null];
                system.debug('~~PSTList.size()~~'+PSTList.size());
                for(ProjectServiceTarget__c obj:PSTList){
                    obj.ProjectAccount__c = ProjAcctList[0].id;
                }
                update PSTList;
                
            }
 
            rw = ResponseWrapper.getInstance(CONSTANTS.RESPONSE_STATE_SUCCESS, 'Successfully deleted account from project', 'SUCCESS');
        }
        catch(Exception ex){
           
            throw new AuraHandledException(ex.getMessage());
            
        }
        
        return JSON.serialize(rw);
        
    } 
    
    //oh-2961:  Verify that Account cannot be removed if Service tied to account is not removed.
    static void ValidateBeforeRemoveAccount(Id project, Id account){
        AggregateResult[] results = [SELECT count(Id) cnt 
                                     FROM ProjectService__c 
                                     WHERE Project__c=:project 
                                     AND Service__r.Account__c=:account];
        if(results.size() > 0 && Integer.valueOf(results[0].get('cnt')) > 0) {
            throw new AuraHandledException('The account can\'t be deleted. There are still some services associated to this account.');
        }
    }
    
    static list<ProjectAccount__c> getAccountList(Id project){
        return [SELECT id FROM ProjectAccount__c WHERE Project__c=:project];
    }
    
    @AuraEnabled
    public static string makeAcctPrimary(string ProjectAccountId) {
        ResponseWrapper rw;
        system.debug(ProjectAccountId);
        
        ProjectAccount__c ProjectAccount = [Select Id,IsPrimary__c,project__c from ProjectAccount__c where id =: ProjectAccountId ];
        ProjectAccount.IsPrimary__c=true;
        
        
        ProjectAccount__c OldProjectAccount = [Select Id,IsPrimary__c from ProjectAccount__c where IsPrimary__c=true and project__c =:ProjectAccount.Project__c  ];
        OldProjectAccount.IsPrimary__c=false;
        update OldProjectAccount;
        
        update ProjectAccount;
        
        
        system.debug('+--+'+ProjectAccount.Id);
        
        try{
            rw = ResponseWrapper.getInstance(CONSTANTS.RESPONSE_STATE_SUCCESS, 'Successfully changed primary account', 'SUCCESS');
        }
        catch(Exception ex){
            rw = ResponseWrapper.getInstance(CONSTANTS.RESPONSE_STATE_ERROR, 'Unable to change primary account. Details: ' + ex.getMessage(), 'ERROR'); 
        }
        
        return JSON.serialize(rw);
        
    } 
    
    @AuraEnabled
    public static list<ProjectServiceTarget__c> getProjectServiceTarget(String projectId) {  
        return LightningProjectServiceTargetsController.getProjectServiceTarget(projectId);
    }
    
    @AuraEnabled
    public static String getNamespaceApex() {
        return CONSTANTS.CURRENTNAMESPACEPREFIX;
    }        
    
}