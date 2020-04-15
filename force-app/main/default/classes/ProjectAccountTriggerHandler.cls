public class ProjectAccountTriggerHandler extends TriggerHandler{
    
    public override void beforeDelete(){
          
        if (TriggerUtil.skipProjectAccountTrigger) return;
        
        Map<String,List<ProjectServiceQuestion__c >> psqMap = new Map<String,List<ProjectServiceQuestion__c>>();                
        Set<ID> projectIds = new Set<ID>();
        for (ProjectAccount__c pa :(List<ProjectAccount__c> ) Trigger.old) {
            projectIds.add(pa.Project__c);
        }

        for(ProjectServiceQuestion__c psq : [SELECT Id,Question__r.Account__c,ProjectService__r.Project__c from ProjectServiceQuestion__c 
                                             Where ProjectService__r.Project__c =: projectIds
                                             AND Question__r.Account__c != null]){
                                                 
                                                 string identifier = String.valueOf(psq.ProjectService__r.Project__c) + String.valueOf(psq.Question__r.Account__c);
                                                 
                                                 List<ProjectServiceQuestion__c> psqList = new List<ProjectServiceQuestion__c>();
                                                 psqList.add(psq);
                                                 
                                                 if (psqMap.get(identifier) != null) {
                                                     psqList.addall(psqMap.get(identifier));
                                                 }
                                                 psqMap.put(identifier,psqList);   
                                             }
        
        for (ProjectAccount__c pa :(List<ProjectAccount__c> ) Trigger.old) {
            
            system.debug('psqMap>>' + psqMap.size());
            
            string identifier = String.valueOf(pa.Project__c) + String.valueOf(pa.Account__c);
            if (psqMap != null && psqMap.size() > 0){
                if (psqMap.containsKey(identifier)){
                    
                    system.debug('error>>' +identifier);
                    string bodyText = 'This account has Survey Question(s) associated with it. Please remove or re-associate the Survey Question(s) before deleting the account.';
                    pa.addError(bodyText);
                }
            }
			//pa.addError('bodyText');
        }      

    }
    
    public override void afterInsert(){
        if (TriggerUtil.skipProjectAccountTrigger) return;
        Map<Id,Id> mapPA = new Map<Id,Id>();
        for (ProjectAccount__c pa :(List<ProjectAccount__c> ) Trigger.new) {
            if(pa.IsPrimary__c)
            {
                mapPA.put(pa.project__c,pa.Id);
                
            }
            
        }
        
        List<Project__c> lstProj = [select Id,name,PrimaryAccount__c from Project__c where Id IN :mapPA.keySet()];
        List<project__c>lstprojupdates =new List<project__c>();
        for(project__c p:lstProj)
        {
            Id pa = mapPA.get(p.Id);
            p.PrimaryAccount__c = pa;
            lstprojupdates.add(p);
        }
        if(lstprojupdates.size()>0) 
        {
            update lstprojupdates;
        }
        
        
    }
    
    public override void afterUpdate()
    {
       if (TriggerUtil.skipProjectAccountTrigger) return;
        Map<Id,Id> mapPA = new Map<Id,Id>();
         for (ProjectAccount__c pa :(List<ProjectAccount__c> )Trigger.new) {
            
            if(pa.IsPrimary__c)
            {
                mapPA.put(pa.project__c,pa.Id);
                
            }
            
        }
        
        List<Project__c> lstProj = [select Id, PrimaryAccount__c from Project__c where Id IN :mapPA.keySet()];
        List<project__c>lstprojupdates =new List<project__c>();
        for(project__c p:lstProj)
        {
            Id pa = mapPA.get(p.Id);
            if (p.PrimaryAccount__c != pa){
            	p.PrimaryAccount__c = pa;
            	lstprojupdates.add(p);    
            }
            
        }
        if(lstprojupdates.size()>0) 
        {
            update lstprojupdates;
        }
        
        
    }
   
    
}