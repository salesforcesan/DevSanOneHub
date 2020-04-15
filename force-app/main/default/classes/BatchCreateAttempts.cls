global class BatchCreateAttempts implements Database.Batchable<sObject>, Database.Stateful {
    
    //batch delete records, then kick off job update process
    Id[] ids;
    Date scheduledDate;
    String attemptReason;
    Set<Id> psIds = new Set<Id>(); 
    Set<Id> projectIds = new Set<Id>();

    global BatchCreateAttempts(Id[] ids, Date scheduledDate, string attemptReason) {
        
        if (ids.size() == 0) return;
        this.ids = ids;
        this.scheduledDate = scheduledDate;
        this.attemptReason = attemptReason;
    }
    
    
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        system.debug('SetJobOpenBatcher Started');
        if (String.Valueof(ids[0].getSObjectType()).containsignorecase('project__c'))       
        {
            return Database.getQueryLocator([SELECT Id, Project__c, ProjectService__c FROM Job__c WHERE Project__c IN :ids]);
        }
        else if (String.Valueof(ids[0].getSObjectType()).containsignorecase('job__c'))       
        {
            return Database.getQueryLocator([SELECT Id, Project__c, ProjectService__c  FROM Job__c WHERE Id IN :ids]);        
        } 
        return null;   
    }
   
    global void execute(Database.BatchableContext BC, List<Job__c> scope) {
    
        Id[] jobIds = new Id[]{};
        for (Job__c job: scope)
        {
            jobIds.add(job.Id);
            psIds.add(job.ProjectService__c); 
            projectIds.add(job.Project__c);           
        }

        JobActionsHelper.CreateAttempts(jobIds, scheduledDate, attemptReason);
    

        
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
        
        system.debug('SetJobOpenBatcher end');
   }    
    
}