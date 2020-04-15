global class ProjectServiceActionsHelper {

    global static void RunProjectServiceHistoryGetter() {
        DateTime lastSyncTime;
        List<ProcessLastSyncTime__c> plsts = [Select Id, CurrentProcessId__c, SyncTime__c from ProcessLastSyncTime__c WHERE ProcessName__c = 'ProjectServiceChangeTracking' LIMIT 1];
        
        if (plsts.isEmpty())
        {
            ProcessLastSyncTime__c plst = new ProcessLastSyncTime__c();
            plst.SyncTime__c = DateTime.Now().addSeconds(-10);
            plst.CurrentProcessId__c = '';
            plst.ProcessName__c = 'ProjectServiceChangeTracking';
            plsts.add(plst);
            insert plsts;
        }

        lastSyncTime = plsts[0].SyncTime__c ;    
        //If there's an existing process running, return
        if (!string.isBlank(plsts[0].CurrentProcessId__c))
            return;
        
        BatchGetProjectServiceHistoryChanges batch = new BatchGetProjectServiceHistoryChanges(lastSyncTime);
        Id batchJobId = Database.ExecuteBatch(batch, 9000);        
        
        plsts[0].CurrentProcessId__c = string.valueOf(batchJobId);
        update plsts[0];
    }         
    
    global static void ProcessProjectServiceHistoryChanges(List<ProjectService__History> pshs) {
        Set<Id> projectIds = new Set<Id>();
        Set<Id> psIds = new Set<Id>();        
        Map<string, string> mapChangeTypes = new Map<string, string>();        
        
        for (ProjectService__History psh : pshs)
        {
            psIds.add(psh.ParentId);
        }
        
        List<ProjectService__c> pss = [Select Id, Name, Project__r.DateLaunched__c, Project__r.ProjectNumber__c, Project__c from ProjectService__c WHERE Id IN :psIds];
        List<EntityChangeType__c> ects = [Select Id, Name, Field__c, Value__c, ChangeType__c from EntityChangeType__c WHERE Entity__c = 'ProjectService'];
       
        for (EntityChangeType__c ect : ects)
        {
            //Check for changes looking for a particular value or any        
            if (ect.Value__c == null)
                mapChangeTypes.put(ect.Field__c.toLowerCase(),ect.ChangeType__c); 
            else        
                mapChangeTypes.put(ect.Field__c.toLowerCase() + '-'+ ect.Value__c.toLowerCase(), ect.ChangeType__c); 
        }
        
        Map<Id, ProjectService__c> mapProjectLaunchedDate = new Map<Id, ProjectService__c>(pss);        
        Map<string, string> newchanges = new Map<string, string>();

        List<EntityChangeLog__c> ecls = new List<EntityChangeLog__c>();
        EntityChangeLog__c ecl;
        
        for (ProjectService__History psh : pshs)
        {
            //Check if this is a field of interest to the system
            //Else ignore the change
            //Check with changes looking for a particular value or any
            string newValue = psh.NewValue==null?'': string.valueof(psh.NewValue).toLowerCase();
            if (mapChangeTypes.get(string.valueof(psh.Field).toLowerCase()) == null && 
                   mapChangeTypes.get(string.valueof(psh.Field).toLowerCase() + '-'+ newValue) == null )
                continue;
                
            if (psh.CreatedDate > mapProjectLaunchedDate.get(psh.ParentId).Project__r.DateLaunched__c)
            {
                string changeType = mapChangeTypes.get(string.valueof(psh.Field).toLowerCase() + '-'+ string.valueof(newValue).toLowerCase()) == null?
                    mapChangeTypes.get(string.valueof(psh.Field).toLowerCase()):mapChangeTypes.get(string.valueof(psh.Field).toLowerCase() + '-'+ string.valueof(newValue).toLowerCase());
                
                //INSERT UNIQUE CHANGES ONLY for the object and change type
                
                if (!newchanges.containskey(string.valueof(psh.ParentId) + changeType ))
                {
                    ecl = new EntityChangeLog__c();
                    ecl.Entity__c = 'ProjectService';
                    ecl.ChangeDateTime__c = psh.CreatedDate;
                    ecl.ChangeType__c = changeType;
                    ecl.EntityId__c = mapProjectLaunchedDate.get(psh.ParentId).Name;
                    ecl.ProjectService__c = mapProjectLaunchedDate.get(psh.ParentId).Id;
                    ecl.Project__c = mapProjectLaunchedDate.get(psh.ParentId).Project__c;
                    ecl.Status__c = 'Hold';
                    
                    ecls.add(ecl);
                    newchanges.put(string.valueof(psh.ParentId) + changeType, string.valueof(psh.ParentId) + changeType);
                }
            }
        }
        
        if (ecls.size() > 0)        
        {
            insert ecls;
        }
                
    }        

    global static List<ActionResponse> DeleteProjectServices(Id[] psIds) {
        
        List<ActionResponse> responses = new  List<ActionResponse>();
        Boolean isBatch = false;
        //Decide between batch and non batch
        
        Id pId = [Select Id, Project__c from ProjectService__c where Id =:psIds[0]].Project__c;
        //Implementation   
        Boolean success = true;
        Savepoint sp = Database.setSavepoint();                                                          
        try
        {
            string stringIds = '';
            Integer jobCount = [Select count() from Job__c WHERE ProjectService__c in :psIds LIMIT :JobActionsHelper.JOB_BATCH_DELETE_DECISION_COUNT];
            if (jobCount >= JobActionsHelper.JOB_BATCH_DELETE_DECISION_COUNT)
            {
                //Call the Apex Job Tracker and Batch
                ApexJobTracker__c ajt = new   ApexJobTracker__c();
                ajt.Object__c = 'ProjectService';
                ajt.Operation__c = 'Delete ProjectService';
                ajt.Project__c = pId;
                ajt.Status__c = 'New';
                for (Id psId: psIds)
                {
                    stringIds += String.valueOf(psId) + ',';
                }
                ajt.Id1__c = String.ValueOf(stringIds);
                insert ajt;
                
                
                BatchProcessApexJobs batch = new BatchProcessApexJobs(psIds, ajt);
                Id batchId = Database.ExecuteBatch(batch, JobActionsHelper.JOB_BATCH_DELETE_DECISION_COUNT);                   
                
                Project__c project =  [SELECT Id,ApexJobName__c,BatchProcessId__c, RecordTypeId
                                       FROM Project__c WHERE Id =:pId];
                
                ProjectActionshelper.LockProject(project, 'Delete Project Service(s)', batchId);
                update project;
                
                isBatch = true;
                
            
            }
            else
            {
                //Call the non batch                
                Id[] jobIds = new Id[] {};
                List<Job__c> jobs = [Select Id from Job__c where ProjectService__c in :psIds];
                for (Job__c job : jobs)
                {
                    jobIds.add(job.Id);
                }
                JobActionsHelper.deleteJobs(jobIds);
                DeleteProjectServiceSansJobs(psIds);            
                
            
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
            if(isBatch){
                responses.add(new ActionResponse(null, true, 'Project service delete is in progress.'));
            }
            else{
               responses.add(new ActionResponse(null, true, 'Successfully deleted project service.')); 
            }
        }
        {
            ActionResponse response = new ActionResponse(null, false, 'Error deleting project service.');
            responses.add(response);
        }

        return responses;
    }        
    
    global static List<ActionResponse> DeleteProjectServiceSansJobs(Id[] psIds) {
 
        List<ActionResponse> responses = new  List<ActionResponse>();
        Set<Id> pids = new Set<Id>();
        List<ProjectService__c> projectservices = [Select Project__c from ProjectService__c WHERE Id in :psIds];
        for (ProjectService__c ps : projectservices)
        {
            pids.add(ps.Project__c);
        }
        //Implementation   
        Boolean success = true;
        Savepoint sp = Database.setSavepoint();                                                          
        try
        {
            TriggerUtil.SkipAllTriggers();
            delete [Select Id from ProjectService__c WHERE Id in :psIds];
            
            //This should most likely be only 1 most of the times.
            for (Id pid: pids)
            {
                ProjectActionsHelper.ReOrderProjectServiceRanks(pid);    
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
            ActionResponse response = new ActionResponse(null, true, 'Successfully deleted project service.');
            responses.add(response);
        }
        {
            ActionResponse response = new ActionResponse(null, false, 'Error deleting project service.');
            responses.add(response);
        }

        return responses;
    }    
    
    global static List<ActionResponse> CancelProjectService(Id[] psIds, string cancelReason, string cancelComments) {
        List<ActionResponse> responses = new  List<ActionResponse>();
        
        //Decide between batch and non batch
        
        Id pId = [Select Id, Project__c from ProjectService__c where Id =:psIds[0]].Project__c;

        //Implementation   
        Boolean success = true;
        Boolean isBatch = true;
        Savepoint sp = Database.setSavepoint();                                                          
        try
        {
            string stringIds = '';
			CancelProjectServiceSansJobs(psIds, cancelReason, cancelComments);                        
            Integer jobCount = [Select count() from Job__c WHERE Project__c = :pId LIMIT :JobActionsHelper.JOB_BATCH_CANCEL_DECISION_COUNT];
            if (jobCount >= JobActionsHelper.JOB_BATCH_CANCEL_DECISION_COUNT)
            {
                //Call the Apex Job Tracker and Batch
                ApexJobTracker__c ajt = new   ApexJobTracker__c();
                ajt.Object__c = 'ProjectService';
                ajt.Operation__c = 'Cancel ProjectService';
                ajt.Project__c = pId;
                ajt.Status__c = 'New';

                for (Id prsId: psIds)
                {
                    stringIds += String.valueOf(prsId) + ',';
                }
                
                ajt.Id1__c = stringIds;
                insert ajt;
                
                BatchProcessApexJobs batch = new BatchProcessApexJobs(psIds, ajt);
                Id batchId = Database.ExecuteBatch(batch, JobActionsHelper.JOB_BATCH_CANCEL_DECISION_COUNT);
                Project__c project =  [SELECT Id,ApexJobName__c,BatchProcessId__c, RecordTypeId
                                       FROM Project__c WHERE Id =:pId];
                ProjectActionsHelper.LockProject(project, 'Cancel Project Srevice(s)', batchId);
                update project;
            
            }
            else
            {
                //Call the non batch                
                Id[] jobIds = new Id[] {};
                List<Job__c> jobs = [Select Id from Job__c where Projectservice__c IN :psIds];
                for (Job__c job : jobs)
                {
                    jobIds.add(job.Id);
                }
                JobActionsHelper.cancelJobs(jobIds, cancelreason, cancelComments);
                isBatch = false;
            
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
            if(isBatch){
                responses.add(new ActionResponse(null, true, 'Project service cancellation in progress.'));
            }
            else{
               responses.add(new ActionResponse(null, true, 'Successfully canceled project service.')); 
            }
        }
        else
        {
            ActionResponse response = new ActionResponse(null, false, 'Error canceling project service.');
            responses.add(response);
        }
        return responses;
    }
    
    global static List<ActionResponse> CancelProjectServiceSansJobs(Id[] psIds, string cancelReason, string cancelComments) {
        List<ActionResponse> responses = new  List<ActionResponse>();

        //Implementation   
        Id[] projectIds = new Id[]{};
        Set<Id> projectIdSet = new Set<Id>();
        Boolean success = true;
        
        Savepoint sp = Database.setSavepoint();                                                          
        try
        {
            TriggerUtil.SkipAllTriggers();
            
            List<ProjectService__c> projectServices = [select id, status__c, CancelReason__c, CancelReasonComment__c from projectservice__c where Id in :psIds ];   
             
            for(projectservice__c ps: projectServices )
            {
                ps.Status__c = CONSTANTS.PROJECT_STATUS_CANCELED;
                ps.CancelReasonComment__c = cancelComments;
                ps.CancelReason__c = cancelReason;
            }
            
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
            ActionResponse response = new ActionResponse(null, true, 'Successfully canceled project service.');
            responses.add(response);
        }
        {
            ActionResponse response = new ActionResponse(null, false, 'Error canceling project service.');
            responses.add(response);
        }

        return responses;
    }       
    
    global static List<ActionResponse> resetScheduleDate(Id psId) {
        
        TriggerUtil.SkipAllTriggers();
        List<ActionResponse> responses = new  List<ActionResponse>();
        Boolean success = true;
        
        try {
            
            List<Job__c> jobs = [SELECT Id, Project__c FROM Job__c 
                                 WHERE ProjectService__c =:psId AND ProjectLocation__r.LocationScheduledDate__c != NULL AND JobStatus__c != :CONSTANTS.JOB_STATUS_CANCELED AND ProjectService__r.Status__c != :CONSTANTS.PROJECT_SERVICE_STATUS_CANCELED LIMIT :JobActionsHelper.JOB_BATCH_SCHEDULEDATE_DECISION_COUNT];
            if (jobs.size() == JobActionsHelper.JOB_BATCH_SCHEDULEDATE_DECISION_COUNT){
                //Call the Apex Job Tracker and Batch
                ApexJobTracker__c ajt = new ApexJobTracker__c();
                ajt.Object__c = 'ProjectService';
                ajt.Operation__c = 'Schedule ProjectService';
                ajt.Project__c = jobs[0].Project__c;
                ajt.Status__c = 'New';
                ajt.Parameters__c = '';
                ajt.Id1__c = psId;
                insert ajt;

                BatchProcessApexJobs batch = new BatchProcessApexJobs(new Id[] {psId}, ajt);
                Id batchId = Database.ExecuteBatch(batch, JobActionsHelper.JOB_BATCH_SCHEDULEDATE_DECISION_COUNT);
                
                Project__c project =  [SELECT Id,ApexJobName__c,BatchProcessId__c, RecordTypeId
                                       FROM Project__c WHERE Id =:jobs[0].Project__c];
                ProjectActionsHelper.LockProject(project, 'Set Schedule Date', batchId);
                update project;
                
            }
            else
            {
                Id[] jobIds = new Id[] {};
    
                for (Job__c job : jobs) {
    
                    jobIds.add(job.Id);
                }
                JobActionsHelper.resetScheduledDate(jobIds);
                
            }
        }
        catch(Exception e){
            success = false;
        }        

        if (success){
            ActionResponse response = new ActionResponse(null, true, 'Success');
            responses.add(response);
        }
        else {
            ActionResponse response = new ActionResponse(null, false, 'Error');
            responses.add(response);
        }
        return responses;
    }    
    
    
    private static Integer getUpdateBatchSize(){
        List<OrgCustomSettings__c> settings = [SELECT UpdateSummaryBatchSize__c FROM OrgCustomSettings__c LIMIT 1];
        if(settings == null || settings.size() == 0){
            return 50;
        }
        return integer.valueOf(settings[0].UpdateSummaryBatchSize__c);
    }    
    
    
    
	//Need to be DEPRACATED. Not being used
    global static void RunProjectServiceJobSummaryUpdate() {
        //Assumption - locations will not exceed 10000
        Id[] projectServiceIds = new Id[] {};
        Integer batchSize = getUpdateBatchSize();
        
        system.debug('Update Batch Size: ' + string.valueof(batchSize));
               
        List<ProjectService__c> pss = [Select Id, RefreshSummary__c,LastSummaryRefreshDateTime__c, Project__c from ProjectService__c 
                    WHERE RefreshSummary__c = true ORDER BY LastSummaryRefreshDateTime__c LIMIT :batchSize];
                    
        if (pss.size() == 0)                    
            return;
        
        Map<Id, Id> projectBatchMap = new Map<Id, Id>();
        Set<Id> projectIds = new Set<Id>();
        
        Id batchJobId;
        for (Projectservice__c ps: pss)
        {
            projectIds.add(ps.Project__c);
            projectServiceIds.add(ps.Id);
        }
        BatchUpdateJobSummary batch = new BatchUpdateJobSummary(projectServiceIds);
        batchJobId = Database.ExecuteBatch(batch, 1);        
        
        TriggerUtil.SkipAllTriggers();
        List<Project__c> projects = [Select Id, name, ApexJobName__c, BatchProcessId__c, RecordTypeId
                                     from Project__c where id in :projectIds];
        for (Project__c project : projects)
        {
            ProjectActionsHelper.LockProject(project, 'Job Summary Update', batchJobId);
            
        }   
        update projects;     
    }

    //Need to be DEPRACATED. Not being used
    global static List<ActionResponse> UpdateJobSummaryCount(Id psId) {
        //Assumption - locations will not exceed 10000
        List<ActionResponse> responses = new  List<ActionResponse>();

        //Implementation   
        Id[] projectIds = new Id[]{};
        Set<Id> projectIdSet = new Set<Id>();
        Boolean success = true;
        Savepoint sp = Database.setSavepoint();                                                          
        try
        {
            TriggerUtil.SkipAllTriggers();

            ProjectService__c ps = [SELECT Id, Name,  NumberOfJobs__c, NumberOfAssignedJobs__c, NumberOfCanceledJobs__c, NumberOfClosedJobs__c,
                            NumberOfCompletedJobs__c, NumberOfExceptionJobs__c, NumberOfExecutedJobs__c, NumberOfFailedQCJobs__c, NumberOfNotCanceledJobs__c,
                            NumberOfOpenJobs__c, NumberOfPendingJobs__c, NumberOfReportedJobs__c, NumberOfScheduledJobs__c, NumberOfStartedJobs__c, ReportedTotalTime__c,
                            NumberOfJobsRescheduled__c, RefreshSummary__c
                            FROM ProjectService__c where Id =:psId];
           
            Integer totalJobs = 0;
            Integer totalAssignedJobs = 0;
            Integer totalCanceledJobs = 0;
            Integer totalClosedJobs = 0;
            Integer totalOpenJobs = 0;
            Integer totalPendingJobs = 0;
            Integer totalReportedJobs = 0;
            Integer totalStartedJobs = 0;            
            Integer totalExceptionJobs = 0;
            Integer totalQCFailedJobs = 0;
            Integer totalNotCanceledJobs = 0;
            Integer totalScheduledJobs = 0;
            Integer totalRescheduledJobs = 0;            
            Integer totalExecutedJobs = 0;
            Integer totalCompletedJobs = 0;            
            Integer totalTimeReported = 0;                        
               
            List<Job__c> jobs = [Select Id, Name, JobStatus__c, QCFailureReason__c, HasException__c, IsExecuted__c, IsScheduled__c, CompletionStatus__c, TimeReported__c, IsRescheduled__c
                        from Job__c WHERE ProjectService__c = :psId];        
                        
            if (ps == null || jobs.size() == 0)
            {
            
                ActionResponse response = new ActionResponse(null, false, 'Invalid Data.');
                responses.add(response);            
                return responses;
            }  
            
                      
            for (Job__c job : jobs)         
            {
                totalJobs += 1;
                totalTimeReported += Integer.ValueOf(job.TimeReported__c);
                if (job.JobStatus__c.toLowerCase() == CONSTANTS.JOB_STATUS_ASSIGNED.toLowerCase())
                    totalAssignedJobs++;
                if (job.JobStatus__c.toLowerCase() == CONSTANTS.JOB_STATUS_CANCELED.toLowerCase())
                    totalCanceledJobs++;
                if (job.JobStatus__c.toLowerCase() == CONSTANTS.JOB_STATUS_CLOSED.toLowerCase())
                    totalClosedJobs++;
                if (job.JobStatus__c.toLowerCase() == CONSTANTS.JOB_STATUS_OPEN.toLowerCase())
                    totalOpenJobs++;
                if (job.JobStatus__c.toLowerCase() == CONSTANTS.JOB_STATUS_PENDING.toLowerCase())
                    totalPendingJobs++;
                if (job.JobStatus__c.toLowerCase() == CONSTANTS.JOB_STATUS_REPORTED.toLowerCase())
                    totalReportedJobs++;
                if (job.JobStatus__c.toLowerCase() == CONSTANTS.JOB_STATUS_STARTED.toLowerCase())
                    totalStartedJobs++;
                if (job.HasException__c)   
                    totalExceptionJobs++;
                if (job.CompletionStatus__c.toLowerCase() == CONSTANTS.JOB_COMPLETION_STATUS_COMPLETED.toLowerCase())
                    totalCompletedJobs++;
                if (job.QCFailureReason__c != null && job.QCFailureReason__c != '')    
                    totalQCFailedJobs++;
                if (job.IsScheduled__c)
                    totalScheduledJobs++;
                if (job.IsRescheduled__c)
                    totalRescheduledJobs++;
                if (job.IsExecuted__c)
                    totalExecutedJobs++;
            }
            totalNotCanceledJobs = totalJobs - totalCanceledJobs;
            ps.NumberOfJobs__c = totalJobs;
            ps.NumberOfAssignedJobs__c = totalAssignedJobs;
            ps.NumberOfCanceledJobs__c = totalCanceledJobs;
            ps.NumberOfClosedJobs__c = totalClosedJobs;
            ps.NumberOfCompletedJobs__c = totalCompletedJobs;
            ps.NumberOfExceptionJobs__c = totalExceptionJobs;
            ps.NumberOfExecutedJobs__c = totalExecutedJobs;
            ps.NumberOfFailedQCJobs__c = totalQCFailedJobs;
            ps.NumberOfNotCanceledJobs__c = totalNotCanceledJobs;
            ps.NumberOfOpenJobs__c = totalOpenJobs;
            ps.NumberOfPendingJobs__c = totalPendingJobs;
            ps.NumberOfReportedJobs__c = totalreportedJobs;
            ps.NumberOfScheduledJobs__c = totalScheduledJobs;
            ps.NumberOfStartedJobs__c = totalStartedJobs;
            ps.ReportedTotalTime__c = totalTimeReported;
            ps.NumberOfJobsRescheduled__c = totalRescheduledJobs;
            ps.RefreshSummary__c = false;
            ps.LastSummaryRefreshDateTime__c = DateTime.Now();     
            ps.ReportedTotalTime__c = totalTimeReported;
            
            update ps;
            
            
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
    
    global static string GetRecordType(ProjectService__c ps, String psrtPattern, Map<String, String> rtmap )
    {
        
        string rtId = '';
        String[] prtArray = psrtPattern.split(',');
        for (Integer i=prtArray.size()-1; i>=0; i--)
        {
            string recordType = '';
            
            for (Integer j=0; j<=i; j++)
            {
                system.debug('PRT Array(j): ' + prtArray[j]);
                String field = prtArray[j];
                String[] sobjectArray = field.split('\\.');
                system.debug('SObJECT Array(j) size: ' + sobjectArray.size());
                if (sobjectArray.size() == 1)
                {
                    recordType += ps.get(prtArray[j]);    
                    
                }
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
}