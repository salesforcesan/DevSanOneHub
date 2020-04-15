global class JobUpdateBatcher implements Database.Batchable<sObject>, Database.Stateful {

    Project__c[] projects;
    Set<String> materalAddedJobs = new Set<String>();

    global JobUpdateBatcher(Project__c[] projects) {
        system.debug('JobUpdateBatcher Started');
        this.projects = projects;
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator([SELECT Id, ProjectService__c, ProjectLocation__c, JobStatus__c, Project__r.Status__c FROM 
                                         Job__c WHERE Project__c IN :projects AND JobStatus__c != 'Canceled']);
    }
   
    global void execute(Database.BatchableContext BC, List<Job__c> jobs) {

        Id[] jobIds = new Id[]{};
        for (Job__c job : jobs) jobIds.add(job.Id);
        materalAddedJobs = JobUpdatesHelper.createJobRelatedRecords(jobIds, materalAddedJobs);
    }   
    
    global void finish(Database.BatchableContext BC) {
        TriggerUtil.skipProjectTrigger = true;
        Set<Id> projectIds = (new Map<Id, Project__c>(projects)).keySet();
        
        //Comment Versioning Code
        //AppUtil.UpdateProjectVersion(projectIds);
        
        List<Project__c> pList = [SELECT Id,BatchProcessId__c, ApexJobName__c, RecordTypeId
                                  FROM Project__c WHERE ID IN:projectIds];
        List<ApexJobTracker__c> ajts = new List<ApexJobTracker__c>();
        for(Project__c p :pList){

			ProjectActionsHelper.UnlockProject(p);
            
            List<ApexJobTracker__c> ajt = [Select Id,EndDateTime__c, Status__c FROM ApexJobTracker__c WHERE Project__c = :p.Id AND Operation__c = 'Create Job Materials' AND Status__c != 'Success' ];
            if(ajt.size()>0){
               ajt[0].Status__c = 'Success';
               ajt[0].EndDateTime__c = DateTime.Now();
               ajts.add(ajt[0]);
            }
        }
        update pList;
        if(ajts.size() >0){
            update ajts;
        }
        
        system.debug('JobUpdateBatcher end');
   }
    
}