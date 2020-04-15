global without sharing class ProjectActionsHelper {
    
    public class SequenceException extends Exception{}
        
    public static void ResetProjectReleaseChangeFields(Set<Id> projectids) {  
        
        //For the projects in question check if all the log entries have been released,
        //If Yes, then set the project pending changes flag to false, IsPendingChangeReleaseRequest__c to false
        //and ApexJob Name to empty.
        
        List<Project__c> resetprojects = [Select Id, Name, ApexJobName__c, BatchProcessId__c, RecordTypeId,
                                          IsPendingChangeReleaseRequest__c, 
                                          IsPendingChanges__c from Project__c WHERE Id in :projectids AND 
                                          Id not in (Select Project__c from EntityChangeLog__c 
                                          WHERE Status__c = 'Hold' and Project__c in :projectids) FOR UPDATE];
        
        for (Project__c project : resetprojects)
        {
            
            UnlockProject(project);
            project.ApexJobName__c = '';
            project.IsPendingChangeReleaseRequest__c = false;
            project.IsPendingChanges__c = false;
        }
        update resetprojects;
    
    }

    global static void RunProjectSequenceUpdater() {
   
        Integer updateSequenceChangeLogSize = getUpdateSequenceChangeLogSize();
        Set<Id> projectIds = new Set<Id>();
        
        //Get all the projects that would need to increment the sequence number
        List<EntityChangeLog__c> eclprojects = [Select Id, Project__c, ChangeNumberNumeric__c from EntityChangeLog__c WHERE 
                        Status__c = 'Hold' AND
                        (
                            Project__r.IsPendingChangeReleaseRequest__c = true 
                            OR Entity__c = 'Job' 
                            OR ChangeType__c = 'ProjectOutOfCycleFulfillment' 
                            OR ChangeType__c = 'ProjectLocationsScheduled'
                            OR ChangeType__c = 'ProjectStatus'
                        ) 
                        
                        order by ChangeNumberNumeric__c LIMIT :updateSequenceChangeLogSize];
        
        if (eclprojects.IsEmpty())
            return;
        
        for (EntityChangeLog__c eclproject : eclprojects)
        {
            projectIds.add(eclproject.Project__c);
        }
        
        
        //Get all the change logs for the projects that need to be updated and set them to released
        //Need BATCH implementation for this. It is possible that the there could be 10s of 1000s of changes
        //for huge projects. like canceling a project that has 50000 jobs can take hours to process and flush out of changelogs
        List<EntityChangeLog__c> ecls = [Select Id, Project__c, ChangeNumberNumeric__c from EntityChangeLog__c WHERE Project__c IN :projectIds 
                                         AND Status__c = 'Hold'
                                         ORDER by ChangeNumberNumeric__c LIMIT :updateSequenceChangeLogSize];
        for (EntityChangeLog__c ecl : ecls)
        {
            ecl.Status__c = 'Released'; 
        
        }
        
        //Update the version of all the changed projects
        AppUtil.UpdateProjectVersion(projectIds);
        
        update ecls;
        
        // To publish platform events for project release status
        //EventChangeNotificationController.publishNotifications(projectIds);
        
        ResetProjectReleaseChangeFields(projectIds);        
        
    }



    global static void RunProjectHistoryGetter() {
        
        DateTime lastSyncTime;
        List<ProcessLastSyncTime__c> plsts = [Select Id, CurrentProcessId__c, SyncTime__c from ProcessLastSyncTime__c WHERE ProcessName__c = 'ProjectChangeTracking' LIMIT 1];
        
        if (plsts.isEmpty())
        {
            ProcessLastSyncTime__c plst = new ProcessLastSyncTime__c();
            plst.SyncTime__c = DateTime.Now().addSeconds(-10);
            plst.CurrentProcessId__c = '';
            plst.ProcessName__c = 'ProjectChangeTracking';
            plsts.add(plst);
            insert plsts;
        }

        lastSyncTime = plsts[0].SyncTime__c ;    
        //If there's an existing process running, return
        if (!string.isBlank(plsts[0].CurrentProcessId__c))
            return;
        
        
        
        system.debug('BatchGetProjectHistoryChanges::');
        
        BatchGetProjectHistoryChanges batch = new BatchGetProjectHistoryChanges(lastSyncTime);
        Id batchJobId = Database.ExecuteBatch(batch, 9000);        
        
        plsts[0].CurrentProcessId__c = string.valueOf(batchJobId);
        update plsts[0];
        
    }


    global static void ProcessProjectHistoryChanges(List<Project__History> phs) {
    
        
        system.debug('phs::' + phs.size());
        
        Set<Id> projectIds = new Set<Id>();
        Map<string, string> mapChangeTypes = new Map<string, string>();        
        
        for (Project__History ph : phs)
        {
            projectIds.add(ph.ParentId);
        }        
        
        system.debug('projectIds::' + projectIds.size());
        
        List<Project__c> projects = [Select Id, DateLaunched__c, ProjectNumber__c from Project__c WHERE Id in :projectIds];
        List<EntityChangeType__c> ects = [Select Id, Name, Field__c, Value__c, ChangeType__c from EntityChangeType__c WHERE Entity__c = 'Project'];
       
        for (EntityChangeType__c ect : ects)
        {
            //Check for changes looking for a particular value or any        
            if (ect.Value__c == null)
                mapChangeTypes.put(ect.Field__c.toLowerCase(),ect.ChangeType__c); 
            else        
                mapChangeTypes.put(ect.Field__c.toLowerCase() + '-'+ ect.Value__c.toLowerCase(), ect.ChangeType__c); 
        }

        Map<Id, Project__c> mapProjectLaunchedDate = new Map<Id, Project__c>(projects );        
        Map<string, string> newchanges = new Map<string, string>();

        List<EntityChangeLog__c> ecls = new List<EntityChangeLog__c>();
        EntityChangeLog__c ecl;
        
        for (Project__History ph : phs)
        {
            //Check if this is a field of interest to the system
            //Else ignore the change
            //Check with changes looking for a particular value or any
            string newValue = ph.NewValue==null?'': string.valueof(ph.NewValue).toLowerCase();
            if (mapChangeTypes.get(string.valueof(ph.Field).toLowerCase()) == null && 
                   mapChangeTypes.get(string.valueof(ph.Field).toLowerCase() + '-'+ newValue) == null )
                continue;
                
            if (ph.CreatedDate >= mapProjectLaunchedDate.get(ph.ParentId).DateLaunched__c)
            {
                string changeType = mapChangeTypes.get(string.valueof(ph.Field).toLowerCase() + '-'+ string.valueof(newValue).toLowerCase()) == null?
                    mapChangeTypes.get(string.valueof(ph.Field).toLowerCase()):mapChangeTypes.get(string.valueof(ph.Field).toLowerCase() + '-'+ string.valueof(newValue).toLowerCase());
                system.debug('Project__History::' + ph);
                
                
                //INSERT UNIQUE CHANGES ONLY for the object and change type                
                if (!newchanges.containskey(string.valueof(ph.ParentId) + changeType ))
                {
                    ecl = new EntityChangeLog__c();
                    ecl.Entity__c = 'Project';
                    ecl.ChangeDateTime__c = ph.CreatedDate;
                    ecl.ChangeType__c = changeType;
                    ecl.EntityId__c = mapProjectLaunchedDate.get(ph.ParentId).ProjectNumber__c;
                    ecl.Project__c = mapProjectLaunchedDate.get(ph.ParentId).Id; 
                    ecl.Status__c = 'Hold';
                    ecls.add(ecl);
                    newchanges.put(string.valueof(ph.ParentId) + changeType, string.valueof(ph.ParentId) + changeType);
                }
            }
        }
        
        if (ecls.size() > 0)        
        {
            insert ecls;
        }
                
    }

    //@deprecated - Need to revisit. Unable to use this - SF throwing an error.
    //This method is depracated. Use LaunchProjects(Id[] pIds) instead.    
    global static List<ActionResponse> MoveProjectsTolaunched() {
    
        List<ActionResponse> responses = new  List<ActionResponse>();

        //Implementation   
        Id[] projectIds = new Id[]{};
        Set<Id> projectIdSet = new Set<Id>();
        Boolean success = true;
        Savepoint sp = Database.setSavepoint();                                                          
        try
        {

            List<Project__c> projects = [SELECT Id, StartDate__c, EndDate__c, Status__c, RecordTypeId, ProjectTypeName__c,
                                    LaunchedProjectStartDate__c, LaunchedProjectEndDate__c
                             FROM Project__c 
                             WHERE ProjectLaunchDate__c <= today and Status__c = 'Booked' FOR UPDATE];        
                             
            for (Project__c project: projects)
            {
                projectIds.add(project.Id);
                projectIdSet.add(project.Id);
                ProjectActionsHelper.ChangeStatus(project, CONSTANTS.PROJECT_STATUS_LAUNCHED);
                project.LaunchedProjectStartDate__c = project.StartDate__c;
                project.LaunchedProjectStartDate__c = project.EndDate__c;
            }
            
            update projects;
            //Comment Versioning Code
            //AppUtil.UpdateProjectVersion(projectIdSet);
            
            if (projects.size() > 0)
            {
                BatchCreateAttempts batch = new BatchCreateAttempts(projectIds,null, '');
                Database.ExecuteBatch(batch, JobActionsHelper.JOB_BATCH_SIZE);        
            }
            
        }
        catch(Exception e)
        {
            Database.rollback(sp); 
            success = false;
            
            //For test purposes
            throw e;       
        }        

        if (success)
        {
            ActionResponse response = new ActionResponse(null, true, 'Successfully called the Batch Job to create attempts.');
            responses.add(response);
        }

        return responses;
    }
    
    global static List<ActionResponse> DeleteProjectSansJobs(Id pId) {
    
    
        List<ActionResponse> responses = new  List<ActionResponse>();

        //Implementation   
        Id[] projectIds = new Id[]{};
        Set<Id> projectIdSet = new Set<Id>();
        Boolean success = true;
        Savepoint sp = Database.setSavepoint();                                                          
        try
        {
            TriggerUtil.SkipAllTriggers();
            
            delete [Select Id from ProjectService__c WHERE Project__c = :pId];
            delete [Select Id from ProjectAccount__c WHERE Project__c = :pId];
            delete [Select Id from ProjectAttribute__c WHERE Project__c = :pId];
            delete [Select Id from ProjectLocation__c WHERE Project__c = :pId];
            delete [Select Id from Project__c WHERE Id = :pId];

        }
        catch(Exception e)
        {
            Database.rollback(sp); 
            success = false;
            
            //For test purposes
            throw e;       
        
        
        }        

        if (success)
        {
            ActionResponse response = new ActionResponse(null, true, 'Successfully deleted project.');
            responses.add(response);
        }
        else
        {
            ActionResponse response = new ActionResponse(null, true, 'Error deleting project.');
            responses.add(response);
        
        }

        return responses;
    }
    
    global static List<ActionResponse> DeleteProject(Id pId) {
        return DeleteProject(pId, false);
    }
    
    global static List<ActionResponse> DeleteAllJobsByProject(Id pId) {
        List<ActionResponse> responses = new  List<ActionResponse>();
        
        //Decide between batch and non batch
        TriggerUtil.SkipAllTriggers();

        //Implementation   
        Boolean success = true;
        Boolean isBatch = false;
        Integer jobCount =0;
        Savepoint sp = Database.setSavepoint();                                                          
        try
        {

           Project__c project =  [SELECT Id,ApexJobName__c,BatchProcessId__c, RecordTypeId, 
                                   Status__c, ArchiveStatus__c FROM Project__c WHERE Id =:pId FOR UPDATE];
								   
           jobCount = [Select count() from Job__c WHERE Project__c = :pId LIMIT :JobActionsHelper.JOB_BATCH_DELETE_DECISION_COUNT];

                  
           if (jobCount >= JobActionsHelper.JOB_BATCH_DELETE_DECISION_COUNT)
           
            {
                //Call the Apex Job Tracker and Batch
                ApexJobTracker__c ajt = new   ApexJobTracker__c();
                ajt.Object__c = 'Project';
                ajt.Operation__c = 'Delete AllProjectJobs';
                ajt.Project__c = pId;
                ajt.Status__c = 'New';
                ajt.Id1__c = String.ValueOf(pId);
                insert ajt;
                
                BatchProcessApexJobs batch = new BatchProcessApexJobs(new Id[] {pId}, ajt);
                Id batchId = Database.ExecuteBatch(batch, JobActionsHelper.JOB_BATCH_SIZE);  
                LockProject(project, 'Delete All Jobs', batchId);
                update project;
                isBatch = true;   
             
            
            }
            else
            {
                //Call the non batch                
                Id[] jobIds = new Id[] {};
                List<Job__c> jobs = [Select Id from Job__c where Project__c = :pId];
                for (Job__c job : jobs)
                {
                    jobIds.add(job.Id);
                }
                JobActionsHelper.deleteJobs(jobIds);
                
                //Temporary code to set the archive status to Complete
                //This needs to be rewritten when we start archiving the 
                //whole project
                //Currently archiving is piggy backing on the delete all jobs process
                if (project.Status__c == CONSTANTS.PROJECT_STATUS_CLOSED
                   && project.ArchiveStatus__c == CONSTANTS.ARCHIVE_STATUS_ARCHIVED)
                {
                    project.ArchiveStatus__c = CONSTANTS.ARCHIVE_STATUS_COMPLETE;
                }    
                update project;
            }
        }
        catch(Exception e)
        {
            Database.rollback(sp); 
            success = false;
            
            //For test purposes
            throw e;       
        
        
        }        

        if (success)
        {
            string successmessage = '';
            if (isBatch)
            {
                successmessage = 'Successfully submitted the request to delete the Jobs';
            }
            else
            {
                successmessage = jobCount  +' ' +'jobs deleted Successfully';
            }
            
            ActionResponse response = new ActionResponse(null, true, successmessage);  
            responses.add(response);
        }
        else
        {
            ActionResponse response = new ActionResponse(null, true, 'Error deleting Jobs.');
            responses.add(response);
        
        }

        return responses;
    }
    
    global static List<ActionResponse> DeleteProject(Id pId, Boolean isBatch) {
    
        List<ActionResponse> responses = new  List<ActionResponse>();
        
        //Decide between batch and non batch
        TriggerUtil.SkipAllTriggers();

        //Implementation   
        Boolean success = true;
        Savepoint sp = Database.setSavepoint();                                                          
        try
        {
            Integer jobCount = [Select count() from Job__c WHERE Project__c = :pId LIMIT :JobActionsHelper.JOB_BATCH_DELETE_DECISION_COUNT];
            if (isBatch || jobCount >= JobActionsHelper.JOB_BATCH_DELETE_DECISION_COUNT)
            {
                //Call the Apex Job Tracker and Batch
                ApexJobTracker__c ajt = new   ApexJobTracker__c();
                ajt.Object__c = 'Project';
                ajt.Operation__c = 'Delete Project';
                ajt.Project__c = pId;
                ajt.Status__c = 'New';
                ajt.Id1__c = String.ValueOf(pId);
                insert ajt;
                
                BatchProcessApexJobs batch = new BatchProcessApexJobs(new Id[] {pId}, ajt);
                Id batchId = Database.ExecuteBatch(batch, JobActionsHelper.JOB_BATCH_SIZE);  
                
                Project__c project = [Select Id, name, ApexJobName__c, BatchProcessId__c, RecordTypeId
                                      from Project__c where id = :pId FOR UPDATE];
                LockProject(project, 'Delete Project', batchId);
                    
                update project;                                    
                isBatch = true;                 
            
            }
            else
            {
                //Call the non batch                
                Id[] jobIds = new Id[] {};
                List<Job__c> jobs = [Select Id from Job__c where Project__c = :pId];
                for (Job__c job : jobs)
                {
                    jobIds.add(job.Id);
                }
                JobActionsHelper.deleteJobs(jobIds);
                DeleteProjectSansJobs(pId);            
                
            
            }
        }
        catch(Exception e)
        {
            Database.rollback(sp); 
            success = false;
            
            //For test purposes
            throw e;       
        
        
        }        

        if (success)
        {
            string successmessage = '';
            if (isBatch)
            {
                successmessage = 'Successfully submitted the request to delete the project.';
            }
            else
            {
                successmessage = 'Successfully deleted the project.';
            }
            
            ActionResponse response = new ActionResponse(null, true, successmessage);    
            responses.add(response);
        }
        else
        {
            ActionResponse response = new ActionResponse(null, true, 'Error deleting project.');
            responses.add(response);
        
        }

        return responses;
    }    
    
    
    global static List<ActionResponse> CancelProject(Id pId, string cancelReason, string cancelComments) {
    
        List<ActionResponse> responses = new  List<ActionResponse>();
        Boolean isBatch = false;
        
        Project__c project;
        List<Project__c> projects = [Select Id, Status__c, ApexJobName__c, BatchProcessId__c, RecordTypeId
                              from Project__c where Id = :pId FOR UPDATE];
        
        if (projects.size() > 0)
        {
            project = projects.get(0);
            if (project.Status__c == CONSTANTS.PROJECT_STATUS_PLANNING)
            {
                ActionResponse response = new ActionResponse(null, false, 'Error canceling project. Project cannot canceled in planning status.');
                responses.add(response);
                return responses;                
            }            
        }
        else
        {
            ActionResponse response = new ActionResponse(null, false, 'Project does not exist.');
            responses.add(response);
            return responses;
        }
        
        
        //Decide between batch and non batch
        

        //Implementation   
        Boolean success = true;
        Savepoint sp = Database.setSavepoint();                                                          
        try
        {

            CancelProjectSansJobs(pId, cancelReason, cancelComments);            
            Integer jobCount = [Select count() from Job__c WHERE Project__c = :pId LIMIT :JobActionsHelper.JOB_BATCH_CANCEL_DECISION_COUNT];
            if (jobCount >= JobActionsHelper.JOB_BATCH_CANCEL_DECISION_COUNT)
            {
                //Call the Apex Job Tracker and Batch
                ApexJobTracker__c ajt = new   ApexJobTracker__c();
                ajt.Object__c = 'Project';
                ajt.Operation__c = 'Cancel Project';
                ajt.Project__c = pId;
                ajt.Status__c = 'New';
                ajt.Id1__c = String.ValueOf(pId);
                ajt.Parameters__c = 'cancelreason::'+cancelreason+'@@@'+'cancelcomments::'+cancelcomments;
                insert ajt;
                
                BatchProcessApexJobs batch = new BatchProcessApexJobs(new Id[] {pId}, ajt);
                Id batchId = Database.ExecuteBatch(batch, JobActionsHelper.JOB_BATCH_CANCEL_DECISION_COUNT);     
                
                
                projects = [Select Id, Status__c from Project__c where Id = :pId FOR UPDATE];
                if (projects.size() > 0)
                {
                    project = projects.get(0);
                    LockProject(project, 'CancelProject', batchId);
                    update project;    
                }

                isBatch = true;
            
            }
            else
            {
                //Call the non batch                
                Id[] jobIds = new Id[] {};
                List<Job__c> jobs = [Select Id from Job__c where Project__c = :pId];
                for (Job__c job : jobs)
                {
                    jobIds.add(job.Id);
                }
                JobActionsHelper.cancelJobs(jobIds, cancelreason, cancelComments);
            }
        }
        catch(Exception e)
        {
            Database.rollback(sp); 
            success = false;
            
            //For test purposes
            throw e;       
        
        
        }        

        if (success)
        {
            string successmessage = '';
            if (isBatch)
            {
                successmessage = 'Successfully submitted the request to cancel the project.';
            }
            else
            {
                successmessage = 'Successfully canceled the project.';
            }
            
            ActionResponse response = new ActionResponse(null, true, successmessage);    
            responses.add(response);
        }
        {
            ActionResponse response = new ActionResponse(null, false, 'Error canceling project.');
            responses.add(response);
        
        }

        return responses;
    }
    
    global static List<ActionResponse> CancelProjectSansJobs(Id pId, string cancelReason, string cancelComments) {
    
    
        List<ActionResponse> responses = new  List<ActionResponse>();

        //Implementation   
        Id[] projectIds = new Id[]{};
        Set<Id> projectIdSet = new Set<Id>();
        Boolean success = true;
        
        Savepoint sp = Database.setSavepoint();                                                          
        try
        {
            TriggerUtil.SkipAllTriggers();
            
            Project__c projObj=[select name,Status__c,CancelReason__c, ProjectCancelLeadTime__c,ApexJobName__c,
                                BatchProcessId__c,RecordTypeId, ProjectTypeName__c, 
                                CancelReasonComment__c from project__c where id=: pId FOR UPDATE]; 
            List<ProjectService__c> projectServices = [select id from projectservice__c where Project__c = :pId  AND 
                                                       Status__c != :CONSTANTS.PROJECT_STATUS_CANCELED FOR UPDATE ];   
            List<ProjectLocation__c> projectLocations = [select id, name, Project__c, Status__c,CancelReason__c from projectlocation__c 
                                                         WHERE Project__c = :pId AND Status__c != :CONSTANTS.PROJECT_STATUS_CANCELED FOR UPDATE];               
    
            ProjectActionsHelper.ChangeStatus(projObj, CONSTANTS.PROJECT_STATUS_CANCELED);
            projObj.IsPendingChangeReleaseRequest__c = true;
            projObj.CancelReason__c = cancelReason;
            projObj.CancelReasonComment__c = cancelComments;
            
            for(ProjectLocation__c loc: projectLocations )
            {            
                loc.Status__c = CONSTANTS.PROJECT_STATUS_CANCELED;
                loc.CancelReason__c = cancelReason ;
            }
    
            
            for(projectservice__c ps: projectServices )
            {
                ps.Status__c = CONSTANTS.PROJECT_STATUS_CANCELED;
            }
            
            update projObj;
            update projectLocations;
            update projectServices;        
    
        }
        catch(Exception e)
        {
            Database.rollback(sp); 
            success = false;
            
            //For test purposes
            throw e;       
        
        
        }        

        if (success)
        {
            ActionResponse response = new ActionResponse(null, true, 'Successfully deleted project.');
            responses.add(response);
        }
        {
            ActionResponse response = new ActionResponse(null, false, 'Error deleting project.');
            responses.add(response);
        
        }

        return responses;
    }    
    
    
    global static List<ActionResponse> CloseProjects(Id[] pIds) {
    
        List<ActionResponse> responses = new  List<ActionResponse>();
        
        //Decide between batch and non batch
        
        List<Project__c> projects = [Select Id, Status__c,BatchProcessId__c,ApexJobName__c, RecordTypeId
                                     from Project__c where Id in :pIds FOR UPDATE];
        
        List<Project__c> closableProjects = new List<Project__c>();
        
        Id[] closableIds = new Id[] {};
        string projectIds = '';
        
        if (projects.size() > 0)
        {
            for (Project__c project: projects)
            {
                if (project.Status__c != CONSTANTS.PROJECT_STATUS_ENDED)
                {
                    ActionResponse response = new ActionResponse(null, false, 'Error closing project. Project needs to be in ENDED state to be closed.');
                    responses.add(response);
                }
                else
                {
                    closableProjects.add(project);
                    closableIds.add(project.Id);
                    projectIds = projectIds + string.valueof(project.Id) + ',';
                }
            
            }
            
        }
        else
        {
            ActionResponse response = new ActionResponse(null, false, 'No projects to close.');
            responses.add(response);
            return responses;
        }    
        

        //Implementation   
        Boolean success = true;
        Savepoint sp = Database.setSavepoint();                                                          
        try
        {
            //Call the Apex Job Tracker and Batch
            ApexJobTracker__c ajt = new   ApexJobTracker__c();
            ajt.Object__c = 'Project';
            ajt.Operation__c = 'Close Project';
            ajt.Project__c = null;
            ajt.Status__c = 'New';
            ajt.Id1__c = projectIds;
            insert ajt;
            
            BatchProcessApexJobs batch = new BatchProcessApexJobs(closableIds, ajt);
            Id batchId = Database.ExecuteBatch(batch, JobActionsHelper.JOB_BATCH_CLOSE_DECISION_COUNT);   
            
            
            for (Project__c project: closableprojects)
            {
                LockProject(project, 'Close Project', batchId);
            }
            update closableprojects;                                    
            
        }
        catch(Exception e)
        {
            Database.rollback(sp); 
            success = false;
            
            //For test purposes
            throw e;       
        
        
        }        

        if (success)
        {
            ActionResponse response = new ActionResponse(null, true, 'Successfully closed projects.');
            responses.add(response);
        }
        {
            ActionResponse response = new ActionResponse(null, false, 'Error closing projects.');
            responses.add(response);
        
        }

        return responses;
    }
    
            

    global static List<ActionResponse> CloseProjectsSansJobs(Id[] pIds) {
    
    
        List<ActionResponse> responses = new  List<ActionResponse>();

        //Implementation   
        Id[] projectIds = new Id[]{};
        Set<Id> projectIdSet = new Set<Id>();
        Boolean success = true;
        
        
        
        
        Savepoint sp = Database.setSavepoint();                                                          
        try
        {
            TriggerUtil.SkipAllTriggers();
            
            List<Project__c> projects=[select name,Status__c, IsPendingChanges__c, IsPendingChangeReleaseRequest__c, 
                                       CancelReason__c, ProjectCancelLeadTime__c,ApexJobName__c,BatchProcessId__c, 
                                       RecordTypeId, ProjectTypeName__c
                                       from project__c where id IN :pIds FOR UPDATE]; 

            for (Project__c project : projects)            
            {
                ProjectActionsHelper.ChangeStatus(project, CONSTANTS.PROJECT_STATUS_CLOSED);
                project.IsPendingChangeReleaseRequest__c = true;
            
            }
            
            update projects;
    
        }
        catch(Exception e)
        {
            Database.rollback(sp); 
            success = false;
            
            //For test purposes
            throw e;       
        
        
        }        

        if (success)
        {
            ActionResponse response = new ActionResponse(null, true, 'Successfully deleted project.');
            responses.add(response);
        }
        {
            ActionResponse response = new ActionResponse(null, true, 'Error deleting project.');
            responses.add(response);
        
        }

        return responses;
    }    



    global static List<ActionResponse> CloseProject(Id pId) {
    
        List<ActionResponse> responses = new  List<ActionResponse>();
        
        //Decide between batch and non batch
        
        Project__c project = [Select Id, Status__c,BatchProcessId__c,ApexJobName__c, RecordTypeId
                              from Project__c where Id = :pId FOR UPDATE];
        
        if (project != null)
        {
            if (project.Status__c != CONSTANTS.PROJECT_STATUS_ENDED)
            {
                ActionResponse response = new ActionResponse(null, false, 'Error closing project. Project needs to be in ENDED state to be closed.');
                responses.add(response);
                return responses;
                
            }
            
        }
        else
        {
                ActionResponse response = new ActionResponse(null, false, 'Project does not exist.');
                responses.add(response);
                return responses;
        
        }
        

        //Implementation   
        Boolean success = true;
        Savepoint sp = Database.setSavepoint();                                                          
        try
        {
            Integer jobCount = [Select count() from Job__c WHERE Project__c = :pId LIMIT :JobActionsHelper.JOB_BATCH_CLOSE_DECISION_COUNT];
            if (jobCount >= JobActionsHelper.JOB_BATCH_CLOSE_DECISION_COUNT)
            {
                //Call the Apex Job Tracker and Batch
                ApexJobTracker__c ajt = new   ApexJobTracker__c();
                ajt.Object__c = 'Project';
                ajt.Operation__c = 'Close Project';
                ajt.Project__c = pId;
                ajt.Status__c = 'New';
                ajt.Id1__c = String.ValueOf(pId);
                insert ajt;
                
                BatchProcessApexJobs batch = new BatchProcessApexJobs(new Id[] {pId}, ajt);
                Id batchId = Database.ExecuteBatch(batch, JobActionsHelper.JOB_BATCH_CLOSE_DECISION_COUNT);   
                
                LockProject(project, 'Close Project', batchId);
                update project;                                    
                                
            
            }
            else
            {
                //Call the non batch                
                Id[] jobIds = new Id[] {};
                List<Job__c> jobs = [Select Id from Job__c where Project__c = :pId];
                for (Job__c job : jobs)
                {
                    jobIds.add(job.Id);
                }
                JobActionsHelper.closeJobs(jobIds, false);
                CloseProjectSansJobs(pId);            
                
            
            }
        }
        catch(Exception e)
        {
            Database.rollback(sp); 
            success = false;
            
            //For test purposes
            throw e;       
        
        
        }        

        if (success)
        {
            ActionResponse response = new ActionResponse(null, true, 'Successfully closed project.');
            responses.add(response);
        }
        {
            ActionResponse response = new ActionResponse(null, false, 'Error closing project.');
            responses.add(response);
        
        }

        return responses;
    }
    
    global static List<ActionResponse> CloseProjectSansJobs(Id pId) {
    
    
        List<ActionResponse> responses = new  List<ActionResponse>();

        //Implementation   
        Id[] projectIds = new Id[]{};
        Set<Id> projectIdSet = new Set<Id>();
        Boolean success = true;
        
        
        
        
        Savepoint sp = Database.setSavepoint();                                                          
        try
        {
            TriggerUtil.SkipAllTriggers();
            
            Project__c projObj=[select name,Status__c,CancelReason__c, ProjectCancelLeadTime__c,ApexJobName__c,
                                BatchProcessId__c, RecordTypeId, ProjectTypeName__c from project__c where id=: pId FOR UPDATE]; 
            
            ProjectActionsHelper.ChangeStatus(projObj, CONSTANTS.PROJECT_STATUS_CLOSED);
            
            update projObj;
    
        }
        catch(Exception e)
        {
            Database.rollback(sp); 
            success = false;
            
            //For test purposes
            throw e;       
        
        
        }        

        if (success)
        {
            ActionResponse response = new ActionResponse(null, true, 'Successfully deleted project.');
            responses.add(response);
        }
        {
            ActionResponse response = new ActionResponse(null, true, 'Error deleting project.');
            responses.add(response);
        
        }

        return responses;
    }    
    


    global static List<ActionResponse> LaunchProjects(Id[] pIds) {
    
        List<ActionResponse> responses = new  List<ActionResponse>();
        
        //Decide between batch and non batch
        
        List<Project__c> projects = [Select Id, Status__c, ApexJobName__c, BatchProcessId__c, RecordTypeId,
                                     ProjectTypeName__c, CancelReason__c, ProjectCancelLeadTime__c,
                					 LaunchedProjectStartDate__c , LaunchedProjectEndDate__c, StartDate__c,EndDate__c, OutofCycleFulfillmentRequest__c,
                                     IsPendingChangeReleaseRequest__c, OutofCycleFulfillment__c, FulfillmentLeadTime__c                                       
                                     from Project__c where Id IN :pIds FOR UPDATE];
        
        List<Project__c> launchableProjects = new List<Project__c>();
        Id[] launchableIds = new Id[] {};
        string projectIds = '';

        if (projects.size() > 0)
        {
            for (Project__c project: projects)
            {
                if (project.Status__c != CONSTANTS.PROJECT_STATUS_BOOKED)
                {
                    ActionResponse response = new ActionResponse(null, false, 'Error launching project. Project needs to be in ' + CONSTANTS.PROJECT_STATUS_BOOKED + ' state to be launched.');
                    responses.add(response);
                }
                else
                {
                    //Oh2-1964
                    project.DateLaunched__c = Datetime.now();
                    
                    launchableProjects.add(project);
                    launchableIds.add(project.Id);
                    projectIds = projectIds + string.valueof(project.Id) + ',';
                }
            
            }
            
        }
        else
        {
            ActionResponse response = new ActionResponse(null, false, 'No projects to launch.');
            responses.add(response);
            return responses;
        }    
                    
        //Implementation   
        Boolean success = true;
        Savepoint sp = Database.setSavepoint();                                                          
        try
        {
            //Call the Apex Job Tracker and Batch
            ApexJobTracker__c ajt = new   ApexJobTracker__c();
            ajt.Object__c = 'Project';
            ajt.Operation__c = 'Launch Project';
            ajt.Project__c = null;
            ajt.Status__c = 'New';
            ajt.Id1__c = projectIds;
            insert ajt;
            
            //Oh2-1964
            //Just to make sure Launch date timestamp is always before all job attempt creation, we update DateLunach__c datetime
            update launchableprojects;            
            
            BatchProcessApexJobs batch = new BatchProcessApexJobs(pIds, ajt);
            Id batchId = Database.ExecuteBatch(batch, JobActionsHelper.JOB_BATCH_LAUNCH_DECISION_COUNT); 
            
            for (Project__c project: launchableprojects)
            {
                LockProject(project, 'Launch Project', batchId);                
            }
            update launchableprojects;                                    
              
        }
        catch(Exception e)
        {
            Database.rollback(sp); 
            success = false;
            
            //For test purposes
            throw e;       
        
        
        }        

        if (success)
        {
            ActionResponse response = new ActionResponse(null, true, 'Successfully closed project.');
            responses.add(response);
        }
        {
            ActionResponse response = new ActionResponse(null, false, 'Error closing project.');
            responses.add(response);
        
        }

        return responses;
    }    

    global static List<ActionResponse> LaunchProjectsSansJobs(Id[] pIds) {
    
    
        List<ActionResponse> responses = new  List<ActionResponse>();

        //Implementation   
        Boolean success = true;
        
        Savepoint sp = Database.setSavepoint();                                                          
        try
        {
            TriggerUtil.SkipAllTriggers();
            
            
            List<Project__c> projects=[select Id, name, ProjectTypeName__c, Status__c,CancelReason__c, ProjectCancelLeadTime__c,ApexJobName__c,BatchProcessId__c, 
                						LaunchedProjectStartDate__c , LaunchedProjectEndDate__c, StartDate__c,EndDate__c, OutofCycleFulfillmentRequest__c,
                                       IsPendingChangeReleaseRequest__c, OutofCycleFulfillment__c, FulfillmentLeadTime__c,
                                       RecordTypeId FROM project__c where id IN :pIds FOR UPDATE]; 
            
            List<ProjectService__c> pss = [Select Id, Project__c, NumberOfMaterials__c from ProjectService__c 
                                            WHERE Project__c IN :pIds and NumberOfMaterials__c > 0];
            
            Set<Id> pIdsWithMat = new Set<Id>();
            
            for (ProjectService__c ps : pss)
            {
                pIdsWithMat.add(ps.Project__c);
                
            }
            

            for (Project__c project : projects)
            {
                ProjectActionsHelper.ChangeStatus(project, CONSTANTS.PROJECT_STATUS_LAUNCHED);

                project.LaunchedProjectStartDate__c = project.StartDate__c;
                project.LaunchedProjectEndDate__c = project.EndDate__c;
                //Auto release when project is launched.
                project.IsPendingChangeReleaseRequest__c = true;
                
                //OH2-1964               
                //project.DateLaunched__c = DateTime.Now();                
                
                if (pIdsWithMat.contains(project.Id))
                {
                    system.debug('Materials exist for the project');
                    Integer leadTimeDays = Integer.valueOf(project.FulfillmentLeadTime__c == null ? 0 : project.FulfillmentLeadTime__c);
                    Datetime leadTimeReachDate =  (DateTime.now()).AddDays(leadTimeDays);
                    system.debug('leadTimeDays: ' + leadTimeDays);
                    system.debug('Start Date: ' + project.StartDate__c);
                    system.debug('FF Date: ' + leadTimeReachDate.date());
                    if(project.StartDate__c <= leadTimeReachDate.date())
                    {
                        project.OutofCycleFulfillment__c = true;
                        system.debug('OutofCycleFulfillment__c = true');
                    }
                    else
                    {
                        project.OutofCycleFulfillment__c = false;
                        system.debug('OutofCycleFulfillment__c = false');
                    }
                }
                else
                {
                    system.debug('No materials for the project');
                    project.OutofCycleFulfillment__c = false;
                }
                

                list<projectservice__c> ProjServList = [select id from projectservice__c where project__C=:project.Id];  

                    
                AttachmentUrlGenerator.generateJobManualNonFutureCall(string.valueof(project.Id));



            }
            
            update projects;
    
        }
        catch(Exception e)
        {
            Database.rollback(sp); 
            success = false;
            
            //For test purposes
            throw e;       
        
        
        }        

        if (success)
        {
            ActionResponse response = new ActionResponse(null, true, 'Successfully launched projects.');
            responses.add(response);
        }
        {
            ActionResponse response = new ActionResponse(null, true, 'Error launched projects.');
            responses.add(response);
        
        }

        return responses;
    }    



    
    global static List<ActionResponse> LaunchProject(Id pId) {
    
        List<ActionResponse> responses = new  List<ActionResponse>();
        
        //Decide between batch and non batch
        
        Project__c project = [Select Id, Status__c, ApexJobName__c, BatchProcessId__c, RecordTypeId
                              from Project__c where Id = :pId FOR UPDATE];
        
        if (project != null)
        {
            if (project.Status__c != CONSTANTS.PROJECT_STATUS_BOOKED)
            {
                ActionResponse response = new ActionResponse(null, false, 'Error launching project. Project should be in Booked state.');
                responses.add(response);
                return responses;
                
            }
            
        }
        else
        {
                ActionResponse response = new ActionResponse(null, false, 'Project does not exist.');
                responses.add(response);
                return responses;
        
        }
        

        //Implementation   
        Boolean success = true;
        Savepoint sp = Database.setSavepoint();                                                          
        try
        {
            Integer jobCount = [Select count() from Job__c WHERE Project__c = :pId LIMIT :JobActionsHelper.JOB_BATCH_LAUNCH_DECISION_COUNT];
            if (jobCount >= JobActionsHelper.JOB_BATCH_LAUNCH_DECISION_COUNT)
            {
                //Call the Apex Job Tracker and Batch
                ApexJobTracker__c ajt = new   ApexJobTracker__c();
                ajt.Object__c = 'Project';
                ajt.Operation__c = 'Launch Project';
                ajt.Project__c = pId;
                ajt.Status__c = 'New';
                ajt.Id1__c = String.ValueOf(pId);
                insert ajt;
                
                BatchProcessApexJobs batch = new BatchProcessApexJobs(new Id[] {pId}, ajt);
                Id batchId = Database.ExecuteBatch(batch, JobActionsHelper.JOB_BATCH_LAUNCH_DECISION_COUNT);  
                
                LockProject(project, 'Launch Project', batchId);
                update project;                                    
                                 
            
            }
            else
            {
                //Call the non batch                
                Id[] jobIds = new Id[] {};
                List<Job__c> jobs = [Select Id from Job__c where Project__c = :pId];
                for (Job__c job : jobs)
                {
                    jobIds.add(job.Id);
                }
                JobActionsHelper.createAttempts(jobIds, null, '', false);
                LaunchProjectSansJobs(pId);            
                
            
            }
        }
        catch(Exception e)
        {
            Database.rollback(sp); 
            success = false;
            
            //For test purposes
            throw e;       
        
        
        }        

        if (success)
        {
            ActionResponse response = new ActionResponse(null, true, 'Successfully closed project.');
            responses.add(response);
        }
        {
            ActionResponse response = new ActionResponse(null, false, 'Error closing project.');
            responses.add(response);
        
        }

        return responses;
    }
    
    
    global static List<ActionResponse> LaunchProjectSansJobs(Id pId) {
    
    
        List<ActionResponse> responses = new  List<ActionResponse>();

        //Implementation   
        Boolean success = true;
        
        
        
        
        Savepoint sp = Database.setSavepoint();                                                          
        try
        {
            TriggerUtil.SkipAllTriggers();
            
            Project__c projObj=[select Id, name,Status__c,CancelReason__c, ProjectCancelLeadTime__c,ApexJobName__c,
                                BatchProcessId__c, LaunchedProjectStartDate__c , LaunchedProjectEndDate__c, 
                                StartDate__c,EndDate__c, RecordTypeId, ProjectTypeName__c from project__c where id=: pId FOR UPDATE]; 
            
            ProjectActionsHelper.ChangeStatus(projObj, CONSTANTS.PROJECT_STATUS_LAUNCHED);
            projObj.LaunchedProjectStartDate__c = projObj.StartDate__c;
            projObj.LaunchedProjectEndDate__c = projObj.EndDate__c;
            
            update projObj;
            

            AttachmentUrlGenerator.generateJobManualFutureCall(string.valueof(pId));                            
            

    
        }
        catch(Exception e)
        {
            Database.rollback(sp); 
            success = false;
            
            //For test purposes
            throw e;       
        
        
        }        

        if (success)
        {
            ActionResponse response = new ActionResponse(null, true, 'Successfully deleted project.');
            responses.add(response);
        }
        {
            ActionResponse response = new ActionResponse(null, true, 'Error deleting project.');
            responses.add(response);
        
        }

        return responses;
    }    
    
    @testVisible
    private static Integer getUpdateSequenceChangeLogSize(){
        List<OrgCustomSettings__c> settings = [SELECT UpdateSequenceChangeLogSize__c FROM OrgCustomSettings__c LIMIT 1];
        if(settings == null || settings.size() == 0 || settings[0] == null || settings[0].UpdateSequenceChangeLogSize__c == null){
            return 4000;
        }
        return integer.valueOf(settings[0].UpdateSequenceChangeLogSize__c);
    }  
    
    @testVisible
    private static Integer getMaxServicesForManualGeneration(){
        List<OrgCustomSettings__c> settings = [SELECT MaxServicesforManualGeneration__c FROM OrgCustomSettings__c LIMIT 1];
        if(settings == null || settings.size() == 0 || settings[0] == null || settings[0].MaxServicesforManualGeneration__c == null){
            return 20;
        }
        return integer.valueOf(settings[0].MaxServicesforManualGeneration__c);
    }        
    
    
    
    
    public static void ReOrderProjectServiceRanks(string pid)
    {
        
        List<ProjectService__c> pss = [Select Id, ServiceRank__c from ProjectService__c WHERE Project__c = :pid
                                      ORDER By ServiceRank__c];
        if (!pss.isEmpty())
        {
            Integer rank = 0;
            for (ProjectService__c ps : pss)
            {
                rank++;
                ps.ServiceRank__c = rank;
            }
            update pss;  
        }
              
    }

    global static void SetRecordType(Project__c project, Map<String, String> rtmap, String projectrtPattern)
    {
        project.RecordTypeId = GetRecordType(project, projectrtPattern,rtMap);
    }

    private static string GetRecordType(Project__c project, String prtPattern, Map<String, String> rtmap )
    {
        
        string rtId = '';
        String[] prtArray = prtPattern.split(',');
        for (Integer i=prtArray.size()-1; i>=0; i--)
        {
            string recordType = '';
            
            for (Integer j=0; j<=i; j++)
            {
                recordType += project.get(prtArray[j]);
                system.debug('RecordType' + recordType);
            }
            //Check if recordType is found
            rtId = rtmap.get(recordType);
            if (rtId == null || rtId == '')
            {
                system.debug('RecordType CONTINUE: ' + recordType);
                continue;
            }
            else
            {
                system.debug('RecordType FOUND: ' + recordType);
                return rtId;
                
            }
        }
        return null;
    }    
    
    global static void ChangeStatus(Project__c project, string status)
    {
        project.Status__c = status;
    }
    
    global static void LockProject(Project__c project, string apexJobName, string batchProcessId)
    {
		string lockedRTName;
        project.ApexJobName__c = apexJobName;
        project.BatchProcessId__c = batchProcessId;

    }

    global static void UnlockProject(Project__c project)
    {
        project.ApexJobName__c = '';
        project.BatchProcessId__c = '';
    }
    
}