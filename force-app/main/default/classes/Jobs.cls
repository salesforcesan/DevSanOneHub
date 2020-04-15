public with sharing class Jobs extends LightningRequestBase{
  
  public override Object add(Object parameters) {
    Map<String,Object> query = (Map<String,Object>) parameters;
    String projectId = LightningRequestHelper.parseString(query.get('projectId'));
    LightningRequestHelper.checkStringValueRequired(projectId,
      'The Project Id is required when creating jobs.');
    if(!hasLocations(projectId)){
      throw new AuraHandledException('Please add locations to the project before creating jobs.');
    }
    return submitSchedulingBatchJob(projectId);
  }

  Boolean hasLocations(String projectId){
    Integer count = [SELECT count() FROM ProjectLocation__c WHERE Project__c=:projectId];
    return count > 0 ? true : false;
  }

  Map<String,Object> submitSchedulingBatchJob(String projectId) {
        String exceedBudgeted = '1';
        Map<String,Object> response;
        Project__c project = [SELECT Id, Name, StartDate__c, EndDate__c, Status__c, ProjectType__c, 
                              ProjectType__r.Name, BudgetedLocationsCount__c, LocationTotalCount__c, 
                              BookBudgetedOnly__c, ApexJobName__c, BatchProcessId__c, RecordTypeId
                              FROM Project__c WHERE Id = :projectId FOR UPDATE];
        validateReserve(project);

        if(project != null && !String.isBlank(project.ApexJobName__c) && project.ApexJobName__c == 'Create Job'){
          return LightningRequestHelper.createResponse('warning','There is already a job creation request in progress. Please allow few minutes to process your request.');
        }
        
        try{
            TriggerUtil.skipProjectTrigger = true;
            project.BookBudgetedOnly__c= true;
            
            ProjectActionsHelper.UnlockProject(project);

            if(exceedBudgeted == '1'){
                project.BookBudgetedOnly__c= false;
            }
            
            SchedulingStrategy schedulingStrategyObject = SchedulingStrategyFactory.getSchedulingStrategy(project.ProjectType__r.Name);
            Boolean isBatchJob = schedulingStrategyObject.isBatchJob(project, exceedBudgeted);
            if(isBatchJob){
                
                ApexJobTracker__c jobTracker = new   ApexJobTracker__c();
                jobTracker.Object__c = 'Project';
                jobTracker.Operation__c = 'Create Jobs';
                jobTracker.Project__c = project.Id;
                jobTracker.Status__c = 'In Progress';
                jobTracker.StartDateTime__c = DateTime.Now();
                jobTracker.Id1__c = String.ValueOf(project.Id);
                insert jobTracker;
                
                string resultIds;
                Integer locationsBatchSize = 100;
                ProjectScheduler batch = new ProjectScheduler(project);
                String batchProcessId = Database.ExecuteBatch(batch, locationsBatchSize);
                TriggerUtil.skipProjectTrigger = true;
                
                ProjectActionsHelper.LockProject(project, 'Create Jobs', batchProcessId);
                
                update project;
                response = LightningRequestHelper.createResponseWithData(
                  'info',
                  'Your job creation request has started. Please allow a few minutes to process your request. You will receive an email notification once request is processed.',
                   'isBatchJob'
                );
            } else {
              update project;
              
              List<ProjectLocation__c> scope = Database.query(schedulingStrategyObject.getSchedulableLocationsQuery(project, ''));
              if(scope.size() == 0){
                response = LightningRequestHelper.createResponse('warning','There are no new locations to create jobs.');
              }
              else{
                  Integer ct = SchedulingStrategyObject.ScheduleLocations(scope, project.ID);

                  response = LightningRequestHelper.createResponse('success','Jobs have been created. Refer to Jobs tab for results.');
                  
                  if(project.Status__c != CONSTANTS.PROJECT_STATUS_PLANNING){
                      TriggerUtil.SkipProjectServiceTrigger = true;
                      List<ProjectService__c> psList = [Select Id, RefreshSummary__c from ProjectService__c where Status__c != 'Canceled' AND Project__c =:project.Id];
                      for (ProjectService__c ps : psList){
                          ps.RefreshSummary__c = true;
                      }
                      update psList;  
                  }
            }
            TriggerUtil.skipProjectTrigger = true;
          }
          return response;
        }
        catch(Exception ex){
            List<String> msg = new List<String>();
            msg.add('There was a problem processing your request. Please try again');
            msg.add('The following exception has occured');
            msg.add(ex.getMessage());
            msg.add(ex.getStackTraceString());
            Throw new AuraHandledException(String.join(msg,'. '));
        }
        finally {
          TriggerUtil.skipProjectTrigger = true;
        }
    }
    
    void validateReserve(Project__c project){
        Integer  psCount = [select count() FROM ProjectService__c WHERE Project__c =: project.Id AND Status__c != 'Canceled'];
        if (psCount == 0) {
          throw new AuraHandledException('Please add project service(s) before creating the jobs.');
        }
      }
}