public without sharing class StateDropDownController {
   @AuraEnabled
  public static list<LocationStates__mdt> locationStateSetting(string recordId) 
  {
        return [Select DeveloperName,MasterLabel from LocationStates__mdt order by MasterLabel asc ];
  }



}