global class BatchUpdateJobSummary implements Database.Batchable<sObject>, Database.Stateful {
    
    //batch delete records, then kick off job update process
    //This batch ONLY runs for ONE Project Service
    Id[] ids;
    Id id;
    Set<Id> projectIds = new Set<Id>();


    global BatchUpdateJobSummary(Id id) {
        
        this.id = id;
        this.ids = new Id[] {id};
    }


    global BatchUpdateJobSummary(Id[] ids) {
        
        if (ids.size() == 0) return;
        this.ids = ids;
        this.id = ids[0];
    }
    
    
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        system.debug('Set Delete Job Batcher Started');
        return Database.getQueryLocator([SELECT Id, name, Project__c FROM ProjectService__c WHERE Id IN :ids]);        
    }
   
    global void execute(Database.BatchableContext BC, List<ProjectService__c> scope) {
    
        for (ProjectService__c ps: scope)
        {
            projectIds.add(ps.Project__c);
                              
        }    
    
        Id[] psIds = new Id[]{};
        for (ProjectService__c ps: scope)
        {
            psIds.add(ps.Id);
        }

        ProjectServiceActionsHelper.UpdateJobSummaryCount(psIds[0]);
   }
    
    global void finish(Database.BatchableContext BC) {
    
        TriggerUtil.SkipAllTriggers();
    
    
        List<ProjectService__c> pss = [Select Id, Name, Project__c, RefreshSummary__c, LastSummaryRefreshDateTime__c from ProjectService__c where Id IN :ids];
        for (ProjectService__c ps : pss)
        {
        
            ps.RefreshSummary__c = false;
            ps.LastSummaryRefreshDateTime__c = DateTime.Now();
        
        }
        
        update pss;
        
        //Clear the batch information form project ONLY if there are no more project services
        //pending for the project
        
        List<Project__c> projects = [Select Id, name, ApexJobName__c, BatchProcessId__c, RecordTypeId
                                     from Project__c where Id IN :projectIds];
                    
        for (Project__c project : projects)
        {
			ProjectActionsHelper.UnlockProject(project);
        }
        update projects;
    
        system.debug('Update Job Summary Batcher Finished');
        
   }    
    
}