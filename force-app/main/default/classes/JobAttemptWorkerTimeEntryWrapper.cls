public class JobAttemptWorkerTimeEntryWrapper {
	
    @AuraEnabled
    public ID Id {get; set;}
        
    @AuraEnabled
    Public ID JobAttemptWorkerID {get; set;}
    
    @AuraEnabled
    Public ID JobAttemptId {get; set;}
        
	@AuraEnabled
    Public Datetime StartTime {get; set;}
    
    @AuraEnabled    
    Public double Duration {get; set;}
    
    @AuraEnabled
    Public string TimeEntryType {get; set;}
    
    @AuraEnabled
    Public boolean IsBillable {get; set;}
    
    @AuraEnabled
    Public string TeamLeadUserId {get; set;}
    
	@AuraEnabled
    Public ID ContactId {get; set;}
    
    public JobAttemptWorkerTimeEntryWrapper(JobAttemptWorkerTimeEntry__c jobAttemptWorkerTimeEntry) {
        ID = jobAttemptWorkerTimeEntry.Id;
        JobAttemptWorkerID = jobAttemptWorkerTimeEntry.JobAttemptWorker__c;        
        StartTime = jobAttemptWorkerTimeEntry.StartTime__c;
        Duration = jobAttemptWorkerTimeEntry.Duration__c;
        TimeEntryType = jobAttemptWorkerTimeEntry.TimeEntryType__c;
        IsBillable= jobAttemptWorkerTimeEntry.IsBillable__c;
        TeamLeadUserId = jobAttemptWorkerTimeEntry.TeamLeadUserId__c;
    }
    
    public JobAttemptWorkerTimeEntryWrapper(JobAttemptWorkerTimeEntry__c jobAttemptWorkerTimeEntry, ID contact) {
        ID = jobAttemptWorkerTimeEntry.Id;
        JobAttemptWorkerID = jobAttemptWorkerTimeEntry.JobAttemptWorker__c;
        StartTime = jobAttemptWorkerTimeEntry.StartTime__c;
        Duration = jobAttemptWorkerTimeEntry.Duration__c;
        TimeEntryType = jobAttemptWorkerTimeEntry.TimeEntryType__c;
        IsBillable= jobAttemptWorkerTimeEntry.IsBillable__c;
        TeamLeadUserId = jobAttemptWorkerTimeEntry.TeamLeadUserId__c;
        ContactId = contact;        
    }
    
}