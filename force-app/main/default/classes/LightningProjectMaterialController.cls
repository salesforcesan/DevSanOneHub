public class LightningProjectMaterialController {
    
    @AuraEnabled
    public static list<Object> GetProjectServiceMaterials(String projectId) {
        
        String equipmentQuery = 'SELECT Name, Id, ShipTo__c, UseType__c, MaterialName__c, Quantity__c, projectservice__r.ServiceName__c, ProjectService__r.ServiceTitle__c, Material__r.FulfillmentCenterName__c, material__r.ExternalId__c, ProjectService__r.Project__r.StartDate__c, Projectservice__r.Project__r.Status__c ' 
            + 'FROM ProjectServiceMaterial__c '
            + 'WHERE projectservice__r.Project__c = \'' + projectId + '\''; 
        
        
        list<ProjectServiceMaterial__c> materials = Database.query(equipmentQuery);  
        
        list<ProjectServiceMaterialWrapper> returnMaterials = new List<ProjectServiceMaterialWrapper>();
        ProjectServiceMaterialWrapper pw;
        for(ProjectServiceMaterial__c material : materials)
        {
            returnMaterials.add( new ProjectServiceMaterialWrapper(material));         
        }
        
        return returnMaterials;        
    }
    
    @AuraEnabled
    public static list<Object> GetMaterials(String searchText) {
        
        String equipmentQuery = 'SELECT Name, Id, FulfillmentCenterName__c, ExternalId__c, IsActive__c ' 
            + 'FROM Material__c '
            + 'WHERE IsActive__c = true and (name like \'%' + searchText + '%\' or ExternalId__c like \'%' + searchText  + '%\')';           
        
        list<Material__c> materials = Database.query(equipmentQuery);  
        
        list<ProjectServiceMaterialWrapper> returnMaterials = new List<ProjectServiceMaterialWrapper>();
        ProjectServiceMaterialWrapper pw;
        for(Material__c material : materials)
        {
            returnMaterials.add( new ProjectServiceMaterialWrapper(material));         
        }
        
        return returnMaterials;   
    }
    
    @AuraEnabled
    public static list<String> GetProjectServiceOptions(String projectId) {
        
        String equipmentQuery = 'SELECT Id, ServiceTitle__c, ServiceName__c ' 
            + 'FROM ProjectService__c '
            + 'WHERE Project__c = \'' + projectId + '\''; 
        
        
        list<ProjectService__c> services = Database.query(equipmentQuery);
        
        List<String> serviceOptions = new List<String>();
        for(ProjectService__c i : services)
        {
            string ServiceText = string.isEmpty(i.ServiceTitle__c) ? i.ServiceName__c : i.ServiceTitle__c;
            serviceOptions.Add(i.Id + ':' + ServiceText);
        }
        
        return serviceOptions;        
    }
    
    @AuraEnabled
    public static string AddMaterials(String materialId, String projectserviceId, Decimal quantity, String useType, String shipTo) {
        
        ResponseWrapper rw;
        ProjectServiceMaterial__c psm = new ProjectServiceMaterial__c();
        psm.ProjectService__c = projectServiceId; 
        psm.Material__c = materialId;
        psm.Quantity__c = quantity; 
        psm.ShipTo__c = shipTo; 
        psm.UseType__c = useType;
            
        
        try{ 
            insert psm;
            List<Project__c> projects = [SELECT Id, Status__c, IsJobManualRegenReqd__c FROM Project__c WHERE Id IN (SELECT Project__c FROM ProjectService__c WHERE Id = :projectserviceId)];
            Project__c project = projects[0];
            system.debug('projectserviceId: ' + projectserviceId);
            
            if(project.Status__c != CONSTANTS.PROJECT_STATUS_PLANNING)
            {
                system.debug('AAAA');
                List<Job__c> jobs = [SELECT Id, ProjectService__c FROM Job__c WHERE  ProjectService__c =: projectserviceId AND JobStatus__c != :CONSTANTS.JOB_ATTEMPT_STATUS_CANCELED];
                JobUpdatesHelper.createJobMaterials(jobs, new List<ProjectServiceMaterial__c>{ psm });
            }
            
            rw = ResponseWrapper.getInstance(CONSTANTS.RESPONSE_STATE_SUCCESS, 'Successfully added material to project', 'SUCCESS'); 
        }
        catch(System.DmlException e) {
            String dmlMessage = e.getDmlMessage(0);
            if(e.getDmlType(0) == StatusCode.DUPLICATE_VALUE){
                dmlMessage = 'Material is already added';
            }
            
            rw = ResponseWrapper.getInstance(CONSTANTS.RESPONSE_STATE_ERROR, 'Unable to add material - ' + dmlMessage, 'error');
        }
        catch(Exception e){
            rw = ResponseWrapper.getInstance(CONSTANTS.RESPONSE_STATE_ERROR, 'Unable to add material - ' + e.getMessage(), 'ERROR'); 
        }
        return JSON.serialize(rw);   
    }
    
    
    @AuraEnabled
    public static string RemoveMaterialFromService(string projectServiceMaterialID) {
        
        ResponseWrapper rw;
        ProjectServiceMaterial__c projectServiceMaterial = [Select Id from ProjectServiceMaterial__c where id =: projectServiceMaterialID ];
        try{
            delete [Select Id from JobMaterial__c where ProjectServiceMaterial__c = :projectServiceMaterialID ];
            delete projectServiceMaterial;  
            rw = ResponseWrapper.getInstance(CONSTANTS.RESPONSE_STATE_SUCCESS, 'Successfully deleted material from project', 'SUCCESS');
        }
        catch(Exception e){
            rw = ResponseWrapper.getInstance(CONSTANTS.RESPONSE_STATE_ERROR, 'Unable to delete material. Details: ' + e.getMessage(), 'ERROR'); 
        }
        
        return JSON.serialize(rw);
        
    }
    
    
}