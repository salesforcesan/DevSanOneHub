global class ProjectInvoiceWrapper {
    @AuraEnabled
    public string Id{get; set;}
    @AuraEnabled
    public string Name{get; set;}
    @AuraEnabled
    public string AccountName{get; set;}
     @AuraEnabled
    public string AccountId{get; set;}
    @AuraEnabled
    public string ProjectId{get; set;}
    @AuraEnabled
    public string ProjectNumber{get; set;}    
    @AuraEnabled
    public string ProjectTitle{get; set;}
    @AuraEnabled
    public string EMSId{get; set;}
    @AuraEnabled
    public string LawsonCompanyCode{get; set;}
    @AuraEnabled
    public string Description{get; set;}
    @AuraEnabled
    public boolean IsGrouped{get; set;}
    @AuraEnabled
    public string GroupedInvoiceId{get; set;}
    @AuraEnabled
    public Date ProjectStartDate{get; set;}    
    @AuraEnabled
    public DateTime CreatedDate{get; set;}
    @AuraEnabled
    public Date DueDate{get; set;}
    @AuraEnabled
    public Decimal InvoiceTotalAmount{get; set;}
    @AuraEnabled
    public string PONumber{get; set;}
    @AuraEnabled
    public string Type{get; set;}
    @AuraEnabled
    public string BillToContactName{get; set;}
    
    @AuraEnabled
    public string ClonedFrom {get; set;}
    @AuraEnabled
    public string CloneReasonCode {get; set;}
    @AuraEnabled
    public string CloneReasonComment {get; set;}
    @AuraEnabled
    public string Status {get; set;}    
    @AuraEnabled
    public string sObjectAPIName {get; set;}    
    
global ProjectInvoiceWrapper()
    {
        Id = '';
        Name = '';
        AccountId = '';
        AccountName = '';
        ProjectId = '';
        Type = '';
        ProjectTitle = '';
        LawsonCompanyCode = '';
        Description = '';
    }
    
global ProjectInvoiceWrapper(ProjectInvoice__c projectInvoice)
    {
        Id = projectInvoice.Id;
        Name = projectInvoice.Name;
        AccountId = projectInvoice.Account__c;        
        ProjectId = projectInvoice.Project__c;
        Type = projectInvoice.Type__c;        
        LawsonCompanyCode = projectInvoice.LawsonCompanyCode__c;
        Description = projectInvoice.Description__c;
        Status = projectInvoice.Status__c;
        ClonedFrom =  (projectInvoice.ClonedFrom__c == null) ? '' : projectInvoice.ClonedFrom__c;
        CloneReasonCode = (projectInvoice.CloneReasonCode__c == null) ? '' : projectInvoice.CloneReasonCode__c;
        CloneReasonComment = (projectInvoice.CloneComment__c == null) ? '' : projectInvoice.CloneComment__c;
    }    
}