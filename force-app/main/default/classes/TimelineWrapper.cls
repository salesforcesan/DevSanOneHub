/*******************************************************************************************************************
** Module Name   : TimelineWrapper
** Description   : This wrapper class is called from ProjectAuditHistoryController class. 
** 
** Organization  : Crossmark
**
** Revision History:-
** Version             Date            Author                             Description of Action
** 1.0                 12/12/16       PRAFULL KUMAR(Algoworks)
** 1.0                 12/12/16       GAURAV BHATIA(Algoworks)
******************************************************************************************************************/
public with sharing class TimelineWrapper {
  @AuraEnabled
  public String Title {get; set;}
      
  @AuraEnabled
  public List<TimeLineEntryWrapper> TimelineEntryWrapperList {get; set;}  
 
}