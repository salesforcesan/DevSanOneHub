public with sharing class ProjectAccountServiceAccessController {
    
    @AuraEnabled
    public static boolean checkIfProjectDataAccessOveride(String projectId) {
        Project__c project = [SELECT OverrideAccountAndServiceAccess__c from Project__c where Id  =:projectId]; 
        return project.OverrideAccountAndServiceAccess__c;       
    }  
    
    @AuraEnabled    
    public static Map<String,Object> GetProjectAccountServiceAccessList(String projectId) {
        
        Map<String,Object> ds = new Map<String, Object>();
        
        Set<ServiceWrapper> serviceList = new Set<ServiceWrapper>();
        
        List<ProjectAccountServiceDataAccessWrapper> PASDataaccess =  new List<ProjectAccountServiceDataAccessWrapper>();
        
        list<ProjectAccount__c> ProjectAccountList = [SELECT Id, Account__c, AccountName__c, Account__r.CMKOneHubAccountID__c FROM ProjectAccount__c where Project__c =:projectId];
        list<ProjectService__c> ProjectServiceList = [SELECT Id, Service__c, ServiceTitle__c FROM ProjectService__c where Project__c =:projectId];
        
        
        for(ProjectService__c projectService : ProjectServiceList){
            ServiceWrapper serviceWrapperObj = new ServiceWrapper();
            serviceWrapperObj.Name = projectService.ServiceTitle__c;            
            serviceList.add(serviceWrapperObj);
        }
        
        
        list<ProjectAccountServiceAccess__c> ProjectAccountServiceAccessList = [SELECT Id, Project__c, ProjectAccount__c,ProjectAccount__r.Id, ProjectAccount__r.AccountName__c, ProjectService__c, ProjectService__r.Id, 
                                                                                AccessLevel__c, UniqueKey__c FROM ProjectAccountServiceAccess__c where Project__c =:projectId];
        
        //When there is no project account or project service, Matrix cannot be built, We return an empty matrix.
        if (ProjectAccountList.size() == 0 || ProjectServiceList.size() == 0)
        {
            return ds;
        }
        
        for (ProjectAccount__c projectAccount :ProjectAccountList)
        {            
            ProjectAccountServiceDataAccessWrapper obj = new ProjectAccountServiceDataAccessWrapper();            
            obj.AccountName = projectAccount.AccountName__c;            
            
            List<ProjectAccountServiceDataAccessWrapper.ProjectAccountService> psList = new List<ProjectAccountServiceDataAccessWrapper.ProjectAccountService>();
            
            for (ProjectService__c projectService :ProjectServiceList)        
            {
                ProjectAccountServiceDataAccessWrapper.ProjectAccountService ps = new ProjectAccountServiceDataAccessWrapper.ProjectAccountService();
                
                String str;
                Id ProjectAccountServiceAccessId;
                ProjectAccountServiceAccess__c PASAccess;
                String ExternalId;
                
                for(ProjectAccountServiceAccess__c objPASAccessList: ProjectAccountServiceAccessList){
                    if (objPASAccessList.ProjectAccount__r.Id == projectAccount.Id && objPASAccessList.ProjectService__r.Id == projectService.Id)
                    {
                        str = objPASAccessList.AccessLevel__c;
                        ProjectAccountServiceAccessId = objPASAccessList.Id;
                        ExternalId = objPASAccessList.UniqueKey__c;
                        PASAccess = objPASAccessList;
                        
                        break;
                    }
                }
                
                if (PASAccess == null)
                {
                    PASAccess = new ProjectAccountServiceAccess__c();
                    PASAccess.Project__c = projectId;
                    PASAccess.ProjectAccount__c = projectAccount.Id;
                    PASAccess.ProjectService__c = projectService.Id;
                    PASAccess.AccessLevel__c = CONSTANTS.PROJECT_ACCOUNT_SERVICE_ACCESS_LEVEL_NO_ACCESS;
                }
                
                ps.ExternalId = ExternalId;
                ps.Access = (str == CONSTANTS.PROJECT_ACCOUNT_SERVICE_ACCESS_LEVEL_FULL_ACCESS ? true : false);
                ps.ProjectAccountServiceAccessId = ProjectAccountServiceAccessId;
                ps.ServiceName = projectService.ServiceTitle__c;
                
                ps.PASAccess = PASAccess;
                psList.add(ps);
            }
            
            obj.ProjectAccountService = psList;
            
            PASDataaccess.add(obj);
        }
        
        ds.put('PASDataAccess', PASDataaccess);
        ds.put('ServiceList', serviceList);
        
        return ds;
    }    
    
    @AuraEnabled    
    public static String saveDataAccess(String projectId,String dataAccessList, Boolean overrideAccess) {
        ResponseWrapper rw;    
        
        List<ProjectAccountServiceDataAccessWrapper> accessList = 
            (List<ProjectAccountServiceDataAccessWrapper>)JSON.deserialize(dataAccessList,List<ProjectAccountServiceDataAccessWrapper>.class);
        
        List<ProjectAccountServiceAccess__c> obj = new List<ProjectAccountServiceAccess__c>();
        List<ProjectAccountServiceAccess__c> objToBeDeleted = new List<ProjectAccountServiceAccess__c>();
        
        for(ProjectAccountServiceDataAccessWrapper accessObj : accessList) {
            for(ProjectAccountServiceDataAccessWrapper.ProjectAccountService obj1 : accessObj.ProjectAccountService){ 
                
                
                if ((!(String.isBlank(obj1.ExternalId)) && obj1.Access == false))
                {
                    objToBeDeleted.add(obj1.PASAccess);
                }
                else if ((!(String.isBlank(obj1.ExternalId)) && overrideAccess == false))
                {
                    objToBeDeleted.add(obj1.PASAccess);
                }
                else if (obj1.Access == true)
                {
                    obj1.PASAccess.AccessLevel__c = CONSTANTS.PROJECT_ACCOUNT_SERVICE_ACCESS_LEVEL_FULL_ACCESS;
                    obj.add(obj1.PASAccess);
                }
            }
        }
        
        try{
            
            // To save data access
            LightningProjectController.saveProjectAccess(projectId,overrideAccess);
            
            upsert obj;            
            
            delete objToBeDeleted;
            
            rw = ResponseWrapper.getInstance(CONSTANTS.RESPONSE_STATE_SUCCESS, 'Project account service data access has been update',CONSTANTS.RESPONSE_STATE_SUCCESS);
            
        }
        catch(Exception ex){            
            
            system.debug(JSON.serialize(rw));
            
            system.debug('ERROR - Project Account Service Data Access: ' + ex.getMessage());
            if(ex.getDmlMessage(0)!='')
                rw = ResponseWrapper.getInstance(CONSTANTS.RESPONSE_STATE_SUCCESS, 'Error updating project account service data access - ' + ex.getDmlMessage(0), CONSTANTS.RESPONSE_STATE_ERROR);
            else
                rw = ResponseWrapper.getInstance(CONSTANTS.RESPONSE_STATE_SUCCESS, 'Error updating project account service data access' , CONSTANTS.RESPONSE_STATE_ERROR);
        }
        return JSON.serialize(rw);
    }   
}