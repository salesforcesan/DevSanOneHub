public with sharing class ScheduleLocationsModalController {
    
    public String messageHead {get;set;}
    public String messageBody {get;set;}
    public String messageSeverity {get;set;}
    public ScheduleLocationsModalController(){}
    
    public void submitSchedulingBatchJob()
    {
        
        Id projectid = ApexPages.currentPage().getParameters().get('projectid');
        String exceedBudgeted = ApexPages.currentPage().getParameters().get('ExceedBudgeted');
        
        
        Project__c project = [SELECT Id, Name, StartDate__c, EndDate__c, Status__c, ProjectType__c, 
                              ProjectType__r.Name, BudgetedLocationsCount__c, LocationTotalCount__c,   
                              ApexJobName__c, BatchProcessId__c, RecordTypeId, 
                              BookBudgetedOnly__c 
                              FROM Project__c WHERE ID = :projectid FOR UPDATE];
        if(!validateReserve(project)) {
            return;
        }
        
        try{
            TriggerUtil.skipProjectTrigger = true;
            project.BookBudgetedOnly__c= true;
            if(exceedBudgeted == '1'){
                project.BookBudgetedOnly__c= false;
            }
            update project; 
            
            SchedulingStrategy schedulingStrategyObject = SchedulingStrategyFactory.getSchedulingStrategy(project.ProjectType__r.Name);
            Boolean isBatchJob = schedulingStrategyObject.isBatchJob(project, exceedBudgeted);
            if(isBatchJob){
                
                ApexJobTracker__c ajt = new   ApexJobTracker__c();
                ajt.Object__c = 'Project';
                ajt.Operation__c = 'Create Jobs';
                ajt.Project__c = project.Id;
                ajt.Status__c = 'In Progress';
                ajt.StartDateTime__c = DateTime.Now();
                ajt.Id1__c = String.ValueOf(project.Id);
                insert ajt;
                
                string resultIds;
                Integer locationsBatchSize = (project.Status__c == CONSTANTS.PROJECT_STATUS_PLANNING) ? 250 : 100;
                ProjectScheduler batch = new ProjectScheduler(project);
                String batchId = Database.ExecuteBatch(batch, locationsBatchSize);
                
                ProjectActionsHelper.LockProject(project, 'Create Jobs', batchId);
                TriggerUtil.skipProjectTrigger = true;
                update project; 
            
                messageHead = 'Create jobs request has started.';
                messageBody = 'Please allow few minutes to process your request. You will receive an email notification once request is processed.';
                messageSeverity = 'info';
            }
            else {
                List<ProjectLocation__c> scope = Database.query(schedulingStrategyObject.getSchedulableLocationsQuery(project, ''));
                if(scope.size() == 0){
                    messageHead = 'No New Locations';
                    messageBody = 'There are no new locations to create jobs';
                    messageSeverity = 'warning';
                }
                else{
                    Integer ct = SchedulingStrategyObject.ScheduleLocations(scope, project.ID);
                    messageHead = 'Jobs created';
                    messageBody = 'Refer to location and job sections for results.';
                    messageSeverity = 'confirm';
                    
                    if(project.Status__c != CONSTANTS.PROJECT_STATUS_PLANNING){
                        //Set Project service refresh flag to true
                        TriggerUtil.SkipProjectServiceTrigger = true;
                        List<ProjectService__c> psList = [Select Id, RefreshSummary__c from ProjectService__c where Status__c != 'Canceled' AND Project__c =:project.Id];
                        for (ProjectService__c ps : psList){
                            ps.RefreshSummary__c = true;
                        }
                        update psList;  
                    }
                }
                TriggerUtil.skipProjectTrigger = true;
		        //Comment Versioning Code
                /*
                if(project.Status__c != CONSTANTS.PROJECT_STATUS_PLANNING) {
                    AppUtil.UpdateProjectVersion(project.Id);
                }
                */
            }
        }
        catch(System.DmlException e) {
            messageHead = 'Failed to create job(s)';
            messageBody = e.getDmlMessage(0);
            messageSeverity = 'error';
        }        
        catch(Exception ex){
            TriggerUtil.skipProjectTrigger = true;
            string err = '';
            update project; 
            messageHead = 'Create Error';
            messageBody = 'There was a problem processing your request. Please try again.';
            System.debug('The following exception has occurred: ' + ex.getMessage());
            messageSeverity = 'error';
            
        }
    }
    
    private Boolean validateReserve(Project__c project){
        Integer  psCount = [select count() FROM ProjectService__c WHERE Project__c =: project.Id AND Status__c != 'Canceled'];
        if(psCount == 0) {
            messageHead = 'Error - Missing Project Service.';
            messageBody = 'Please add Project Service(s) to Create Jobs.';
            messageSeverity = 'error';
            return false;
        }
        return true;
    }
}