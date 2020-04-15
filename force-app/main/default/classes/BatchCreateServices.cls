global class BatchCreateServices implements Database.Batchable<sObject>, Database.Stateful, Database.AllowsCallouts {
    
    String projectId;
    String caller;
    List<String> serviceIds;
    
    
    global BatchCreateServices(String projectId, List<String> serviceIds, String caller){
        this.projectId = projectId;
        this.caller = caller;
        this.serviceIds = serviceIds;
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        
		return Database.getQueryLocator([Select Id, Name from Service__c WHERE Id IN :serviceIds]);
    }
    
    global void execute(Database.BatchableContext BC, List<Service__c> scope) {
    	        
        Service__c service = ((List<Service__c>)scope)[0];        
        LightningProjectServiceController.createService(projectId, service.Id);
         
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
            update project;
            
            AsyncApexJob a = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, 
                              CreatedBy.Email FROM AsyncApexJob WHERE Id = :BC.getJobId()];    
            if (a.NumberOfErrors > 0 )
            {
                messageBody = 'Your request to ' + caller + ' has failed.<br>Project Id: ' + project.ProjectNumber__c + '<br>Project Title: ' + project.Name;
            }         
            else   
            {
                messageBody = 'Your request to ' + caller + ' has completed successfully.<br>Project Id: ' + project.ProjectNumber__c + '<br>Project Title: ' + project.Name;
                messageBody = messageBody + '<br><br><a href=' + link + '>Click here to directly access the project.</a>';            
            }
            
            notifyUserByEmail(messageBody, project);
        }
        catch (Exception e)
        {
            Database.rollback(sp);

        }
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
                system.debug('ERROR: Failed to send Create Services update success email. Details: ' + ex.getMessage());
            }
        }
        
        
    }
    
}