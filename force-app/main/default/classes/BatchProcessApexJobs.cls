global class BatchProcessApexJobs implements Database.Batchable<sObject>, Database.Stateful {
    
    Id[] ids;
    public ApexJobTracker__c ajt {get; set;}

    String objectname;
    String operation;
    
    global BatchProcessApexJobs (Id[] ids, ApexJobTracker__c pajt) {
    
        this.ajt = [Select Id, Name, BatchProcessId__c, Object__c, Operation__c, Project__c, 
            StartDateTime__c, EndDateTime__c, Status__c, NumberofTries__c, Id1__c, Id2__c, Id3__c,
            Parameters__c FROM ApexJobTracker__c WHERE Id = :pajt.Id];    
        
        if (ids.size() == 0) return;
        this.ids = ids;
        this.operation = ajt.operation__c;
        
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
    
        system.debug('BatchProcessApexJobs Started');
        UpdateApexJobTracker('In Progress', DateTime.Now(), null, true);
        
        this.objectname = String.Valueof(ids[0].getSObjectType());
        
        if (String.Valueof(ids[0].getSObjectType()).containsignorecase('project__c'))       
        {
            return Database.getQueryLocator([SELECT Id, Project__c, ProjectService__c, ProjectLocation__c, Project__r.ApprovalDate__c FROM Job__c WHERE Project__c IN :ids]);
        }
        else if (String.Valueof(ids[0].getSObjectType()).containsignorecase('job__c'))       
        {
            return Database.getQueryLocator([SELECT Id, Project__c, ProjectService__c, ProjectLocation__c, Project__r.ApprovalDate__c  FROM Job__c WHERE Id IN :ids]);        
        } 
        else if (String.Valueof(ids[0].getSObjectType()).containsignorecase('projectservice__c'))       
        {
            return Database.getQueryLocator([SELECT Id, Project__c, ProjectService__c, ProjectLocation__c, Project__r.ApprovalDate__c  FROM Job__c WHERE ProjectService__c IN :ids]);        
        } 
        else if (String.Valueof(ids[0].getSObjectType()).containsignorecase('projectlocation__c'))       
        {
            return Database.getQueryLocator([SELECT Id, Project__c, ProjectService__c, ProjectLocation__c, Project__r.ApprovalDate__c  FROM Job__c WHERE ProjectLocation__c IN :ids]);        
        } 
        
        return null;   
    }
   
    global void execute(Database.BatchableContext BC, List<Job__c> scope) {
    
        Id[] jobIds = new Id[]{};
        for (Job__c job: scope)
        {
            jobIds.add(job.Id);
        }

        if (operation.containsignorecase('delete'))
        {
            JobActionsHelper.deletejobs(jobIds, true);        
        }
        else if (operation.containsignorecase('cancel'))
        {
            JobActionsHelper.canceljobs(jobIds, '','', true);                
        }
        else if (operation.containsignorecase('close'))
        {
            JobActionsHelper.closejobs(jobIds, true);                
        }
        else if (operation.containsignorecase('launch'))
        {
            //filter only 
            list<job__c> jobList = [select id from job__C where ActiveJobAttempt__c = null and id in: jobIds];
            Set<id> temp = (new Map<Id,job__C>(jobList)).keySet();
            jobIds = new list<id>(temp);
            JobActionsHelper.createAttempts(jobIds, null, '', true);                
        }
        else if (operation.containsignorecase('schedule projectservice'))
        {
            JobActionsHelper.resetScheduledDate(jobIds);
        }
        else if (operation.containsignorecase('schedule'))
        {
            Date scheduleDate = Date.parse(ajt.Parameters__c);
            JobActionsHelper.setScheduledDate(jobIds, scheduleDate);
        }
   }
    
    global void finish(Database.BatchableContext BC) {
    
        Savepoint sp = Database.setSavepoint(); 
        try
        {
            TriggerUtil.SkipAllTriggers();    
            
            AsyncApexJob a = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email FROM AsyncApexJob WHERE Id = :BC.getJobId()];    
            
            if (a.NumberOfErrors > 0)
            {
                UpdateApexJobTracker('Failure',null, null, true);
            }         
            else   
                HandleBatchFinish(operation);    
        }
        catch(Exception e)
        {
            Database.rollback(sp);
            UpdateApexJobTracker('Failure',null, null, true);              
            
            //Test
            throw e;
        }
   }   
   
   
   private void HandleBatchFinish(string operation)
   {
   
       Set<Id> projectIdsforUpdate = new Set<Id>();
   
        if (operation.containsignorecase('delete projectlocation'))
        {
            ProjectLocationActionsHelper.DeleteProjectLocationSansJobs(ids);     
            UpdateApexJobTracker('Success',null, DateTime.Now(), false);
            projectIdsforUpdate.add(ajt.Project__c);
        }
        else if (operation.containsignorecase('schedule projectlocation'))
        {
            UpdateApexJobTracker('Success',null, DateTime.Now(), false);
            projectIdsforUpdate.add(ajt.Project__c);
        }
        else if (operation.containsignorecase('schedule projectservice'))
        {
            UpdateApexJobTracker('Success',null, DateTime.Now(), false);
            projectIdsforUpdate.add(ajt.Project__c);
        }
        else if (operation.containsignorecase('delete projectservice'))
        {
            ProjectServiceActionsHelper.DeleteProjectServiceSansJobs(ids);     
            UpdateApexJobTracker('Success',null, DateTime.Now(), false);
            projectIdsforUpdate.add(ajt.Project__c);
        }
        else if (operation.containsignorecase('delete project'))
        {
            ProjectActionsHelper.DeleteProjectSansJobs(ids[0]);     
            UpdateApexJobTracker('Success',null, DateTime.Now(), false);
            return;
        }
        else if (operation.containsignorecase('delete job') || operation.containsignorecase('Delete AllProjectJobs'))
        {
            UpdateApexJobTracker('Success',null, DateTime.Now(), false);
            projectIdsforUpdate.add(ajt.Project__c);
        }
        else if (operation.containsignorecase('cancel projectservice'))
        {
            UpdateApexJobTracker('Success',null, DateTime.Now(), false);
            projectIdsforUpdate.add(ajt.Project__c);            
        }
        else if (operation.containsignorecase('cancel projectlocation'))
        {
            ProjectLocationActionsHelper.CancelProjectLocationSansJobs(ids,'','');     
            UpdateApexJobTracker('Success',null, DateTime.Now(), false);
            projectIdsforUpdate.add(ajt.Project__c);            
        }
        else if (operation.containsignorecase('cancel job'))
        {
            UpdateApexJobTracker('Success',null, DateTime.Now(), false);
            projectIdsforUpdate.add(ajt.Project__c);
        }
        else if (operation.containsignorecase('cancel project'))
        {
            string cancelreason = '';
            string cancelcomments = '';
            if (!String.IsBlank(ajt.Parameters__c))
            {
                string[] parameters = ajt.Parameters__c.split('@@@');
                for(string parameter : parameters)
                {
                    string[] keyvalue = parameter.split('::');
                    if (keyvalue.size() == 2 && keyvalue[0].toLowerCase() =='cancelreason')
                    {
                        cancelreason = keyvalue[1];
                    }
                    if (keyvalue.size() == 2 && keyvalue[0].toLowerCase() =='cancelcomments')
                    {
                        cancelcomments = keyvalue[1];
                    }
                    
                }
            }
             
            UpdateApexJobTracker('Success',null, DateTime.Now(), false);
            projectIdsforUpdate.add(ajt.Project__c);            
        }
        else if (operation.containsignorecase('close project'))
        {
            ProjectActionsHelper.CloseProjectsSansJobs(ids);     
            UpdateApexJobTracker('Success',null, DateTime.Now(), false);
            for (Id id : ids)
            {
                projectIdsforUpdate.add(id);
            }
            
        }
        else if (operation.containsignorecase('launch project'))
        {
            ProjectActionsHelper.LaunchProjectsSansJobs(ids);     
            UpdateApexJobTracker('Success',null, DateTime.Now(), false);
            for (Id id : ids)
            {
                projectIdsforUpdate.add(id);
            }
        }
       
       
        List<Project__c> projects = [Select Id, Status__c, ArchiveStatus__c, ApexJobName__c, BatchProcessId__c, RecordTypeId
                                     from Project__c where Id in :projectIdsforUpdate];
        for (Project__c project :projects)
        {
            //Temporary code to set the archive status to Complete
            //This needs to be rewritten when we start archiving the 
            //whole project
            //Currently archiving is piggy backing on the delete all jobs process
            if (operation.containsignorecase('Delete AllProjectJobs') 
               && project.Status__c == CONSTANTS.PROJECT_STATUS_CLOSED
               && project.ArchiveStatus__c == CONSTANTS.ARCHIVE_STATUS_ARCHIVED)
            {
                project.ArchiveStatus__c = CONSTANTS.ARCHIVE_STATUS_COMPLETE;
            }    
            
			ProjectActionsHelper.UnlockProject(project);
        }
        update projects;

        system.debug('SetJobOpenBatcher end');
   
   }
   
   private void UpdateApexJobTracker(string status, DateTime starttime, DateTime endtime, boolean incrementtries)
   {
   
       //getting ajt again because update throws an error if the ajt was updated in the meantime
       
       this.ajt = [Select Id, Name, BatchProcessId__c, Object__c, Operation__c, Project__c, 
            StartDateTime__c, EndDateTime__c, Status__c, NumberofTries__c, Id1__c, Id2__c, Id3__c,
            Parameters__c FROM ApexJobTracker__c WHERE Id = :ajt.Id];         
       
       ajt.Status__c = status;
       if (starttime != null) ajt.StartDateTime__c = starttime;
       if (endtime != null) ajt.EndDateTime__c = endtime;
       if (incrementtries) {
           if(ajt.NumberofTries__c == null)
                ajt.NumberofTries__c = 0;
           else
                ajt.NumberOfTries__c++;
       }
       update ajt;     
   
   } 
    
}