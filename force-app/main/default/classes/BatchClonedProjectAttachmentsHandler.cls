global class BatchClonedProjectAttachmentsHandler implements Database.Batchable<sObject>, Database.Stateful, Database.AllowsCallouts {
    
    Id projectId;
    global BatchClonedProjectAttachmentsHandler(Id projectId){
        this.projectId = projectId;
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        string query = 'SELECT Id, AttchFileName__c, AttributeValue__c, IsClonedAttachment__c FROM ProjectServiceAttribute__c ';
        query += 'WHERE  ProjectService__r.Project__c = \''+ projectId + '\' AND (AttributeType__c = \'Photo\' OR AttributeType__c = \'File\')';
        system.debug('Clone PSA Query:::: '+query);
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<ProjectServiceAttribute__c> scope) {
        ProjectServiceAttribute__c psa = ((List<ProjectServiceAttribute__c>)scope)[0];
        if(psa.AttributeValue__c != null && psa.AttributeValue__c != ''){         
            system.debug('Before GenerateURL'+psa);
            GenerateURL.GenerateNewURLNonFutureCall(psa.id, psa.AttributeValue__c.split('=')[0]);
            system.debug('After GenerateURL'+psa);
        }
    }   
    
    global void finish(Database.BatchableContext BC) {
        
        String messageBody = '';
        Project__c project = [Select Id, Name, ProjectNumber__c, ApexJobName__c, BatchProcessId__c, RecordTypeId 
                              from Project__c WHERE Id =: this.projectId];
        string link = System.URL.getSalesforceBaseUrl().toExternalForm() + '/' + project.Id;
        messageBody = 'Your request to clone project has completed successfully.<br>Cloned Project Id: ' + project.ProjectNumber__c + '<br>Cloned Project Title: ' + project.Name;
        messageBody = messageBody + '<br><br><a href=' + link + '>Click here to directly access the Cloned project.</a>';            
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        User activeUser = [Select Email From User where Username = :UserInfo.getUserName() limit 1];
        
        TriggerUtil.skipAllTriggers();
        project.CloneStatus__c = CONSTANTS.CLONE_STATUS_COMPLETE;
		ProjectActionsHelper.UnlockProject(project);
        update project;
        
        if (activeUser != null)
        {
            try{
                String[] toAddresses = new String[] {activeUser.Email};
                String messageSubject = 'Clone Request Status: ' + project.Name;
                EmailHelper.SendEmail(toAddresses,messageSubject,messageBody);                
            }
            catch(Exception ex){
                system.debug('ERROR: Failed to send clone success email. Details: ' + ex.getMessage());
            }
        }
    }
    
}