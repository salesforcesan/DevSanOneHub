public with sharing class ProjectSubmitRequestModel extends LightningRequestBase {
    private Project__c project {get; set;}
    private ProjectCompletionStrategy projectCompletionStrategyObject {get; set;}
    private ResponseBuilder builder {get; private set;}

    public ProjectSubmitRequestModel() {
        this.builder = new ResponseBuilder();
    }

    //api: get
    public override Object get(Object parameters) {
        this.bootstrap(parameters);
        this.runProjectValidationRules(this.project);
        
        return this.builder.build();
    }

    private void bootstrap(Object parameters) {
        initProject(parameters);
        initProjectStrategyImplementation();

        checkProject();
        checkAccounts();
        checkServices();
        checkLocations();
        checkJobs();
    }

    private void initProject(Object parameters) {
        Map<String, Object> query = LightningRequestHelper.parseObjectMap(parameters);
        String projectId = LightningRequestHelper.parseString(query.get('projectId'));
        validateProjectId(projectId);
        this.project = getProject(projectId);
    }

    private void validateProjectId(String projectId) {
        if (String.isBlank(projectId)) {
            throw new AuraHandledException('The project ID can not be null.');
        }
    }

    private Project__c getProject(String projectId) {
        List<Project__c> projects = [
                                        Select Id, Name, BudgetedLocationsCount__c, LocationTotalCount__c, Status__c, StartDate__c, MinServiceCount__c, ProjectType__c, ProjectTypeName__c, Approvaldate__c, Approver__c, Splittype__c, RecordTypeId from Project__c WHERE ID = :projectID];

        if (projects.isEmpty()) {
            throw new AuraHandledException('The project (' + projectId + ') is not found.');
        }

        return projects[0];
    }



    private void initProjectStrategyImplementation() {
        this.projectCompletionStrategyObject = ProjectCompletionStrategyFactory.getProjectCompletionStrategy(this.project.ProjectType__c);
    }

    @testVisible
    private void checkProject() {
        validateRequiredProjectAttributes();
        validateProjectgStartDateNotInPast();
        validateProjectHasEnoughLeadTime();
        validateMinimumServiceCount();
        validateScheduledAndBudgetedLocations();
    }

    private void validateRequiredProjectAttributes() {
        String msg = projectCompletionStrategyObject.validateProjectAttributes(this.project.ID);
        if (String.isNotBlank(msg)) {
            this.builder.addError('The project does not have values for required attributes ' + '(' + msg  + ')');
        }
    }

    private void validateProjectgStartDateNotInPast() {
        if (this.project.StartDate__c < date.today()) {
            this.builder.addError('The project\'s start date is in the past that is not allowed.');
        }
    }

    private void validateProjectHasEnoughLeadTime() {
        if (!projectCompletionStrategyObject.doesProjectHaveEnoughLeadTime(this.project.ID)) {
            this.builder.addWarn('The project does not have the required lead time (Execution/Fulfillment).');
        }
    }

    private void validateMinimumServiceCount() {
        String projectId = this.project.Id;
        Integer serviceCount = [SELECT Count() FROM ProjectService__c WHERE Project__c = :projectId];
        if (this.project.MinServiceCount__c > serviceCount) {
            this.builder.addError('Project does not have minimum number of services required.');
        }
    }

    private void validateScheduledAndBudgetedLocations() {
        Project__c project = this.project;
        if (project.BudgetedLocationsCount__c != project.LocationTotalCount__c) {
            this.builder.addWarn('The number of locations added to the project  does not equal the number of  budgeted locations.');
        }
    }

    @testVisible
    private void checkAccounts() {
        ValidationResult result = projectCompletionStrategyObject.validateAccounts(this.project.ID);
        if (result.Status == CONSTANTS.STATUS_OK) return;
        this.builder.addAllWarns(result.Warnings);
        this.builder.addAllErrors(result.Errors);
        this.builder.addElements('accounts', result.Errors);
    }

    @testVisible
    private void checkServices() {
        if (projectCompletionStrategyObject.doesHaveProjectService(this.project.ID)) {
            if (!validateEstimatedTime()) {
                this.builder.addError('Estimated Time must be entered either at the Project or the Service level in order to submit.');
            }
        } else {
            this.builder.addError('The project does not have any services.');
            this.builder.addElement('services', 'The project does not have any services');
        }
        validateServiceNubmerOfDays();
        checkServiceTargets();
        checkSurveyQuestions();
        validateJobManual();
    }

    private void checkServiceTargets() {
        Map<String,Boolean> result = projectCompletionStrategyObject.validateServiceTargetRequirement(this.project.Id);
        if (!Boolean.valueOf(result.get('require_target'))){
            this.builder.addError('At least one service for this Project has a survey that is expecting Target(s) and there are no Target(s) assigned.');
        }
        if (! Boolean.valueOf(result.get('might_need_item_question'))) {
            this.builder.addWarn('At least one service for this project has targets but doesn\'t have target related questions.');
        }
    }

    private void validateServiceNubmerOfDays() {
        if (!projectCompletionStrategyObject.hasValidNumberOfDays(this.project.Id)) {
            this.builder.addWarn('Invalid number of days. Number of days on service(s) exceeded the project number of days.');
        }
    }

    private Boolean validateEstimatedTime() {
        return projectCompletionStrategyObject.validateEstimatedTime(this.project.ID);
    }

    //@testVisible
    //private void checkServiceTargets() {
    //    ValidationResult result = projectCompletionStrategyObject.validateServiceTarget(this.project.Id);
    //    if (result.Status == CONSTANTS.STATUS_OK) return;
    //    this.builder.addAllWarns(result.Warnings);
    //    this.builder.addAllErrors(result.Errors);
    //    this.builder.addElements('services', result.Errors);
    //}

    @testVisible
    private void checkLocations() {
        if (!projectCompletionStrategyObject.doesHaveProjectLocation(this.Project.Id)) {
            this.builder.addError('The project does not have any locations.');
            this.builder.addElement('locations', 'The project does not have any locations.');
        }
        if (!projectCompletionStrategyObject.doesAllLocationsHaveAJob(this.project.ID)) {
            this.builder.addWarn('There are locations that currently do not have jobs created.');
        }
    }

    @testVisible
    private void checkJobs() {
        String msg;
        if (!projectCompletionStrategyObject.doesHaveAJob(this.project.Id)) {
            msg = 'There are no jobs created for the project yet.';
            this.builder.addError(msg);
            this.builder.addElement('jobs', msg);
        } else {
            List<ProjectService__c> psList = projectCompletionStrategyObject.getProjectServicesWithJobsOutsideProjectWindow(this.project.Id);
            if (!psList.isEmpty()) {
                msg = 'The project has invalid jobs. Some of the jobs fall outside the project window.';
                this.builder.addError(msg);
                this.builder.addElement('jobs', msg);

            }
            if (!projectCompletionStrategyObject.doesAllServicesHaveAJob(this.project.Id)) {
                msg = 'There are no jobs created for some of the service(s).';
                this.builder.addError(msg);
                this.builder.addElement('jobs', msg);
            }
            if (!projectCompletionStrategyObject.validateJobScheduledDates(this.project.Id)) {
                msg = 'This Project contains Jobs for recently added Services that do not have a Scheduled Date. Please add a Scheduled Date through the Manage Locations screen;  else these Jobs will not be launched to downstream systems.';
                this.builder.addWarn(msg);
            }
        }
    }

    private void checkSurveyQuestions() {
        ValidationResult result = projectCompletionStrategyObject.validateSurveyQuestion(this.Project.Id);
        if (result.Status == CONSTANTS.STATUS_OK) return;
        this.builder.addAllErrors(result.Errors);
        this.builder.addAllWarns(result.Warnings);
        this.builder.addElements('surveys', result.Errors);
        validateSurveyScoreStatus();
    }

    private void validateSurveyScoreStatus() {
        List<string> thresholdExceptions = projectCompletionStrategyObject.getServicesSurveyScoreStatus(this.project.Id, 'warning');
        if (thresholdExceptions.size() > 0) {
            string displayError = string.join(thresholdExceptions, '<br/>');
            this.builder.addWarn('Please review your survey for any complexities that may be removed. <br/><br/><b>' + displayError + '</b><br/><br/>');
        }

        thresholdExceptions = projectCompletionStrategyObject.getServicesSurveyScoreStatus(this.project.Id, 'error');
        if (thresholdExceptions.size() > 0) {
            string displayError = string.join(thresholdExceptions, '<br/>');
            String msg = 'Please fix your survey to reduce the complexity. <br/><br/><b>' + displayError + '</b><br/><br/>';
            this.builder.addError(msg);
            this.builder.addElement('surveys', msg);
        }
    }

    private void validateJobManual() {
        List<String> jobManualErrors = projectCompletionStrategyObject.validateJobManuals(this.project.Id);
        this.builder.addAllErrors(jobManualErrors);
        this.builder.addElements('services', jobManualErrors);
    }

    //todo: need to implement all validations rules in apex codes instead
    // based on the business requirement
    // pre-flight.

    private void runProjectValidationRules(Project__c project)
    {
        Savepoint sp = Database.setSavepoint();        
        try
        {
            TriggerUtil.SkipAllTriggers();
            ProjectActionsHelper.ChangeStatus(project, CONSTANTS.PROJECT_STATUS_BOOKED);
            update project;
            Database.rollback(sp);
        }
        catch(System.DmlException e) {
            Database.rollback(sp);
            this.builder.addError('Unable to move the project to Booked status. Details: ' + e.getDmlMessage(0));            
        }    
        catch(Exception e){
            Database.rollback(sp);
            this.builder.addError(
                'Unable to move the project to Booked status. Details: ' + 
                e.getMessage() + 
                '(' + 
                e.getLineNumber() + 
                ')');            
        }
    }

    //api: modify
    public override Object modify(Object parameters) {
        this.bootstrap(parameters);
        if (this.builder.hasError()) {
            return this.builder.build();
        }

        try {
            this.submitProject();
        } catch (System.DmlException e) {
            this.builder.addError('Unable to move the project to Booked status. Details: ' + e.getDmlMessage(0));
        } catch (Exception e) {
            this.builder.addError('Unable to move the project to Booked status. Details: ' + e.getMessage() + '(' + e.getLineNumber() + ').');
        }

        return this.builder.build();
    }

    private void submitProject() {
        Project__c project = this.project;

        if (project.approver__c == null) {
            ProjectActionsHelper.ChangeStatus(project, CONSTANTS.PROJECT_STATUS_BOOKED);
            project.ApprovalRequestDate__c  = System.Now();
            project.ApprovalDate__c = project.ApprovalRequestDate__c;
            project.BookedProjectStartDate__c = project.StartDate__c;
            project.BookedProjectEndDate__c = project.EndDate__c;
        } else {
            ProjectActionsHelper.ChangeStatus(project, CONSTANTS.PROJECT_STATUS_PENDING);
            project.ApprovalRequestDate__c = System.Now();
        }

        update project;

        AttachmentUrlGenerator.generateJobManualFutureCall(string.valueof(project.Id));  
    }
}