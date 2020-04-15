global class BatchDeleteJobs implements Database.Batchable<sObject>, Database.Stateful {
    
    //batch delete records, then kick off job update process
    Id[] ids;
    Set<Id> projectIds = new Set<Id>();
    Set<Id> psIds = new Set<Id>();

    global BatchDeleteJobs(Id[] ids) {
        
        if (ids.size() == 0) return;
        this.ids = ids;
    }
    
    
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        system.debug('Set Delete Job Batcher Started');
        return Database.getQueryLocator([SELECT Id, Project__c, ProjectService__c FROM Job__c WHERE Id IN :ids]);        
    }
   
    global void execute(Database.BatchableContext BC, List<Job__c> scope) {
    
        Id[] jobIds = new Id[]{};
        for (Job__c job: scope)
        {
            jobIds.add(job.Id);
            projectIds.add(job.Project__c);
            psIds.add(job.ProjectService__c);
        }

        JobActionsHelper.deleteJobs(jobIds);
    

        
   }
    
    global void finish(Database.BatchableContext BC) {
    
        List<Project__c> projects = [Select Id, Status__c, ApexJobName__c, BatchProcessId__c, RecordTypeId 
                                     from Project__c where Id in :projectIds];
        for (Project__c project :projects)
        {

			ProjectActionsHelper.UnlockProject(project);
        }

        update projects; 
   }    
    
}