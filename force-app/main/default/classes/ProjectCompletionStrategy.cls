global abstract class ProjectCompletionStrategy {
    private Project__c Project {get;set;}

    global List<ProjectService__c> getProjectServicesWithoutATarget(ID projectID){
         return [Select Id, Name, Service__c, Project__c, TargetType__c From ProjectService__c WHERE Project__c = :projectID AND TargetType__c = null];
    }
    
    global List<ProjectService__c> getProjectServicesWithoutAPrimaryProduct(ID projectID){
         return [Select Id, Name, Service__c, Project__c, TargetType__c From ProjectService__c WHERE Project__c = :projectID AND TargetType__c = 'Product' AND NumberOfTargets__c = 0 and project__r.ProjectType__r.name!=:ProjectType.MD];
    }
    
    global boolean doesProjServiceHasPrimaryItem(ID projectID){
        Integer psCount =  [SELECT Count() FROM ProjectService__c where project__c =:projectID];
        Integer pstCount =  [SELECT Count() FROM ProjectService__c where Id IN (SELECT ProjectService__c FROM ProjectServiceTarget__c WHERE projectservice__r.project__c =:projectID AND Type__c = 'primary' )];
        if(psCount == pstCount) {
           return true;
        }
        return false;
    }
    global virtual ValidationResult validateServiceTarget(ID projectID){
        ValidationResult result = ValidationResult.createInstance();

        AggregateResult count = [Select count(id) cnt from ProjectService__c 
            WHERE Project__c = :projectID 
            AND NumberofTargetQuestions__c > 0 
            AND NumberOfTargets__c = 0];
        if (count.get('cnt') == 0) {
            result.addError('At least one service for this Project has a survey that is expecting Target(s) and there are no Target(s) assigned.');
        }
        
        count = [Select count(id) cnt from ProjectService__c 
            WHERE Project__c = :projectID 
            AND NumberofTargetQuestions__c = 0 
            AND NumberOfTargets__c > 0];

        if (count.get('cnt') == 0) {
            result.addWarning('At least one service for this project has targets but doesn\'t have target related questions.');
        }

        return result;
    }   

    //oh-1029
    global virtual Map<String,Boolean> validateServiceTargetRequirement(ID projectID){
        Map<String,Boolean> validations = new Map<String,Boolean>();
        AggregateResult count = [Select count(id) cnt from ProjectService__c 
            WHERE Project__c = :projectID 
            AND NumberofTargetQuestions__c > 0 
            AND NumberOfTargets__c = 0];

        validations.put('require_target',Integer.valueOf(count.get('cnt')) > 0 ? false: true);

        count = [Select count(id) cnt from ProjectService__c 
            WHERE Project__c = :projectID 
            AND NumberofTargetQuestions__c = 0 
            AND NumberOfTargets__c = 0];

        validations.put('might_need_target',Integer.valueOf(count.get('cnt')) > 0 ? false: true);

        count = [Select count(id) cnt from ProjectService__c 
            WHERE Project__c = :projectID 
            AND NumberofTargetQuestions__c = 0 
            AND NumberOfTargets__c > 0];

        validations.put('might_need_item_question', Integer.valueOf(count.get('cnt')) > 0 ? false: true);

        return validations;
    }
    
    global boolean IsDateInPast(ID projectID){
        project__c p = [Select startdate__c From Project__c WHERE id = :projectID];
        boolean rtnVal= false;
        if(p.startdate__c<date.today())
        {
              rtnVal= true;
        }
        return rtnVal;
    } 

    global Boolean doesHaveProjectService(ID projectID){
        List<ProjectService__c> pss = [Select Id, Name, Service__c, Project__c, TargetType__c From ProjectService__c WHERE Project__c = :projectID LIMIT 1];
        if (pss.IsEmpty())
        {
            return false;
        }
        else
        {
            return true;
        }
    }

    global Boolean doesHaveAJob(ID projectID){
        List<Job__c> jbs = [Select Id, Name From Job__c WHERE Project__c = :projectID LIMIT 1];
        if (jbs.IsEmpty())
        {
            return false;
        }
        else
        {
            return true;
        }
    }
    
    global virtual Boolean doesHaveProjectAccount(ID projectID){
        List<ProjectAccount__c> pas = [Select Id, Name From ProjectAccount__c WHERE Project__c = :projectID LIMIT 1];
        if (pas.IsEmpty())
        {
            return false;
        }
        else
        {
            return true;
        }
    }
    
    global virtual Boolean doesHaveProjectLocation(ID projectID){
        List<ProjectLocation__c> pls = [Select Id, Name From ProjectLocation__c WHERE Project__c = :projectID LIMIT 1];
        if (pls.IsEmpty())
        {
            return false;
        }
        else
        {
            return true;
        }
    }
    
    //@deprecated
    global virtual Boolean hasValidProjectLocations(ID projectId){
         Integer reservedCount = [Select Count() FROM ProjectLocation__c WHERE Project__c = :projectId and Status__c = 'Booked'];
         Integer totalCount = [Select Count() FROM ProjectLocation__c WHERE Project__c = :projectId];      

         return (totalCount == 0 || reservedCount == 0 || totalCount != reservedCount) ? false : true;
    }
        
    global virtual Boolean doesAllServicesHaveAJob(ID projectID){
        Integer count = [Select count() From ProjectService__c WHERE Project__c = :projectID AND 
                         Id NOT IN (SELECT ProjectService__c FROM Job__c WHERE Project__c = :projectID)];
        if(count > 0){
            return false;
        }
        return true;
    }
    
    global virtual Boolean doesAllLocationsHaveAJob(ID projectID){
        List<ProjectLocation__c> pls = [Select Id From ProjectLocation__c WHERE Project__c = :projectID AND Id NOT IN 
                         (SELECT ProjectLocation__c FROM Job__c WHERE Project__c = :projectID) LIMIT 1];
        if(!pls.isEmpty()){
            return false;
        }
        return true;
    }


    global List<ProjectService__c> getProjectServicesWithJobsOutsideProjectWindow(ID projectID){
         
         Date projectStartDate = [Select StartDate__c FROM Project__c WHERE Id = :projectID LIMIT 1].StartDate__c;
         Date projectEndDate = [Select EndDate__c FROM Project__c WHERE Id = :projectID LIMIT 1].EndDate__c;
         
         
         return [Select Id, Name, Service__c,  Project__c FROM ProjectService__c WHERE Id in (Select ProjectService__c FROM Job__c WHERE Project__c = :projectID AND 
                     (JobStartDate__c < :projectStartDate OR JobStartDate__c > :projectEndDate OR JobEndDate__c < :projectStartDate OR JobEndDate__c > :projectEndDate))];
    }


    global Boolean doesProjectHaveEnoughLeadTime(ID projectID){
         Project__c project = [Select Id, StartDate__c, ProjectCancelLeadTime__c, FulfillmentLeadTime__c, ProjectOrigin__c FROM Project__c where Id = :projectID LIMIT 1];
         return AppUtil.hasProjectLeadTime(project);
                  
    }
    
    global List<ProjectServiceQuestion__c> getSurveyQuestionsWithMissingDefinedResponses(ID projectID){
         //returns the question with no defined responses or with no project service defined responses
         String Proj15Digit = string.valueof(projectID).substring(0, 15);

         integer cnt = [Select count() from ProjectServiceQuestion__c WHERE ProjectId__c = :Proj15Digit AND QuestionType__c 
                 IN ('Single-Select List','Multi-Select List', 'Yes/No') AND DefinedResponseCount__c = 0];
         system.debug('project~~~~~cnt~~~~'+projectID+'~~~~~~~'+cnt);       
          
         return [Select Id, Name, QuestionText__c from ProjectServiceQuestion__c WHERE ProjectId__c = :Proj15Digit AND QuestionType__c 
                 IN ('Single-Select List','Multi-Select List', 'Yes/No') AND DefinedResponseCount__c = 0];
    }

    global virtual ValidationResult validateSurveyQuestion(String projectId) {
        ValidationResult result = ValidationResult.createInstance();
        String sql = 'Select count() from ProjectServiceQuestion__c WHERE ProjectId__c = :projectId AND QuestionType__c IN (\'Single-Select List\',\'Multi-Select List\', \'Yes/No\') AND DefinedResponseCount__c = 0';

        if (Database.countQuery(sql) > 0){
            result.addError('The project has invalid survey questions.');
        }

        return result;
    }
    

    global Integer checkScheduledAndBudgetLocations(ID projectId){
        Project__c project = getProject(projectId);
        if (project.BudgetedLocationsCount__c == project.LocationTotalCount__c) {
            return 0;
        }
        return (project.BudgetedLocationsCount__c < project.LocationTotalCount__c) ? 1 : -1;
    } 

    private Project__c getProject(ID id){
        if (Project == null ) {
            Project = [
                SELECT
                    StartDate__c, FulfillmentLeadTime__c, ProjectCancelLeadTime__c,
                    LocationTotalCount__c, BudgetedLocationsCount__c, 
                    TotalAccountSplit__c, SplitType__c
                FROM Project__c
                WHERE Id = :id
                LIMIT 1
            ];
        }
        return Project;
    }

    global Boolean isProjectFullySplitted(ID projectId) {
    
        Project__c project = getProject(projectId);
        if (project.SplitType__c!=null && project.SplitType__c.contains('Percentage'))
        {
            if (Integer.valueOf(project.TotalAccountSplit__c) != 100)
                return false;
        
        }
    
        return true;
    }

   


    global Boolean isMaterialAddedWithinLeadTime(ID projectId) {
        Project__c project = getProject(projectId);
        Integer leadDays = Integer.ValueOf(project.FulfillmentLeadTime__c > project.ProjectCancelLeadTime__c ? project.FulfillmentLeadTime__c : project.ProjectCancelLeadTime__c);
        Boolean result = false;
        Date startDate = project.StartDate__c;
        List<ProjectServiceMaterial__c> materials = [
            SELECT CreatedDate FROM ProjectServiceMaterial__c
            WHERE ProjectService__r.Project__c = :projectId
        ];

        for(ProjectServiceMaterial__c m: materials) {
            if ( m.createdDate.date().daysBetween(startDate) <= leadDays ) {
                system.debug('startDate.daysBetween(m.createdDate.date()):: '+startDate.daysBetween(m.createdDate.date()));
                system.debug('leadDays:: '+leadDays);
                result = true;
                break;
            }
        }
        return result;
    }
    
    global abstract void ValidateProjectCompletion(String projectID);
    
    /*global Boolean validateQuestionResponse(ID projectId) {   
       integer ResponsesCount =  [Select count() from ProjectServiceQuestion__c WHERE ProjectId__c = :projectID AND QuestionType__c 
            IN ('Single-Select List','Multi-Select List', 'Yes/No') AND Question__r.DefinedResponseCount__c = 0 AND DefinedResponseCount__c = 0];
                 
       return (ResponsesCount==0);
    }*/

    global virtual ValidationResult validateAccounts(ID projectId) {
        ValidationResult result = ValidationResult.createInstance();

        List<ProjectAccount__c> accounts = [SELECT IsPrimary__c, Account__r.isApproved__c FROM ProjectAccount__c WHERE Project__c =: projectId];
        
        if (accounts.isEmpty()){
            result.addError('The project account(s) are not defined.');
            return result;
        }

        Boolean hasApproved = false;
        for(ProjectAccount__c acct: accounts) {
            if (acct.Account__r.IsApproved__c) {
                hasApproved = true;
            }
            else if (acct.IsPrimary__c) {
                result.addError('The primary account is not approved.');
            }
        }

        if (!hasApproved) {
            result.addError('The project does not have approved account(s).');
        }

        return result;
    }
    
    global boolean IsAccountApproved(ID projectId) {
        integer ResponsesCount =  [Select count() from projectaccount__c WHERE Project__c = :projectID AND account__r.isapproved__c=false and IsPrimary__c = true];
        return (ResponsesCount==0);
    }
    
    global virtual integer ProjectAccountCount(ID projectId) {
        integer ResponsesCount =  [Select count() from projectaccount__c WHERE Project__c = :projectID AND account__r.isapproved__c=true];
        return (ResponsesCount);
    }
    
    global virtual boolean hasValidNumberOfDays(ID projectId) {
        Project__c p =  [Select NumberOfDays__c, ProjectType__r.AllowMultidays__c from Project__c WHERE Id = :projectID];
        if(p.ProjectType__r.AllowMultidays__c != true){
            return true;
        }
        
        List<ProjectService__c> psList = [Select NumberOfDays__c from ProjectService__c WHERE Project__c = :projectID ORDER BY NumberOfDays__c DESC LIMIT 1];
        if(psList.size() > 0 && psList[0].NumberOfDays__c != null &&  psList[0].NumberOfDays__c > p.NumberOfDays__c){
            return false;
        }
        return true;
    }
    
    global virtual boolean validateJobScheduledDates(ID projectId) {
        List<Job__c> jobs = [SELECT Id, name FROM Job__c WHERE Project__c = :projectID AND 
                                      JobScheduledDate__c = NULL AND 
                                      Project__r.ProjectScheduleOptionCode__c != :CONSTANTS.SCHEDULE_OPTION_EC LIMIT 1]; 
        
        if(!jobs.isEmpty()){
            return false;
        }
        return true;
    }
    
    global virtual String validateProjectAttributes(ID projectId){
      	List<ProjectAttribute__c> pAttributes =  [Select Id, AttributeName__c, AttributeValue__c from ProjectAttribute__c 
                                                  WHERE Project__c = :projectID and IsRequired__c=true];
        String result='';
        for(ProjectAttribute__c pa: pAttributes)
        {
			if(pa.AttributeValue__c==null||pa.AttributeValue__c=='')
            {
                result += pa.AttributeName__c + ',';
            }
        }
        if(result!=''){
            result = result.substring(0,result.length()-1);
        }
        system.debug('######### result ###### '+ result);
            
        return result;
    }
    
    global virtual boolean validateMaterials(ID projectId){
        boolean isMissing = false;
        List<ProjectService__c> pServices = [SELECT Id, IsMaterialNeeded__c FROM ProjectService__c 
                                             where Project__c = :projectId and 
                                             IsMaterialNeeded__c=true];
        for(ProjectService__c ps:pServices)    
        {
            List<ProjectServiceMaterial__c> psMaterials = [select Id,Name FROM ProjectServiceMaterial__c 
                                                           where ProjectService__c = : ps.Id];
            if(psMaterials.isEmpty())
            {
                isMissing=true;
                break;
            }
        }
        return isMissing;
    }
    
    global virtual boolean validateMinServiceCount(ID projectId){
        Project__c project = [select Id, MinServiceCount__c FROM Project__c WHERE Id= :projectId];
        Integer serviceCount = [SELECT Count() FROM ProjectService__c WHERE Project__c = :projectId];
        if(serviceCount < project.MinServiceCount__c){
            return false;
        }
        return true;
    }
    
    global virtual boolean validateEstimatedTime(ID projectId){
        List<Project__c> projects = [SELECT Id, Name, EstimatedMinutesCalculated__c FROM Project__c where EstimatedMinutesCalculated__c in (null,0) and Id= :projectId];
        List<ProjectService__c> services = [SELECT Id, Name, Project__c, EstimatedMinutes__c FROM ProjectService__c where EstimatedMinutes__c in (null,0) and Project__c= :projectId];
        if(projects.size()>0 && services.size()>0){
            return false;
    	}
        return true;
    }
    
    global virtual Boolean validatePcardLeadTime(ID projectID){
        List<ProjectService__c> pcl = [Select Id, Name, PcardLeadTime__c FROM ProjectService__c WHERE Project__c = :projectID AND PcardLeadTime__c < 5];
        if (pcl.IsEmpty())
        {
            return false;
        }
        else
        {
            return true;
        }
    }
    
    global virtual List<String> validateJobManuals(ID projectId){
          
        
        List<ProjectService__c> pss = [SELECT Id, Name, Service__r.Name, ServiceTitle__c,JobManualFileName__c,isManualGenInProgress__c, JobManualURL__c FROM ProjectService__c where  JobManual__c Not IN ('Standard','No Manual') AND (JobManualFileName__c = '' OR isManualGenInProgress__c = true) and Project__c= :projectId];
        List<String> errors = new List<String>();
        List<String> inprogressServices = new List<String>();
        List<String> missingServices = new List<String>();
        if(pss.size() > 0 ){
            for(ProjectService__c ps : pss){
                if(ps.isManualGenInProgress__c == true){
                    inprogressServices.add(ps.Service__r.Name + (ps.ServiceTitle__c == null ? '' : (' - ' + ps.ServiceTitle__c)));
                }
                if(String.isBlank(ps.JobManualFileName__c)){
                    missingServices.add(ps.Service__r.Name + (ps.ServiceTitle__c == null ? '' : (' - ' + ps.ServiceTitle__c)));
                }
            }
    	}
        String separator = ', ';

        if(inprogressServices.size() > 0){
        	errors.add('Job manual generation is in progress for ' + String.join(inprogressServices, separator) + '. Please try again.' );
        }
        if(missingServices.size() > 0){
        	errors.add('Custom Job Manual is missing for ' + String.join(missingServices, separator) + '.' );
        }
        
        return errors;
    }
    
    //This method needs to be depracated
    global virtual List<string> getThresholdExceededServices(ID projectId, Boolean isWarning){
        
        List<ProjectService__c> exceededProjectServices = [select Id, Name, ServiceTitle__c from ProjectService__c where Project__c= :projectId and IsSurveyScoreWarning__c= :isWarning and IsSurveyScoreExceedThreshold__c != :isWarning];
        List<String> services = new List<String>();
        
        for(ProjectService__c ps:exceededProjectServices)
        {
            services.add(ps.Name + ' - ' + ps.ServiceTitle__c);
        }
       return services;
    }
    
    global virtual List<string> getServicesSurveyScoreStatus(ID projectId, String statustype){
        
        List<ProjectService__c> exceededProjectServices;
        if (statustype.compareTo('error') == 0)
        {
        	exceededProjectServices = [select Id, Name, ServiceTitle__c from ProjectService__c where Project__c= :projectId and IsSurveyScoreExceedThreshold__c = True];    
        }
        else if (statustype.compareTo('warning') == 0)
        {
            exceededProjectServices = [select Id, Name, ServiceTitle__c from ProjectService__c where Project__c= :projectId and IsSurveyScoreWarning__c = True];    
        }
        
        
        List<String> services = new List<String>();
        
        for(ProjectService__c ps:exceededProjectServices)
        {
            services.add(ps.Name + ' - ' + ps.ServiceTitle__c);
        }
       return services;
    }
    
    
    
}