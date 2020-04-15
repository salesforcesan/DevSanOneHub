global class DataArchiveHandler {
	global DataArchiveHandler() {}
    
    global void archive(){
        
        OrgCustomSettings__c settings = OrgCustomSettings__c.getInstance('Setting');
        Integer projectArchivePendingDays = (settings == null || settings.ClosedProjectPendingArchiveDays__c == null) ? 30 : Integer.valueOf(settings.ClosedProjectPendingArchiveDays__c);
        Integer projectRetentionDays = (settings == null || settings.ClosedProjectRetentionDays__c == null) ? 30 : Integer.valueOf(settings.ClosedProjectRetentionDays__c);
        Integer dataArchiveProjectsLimit = (settings == null || settings.DataArchiveProjectsLimit__c == null) ? 50 : Integer.valueOf(settings.DataArchiveProjectsLimit__c);
		Integer dataArchivePendingProjectsLimit = (settings == null || settings.DataArchivePendingProjectsLimit__c == null) ? 50 : Integer.valueOf(settings.DataArchivePendingProjectsLimit__c);        
        
        Date pendingArchiveDay = (DateTime.now()).AddDays(projectArchivePendingDays * -1).date();
        Date deleteDay = (DateTime.now()).AddDays(projectRetentionDays * -1).date();
        
        system.debug('pendingArchiveDay::::::: '+pendingArchiveDay);
        system.debug('deleteDay::::::: '+deleteDay);
        try {
            TriggerUtil.SkipAllTriggers();
            //mark arcive status for projects that are colsed for more than x days to pending
            //Excluding OHM projects for now until we have a plan for JobImages
  			List<Project__c> projects = [SELECT Id, ArchiveStatus__c, SkipValidationRules__c, ProjectCloseDate__c FROM Project__c WHERE 
                                         Status__c = :CONSTANTS.PROJECT_STATUS_CLOSED AND ProjectCloseDate__c <= :pendingArchiveDay 
                                         AND ArchiveStatus__c = null AND IsOneHubMobile__c = false 
                                         ORDER BY ProjectCloseDate__c LIMIT :dataArchivePendingProjectsLimit];
            for(Project__c p: projects){
                p.ArchiveStatus__c = CONSTANTS.ARCHIVE_STATUS_PENDING;
                p.SkipValidationRules__c = true;
            }
            update projects;
            
            projects = [SELECT Id, ArchiveStatus__c FROM Project__c WHERE Status__c = :CONSTANTS.PROJECT_STATUS_CLOSED 
                        AND ProjectCloseDate__c <= :deleteDay AND ArchiveStatus__c =:CONSTANTS.ARCHIVE_STATUS_ARCHIVED
                        AND (ApexJobName__c = '' OR ApexJobName__c = null) 
                        ORDER BY ProjectCloseDate__c LIMIT :dataArchiveProjectsLimit];
            system.debug('Projects to Archive' + projects);
            //Changes by RN on 12/4/2017
            //For now, we'll remove only Jobs and Job Attempts so
            //the archived project can be cloned
            for(Project__c p :projects){
                ProjectActionsHelper.DeleteAllJobsByProject(p.Id);
            }
        }
        catch(Exception e) {
        	
            String messageSubject = 'Data archive job failed';
            String messageBody = e.getMessage();            
            String[] toAddresses = AppUtil.getAppSetting('DevAlertEmails').split(',');
            EmailHelper.SendEmail(toAddresses,messageSubject,messageBody,true); 
        }
    }
}