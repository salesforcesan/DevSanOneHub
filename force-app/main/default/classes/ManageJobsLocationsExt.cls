global without sharing class ManageJobsLocationsExt {
    
    public Project__c proj {get;set;}
    public String projectName {get;set;}
    public String projectId {get;set;} 
    public Boolean showCancelButton {get;set;}
    public Boolean showDeleteButton {get;set;}
    public Map<String,Boolean> hiddenMap {get;set;}
    public boolean showSetSchedule {get;set;}
    public String scheduleWindowStartDate {get;set;}
    public String scheduleWindowEndDate{get;set;}
    public Integer maxServiceDaysNeeded{get;set;}
    public boolean showScheduledate{get;set;}
    public String getNAMESPACE() {
        return CONSTANTS.CURRENTNAMESPACEPREFIX;
    }
    
    public ManageJobsLocationsExt(ApexPages.StandardController controller) {               
        ProjectID = ApexPages.currentPage().getParameters().get('projectid'); 
        proj = [select id,name,retailer__c, OneHubRetailerId__c,Status__c,IsExternalProject__c, ProjectScheduleOption__r.Code__c, format(StartDate__c), format(EndDate__c),NumberOfDays__c, ProjectType__r.SetScheduleDateLeadTime__c,ProjectType__r.AllowMultidays__c from project__c where id=:projectId];
        List<ProjectService__c> psList = [select id, NumberOfDays__c, StartDayNumber__c from ProjectService__c where Project__c =:projectId];
        maxServiceDaysNeeded = Integer.valueOf(proj.NumberOfDays__c);
        if(maxServiceDaysNeeded == null){
            maxServiceDaysNeeded = 1;
        }
        /*maxServiceDaysNeeded = 1;
        for(ProjectService__c ps:psList){
            if(ps.NumberOfDays__c > maxServiceDaysNeeded ){
                maxServiceDaysNeeded = Integer.valueOf(ps.NumberOfDays__c);
            }
        }*/
        showSetSchedule = false;
        showScheduledate = false;
        boolean hasScheduleLeadTime = false;
        if(proj.ProjectType__r.SetScheduleDateLeadTime__c != NULL && proj.StartDate__c.addDays(Integer.valueOf(proj.ProjectType__r.SetScheduleDateLeadTime__c * -1)) >= date.today()) {
            hasScheduleLeadTime = true;
        }
        if(proj.ProjectScheduleOption__r.Code__c == CONSTANTS.SCHEDULE_OPTION_USER){
            showScheduledate = true;
            if(hasScheduleLeadTime){
                showSetSchedule = true;
            }
        }
        scheduleWindowStartDate = String.valueOf(proj.StartDate__c);
        scheduleWindowEndDate = String.valueOf(proj.EndDate__c.addDays((maxServiceDaysNeeded * -1) + 1));
        projectName = proj.name;
        //showSetSchedule =  (proj.ProjectScheduleOption__r.Code__c != CONSTANTS.SCHEDULE_OPTION_EC) && (proj.Status__c == CONSTANTS.PROJECT_STATUS_BOOKED || proj.Status__c == CONSTANTS.PROJECT_STATUS_LAUNCHED || proj.Status__c == CONSTANTS.PROJECT_STATUS_PLANNING);
        Set<String> hiddenElemets = new Set<String>{'ProjectLocation__c.Delete', 'ProjectLocation__c.Cancel'};
        hiddenMap = UIConfig.isHidden(proj.Status__c, hiddenElemets);        
        showCancelButton = !hiddenMap.get('ProjectLocation__c.Cancel');
        showDeleteButton = !hiddenMap.get('ProjectLocation__c.Delete');
                  
    }
    
    //deprecated
    @RemoteAction
    global static list<location__c> getProj(string state,string city,string zipcode, string projectId, string Location,string Status) 
    {
        return null;
    }
    @RemoteAction
    global static list<location__c> getLocations(string state,string city,string zipcode, string projectId, string Location,string Status, string showScheduledOnly) 
    {  
        project__c proj = [select id,retailer__c from project__c where id=:projectId];
        string LocationQry = 'Select name,Status__c,Project__c, location__r.Address__c,location__r.state__c,location__r.name,location__r.city__c,location__r.postalcodename__c,location__r.postalcode__r.name,location__r.locationnumber__c,location__c, statuscomments__c, format(LocationScheduledDate__c) from ProjectLocation__c where project__c =  \'' + ProjectID +'\'  '; 
        boolean isFilterExist = false;
        
        Set<String> locsTofilter = new Set<String>();
        Location = Location.replace(' ','').replace(',','\n');
        for(String item : Location.split('\n'))
        {
           locsTofilter.add(item);           
        }
        
        if(Location!=null && Location!='')
        {   
            isFilterExist =true;         
            LocationQry+= ' and location__r.locationnumber__c IN :locsTofilter '; 
        }        
        
        if(state.indexOf('NONE') == -1 && state!=null)
        {   
            isFilterExist =true;         
            LocationQry+= ' and location__r.State__c = \'' + string.valueof(state) +'\'  '; 
        }     
        if(city!='' && city!=null)
        {   
            isFilterExist =true;         
            LocationQry+= ' and location__r.city__c like \'%' + string.valueof(city) +'%\'  '; 
        }     
        
        if(zipcode!='' && zipcode!=null)
        {            
            isFilterExist =true;
            LocationQry+= ' and location__r.postalcode__r.name like \'%' + string.valueof(zipcode) +'%\'  '; 
        }
        if(showScheduledOnly == 'yes'){
            isFilterExist =true;
            LocationQry+= ' and LocationScheduledDate__c != NULL  '; 
        }
        system.debug('__#### Status __'+Status+'-----'+Status.indexOf('NONE'));  
        //if(Status!='' && Status!=null)
        if(Status.indexOf('NONE') == -1)
        {            
            isFilterExist =true;
            if(Status=='Reserve'){
                LocationQry+= ' and  location__c in ( select location__c from job__c where project__c =  \'' + ProjectID +'\' )' ; 
            }
            else{
                LocationQry+= ' and  location__c not in ( select location__c from job__c where project__c =  \'' + ProjectID +'\' )' ; 
            }
        }        
        
        LocationQry+= '  order by status__c desc,name ';
        
        system.debug('__#### loc qry __'+LocationQry+'-----');  
        
        return Database.query(LocationQry);
        
    }
    
    @RemoteAction
    global static string Cancel(string allLocID,string projectID,string operation,string reason)
    {
        string msg = '';
        
        set<string> AllUniqIDSet = new set<string>();
        Id[] allIds = new Id[]{};
        for(string item : allLocID.split(','))
        {
            AllUniqIDSet.add(item);           
            allIds.add(item);
        }
        
        project__c projObj = [select name, status__c, ProjectCancelLeadTime__c from project__c where id=:projectID];
        
        TriggerUtil.SkipAllTriggers(); 
        
        if(operation=='Delete'){
   
            Integer jobCount = [Select count() from Job__c WHERE ProjectLocation__c in :AllUniqIDSet LIMIT :JobActionsHelper.JOB_BATCH_DELETE_DECISION_COUNT];
            
            List<ActionResponse> responses = ProjectLocationActionsHelper.DeleteProjectLocations(allIds);
            
            
            if (jobCount == JobActionsHelper.JOB_BATCH_DELETE_DECISION_COUNT)
            {
                return  'Delete Project Location(s) in progress';
            }
            if(responses[0].IsSuccessful){
                return  AllUniqIDSet.size() +' Project Location(s) deleted from project';
            }
            return  'Error deleting Project Location(s)';
            
        }
        else { //cancel    
            Integer jobCount = [Select count() from Job__c WHERE ProjectLocation__c in :AllUniqIDSet AND ProjectLocation__r.Status__c != :CONSTANTS.PROJECT_LOCATION_CANCELED LIMIT :JobActionsHelper.JOB_BATCH_CANCEL_DECISION_COUNT];
            List<ActionResponse> responses = ProjectLocationActionsHelper.CancelProjectLocation(allIds, reason, 'Cancel at Project Location(s) level');
            if (jobCount == JobActionsHelper.JOB_BATCH_CANCEL_DECISION_COUNT)
            {
                return  'Cancel Project Location(s) in progress';
            }
            if(responses[0].IsSuccessful){
                return  AllUniqIDSet.size() +' Project Location(s) canceled from project';
            }
            return  'Error canceling Project Location(s)';
        }
        
    } 
    
    @RemoteAction
    global static string setScheduleDate(string ids, string projectID, string scheduleDateString)
    {
        string msg = '';
        Date scheduleDate = Date.parse(scheduleDateString);
        
        Id[] allIds = new Id[]{};
        for(string item : ids.split(','))
        {
            allIds .add(item);
        }
        system.debug('allIds::::: '+allIds);
        Integer jobCount = [Select count() from Job__c WHERE ProjectLocation__c in :allIds AND ProjectLocation__r.Status__c != :CONSTANTS.PROJECT_LOCATION_CANCELED LIMIT :JobActionsHelper.JOB_BATCH_SCHEDULEDATE_DECISION_COUNT];
        if(jobCount == 0){
            return  'Error, no jobs found.';
        }
        List<ActionResponse> responses = ProjectLocationActionsHelper.setScheduleDates(allIds, scheduleDate);
        
        if (jobCount == JobActionsHelper.JOB_BATCH_SCHEDULEDATE_DECISION_COUNT)
        {
            return  'Schedule dates in progress';
        }
        if(responses[0].IsSuccessful){
            return  'Scheduled ' + jobCount + ' job(s)';
        }
        return  'Error processing your request. ' + responses[0].ResponseMessage;        
    }   
}