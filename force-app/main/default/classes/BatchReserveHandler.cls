global class BatchReserveHandler implements Database.Batchable<sObject>, Database.Stateful {
    
    Project__c project;
    SchedulingStrategy SchedulingStrategyObject;
    
    global BatchReserveHandler(Project__c project){
        this.project = project;
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        SchedulingStrategyObject = SchedulingStrategyFactory.getSchedulingStrategy(this.project.ProjectType__r.Name);
        String projectId = project.ID;//this is requiired for query
        return Database.getQueryLocator(SchedulingStrategyObject.getSchedulableLocationsQuery(this.project, ''));
    }
   
    global void execute(Database.BatchableContext BC, List<ProjectLocation__c> scope) {
        for(ProjectLocation__c projLoc : scope){
         
            projLoc.status__c = null;
            
        }
        TriggerUtil.SkipProjectLocationTrigger = true;
        update scope;
        
        
        if(project.Status__c == CONSTANTS.PROJECT_STATUS_PLANNING){
            TriggerUtil.SkipJobDeleteTrigger = true;
            Set<Id> projLocIds = (new Map <Id, ProjectLocation__c>(scope)).keySet();
            List<Job__c> jobs = [SELECT Id FROM Job__c WHERE ProjectLocation__c IN: projLocIds];
            delete jobs;
        }
    }   
    
    global void finish(Database.BatchableContext BC) {
        ProjectScheduler batch = new ProjectScheduler(this.project);
        Integer batchSize = 100;
        //Reduce batcd size as Scheduled projet also creates job materials
        if(project.status__c == 'Booked'){
            batchSize = Integer.valueOf(batchSize /2);
        }
        Database.ExecuteBatch(batch, batchSize);
   }

}