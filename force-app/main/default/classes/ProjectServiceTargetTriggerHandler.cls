public class ProjectServiceTargetTriggerHandler extends TriggerHandler {

    public override void afterInsert() {
        if(TriggerUtil.skipProjectServiceTargetTrigger){
            return;
        } 
        TriggerUtil.skipProjectServiceTargetTrigger = true;
        String psId = ((List <ProjectServiceTarget__c> ) Trigger.new)[0].projectservice__c;
        
        Set<Id> primaryHaloPSIds = new Set<Id>();
        for (ProjectServiceTarget__c psc: (List <ProjectServiceTarget__c> ) Trigger.new) {
            if(psc.Type__c == 'primary' || psc.Type__c == 'supplemental'){
                primaryHaloPSIds.add(psc.ProjectService__c);
            }
        }

        if(primaryHaloPSIds.size()>0)
            AppUtil.updateProjectService(primaryHaloPSIds);
        
    }
    
    public override void afterUpdate() {
        if(TriggerUtil.skipProjectServiceTargetTrigger) {
            return;
        }
        TriggerUtil.skipProjectServiceTargetTrigger = true;
        
        
        Set<Id> primaryHaloPSIds = new Set<Id>();
        string psID;
        for (ProjectServiceTarget__c psc: (List <ProjectServiceTarget__c> ) Trigger.new) {
            psID = psc.projectservice__c;
            if(psc.Type__c == 'primary' || psc.Type__c == 'supplemental'){
                primaryHaloPSIds.add(psc.ProjectService__c);
            }
        }
        
        if(primaryHaloPSIds.size()>0){
            AppUtil.updateProjectService(primaryHaloPSIds);
        }
    }

    public override void afterDelete() {
         if(TriggerUtil.skipProjectServiceTargetTrigger){
            return;
        } 
        TriggerUtil.skipProjectServiceTargetTrigger = true;
        
        String psId = ((List <ProjectServiceTarget__c> ) Trigger.old)[0].projectservice__c;
        
        Set<Id> primaryHaloPSIds = new Set<Id>();
        for (ProjectServiceTarget__c psc: (List <ProjectServiceTarget__c> ) Trigger.old) {
            if(psc.Type__c == 'primary' || psc.Type__c == 'supplemental'){
                primaryHaloPSIds.add(psc.ProjectService__c);
            }
        }
        if(primaryHaloPSIds.size()>0)
            AppUtil.updateProjectService(primaryHaloPSIds);
        
    }
}