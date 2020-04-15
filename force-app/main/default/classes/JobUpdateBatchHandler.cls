/* not needed at this time */
global class JobUpdateBatchHandler implements Database.Batchable<sObject>, Database.Stateful {
    
    //batch delete records, then kick off job update process
    Project__c[] projects;

    global JobUpdateBatchHandler(Project__c project) {
		List<Project__c> projs = new List<Project__c>();
		projs.add(project);
        this.projects = projs;
    }

	
    global JobUpdateBatchHandler(Project__c[] projects) {
        this.projects = projects;
    }
	
	
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
    	system.debug('JobUpdateBatchHandler Started');
        return Database.getQueryLocator([SELECT Id FROM Job__c WHERE Project__c IN :projects]);
    }
   
    global void execute(Database.BatchableContext BC, List<Job__c> scope) {
        
        Set<Id> jobIds = (new Map <Id, Job__c>(scope)).keySet();
        delete [SELECT Id FROM JobMaterial__c WHERE Job__c IN :jobIds];
    }
    
    global void finish(Database.BatchableContext BC) {
        
        JobUpdateBatcher batch = new JobUpdateBatcher(projects);
        Database.ExecuteBatch(batch, 100);
        system.debug('JobUpdateBatchHandler end');
   }    
    
}