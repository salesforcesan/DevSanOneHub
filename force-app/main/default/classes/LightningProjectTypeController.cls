public with sharing class LightningProjectTypeController {
	@AuraEnabled
    public static list<ProjectType__c> getProjectTypes(){
        return [select Id, Name,ProjectTypeDescription__c from ProjectType__c];
    }
}