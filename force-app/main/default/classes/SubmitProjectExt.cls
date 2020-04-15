public with sharing class SubmitProjectExt {
    private List<String> errors;
    private List<String> warnings;
    private String projectSubmitStage;

    public Project__c project;
    public string projectID{get;set;}
    public List<ProjectService__c> invalidps {get; set;}
    public List<ProjectService__c> invalidmtps {get; set;}    
    public List<ProjectServiceQuestion__c> invalidsq {get; set;}
    public List<ProjectService__c> invalidjobsps {get; set;}
    public ProjectCompletionStrategy projectCompletionStrategyObject;
    public Boolean leadTime {get; set;}
    public Boolean reservedLocation {get; set;}
    public Boolean success {get; set;}
    public Boolean doesHaveProjectService {get; set;}
    public Boolean doesHaveProjectAccount {get; set;}
    public Boolean doesHaveProjectLocation {get; set;}
    public Boolean doesHavePrimaryProducts {get; set;}
    public boolean validateJobScheduledDates{get; set;}
    public Boolean getProjectServicesWithTargetQuestion{get; set;}
    public Boolean getProjectServicesWithTarget{get; set;}
    //public Boolean validatePcardLeadTime{get; set;}
 
    public Boolean doesAllLocationsHaveAJob{get; set;}  
    public Boolean doesHaveJob {get; set;}
    public Boolean isProjectSplit100Percent {get;set;}
    public Boolean isBudgetLocationsFullyScheduled {get;set;}
    public String overallMessage {get; set;}
    public String overallTitle {get; set;}
    public boolean IsAccountApproved{get;set;}
    public boolean IsDateInPast{get;set;}
    public String getMissingProjectAttributes{get;set;}
    public Boolean isMaterialRequired{get;set;}    
    public boolean isValidEstimatedTime {get;set;}
    
    public SubmitProjectExt(ApexPages.StandardController controller) {
    
        projectID  = ApexPages.currentPage().getParameters().get('id');
        projectSubmitStage = ApexPages.currentPage().getParameters().get('stage');
        project = [Select Id, Name, Status__c,  ProjectType__c, ProjectTypeName__c, 
                   approvaldate__c,Approver__c,splittype__C, RecordTypeId from 
                   Project__c WHERE ID = :projectID LIMIT 1];
        projectCompletionStrategyObject = ProjectCompletionStrategyFactory.getProjectCompletionStrategy(this.project.ProjectType__c);        
        initDefault();
    }

    private void initDefault() {
        invalidps = new List<ProjectService__c>();
        invalidmtps = new List<ProjectService__c>();
        invalidsq = new List<ProjectServiceQuestion__c>();
        invalidjobsps = new List<ProjectService__c>();
        success=true;
        errors = new List<String>();
        warnings = new List<String>();
    }


    private void genErrors(){
        String msg = '';

        ApexPages.Message msgObj;

        if (overallTitle == '' || overallTitle == null)
        {
            overallTitle = 'Error submitting';
        }

        if ( errors.size() == 0 ) {
            msgObj = new ApexPages.Message(ApexPages.Severity.Error, 
                overallTitle,'Overall Results: Failed - See below for details.');
            ApexPages.AddMessage(msgObj);
            return;
        } 
        for(String err: errors){
            msgObj = new ApexPages.Message(ApexPages.Severity.ERROR, err);    
            ApexPages.AddMessage(msgObj);
        }
        
    }

    private void genWarnings(){
        String msg = '';
        ApexPages.Message msgObj;
        
        for(String warn: warnings){
            msgObj = new ApexPages.Message(ApexPages.Severity.WARNING, warn);    
            ApexPages.AddMessage(msgObj);   
        }
    }

    private void genSuccess(String msg) {
        ApexPages.Message msgObj = new ApexPages.Message(ApexPages.Severity.INFO, msg);    
        ApexPages.AddMessage(msgObj);  
    }
    
    public void init()
    {
        try {
            doInit();
        }
        catch(Exception ex){
            errors.add(ex.getStackTraceString());
            success = false;
            genErrors();
        }
    }

    void doInit()
    {
        getMissingProjectAttributes = GetMissingProjectAttributes();
        
        if(getMissingProjectAttributes!=null && getMissingProjectAttributes.length()>1)
        {
            errors.add('Project does not have values for required attributes ' + '(' + getMissingProjectAttributes  + ')');
            success = false;
        }
            
        doesHaveProjectService = validateMissingProjectService();
        if (!doesHaveProjectService)
        {
            errors.add('The project does not have a service.');
            success = false;
        } else {
            isValidEstimatedTime = IsValidEstimatedTime();
            if(!isValidEstimatedTime)
            {
                errors.add('Estimated Time must be entered either at the Project or the Service level in order to submit.');
                success = false;
            }
        } 

        //oh-1029
        //success = validateServiceTargetRequirement();
        
        if (!validateServiceTargetRequirement())
            success = false;
        
        
        doesHaveProjectLocation = validateMissingProjectLocation();
        if (!doesHaveProjectLocation)
        {
            errors.add('The project does not have locations.');
            success = false;
        }
        
        doesHavePrimaryProducts = true;
        
        doesHaveJob = validateMissingJobs();
        if (doesHaveJob == false)
        {
            errors.add('There are no jobs created for the project yet.');
            success = false;
        }

        if ( doesHaveJob ) {
            invalidjobsps = validateJobsOutsideProjectWindow();
            if (invalidjobsps.size() > 0)
            {
                errors.add('The project has invalid jobs. Some of the jobs fall outside the project window');
                success = false;
            }
            Boolean validServiceJobs = validateMissingServiceJobs();
            if (!validServiceJobs)
            {
                errors.add('There are no jobs created for some of the service(s).');
                success = false;
            }
            
            Boolean validScheduledJobs = validateJobScheduledDates();
            if (!validScheduledJobs)
            {
                warnings.add('This Project contains Jobs for recently added Services that do not have a Scheduled Date. Please add a Scheduled Date through the Manage Locations screen;  else these Jobs will not be launched to downstream systems.');
            }
            
        }
            
        leadTime = validateProjectleadTime();
        if (leadTime == false)
        {
            warnings.add('The project does not have the required lead time (Execution/Fulfillment).');
        }

        IsAccountApproved = IsAccountApproved();
        if(!IsAccountApproved)
        {
            errors.add('Please approve the primary account before booking.');
            success = false;        
        }
        
        integer cnt = projectCompletionStrategyObject.ProjectAccountCount(this.project.ID);
        if(cnt==0){
            errors.add('Please add an account(s) before booking.');
            success = false;  
        }
        
        doesHaveProjectAccount = validateMissingProjectAccount();
        if (!doesHaveProjectAccount)
        {
            errors.add('The project does not have an account.');
            success = false;
        }
        
        //Removed for now because we are no longer supporting Split Billing - Michael Mayrell
        //else{
        //    if(project.splittype__c!='Solo' && cnt<2)
        //        warnings.add('Please add more than one Project Account(s) when Project Split Type is % or $ ');
        // }

        invalidsq = validateSurveyQuestions();
        system.debug('~~ invalidsq ~~' + invalidsq);
        if (invalidsq.size() > 0)
        {
            errors.add('The project has invalid survey questions.');
            success = false;
        }
        
        validateDefault();
        
        
        //Removed for now because we are no longer supporting Split Billing - Michael Mayrell 
        //isProjectSplit100Percent = projectCompletionStrategyObject.isProjectFullySplitted(projectId);
        //if (!isProjectSplit100Percent){
        //    warnings.add('The split of project accounts does not add up to 100%.');
        //}
        
        doesAllLocationsHaveAJob= doesAllLocationsHaveAJob();
        if (doesAllLocationsHaveAJob== false)
        {
            warnings.add('There are locations that currently do not have jobs created.');
        } else {
            reservedLocation = true;
        } 

        Integer checkResult = projectCompletionStrategyObject.checkScheduledAndBudgetLocations(projectId);
        
        if (checkResult == 0) {
            isBudgetLocationsFullyScheduled = true;
        } else {
            isBudgetLocationsFullyScheduled =  false;
        }
        
        if (checkResult != 0) {
            warnings.add('The number of locations added to the project  does not equal the number of  budgeted locations.');
        } 
        
        IsDateInPast = validateDates();
        if(IsDateInPast){
            errors.add('Invalid dates. Project has dates in the past that is not allowed.');
            success = false;
        }
        
        Boolean hasValidMinServices = projectCompletionStrategyObject.validateMinServiceCount(projectId);
        if(!hasValidMinServices){
            errors.add('Project does not have minimum number of services required.');
            success = false;
        }
        Boolean validNumberDays = projectCompletionStrategyObject.hasValidNumberOfDays(projectId);
        if(!validNumberDays){
            errors.add('Invalid number of days. Number of days on service(s) exceeded the project number of days.');
            success = false;
        }

        List<string> thresholdExceptions = projectCompletionStrategyObject.getServicesSurveyScoreStatus(projectId, 'warning');
        if(thresholdExceptions.size()>0){
            string displayError = string.join(thresholdExceptions, '<br/>');
            warnings.add('Please review your survey for any complexities that may be removed. <br/><br/><b>' + displayError + '</b><br/><br/>');
        }        
        
        thresholdExceptions = projectCompletionStrategyObject.getServicesSurveyScoreStatus(projectId, 'error');
        if(thresholdExceptions.size()>0){
            string displayError = string.join(thresholdExceptions, '<br/>');
            errors.add('Please fix your survey to reduce the complexity. <br/><br/><b>' + displayError + '</b><br/><br/>');
            success = false;
        }                
        
        
        if (projectCompletionStrategyObject.isMaterialAddedWithinLeadTime(projectID)) {
            //removed from mvp
            //warnings.add('The project has materials that have been added after the lead time has run out. This could result in increased shipping costs.');
        }
        
        List<String> jobManualErrors = projectCompletionStrategyObject.validateJobManuals(projectID);
        if(jobManualErrors.size() > 0){
            errors.addAll(jobManualErrors);
            success = false;
        }

        //Test submit for validation rule violations
        if (projectSubmitStage != 'submit') {
            List<String> vrErrors = getValidationRuleErrors(project);
            if (!vrErrors.isEmpty())
            {
                success = false;
                errors.addAll(vrErrors);
            }
            
        }
       
       //oh-1029, success flag is compromised by some if logic above Thus we need to check if hardstop errors.size() > 0, success is false positive.
        if (success == true && errors.size() == 0)
        {
            if (projectSubmitStage == 'submit') {

                
                if (project.approver__c == null)
                {
                    ProjectActionsHelper.ChangeStatus(project, CONSTANTS.PROJECT_STATUS_BOOKED);
                    project.ApprovalRequestDate__c  = System.Now();
                    project.ApprovalDate__c = project.ApprovalRequestDate__c;
                    project.BookedProjectStartDate__c = project.StartDate__c;
                    project.BookedProjectEndDate__c = project.EndDate__c;  
                }
                else
                {
                    ProjectActionsHelper.ChangeStatus(project, CONSTANTS.PROJECT_STATUS_PENDING);
                    project.ApprovalRequestDate__c = System.Now();
                }

                update project;    
                
                system.debug('********Start of Generating pdf manual request...');
                
                list<projectservice__c> ProjServList = [select id from projectservice__c where project__C=:project.id order by servicerank__c];
                
                system.debug('********ProjServList.size()...'+ ProjServList.size());
                
                integer i=0;
                list<id> psIDList = new list<id>();
                system.debug('********start of Generating pdf manual request...');
                AttachmentUrlGenerator.generateJobManualFutureCall(string.valueof(project.Id));  
                system.debug('********End of Generating pdf manual request...');
                genSuccess('Successfully submitted  project.');  
                success = false;  
                
            } else {
                genWarnings();
            } 
        }
        else
        {
            genErrors();
            genWarnings();
        }
    }
    
    
    public Boolean validateDates() {
        return projectCompletionStrategyObject.IsDateInPast(this.project.ID);
    } 
    
    public Boolean validateMissingProjectService() {
        return projectCompletionStrategyObject.doesHaveProjectService(this.project.ID);
    }  
    
    public Boolean validateMissingProjectAccount() {
        return projectCompletionStrategyObject.doesHaveProjectAccount(this.project.ID);
    }   
    
    //oh-1029
    public Boolean validateServiceTargetRequirement() {
        Boolean success = true;
        Map<String,Boolean> result = projectCompletionStrategyObject.validateServiceTargetRequirement(this.project.ID);
        if (!Boolean.valueOf(result.get('require_target'))){
            success = false;
            errors.add('At least one service for this Project has a survey that is expecting Target(s) and there are no Target(s) assigned.');
        }
        //Removed OH-3807 by JV 10/31/17
        /*if(!Boolean.valueOf(result.get('might_need_target'))){
            warnings.add('At least one service for this project doesn\'t have any target.');
        }*/
        if (! Boolean.valueOf(result.get('might_need_item_question'))) {
            warnings.add('At least one service for this project has targets but doesn\'t have target related questions.');
        }
        return success;
    }
    
     /*public Boolean validatePcard() {
        return projectCompletionStrategyObject.validatePcardLeadTime(this.project.ID);
    }*/
    
    public Boolean validateMissingProjectLocation() {
        return projectCompletionStrategyObject.doesHaveProjectLocation(this.project.ID);
    }   
    
    public Boolean validateMissingJobs() {
        return projectCompletionStrategyObject.doesHaveAJob(this.project.ID);
    }   
    
    public Boolean validateMissingServiceJobs() {
        return projectCompletionStrategyObject.doesAllServicesHaveAJob(this.project.ID);
    }
    
    public Boolean doesAllLocationsHaveAJob() {
        return projectCompletionStrategyObject.doesAllLocationsHaveAJob(this.project.ID);
    }
    
    public Boolean doesProjServiceHasPrimaryItem() {
        return projectCompletionStrategyObject.doesProjServiceHasPrimaryItem(this.project.ID);
    }
    
    public List<ProjectService__c> validateMissingTargetType() {
        return projectCompletionStrategyObject.getProjectServicesWithoutATarget(this.project.ID);
    }   
    
    public List<ProjectService__c> validateMissingPrimaryTargets() {
        return projectCompletionStrategyObject.getProjectServicesWithoutAPrimaryProduct(this.project.ID);
    }
      
    public Boolean validateProjectleadTime() {
        return projectCompletionStrategyObject.doesProjectHaveEnoughLeadTime(this.project.ID);
    }       
    
    public List<ProjectServiceQuestion__c> validateSurveyQuestions() {
        return projectCompletionStrategyObject.getSurveyQuestionsWithMissingDefinedResponses(this.project.ID);
    }     
    
    public List<ProjectService__c> validateJobsOutsideProjectWindow() {
        return projectCompletionStrategyObject.getProjectServicesWithJobsOutsideProjectWindow(this.project.ID);
        }

    public void validateDefault() {
            projectCompletionStrategyObject.validateProjectCompletion(this.project.ID);
        }    
    
    public boolean IsAccountApproved(){
        return projectCompletionStrategyObject.IsAccountApproved(this.project.ID);
    }
    
    public boolean validateJobScheduledDates(){
        return projectCompletionStrategyObject.validateJobScheduledDates(this.project.ID);
    }

    public String GetMissingProjectAttributes(){
        return projectCompletionStrategyObject.validateProjectAttributes(this.project.ID);
    }
    
    public boolean AreMaterialsRequired(){
        return projectCompletionStrategyObject.validateMaterials(this.project.ID);
    }
    
    public boolean validateMinServiceCount(){
        return projectCompletionStrategyObject.validateMinServiceCount(this.project.ID);
    }
    
    public boolean IsValidEstimatedTime(){
        return projectCompletionStrategyObject.validateEstimatedTime(this.project.ID);
    }
    
    public List<String> validateJobManuals(){
        return projectCompletionStrategyObject.validateJobManuals(this.project.ID);
    }
    
    
    private List<String> getValidationRuleErrors(Project__c project)
    {
        //RN - This is just a quick fix
        //Will need to change this as soon as we get a chance
        //
        List<String> errors = new List<String>();
        Savepoint sp = Database.setSavepoint();
        
        try
        {
            TriggerUtil.SkipAllTriggers();
            ProjectActionsHelper.ChangeStatus(project, CONSTANTS.PROJECT_STATUS_BOOKED);
            update project;
            //ProjectActionsHelper.ChangeStatus(project, CONSTANTS.PROJECT_STATUS_PLANNING);
            //update project;
            Database.rollback(sp);
            return errors;
            
        }
        catch(System.DmlException e) {

            //RN - We need all validation rule failures not just the 
            //first one
            //Need to investigate if there's a way to capture ALL the
            //validation rule failures
            
            // Process exception here
            errors.add('Unable to move the project to Booked status. Details: ' + e.getDmlMessage(0));            
            success = false;
            Database.rollback(sp);
            return errors;
        }    
        catch(Exception e){
            
            errors.add('Unable to move the project to Booked status. Details: ' + e.getMessage());            
            success = false;
            Database.rollback(sp);
            return errors;
        }
    }
    
    
}