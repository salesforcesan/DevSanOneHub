public with sharing class ProjectWrapper {
	
    public ProjectWrapper(){
        this.Namespace = CONSTANTS.CURRENTNAMESPACEPREFIX;
    }
    @AuraEnabled
    public Id Id {get;set;}
    @AuraEnabled
    public String Name {get;set;}
    @AuraEnabled
    public String OperationsTitle {get;set;}
    @AuraEnabled
    public String ProjectNumber {get;set;}
    @AuraEnabled
    public String ProjectTypeName {get;set;}
    @AuraEnabled
    public Boolean IsShowProjectSummary {get;set;}
    
    @AuraEnabled
    public Date StartDate {get;set;}    
    @AuraEnabled
    public Date EndDate {get;set;}
    @AuraEnabled
    public Date ProjectLaunchDate {get;set;}
    @AuraEnabled
    public String Status {get;set;}
    @AuraEnabled
    public String StatusDisplay {get;set;}
    @AuraEnabled
    public Decimal PercentExecuted {get;set;}
    @AuraEnabled
    public Decimal ExecutionSLA {get;set;}
    @AuraEnabled
    public Decimal NumberofJobsException {get;set;}
    @AuraEnabled
    public Decimal NumberofJobsFailedQC {get;set;}
    @AuraEnabled
    public Decimal ServiceCount {get;set;}
    @AuraEnabled
    public Decimal MaxServiceCount {get;set;}
    @AuraEnabled
    public Decimal LocationTotalCount {get;set;}
    @AuraEnabled
    public Decimal NumberOfJobs {get;set;}
    @AuraEnabled
    public Decimal NumberOfDays {get;set;}
	@AuraEnabled
    public Decimal BudgetedLocationsCount {get;set;}    
    @AuraEnabled
    public String OwnerName {get;set;}
    @AuraEnabled
    public String ProjectRetailerName {get;set;}
    @AuraEnabled
    public String Program {get;set;}
    @AuraEnabled
    public String ProjectCycle {get;set;}
    @AuraEnabled
    public String ProjectScheduleOptionName {get;set;}
    @AuraEnabled
    public Boolean IsBundleService{get;set;}
    @AuraEnabled
    public Date LaunchedProjectStartDate {get;set;}
    @AuraEnabled
    public Date LaunchedProjectEndDate {get;set;}
    @AuraEnabled
    public Date ProjectCloseDate {get;set;}
    @AuraEnabled
    public Boolean IsSingleDay{get;set;}
    @AuraEnabled
    public Boolean IsReAttemptDateRequired{get;set;}
    @AuraEnabled
    public Boolean IsPendingChanges{get;set;}
    @AuraEnabled
    public Boolean IsPendingChangeReleaseRequest{get;set;}    
    @AuraEnabled
    public list<ProjectAttributeWrapper> ProjAttributeList{get; set;}    
	@AuraEnabled
    public list<AttributeDefinedResponseWrapper> DefinedResponseList{get; set;}   
    @AuraEnabled
    public String CancelReason{get;set;}
    @AuraEnabled
    public String CancelReasonComment{get;set;}
    @AuraEnabled
    public Boolean OutOfCycleFulfillment{get;set;}
     @AuraEnabled
    public Boolean OverrideAccountAndServiceAccess{get;set;}
    @AuraEnabled
    public Boolean IsJobManualRegenReqd{get;set;}
    @AuraEnabled
    public String DetailReportURL{get;set;}
    @AuraEnabled
    public String ExternalDetailReportURL{get;set;}
    @AuraEnabled
    public String Namespace {get;set;}
    @AuraEnabled
    public String ProjectInstructions {get;set;}
    @AuraEnabled
    public String ApexJobName {get;set;}
    @AuraEnabled
    public Boolean AllowReattempt {get;set;}
    
}