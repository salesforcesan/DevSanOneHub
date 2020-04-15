global class BatchCancelJobs implements Database.Batchable<sObject>, Database.Stateful {
    
    //batch delete records, then kick off job update process
    Id[] ids;
    Set<Id> projectIds = new Set<Id>();
    String cancelReason;
    String cancelComments;
    Set<Id> psIds = new Set<Id>();        

    global BatchCancelJobs(Id[] ids, string cancelReason, string cancelComments) {
        
        if (ids.size() == 0) return;
        this.ids = ids;
        this.cancelReason = cancelReason;
        this.cancelComments = cancelComments;
    }
    
    
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        system.debug('Set Cancel Job Batcher Started');
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

        JobActionsHelper.cancelJobs(jobIds, cancelReason, cancelComments);
    

        
   }
    
    global void finish(Database.BatchableContext BC) {
        
        
        List<Project__c> projects = [Select Id, Status__c, ApexJobName__c, BatchProcessId__c, RecordTypeId 
                                     from Project__c where Id in :projectIds];
        for (Project__c project :projects)
        {
            ProjectActionsHelper.UnlockProject(project);
        }
        update projects; 
        

        
        List<ProjectService__c> pss = [Select Id, Name, Project__c, RefreshSummary__c, LastSummaryRefreshDateTime__c from ProjectService__c where Id IN :psIds];
        for (ProjectService__c ps : pss)
        {
            ps.RefreshSummary__c = true;

        }
        update pss;                
        
        system.debug('Set Cancel Job Batcher Finished');
        
   }    
    
}