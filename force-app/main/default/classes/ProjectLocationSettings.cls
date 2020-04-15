public without sharing class ProjectLocationSettings extends LightningRequestBase {
    public static final Map<Id, Integer> ADDLOCATION_LEADTIMES;
    public static final Map<Id, Boolean> ADDLOCATION_HASRESERVATIONS;
    public static final Integer SEARCHLOCATIONFIELD_BY_ONEHUBLOCATIONID;
    public static final Map<Id, String> PROJECT_RECORD_TYPES;
    
    static {
        ADDLOCATION_LEADTIMES = new Map<Id, Integer>();
        ADDLOCATION_HASRESERVATIONS = new Map<Id, boolean>();
        for(ProjectType__c pt: [SELECT Id, AddLocationsLeadTime__c, UseReservations__c FROM ProjectType__c]){
            ADDLOCATION_LEADTIMES.put(pt.Id, Integer.valueOf(pt.AddLocationsLeadTime__c));
            ADDLOCATION_HASRESERVATIONS.put(pt.Id, Boolean.valueOf(pt.UseReservations__c));
        }
        SEARCHLOCATIONFIELD_BY_ONEHUBLOCATIONID = checkSearchByOneHubId() ? 1: 0;
        PROJECT_RECORD_TYPES = initProjectRecordTypes();
    }
    
    static Map<Id, String> initProjectRecordTypes(){
        string namespace = CONSTANTS.CURRENTNAMESPACE;
        string sObjectName = CONSTANTS.CURRENTNAMESPACE.indexOf('CMK') != -1 ? 'CMKOneHub__Project__c': 'Project__c';
        Map<Id, String> objMap = new Map<Id, String>();
        for(RecordType tp: [SELECT Id, Name FROM RecordType WHERE SobjectType=:sObjectName]){
            objMap.put(tp.Id, tp.Name);      
        }
        return objMap;
    }
    
    static Boolean checkSearchByOneHubId(){
        String field = AppUtil.LocationSearchField;
        return (field != null && field.equalsIgnoreCase('OneHubLocationId__c'));
    }
    
    public static Boolean IsSearchLocationByOneHubId(){
        return SEARCHLOCATIONFIELD_BY_ONEHUBLOCATIONID == 1;
    }
    
    public override Object get(Object parameters) {
        Map<String,object> query = (Map<String,Object>) parameters;
        String projectId = LightningRequestHelper.parseString(query.get('projectId'));
        if (String.isBlank(projectId)){
            throw new AuraHandledException('The Project Id is required when retrieving the project location application settings.');
        }
        Map<String,Object> response = new Map<String,Object>();
        response.put('project', getProject(projectId));
        response.put('cancelReasons', getJobCancelReasons());
        return response;
    }
    
    Map<String,Object> getProject(String projectId){
        Map<String,Object> result = new Map<String,Object>();
        List<Project__c> pList = [SELECT Id, ProjectNumber__c, RecordTypeId, Status__c, StartDate__c, EndDate__c, 
                                  ProjectType__c, NumberOfDays__c, ProjectType__r.SetScheduleDateLeadTime__c, 
                                  ProjectScheduleOption__r.Code__c, ApexJobName__c, RetailerAccount__c 
                                  FROM Project__c Where Id=:projectId];
        if(pList.size() == 0){
            throw new AuraHandledException('The project can not be found.');
        }
        Project__c p = pList.get(0);
        result.put('locationReportUrl', AppUtil.LocationReportUrl.replace('{ProjectNumber}',p.ProjectNumber__c));
        result.put('startDate', p.StartDate__c);
        result.put('endDate', getEndDate(p));
        result.put('hasAccount', String.isNotBlank(p.RetailerAccount__c) ? 1 : 0);
        result.put('NumberOfDays', p.NumberOfDays__c != null ? p.NumberOfDays__c: 0);
        result.put('status', p.Status__c);
        result.put('locked', isProjectLocked(p.RecordTypeId) ? 1: 0);
        result.put('batchJob', String.isBlank(String.valueOf(p.ApexJobName__c)) ? 0: 1);
        result.put('canAddLocation', canAddLocation(p.EndDate__c, p.ProjectType__c));
        result.put('searchByOneHubId', SEARCHLOCATIONFIELD_BY_ONEHUBLOCATIONID);
        addScheduleSetting(p, result);
        return result;
    }
    
    static Boolean isProjectLocked(Id recordTypeId){
        if (!PROJECT_RECORD_TYPES.containsKey(recordTypeId)){
            return false;
        }
        String name = String.valueOf(PROJECT_RECORD_TYPES.get(recordTypeId));
        return name == 'Locked' ? true: false;
    }
    
    
    static Date getEndDate(Project__c proj){
        try{
            Integer maxServiceDaysNeeded = Integer.valueOf(proj.NumberOfDays__c) == null ? 1 : Integer.valueOf(proj.NumberOfDays__c);
            return proj.EndDate__c.addDays(1-maxServiceDaysNeeded);
        }catch(Exception ex){
        }
        return proj.EndDate__c;
    }
    
    static void addScheduleSetting(Project__c p, Map<String,Object> result){
        try{
            if (p.ProjectScheduleOption__r.Code__c == CONSTANTS.SCHEDULE_OPTION_USER){
                result.put('showSchedule', 1);
                result.put('canSchedule',canSchedule(p) ? 1: 0);
                return;
            }
        } catch(Exception ex){
            system.debug(ex.getLineNumber() + ':' + ex.getMessage());
        }
        
        result.put('showSchedule', 0);
        result.put('canSchedule', 0);
    }
    
    static Boolean canSchedule(Project__c proj){
        try{
            
            if( proj.ProjectType__r.SetScheduleDateLeadTime__c != NULL && 
               (Integer.valueOf(proj.ProjectType__r.SetScheduleDateLeadTime__c) <= -1 || 
                (proj.StartDate__c.addDays(Integer.valueOf(-proj.ProjectType__r.SetScheduleDateLeadTime__c))) >= date.today())) 
            {
                return true;
            }
        }catch(Exception ex){
            system.debug(ex.getLineNumber() + ':' + ex.getMessage());
        }
        return false;
    }
    
    static Integer canAddLocation(Date endDate, Id projectType){
        
        boolean hasReservation = Boolean.valueOf(ADDLOCATION_HASRESERVATIONS.get(projectType));
        if (hasReservation ){
            return 0;
        }
        
        if(endDate == null) {
            return 1;
        }
        
        Date dateEnd = Date.valueOf(endDate);
        Date today = Date.today();
        
        if (projectType == null || ADDLOCATION_LEADTIMES.get(projectType) == null){
            return dateEnd > today ? 1: 0;
        }
        
        Integer i = Integer.valueOf(ADDLOCATION_LEADTIMES.get(projectType));
        Date leadStartDate = dateEnd.addDays(-i);
        return leadStartDate > today ? 1: 0;
    }
    
    List<Map<String,String>> getJobCancelReasons(){
        return LightningRequestHelper.getPicklist('Job__c', 'JobCanceledReason__c');
    }
}