public class JobAttemptWorkerWrapper {
    @AuraEnabled
    public string Id{get; set;}
    @AuraEnabled
    public string Name{get; set;}
    
    @AuraEnabled
    public string ScheduledDate{get; set;}
    @AuraEnabled
    public string LocationName{get; set;}
    @AuraEnabled
    public string LocationNumber{get; set;}
    @AuraEnabled
    public string LocationCity{get; set;}
    @AuraEnabled
    public string LocationState{get; set;}
    @AuraEnabled
    public string EstimatedMinutes{get; set;}
    
    Public JobAttemptWorkerWrapper(){}
    public JobAttemptWorkerWrapper(JobAttemptWorker__c jaw){
        
        Id = jaw.Id;
        Name = jaw.Name;
        ScheduledDate = string.valueOf(jaw.ScheduledDate__c);
        LocationName =jaw.LocationName__c ;
        LocationNumber = jaw.LocationNumber__c;
        LocationCity=jaw.LocationCity__c;
        LocationState =jaw.LocationState__c;
        EstimatedMinutes= string.valueOf(jaw.EstimatedMinutes__c);
        
    }
}