global class BatchRetryHandler {

    global BatchRetryHandler() {}
    
    global void retry(){
        
        OrgCustomSettings__c settings = OrgCustomSettings__c.getInstance('Setting');
        Integer maxRetries = (settings == null || settings.NumberOfBatchRetries__c == null) ? 3 : Integer.valueOf(settings.NumberOfBatchRetries__c);
        
        List<ApexJobTracker__c> ajts = [Select Id, Id1__c, Id2__c, Id3__c, Operation__c, Parameters__c,NumberOfTries__c, IsFailureNotified__c, Project__c, BatchProcessId__c, StartDateTime__c, EndDateTime__c
                                        FROM ApexJobTracker__c 
                                        WHERE IsLongRunning__c = true AND IsFailureNotified__c != true LIMIT 20]; 
        try {
            for (ApexJobTracker__c ajt: ajts) {
                if(ajt.NumberOfTries__c != null && ajt.NumberOfTries__c > maxRetries){
                    notifyFailure(ajt);    
                    continue;
                }
                if(ajt.Project__c != null){
                    List<Project__c> batchedProject = [SELECT BatchProcessId__c FROM Project__c WHERE ID = :ajt.Project__c];
                    if(batchedProject.size() > 0 && batchedProject[0].BatchProcessId__c != null){
                        List<AsyncApexJob> a = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email FROM AsyncApexJob WHERE Id = :batchedProject[0].BatchProcessId__c];     
                        if(a.size()>0 && (a[0].Status == 'Holding' || a[0].Status == 'Queued' || a[0].Status == 'Preparing' || a[0].Status == 'Processing')){
                            continue;
                        }
                    }
                }
                
                if(ajt.Operation__c == 'Create Jobs'){
                    RetryCreateJobs(ajt);
                }
                else if(ajt.Operation__c == 'Create Job Materials'){
                    RetryCreateJobMaterials(ajt);
                }
                else{
                    RetryBatchJobs(ajt);
                }
            }    
        }
        catch(Exception e) {
            String messageSubject = 'Batch retry job failed';
            String messageBody = 'BatchRetryHandler.retry() failed: ' + e.getMessage();           
            String[] toAddresses = AppUtil.getAppSetting('DevAlertEmails').split(',');
            EmailHelper.SendEmail(toAddresses,messageSubject,messageBody,true);            
        }
    }
    
    public void RetryBatchJobs(ApexJobTracker__c ajt){
        Id[] ids = new Id[] {};
		String allIds = (ajt.Id1__c == null ? '' : ajt.Id1__c) + ',' + (ajt.Id2__c == null ? '' : ajt.Id2__c) + ',' + (ajt.Id3__c == null ? '' : ajt.Id3__c);
		for (string s: allIds.split(',')) {
            if(s!=''){
            	ids.add(Id.valueOf(s));    
            }
			
        }
        BatchProcessApexJobs batch = new BatchProcessApexJobs(ids, ajt);
        Database.ExecuteBatch(batch, JobActionsHelper.JOB_BATCH_SIZE);                    
    }
    
    public void RetryCreateJobs(ApexJobTracker__c ajt){
        Project__c project = [SELECT Id, Name, StartDate__c, EndDate__c, Status__c, ProjectType__c, 
                              ProjectType__r.Name, BudgetedLocationsCount__c, LocationTotalCount__c, 
                              BookBudgetedOnly__c, ApexJobName__c, BatchProcessId__c, RecordTypeId 
                              FROM Project__c WHERE ID = :ajt.Project__c];
        
        ajt.StartDateTime__c = DateTime.Now();
        ajt.NumberOfTries__c = ajt.NumberofTries__c == null ? 1 : (ajt.NumberofTries__c + 1);
        update ajt;
        
        ProjectScheduler batch = new ProjectScheduler(project);
        String batchProcessId = Database.ExecuteBatch(batch, 250);
        
		ProjectActionsHelper.LockProject(project,'Create Jobs', batchProcessId);        

        TriggerUtil.skipProjectTrigger = true;
        update project; 
        
    }
    
    public void RetryCreateJobMaterials(ApexJobTracker__c ajt){
        Project__c project = [SELECT Id, Name, StartDate__c, EndDate__c, Status__c, ProjectType__c, ProjectType__r.Name, BudgetedLocationsCount__c, LocationTotalCount__c, BookBudgetedOnly__c FROM Project__c WHERE ID = :ajt.Project__c];
        
        ajt.StartDateTime__c = DateTime.Now();
        ajt.NumberOfTries__c = ajt.NumberofTries__c == null ? 1 : (ajt.NumberofTries__c + 1);
        update ajt;
        
        JobUpdateBatcher batch = new JobUpdateBatcher(new List<Project__c>{ project });
        project.BatchProcessId__c = Database.ExecuteBatch(batch, JobUpdatesHelper.getJobUpdateBatchHandlerBatchSize(project));
        
        ProjectActionsHelper.LockProject(project, 'Create Jobs', '');
        
        TriggerUtil.skipProjectTrigger = true;
        update project; 
    }
    
    public void notifyFailure(ApexJobTracker__c ajt){
        if(ajt.IsFailureNotified__c == true) return;
        
        
        String messageSubject = 'Batch retry failed for ' + ajt.Operation__c;
        String messageBody = 'Apex Job Tracker Id: ' + ajt.Id;
        if(ajt.Project__c != null){
            Project__c p = [SELECT Id, Name, ProjectNumber__c FROM Project__c WHERE ID = :ajt.Project__c];
            messageBody += '\r\n\r\nProject: ' + p.Name + '\r\n\r\n Project Number: ' + p.ProjectNumber__c;
        }
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        String[] toAddresses = AppUtil.getAppSetting('DevAlertEmails').split(',');
        OrgCustomSettings__c settings = OrgCustomSettings__c.getInstance('Setting');
        if(settings.BatchRetryAlertEmails__c == null){
            toAddresses = AppUtil.getAppSetting('DevAlertEmails').split(',');
        }
        else{
            toAddresses = settings.BatchRetryAlertEmails__c.split(',');
        }
        
		try{
        	EmailHelper.SendEmail(toAddresses,messageSubject,messageBody);
        }
        catch(Exception ex){
            system.debug('BatchRetry failed to send email. Exception details:' + ex.getMessage());
        }        
        finally{
			ajt.IsFailureNotified__c = true;
            update ajt;                
        }
        
    }
}