public class JobWrapper {
    
    @AuraEnabled
    public String JobId {get; set;}

    @AuraEnabled
    public String Name {get; set;}
    
    @AuraEnabled
    public Integer PercentComplete {get; set;}
    
    @AuraEnabled
    public Integer EstimatedMinutes {get; set;}
    
    @AuraEnabled
    public Date ScheduledDate {get; set;}

    @AuraEnabled
    public String Status {get; set;}
    
    @AuraEnabled
    public String ExceptionId {get; set;}
    
    @AuraEnabled
    public String ExceptionCode {get; set;}
    
    @AuraEnabled
    public String ExceptionComments {get; set;}
    
    @AuraEnabled
    public String ExceptionName {get; set;}
    
    @AuraEnabled
    public String ExceptionCodeDesc {get; set;}
    
    @AuraEnabled
    public String ServiceTitle {get; set;}
    
    @AuraEnabled
    public String ProjectTitle {get; set;}

    @AuraEnabled
    public String ProjectNumber {get; set;}

    @AuraEnabled
    public String ProjectName {get; set;}

    @AuraEnabled
    public String ProjectStartDate {get; set;}

    @AuraEnabled
    public String ProjectEndDate {get; set;}
    
    @AuraEnabled
    public String LocationNumber {get; set;}

    @AuraEnabled
    public String LocationAddress {get; set;}
    
    @AuraEnabled
    public String JobManualUrl {get; set;}
    

    
    public JobWrapper(Job__c job) {
        JobId = job.Id;
        Name = job.Name;
        if (job.ActiveJobAttempt__r.PercentComplete__c == null)
        {
            PercentComplete = 0;
        }
        else
        {
        	PercentComplete = Integer.valueOf(job.ActiveJobAttempt__r.PercentComplete__c);    
        }
        
        EstimatedMinutes = Integer.valueOf(job.EstimatedMinutes__c);        
        Status = job.JobStatus__c;
        ProjectName = job.Project__r.Name;
        ProjectNumber = job.Project__r.ProjectNumber__c;        
        ProjectStartDate = String.valueOf(job.Project__r.StartDate__c);        
        ProjectEndDate = String.ValueOf(job.Project__r.EndDate__c); 
        ExceptionId = job.ActiveJobAttempt__r.Exception__c;
        ExceptionCode = job.ActiveJobAttempt__r.ExceptionCode__c;
        ExceptionComments = job.ActiveJobAttempt__r.ExceptionCommentsLong__c;
        ExceptionName = job.ActiveJobAttempt__r.Exception__r.ExceptionCodeDesc__c;
        ExceptionCodeDesc = job.ActiveJobAttempt__r.Exception__r.ExceptionCodeDesc__c;
        ProjectTitle = job.Project__r.Name;
        ServiceTitle = job.ProjectService__r.ServiceTitle__c;
        ScheduledDate = job.JobScheduledDate__c;
        LocationNumber = job.LocationNumber__c;
        LocationAddress = job.Location__r.Address__c;
        JobManualUrl = job.ProjectService__r.JobManualUrl__c;
        
    }
}