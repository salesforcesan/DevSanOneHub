public class ProjectServiceMaterialWrapper {
    
    @AuraEnabled
    public String ProjectServiceMaterialId {get;set;}
    
    @AuraEnabled
    public String ProjectServiceId {get;set;}
    
    @AuraEnabled
    public String MaterialId {get;set;}
    
    @AuraEnabled
    public String MaterialName {get;set;}
    
    @AuraEnabled
    public Decimal Quantity {get;set;}
    
    @AuraEnabled
    public Boolean Selected {get; set;}
    
    @AuraEnabled
    public String ProjectServiceTitle {get;set;}
    
    @AuraEnabled
    public String FulfillmentCenterName {get;set;}
    
    @AuraEnabled
    public String UseType {get;set;}
    
    @AuraEnabled
    public String ShipTo {get;set;}
    
    @AuraEnabled
    public String ExternalId {get;set;}
    
    @AuraEnabled
    public String ProjectStatus {get;set;}
    
        
    public ProjectServiceMaterialWrapper()
    {
        
    }
    
    public ProjectServiceMaterialWrapper(ProjectServiceMaterial__c projectServiceMaterial)
    {
        ProjectServiceMaterialId = projectServiceMaterial.Id;
        ProjectServiceId = projectServiceMaterial.ProjectService__c;
        MaterialId = projectServiceMaterial.Material__c;
        MaterialName = projectServiceMaterial.MaterialName__c;           
        Quantity = projectServiceMaterial.Quantity__c;
        ProjectServiceTitle = projectServiceMaterial.ProjectService__r.ServiceTitle__c;
        FulfillmentCenterName = projectServiceMaterial.Material__r.FulfillmentCenterName__c;
        ExternalId = projectServiceMaterial.Material__r.ExternalId__c;
        ShipTo = projectServiceMaterial.ShipTo__c;
        UseType = projectServiceMaterial.UseType__c;
        ProjectStatus = projectServiceMaterial.Projectservice__r.Project__r.Status__c;
        Selected = false;
    }
    
    public ProjectServiceMaterialWrapper(Material__c material)
    {        
        MaterialId = material.Id;
        MaterialName = material.Name;  
        Quantity = 0;
        Selected = false;
        FulfillmentCenterName = material.FulfillmentCenterName__c;
        ExternalId = material.ExternalId__c;
    }
}