global class ProjectScheduler implements Database.Batchable<sObject>, Database.Stateful {
    
    Project__c project;
    SchedulingStrategy algorithmStrategy;
    Integer scheduledItemCount = 0;
    Integer totalItemCount = 0;
    String operation = '';
    
    global ProjectScheduler(Project__c project){
        this.project = project;
    }
    
    global ProjectScheduler(Project__c project, String operation){
        this.project = project;
        this.operation = operation;
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        algorithmStrategy = SchedulingStrategyFactory.getSchedulingStrategy(this.project.ProjectType__r.Name);
        String projectId = project.Id;
        return Database.getQueryLocator(algorithmStrategy.getSchedulableLocationsQuery(this.project, operation));
    }
    
    global void execute(Database.BatchableContext BC, List<ProjectLocation__c> scope) {
        totalItemCount += scope.size();
        scheduledItemCount += algorithmStrategy.ScheduleLocations((List<ProjectLocation__c>)scope, this.project.Id, this.operation);
    }   
    
    global void finish(Database.BatchableContext BC) {
        // Get the ID of the AsyncApexJob representing this batch job
        // from Database.BatchableContext.
        // Query the AsyncApexJob object to retrieve the current job's information.
        AsyncApexJob a = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email FROM AsyncApexJob WHERE Id = :BC.getJobId()];        
        System.debug('Batch Job Status:' + a.Status);
        ProjectActionsHelper.UnlockProject(project);
        TriggerUtil.skipProjectTrigger = true;
        update project;
        
        List<ApexJobTracker__c> ajt = [Select Id,EndDateTime__c, Status__c FROM ApexJobTracker__c WHERE Project__c = :this.project.Id AND Operation__c = 'Create Jobs' AND Status__c != 'Success' ];
        
        if(ajt.size()>0){
           ajt[0].Status__c = 'Success';
           ajt[0].EndDateTime__c = DateTime.Now();
           update ajt;
        }
        
        
        if(this.operation == 'update jobs'){
            return;
        }
        
        try {
            // Send an email to the Apex job's submitter notifying of job completion.
            String messageBody = 'Your schedule locations job for ' + project.Name + ' is completed with ' + scheduledItemCount + ' bookings';
            String messageSubject = project.Name + ' schedule locations status - ' + a.Status;
            
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            
            AppUtil.setOrgWideEmailAddress(mail);
                        
            String[] toAddresses = new String[] {a.CreatedBy.Email};
 
            if(totalItemCount == 0){
                messageBody += '. No new locations to reserve.';
            }
            else if((totalItemCount -  scheduledItemCount) > 0){
                
                messageBody += ' and '+ (totalItemCount -  scheduledItemCount )+ ' failures.';
            }
            
            EmailHelper.SendEmail(mail,toAddresses,messageSubject,messageBody,true);
            
        }
        catch(Exception e){
            System.debug('Email send error:' + e);
        }
        
    }
}