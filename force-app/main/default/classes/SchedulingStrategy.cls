global abstract class SchedulingStrategy {
    
    global virtual List<ProjectLocation__c> getProjectLocations(ID projectID){
         return [SELECT Id, Status__c FROM ProjectLocation__c WHERE Project__c = :projectID];
    }
    
    global virtual List<ProjectService__c> getProjectServices(ID projectID){
         return [Select Id, Service__c,  Service__r.Name, Project__c,  ResponsibleForExecution__c, NumberOfWorkers__c From ProjectService__c WHERE Project__c = :projectID AND Status__c != 'Canceled'];
    }

    
    //returns null if ResponsibleForExecution is not 'Execution Company', returns an set instance otherwsie
    global virtual Set<String> getLocationAssignments(Project__c project, Set<Id> scopeLocationIds){
        Integer  ecCount = [SELECT COUNT() FROM ProjectService__c where Project__c =: project.ID AND ResponsibleForExecution__c = 'Execution Company'];
        Set<String> locAssignmentSet =  null;
        if(ecCount > 0){
            locAssignmentSet = new Set<String>();
            List<LocationAssignment__c> laList = [SELECT Location__c FROM LocationAssignment__c WHERE ProjectType__c =: project.ProjectType__c AND AccountableExecutionCompany__c != NULL AND Location__c IN :scopeLocationIds];
            for(LocationAssignment__c la : laList){
                locAssignmentSet.add(la.Location__c);
            }
        }
        return locAssignmentSet;
    }
    
    global abstract Integer ScheduleLocations(List<ProjectLocation__c> scope, String projectID);
    
    //only virtual global methods (with implementations) can be added to previously managed virtual or abstract classes
    global virtual Integer ScheduleLocations(List<ProjectLocation__c> scope, String projectID, String operation){
        return 0;
    }
    
    //obsolte -- keep the signature for managed package
    global abstract String getSchedulableLocationsQuery(Project__c project);
    
    //only virtual global methods (with implementations) can be added to previously managed virtual or abstract classes
    global virtual String getSchedulableLocationsQuery(Project__c project, String operation){
        return '';
    }
    
    global abstract Boolean deallocateLocations(List<ProjectLocation__c> scope);
    
    global abstract Boolean isBatchJob(Project__c p, String exceedBudgeted);
    
    
}