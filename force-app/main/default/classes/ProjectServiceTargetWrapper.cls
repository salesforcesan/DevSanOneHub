public class ProjectServiceTargetWrapper {
    
    @AuraEnabled
    public String ProjectServiceTargetId{get;set;}
    @AuraEnabled
    public String ProjectServiceId{get;set;}
    @AuraEnabled
    public String TargetId{get;set;}
    @AuraEnabled
    public String TargetName{get;set;}
    @AuraEnabled
    public String ImageURL{get;set;}
    @AuraEnabled
    public String UPC{get;set;}
    @AuraEnabled
    public String Description{get;set;}
    @AuraEnabled
    public String Quantity{get;set;}
    @AuraEnabled
    public Boolean Selected{get; set;}
    @AuraEnabled
    public string ProjectStatus{get; set;}
    @AuraEnabled
    public string AccountInfo{get; set;}
    @AuraEnabled 
    public Boolean canDelete{get;set;}
    @AuraEnabled
    public string visibility{get; set;}
    @AuraEnabled 
    public string TargetType{get; set;}
    @AuraEnabled
    public string TargetUse{get; set;}
    @AuraEnabled
    public string StockCode{get; set;}    
    @AuraEnabled
    public string Account{get; set;}
    @AuraEnabled
    public string AccountName{get; set;}
    @AuraEnabled
    public String ProjectAccountId{get;set;}    
    @AuraEnabled
    public string InvalidTargetSearchText {get; set;}
    @AuraEnabled
    public decimal SortOrder {get; set;}
    
    public ProjectServiceTargetWrapper()
    {
        
    }
    
    public ProjectServiceTargetWrapper(ProjectServiceTarget__c projectServiceTarget)
    {
        ProjectServiceTargetId = projectServiceTarget.Id;
        ProjectServiceId = projectServiceTarget.ProjectService__c;
        TargetId = projectServiceTarget.Target__c;
        TargetName = projectServiceTarget.TargetName__c;           
        ImageURL = projectServiceTarget.Target__r.ImageURL__c;   
        UPC = projectServiceTarget.TargetUPC__c;           
        Description = projectServiceTarget.TargetDescription__c;
        Selected = false;
        SortOrder = projectServiceTarget.sortorder__c;
        StockCode = projectServiceTarget.Target__r.StockCode__c;
        ProjectStatus = projectServiceTarget.ProjectService__r.Project__r.Status__c;
        AccountInfo = projectServiceTarget.Target__r.AccountInfo__c;
        visibility = projectServiceTarget.Visibility__c;
        canDelete= !UIConfig.checkFieldHidden(projectServiceTarget.ProjectService__r.Project__r.Status__c, 'ProjectTarget__c.Delete');
        TargetType = projectServiceTarget.ProjectService__r.TargetType__c;
        TargetUse = projectServiceTarget.Type__c;
        Account = projectServiceTarget.Account__c;
        AccountName = projectServiceTarget.ProjectAccount__r.AccountName__c;
        ProjectAccountId = projectServiceTarget.ProjectAccount__c;
    }
    
    public ProjectServiceTargetWrapper(Target__c target)
    {        
        TargetId = target.Id;
        TargetName = target.Name;           
        ImageURL = target.ImageURL__c;   
        UPC = target.UPC__c;           
        Description = target.Description__c;   
        Selected = false;
        StockCode = target.StockCode__c;
        AccountInfo = target.AccountInfo__c;
        
    }
}