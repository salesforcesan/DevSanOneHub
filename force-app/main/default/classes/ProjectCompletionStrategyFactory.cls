public with sharing class ProjectCompletionStrategyFactory {
    public static ProjectCompletionStrategy getProjectCompletionStrategy(ID projectTypeID){
        String projectCompletionStrategy = 'BaseProjectCompletionStrategy';
        String projectTypeName = [Select Name From ProjectType__c WHERE ID = :projectTypeID].Name;
        ProjectTypeCustomSettings__c cs = ProjectTypeCustomSettings__c.getValues(projectTypeName);
        if(cs != null && cs.ProjectCompletionStrategyClass__c!=null){
            projectCompletionStrategy = cs.ProjectCompletionStrategyClass__c;
        }
        return (ProjectCompletionStrategy)Type.forName(projectCompletionStrategy).newInstance();
    }
}