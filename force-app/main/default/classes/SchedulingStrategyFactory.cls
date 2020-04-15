public with sharing class SchedulingStrategyFactory {
    public static SchedulingStrategy getSchedulingStrategy(String projectTypeName){
        String schedulingStrategy = 'BaseSchedulingStrategy';
        ProjectTypeCustomSettings__c cs = ProjectTypeCustomSettings__c.getValues(projectTypeName);
        if(cs != null && cs.SchedulingStrategyClass__c!=null){
            schedulingStrategy = cs.SchedulingStrategyClass__c;
        }
        return (SchedulingStrategy)Type.forName(schedulingStrategy).newInstance();
    }
}