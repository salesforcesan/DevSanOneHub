public with sharing class ProjectDisplaySummaryControllerExt {
   public Project__c Project {get; private set;}

    public ProjectDisplaySummaryControllerExt(ApexPages.StandardController controller) {
        String id = ApexPages.CurrentPage().getParameters().get('id');
        this.Project = [SELECT TotalTimeReported__c, TotalEstimatedMinutes__c, NumberOfJobs__c, NumberOfJobsPending__c, NumberOfJobsOpen__c, NumberOfJobsAssigned__c, NumberOfJobsStarted__c, NumberOfJobsReported__c, NumberOfJobsCanceled__c, NumberOfJobsClosed__c, NumberOfJobsNotCanceled__c, NumberOfJobsExecuted__c, NumberOfJobsCompleted__c, NumberOfJobsScheduled__c, NumberOfJobsRescheduled__c, NumberOfJobsException__c, NumberOfJobsFailedQC__c FROM Project__c WHERE Id=:id];        
        
    }
}