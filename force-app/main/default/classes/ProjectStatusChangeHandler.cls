global without sharing class  ProjectStatusChangeHandler {
    
    
    global ProjectStatusChangeHandler() {       
    }
    
    global void changeStatus(){
        
        TriggerUtil.SkipAllTriggers();
        try{
            //1. Move Ended to Closed
            Date todaysDate = system.Today();
            List<Project__c> endedClosedProjects = [SELECT Id, Name, UpdateSequence__c, Status__c FROM Project__c 
                                                    WHERE ProjectCloseDate__c < :todaysDate and 
                                                    (ApexJobName__c = '' OR ApexJobName__c = null) and 
                                                    (Status__c = :CONSTANTS.PROJECT_STATUS_INPROGRESS OR Status__c = :CONSTANTS.PROJECT_STATUS_ENDED)  
                                                    order by ProjectNumber__c  LIMIT 1];
 
            Id[] endedClosedProjectIds = new Id[] {};
            if (endedClosedProjects.size() > 0) {
                for (Project__c project:endedClosedProjects ) {
                    endedClosedProjectIds.add(project.Id);
                }
                try{
                    //for testing throw new CustomException('Ended to Closed Failed');
                  ProjectActionsHelper.CloseProjects(endedClosedProjectIds);    
                }
                catch(Exception ex){
                    notifyFailure('Project failed to move from Ended to Closed!', endedClosedProjects[0].Name + '; Error Details: ' + endedClosedProjects[0].id + '--' + ex.getMessage());
                }
                
            }
            
            //2. Move In Progress to Ended
            List<Project__c> inProgressProjects = [SELECT Id, Name, ProjectTypeName__c, IsPendingChangeReleaseRequest__c, 
                                                   UpdateSequence__c, Status__c, RecordTypeId FROM Project__c 
                                                   WHERE EndDate__c <= yesterday and  
                                                   (ApexJobName__c = '' OR ApexJobName__c = null) and 
                                                   Status__c = :CONSTANTS.PROJECT_STATUS_INPROGRESS order by ProjectNumber__c
                                                   LIMIT :AppUtil.ProjectStatusChangeSize];
            
            for(Project__c p:inProgressProjects){
                //Comment Versioning Code
                //version = version + 1;
                //p.UpdateSequence__c = version;

                ProjectActionsHelper.ChangeStatus(p, CONSTANTS.PROJECT_STATUS_ENDED);
                p.IsPendingChangeReleaseRequest__c = true;
            }
            
            List<Database.SaveResult> results = Database.update(inProgressProjects, false);
            for (Database.SaveResult result : results) {
              if (!result.isSuccess()){
                for (Database.Error err : result.getErrors()){
                    System.debug('Error: '+ err.getStatusCode() + ' ' + err.getMessage());
                    notifyFailure('Project failed to move from InProgress to Ended!', inProgressProjects[0].Name + '; Error Details: ' + inProgressProjects[0].id + '--' + err.getMessage());
                }
              }
            }
            
             //3. Move Launched to In Progress            
            set<id> projIDs = new set<id>();   
            string multiAttemptProj= '';
            
            OrgCustomSettings__c settings = OrgCustomSettings__c.getInstance('Setting');
			string fieldName=String.valueOf(settings.IsAttemptableFieldName__c == null? '': settings.IsAttemptableFieldName__c);
            system.debug('::-fieldName-::  '+fieldName);    
            
            List<Project__c> launchedProjects = [SELECT Id FROM Project__c 
                                                 WHERE StartDate__c <= today and 
                                                 (ApexJobName__c = '' OR ApexJobName__c = null) 
                                                 and Status__c = :CONSTANTS.PROJECT_STATUS_LAUNCHED 
                                                 order by ProjectNumber__c LIMIT :AppUtil.ProjectStatusChangeSize];
            set<id> InitProjIDs = (new Map<Id,Project__c>(launchedProjects)).keySet();
           system.debug('InitProjIDs::-soqlQry-::  ' +InitProjIDs);

                                                   	
            string soqlQry = 'Select Project__c proj from Job__c where ActiveJobAttempt__c =null and ProjectStatus__c =\''+  CONSTANTS.PROJECT_STATUS_LAUNCHED + '\'  and ' +  fieldName + ' =true group by Project__c having project__c in :InitProjIDs';  
            
            List<AggregateResult> groupedResults   =  Database.query(soqlQry);  //check for null attempts 
            for (AggregateResult ar : groupedResults)  {
                projIDs.add((ID)ar.get('proj'));    
            }
            system.debug('null attempts::-soqlQry-::  '+soqlQry +  '~~~' +groupedResults.size()+  '~~~' +projIDs);
            


            soqlQry = 'Select Project__c proj from Job__c where ActiveJobAttempt__c !=null and TotalJobAttempts__c>1 and ProjectStatus__c =\''+  CONSTANTS.PROJECT_STATUS_LAUNCHED + '\'  and ' +  fieldName + ' =true group by Project__c having project__c in :InitProjIDs';  
            groupedResults   =  Database.query(soqlQry);  //check for multi attempts             
            for (AggregateResult ar : groupedResults)  {
                projIDs.add((ID)ar.get('proj'));  
                multiAttemptProj = multiAttemptProj + String.valueOf(ar.get('proj'))   + ',';
            }
            system.debug(' multi attempts::-soqlQry-::  '+soqlQry +  '~~~' +groupedResults.size()+  '~~~' +projIDs);
            
            if(!string.isEmpty(multiAttemptProj)){
                notifyFailure('Multi Attempt detected !', ' Project Details: ' + multiAttemptProj);
            }
            
            system.debug('AppUtil.ProjectStatusChangeSize::--::'+AppUtil.ProjectStatusChangeSize + '::--::'+projIDs);
            launchedProjects = [SELECT Id, Name, ProjectTypeName__c, IsPendingChangeReleaseRequest__c, 
                                                 UpdateSequence__c, Status__c, RecordTypeId FROM Project__c 
                                                 WHERE id in : InitProjIDs  and id not in :projIDs 
                                                 order by ProjectNumber__c];
            
            system.debug(' launchedProjects::--::  '+ (new Map<Id,Project__c>(launchedProjects)).keySet());
            
            
            
            for(Project__c p:launchedProjects){
                //Comment Versioning Code
            
                //version = version + 1;
                //p.UpdateSequence__c = version;
                ProjectActionsHelper.ChangeStatus(p, CONSTANTS.PROJECT_STATUS_INPROGRESS);
                p.IsPendingChangeReleaseRequest__c = true;
            }
            results = Database.update(launchedProjects, false);
            for (Database.SaveResult result : results) {
              if (!result.isSuccess()){
                for (Database.Error err : result.getErrors()){
                    System.debug('Error: '+ err.getStatusCode() + ' ' + err.getMessage());
                    notifyFailure('Project failed to move from Launched to In Progress!', launchedProjects[0].Name + '; Error Details: '+ launchedProjects[0].id + err.getMessage());
                }
              }
            }
            
            //4. Move Booked to Launched
            Id[] launchedProjectIds = new Id[]{};
            List<Project__c> bookedProjects = [SELECT Id, Name, UpdateSequence__c, Status__c, StartDate__c, 
                                               EndDate__c, LaunchedProjectStartDate__c, LaunchedProjectEndDate__c, 
                                               ProjectNumber__c  FROM Project__c 
                                               WHERE ProjectLaunchDate__c <= today and 
                                               (ApexJobName__c = '' OR ApexJobName__c = null) and 
                                               Status__c = :CONSTANTS.PROJECT_STATUS_BOOKED 
                                               order by ProjectNumber__c  LIMIT 1];

            if (bookedProjects.size() > 0)
            {
                for (Project__c project :bookedProjects)
                {
                    launchedProjectIds.add(project.Id);
                }
                try{
                  ProjectActionsHelper.LaunchProjects(launchedProjectIds);
                    
                }
                catch(Exception ex){
                    notifyFailure('Project failed to move from Booked to Launched', bookedProjects[0].Name + '; Error Details: '  + bookedProjects[0].id + ex.getMessage());
                }
                
            }
            
            
        }
        catch(Exception e){
            String messageSubject = 'Schedule project status job failed';
            String messageBody = 'Error Details: ' + e;            
            String[] toAddresses = AppUtil.getAppSetting('DevAlertEmails').split(',');                        
            EmailHelper.SendEmail(toAddresses,messageSubject,messageBody,true);
            
        }
    }
    
    public void notifyFailure(string subject, string body){
        String messageSubject = subject;
        String messageBody = body;
        
        
        String[] toAddresses = AppUtil.getDevAlertEmails();
        if(toAddresses == null){
            return;
        }

        try{
        	Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        	mail.emailPriority = 'Highest';
        	EmailHelper.SendEmail(mail,toAddresses,messageSubject,messageBody,true);
        }
        catch(Exception ex){
            system.debug('Projest status change handler failed to send email. Exception details:' + ex.getMessage());
        }
        finally{
        }
    }
}