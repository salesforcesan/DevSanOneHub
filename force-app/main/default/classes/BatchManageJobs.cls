global class BatchManageJobs implements Database.Batchable<sObject>, Database.Stateful, Database.AllowsCallouts {
    
    Id projectId;
    private static final string[] IMPORT_JOB_ATTACHMENT_PATTERN = new String[]{'%' + 'import_jobs' + '%'};

    List<ActionResponse> errorresponses = new List<ActionResponse>();
    
    global BatchManageJobs(Id projectId){
        this.projectId = projectId;
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        
		return Database.getQueryLocator([SELECT Id, ParentId, Name, IsPrivate, ContentType, BodyLength, 
                                         Body, Description, IsDeleted
                                         FROM Attachment where ParentId =:projectId AND
                                         Name like :IMPORT_JOB_ATTACHMENT_PATTERN]);
    }
    
    global void execute(Database.BatchableContext BC, List<Attachment> scope) {
        List<String> jobs = new List<String>();
        
        Attachment attachment = ((List<Attachment>)scope)[0];
		
        if(attachment != null && attachment.BodyLength > 0){         
            jobs = (List<String>) JSON.deserialize(attachment.Body.toString(),List<String>.class);
            List<ActionResponse> batcherrorresponses = JobActionsHelper.updateBulkJobsFromFile(jobs, String.valueOf(projectId));
            if (batcherrorresponses != null && !batcherrorresponses.isEmpty())
            	this.errorresponses.addAll(batcherrorresponses);
            
        }
    }   
    
    global void finish(Database.BatchableContext BC) {
        
        Savepoint sp = Database.setSavepoint(); 
        
        
        try
        {
            
            String messageBody = '';
           
            Project__c project = [Select Id, Name, ProjectNumber__c, ApexJobName__c, BatchProcessId__c, RecordTypeId, PendingJobImportRequest__c 
                                  from Project__c WHERE Id =: this.projectId];
            string link = System.URL.getSalesforceBaseUrl().toExternalForm() + '/' + project.Id;
            
            TriggerUtil.SkipAllTriggers();    
            ProjectActionsHelper.UnlockProject(project);
            project.PendingJobImportRequest__c = false;
            update project;
            
            AsyncApexJob a = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, 
                              CreatedBy.Email FROM AsyncApexJob WHERE Id = :BC.getJobId()];    
            if (a.NumberOfErrors > 0 || (!this.errorresponses.isEmpty()))
            {
                messageBody = 'Your request to process jobs has failed.<br>Project Id: ' + project.ProjectNumber__c + '<br>Project Title: ' + project.Name;
                messageBody += '<br>List of Failed jobs: <br>';
                for (ActionResponse response: this.errorresponses)
                {
                    messageBody += '<br>' + response.ResponseMessage;
                }
                
            }         
            else   
            {
                messageBody = 'Your request to process jobs has completed successfully.<br>Project Id: ' + project.ProjectNumber__c + '<br>Project Title: ' + project.Name;
                messageBody = messageBody + '<br><br><a href=' + link + '>Click here to directly access the project.</a>';            
            }
            
            removeImportJobsAttachments();
            notifyUserByEmail(messageBody, project);
        }
        catch (Exception e)
        {
            Database.rollback(sp);

        }
    }
    
    private void removeImportJobsAttachments()
    {
		delete [SELECT Id FROM Attachment 
                where ParentId =:projectId AND
                Name like :IMPORT_JOB_ATTACHMENT_PATTERN];
    }

    private void notifyUserByEmail(String messageBody, Project__c project)
    {
        
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();        
        
        User activeUser = [Select Email From User where Username = :UserInfo.getUserName() limit 1];        
        
        if (activeUser != null)
        {
            try{
                String[] toAddresses = new String[] {activeUser.Email};
                String messageSubject = 'Jobs Update Request Status: ' + project.Name;
                EmailHelper.SendEmail(toAddresses,messageSubject,messageBody);               
            }
            catch(Exception ex){
                system.debug('ERROR: Failed to send jobs update success email. Details: ' + ex.getMessage());
            }
        }
        
        
    }
    
}