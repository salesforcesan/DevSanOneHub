/*******************************************************************************************************************
** Module Name   : LightningProjectAuditHistoryController
** Description   : This class is used to receive the Project Id as parameter and set the "Timeline Title" & "TimelineEntry Array".
**                 It is called from ProjectAuditHistory Component.
** 
** Organization  : Crossmark
**
** Revision History:-
** Version             Date            Author                             Description of Action
** 1.0                 12/12/16       GAURAV BHATIA(Algoworks)
** 1.1                 12/14/16       PRAFULL KUMAR(Algoworks)
******************************************************************************************************************/
public with sharing class LightningProjectAuditHistoryController {
    
    // Define Constant literals
    private static final String CLOSE_DATE_PREFIX = 'Close Date on';
    private static final String END_DATE_PREFIX = 'End Date on';
    private static final String LAUNCH_DATE_PREFIX = 'Launched on';
    private static final String START_DATE_PREFIX = 'Start Date on';
    private static final String APPROVE_DATE_PREFIX = 'Approved on';
    private static final String CREATE_DATE_PREFIX = 'Created on';
    private static final String DATE_TIME_FORMAT = 'MMM d, yyyy';
    private static final String DATE_TIME_FORMAT_DD = 'MMM dd, yyyy';
    private static final String SYSTEM_DATE_TIME_FORMAT = 'MMMM dd, yyyy';
    private static final String ENTRY_TITLE_BY_USER = 'by';
    private static final Boolean TRUE_VALUE = true;
    private static final Boolean FALSE_VALUE = false;
    private static final Integer EVENTINDEX = 6;
    private static final String SPACE = ' ';
    
    // Define icons URL
    private static final String CLOSE_DATE_ICON = '/assets/icons/custom-sprite/svg/symbols.svg#custom42';
    private static final String END_DATE_ICON = '/assets/icons/standard-sprite/svg/symbols.svg#campaign';
    private static final String LAUNCH_DATE_ICON = '/assets/icons/custom-sprite/svg/symbols.svg#custom20';
    private static final String START_DATE_ICON = '/assets/icons/standard-sprite/svg/symbols.svg#coaching';
    private static final String UNKNOWN_USER_ICON = '/assets/icons/standard-sprite/svg/symbols.svg#user';
    
    
    
    /** 
    * Return TimelineWrapper Object based on the parameter projectId. 
    */
    @AuraEnabled
    public static TimelineWrapper GetTimelineObject(String projectId) { 
        TimelineWrapper timelineWrapper = new TimelineWrapper();
        List<ActivityDate> listOfEventDate = new List<ActivityDate>();
        List<TimelineEntryWrapper> timelineEntryList = new List<TimelineEntryWrapper>();
        List<Project__c> projectList = [SELECT Id, Name, ProjectCloseDate__c, EndDate__c, ProjectLaunchDate__c, StartDate__c, ApprovalDate__c, Approver__r.Name, Approver__r.FullPhotoUrl, CreatedDate, CreatedBy.Name, CreatedBy.FullPhotoUrl FROM Project__c where id =: projectId limit 1];
        timelineWrapper.Title = System.now().format(SYSTEM_DATE_TIME_FORMAT);
        if(projectList.size() > 0){
            for(Project__c projectObj : projectList){
                Integer eventIndexInt = EVENTINDEX;
                if(projectObj.ProjectCloseDate__c != null){
                    createTimelineEntry(listOfEventDate, projectObj.ProjectCloseDate__c, CLOSE_DATE_PREFIX, null, TRUE_VALUE, CLOSE_DATE_ICON, eventIndexInt);
                }
                
                if(projectObj.EndDate__c != null){
                    eventIndexInt = eventIndexInt - 1;
                    createTimelineEntry(listOfEventDate, projectObj.EndDate__c, END_DATE_PREFIX, null, TRUE_VALUE, END_DATE_ICON, eventIndexInt);
                }
                
                if(projectObj.ProjectLaunchDate__c != null){
                    eventIndexInt = eventIndexInt - 1;
                    createTimelineEntry(listOfEventDate, projectObj.ProjectLaunchDate__c, LAUNCH_DATE_PREFIX, null, TRUE_VALUE, LAUNCH_DATE_ICON, eventIndexInt);
                }
                
                if(projectObj.StartDate__c != null){
                    eventIndexInt = eventIndexInt - 1;
                    createTimelineEntry(listOfEventDate, projectObj.StartDate__c, START_DATE_PREFIX, null, TRUE_VALUE, START_DATE_ICON, eventIndexInt);
                }
                
                if(projectObj.ApprovalDate__c != null){
                    eventIndexInt = eventIndexInt - 1;
                    Date approvalDate= projectObj.ApprovalDate__c.Date(); // DateTime to date conversion for approval date 
                    createTimelineEntry(listOfEventDate, approvalDate, APPROVE_DATE_PREFIX, projectObj.Approver__r, FALSE_VALUE, UNKNOWN_USER_ICON, eventIndexInt);
                }
                
                if(projectObj.CreatedDate != null){
                    eventIndexInt = eventIndexInt - 1;
                    Date createdDate= projectObj.CreatedDate.Date();  // DateTime to date conversion for created date 
                    createTimelineEntry(listOfEventDate, createdDate, CREATE_DATE_PREFIX, projectObj.CreatedBy, FALSE_VALUE, UNKNOWN_USER_ICON, eventIndexInt);
                }
                
                listOfEventDate.sort();
                for (Integer i = (listOfEventDate.size() - 1); i >= 0; i--){
                    timelineEntryList.add(((ActivityDate)listOfEventDate.get(i)).getTimelineEntry());
                }
                
                timelineWrapper.TimelineEntryWrapperList = timelineEntryList;
                system.debug('##########timelineWrapper.TimelineEntryWrapperList: '+timelineWrapper.TimelineEntryWrapperList);
            }
        }
         
        return timelineWrapper;
    }
    
    /**
    * Creates a new TimelineEntry object based on the parameters passed, and adds to the list.
    */
    private static void createTimelineEntry(List<ActivityDate> listOfEventDate, Date dateTimeObj, String timelineEntryTitlePrefix, User userObj, Boolean isEventIcon, String eventIconName, Integer eventIndexInt) {
        Boolean isTitleSet = false;
        TimelineEntryWrapper timelineEntry = new TimelineEntryWrapper();
        String dateTimeStr =  DateTime.newInstance(dateTimeObj.year(),dateTimeObj.month(),dateTimeObj.day()).format(DATE_TIME_FORMAT_DD); // Conversion datetime to required format 
        String dateTimeStrWithDDFormat =  DateTime.newInstance(dateTimeObj.year(),dateTimeObj.month(),dateTimeObj.day()).format(DATE_TIME_FORMAT_DD)+eventIndexInt; // Adding the event index to set the right sorting order  
        timelineEntry.TimelineEntryDate = dateTimeStr;
        
        // Checking the user object which is valid for create event and may exist for approver event as well
        if(userObj != null)
        {
            String userObjName =  userObj.Name;
            timelineEntry.PhotoURL = userObj.FullPhotoUrl;
            timelineEntry.IsEventIcon = FALSE_VALUE;
            
            // Checking the user object name which may come as blank for approver event 
            if(userObjName != ''){ 
                timelineEntry.TimelineEntryTitle = timelineEntryTitlePrefix + SPACE + dateTimeStr + SPACE + ENTRY_TITLE_BY_USER + SPACE + userObjName;
                isTitleSet = true;
            }
        }
        
        // Default SLDS icons are used if user object is not found
        else{
            timelineEntry.EventIconName = eventIconName;
            timelineEntry.IsEventIcon = TRUE_VALUE;
        }
        
        // This is for all those events where the event action is happening without having associated user information
        if(!isTitleSet) {
            timelineEntry.TimelineEntryTitle = timelineEntryTitlePrefix + SPACE + dateTimeStr;
        }
        
        ActivityDate activityDate = new ActivityDate(dateTimeObj, eventIndexInt, timelineEntry);
        listOfEventDate.add(activityDate);
    }
    
    /**
    * A Comparable class to sort activity history based on date and event index.
    */
    private class ActivityDate implements Comparable {

        private Date eventDate;
        private Integer eventIndexInt;
        private TimelineEntryWrapper timelineEntry;
        
        // Constructor
        public ActivityDate(Date d, Integer index, TimelineEntryWrapper te) {
            eventDate = d;
            eventIndexInt = index;
            timelineEntry = te;
        }
        
        /**
        * Get TimelineEntry Object
        */
        public TimelineEntryWrapper getTimelineEntry() {
            return this.timelineEntry;
        }
        
        // Implement the compareTo() method
        public Integer compareTo(Object compareTo) {
            ActivityDate compareToActivity = (ActivityDate)compareTo;
            if (eventDate > compareToActivity.eventDate) return 1;
            if (eventDate < compareToActivity.eventDate) return -1;
            if (eventDate == compareToActivity.eventDate) {
                if (eventIndexInt > compareToActivity.eventIndexInt) return 1;
                if (eventIndexInt < compareToActivity.eventIndexInt) return -1;
                return 0;
            }
            return 0;        
        }
    }
}