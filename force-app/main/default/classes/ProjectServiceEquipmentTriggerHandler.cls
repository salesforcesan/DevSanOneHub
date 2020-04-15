public class ProjectServiceEquipmentTriggerHandler extends TriggerHandler {
    
    
    public override void beforeUpdate() {

        if(TriggerUtil.skipLocationEquipmentTrigger == true){
            return;
        }
        
        list<AppSettings__mdt> lstappsettings = new list<AppSettings__mdt>();
        string eqAsset = '';
        lstappsettings = [SELECT Value__c FROM AppSettings__mdt WHERE DeveloperName = 'EquimentTypeAsset' limit 1];
        if(lstappsettings.size()>0){
            eqAsset = lstappsettings[0].Value__c;
        }
        
        set<Id> projectequipmentIds = new set<Id> ();
        projectequipmentIds = trigger.newmap.keyset();
        set<Id> serviceIds = new set<Id>();
        set<Id> retailerIds = new set<Id> ();
        //map<String,ProjectServiceEquipment__c> mapServiceRetailer = new map<String,ProjectServiceEquipment__c>();
        
        for(ProjectServiceEquipment__c pse : [Select ProjectService__r.Project__r.Retailer__c,ProjectService__r.Service__c from ProjectServiceEquipment__c where Id IN :projectequipmentIds]){
            serviceIds.add(pse.ProjectService__r.Service__c);
            retailerIds.add(pse.ProjectService__r.Project__r.Retailer__c);
           // mapServiceRetailer.put(pse.ProjectService__r.Project__r.Retailer__c+'-'+pse.ProjectService__r.Service__c,pse);
        }
        Map<ID,Decimal> lockedEquipmentMap = new Map<ID,Decimal>();
        for(RetailerServiceEquipment__c lockedEq : [SELECT Equipment__c, Quantity__c FROM RetailerServiceEquipment__c 
                                                            WHERE Equipment__r.EquipmentType__c=:eqAsset 
                                                            AND Retailer__c IN : retailerIds 
                                                            AND Service__c IN :serviceIds 
                                                            AND IsLocked__c = true]){
            lockedEquipmentMap.put(lockedEq.Equipment__c, lockedEq.Quantity__c);
        }
        for(projectServiceEquipment__c pse : (list<projectServiceEquipment__c>) trigger.new){
             if(lockedEquipmentMap.containsKey(pse.Equipment__c) && pse.Quantity__c < lockedEquipmentMap.get(pse.Equipment__c)){
                pse.addError('Locked equipment quantity cannot be reduced.'); 
                return;
            }  
        }
    }
    
    public override void afterUpdate() {
        // COMMENTING THE WHOLE TRIGGER AS IT NO MORE HAS VALID LOGIC 

        /*if(TriggerUtil.skipLocationEquipmentTrigger == true){
            return;
        }
        List<ProjectServiceEquipment__c> pseList = (List < ProjectServiceEquipment__c > ) Trigger.new;
        List<ProjectService__c> psList = [SELECT Id, Project__c FROM ProjectService__c WHERE ID = :pseList[0].ProjectService__c LIMIT 1];
        Project__c project = [SELECT Id FROM Project__c WHERE ID = :psList[0].Project__c LIMIT 1];
        system.debug('psList####'+psList);
        system.debug('project+++++'+project);
        system.debug('pseList####'+pseList);
        
        string eqAsset = [SELECT Value__c FROM AppSettings__mdt WHERE DeveloperName = 'EquimentTypeAsset' limit 1].Value__c;
        
        for (ProjectServiceEquipment__c pse: pseList) {
            
            Equipment__c eq = [SELECT Id, Name, EquipmentType__c FROM Equipment__c WHERE ID = :pse.Equipment__c];
            /*
            if(pse.IsCapacityImpact__c != ((ProjectServiceEquipment__c)Trigger.oldMap.get(pse.Id)).IsCapacityImpact__c){
                FeedItem post = new FeedItem();
                post.ParentId = project.Id;
                if(pse.IsCapacityImpact__c){
                    post.Body = userinfo.getname() + ' checked '+ eq.Name +' impact capcity flag';
                } 
                else {
                    post.Body = userinfo.getname() + '  removed '+ eq.Name +' impact capcity flag';
                }
                insert post;
               
            }
            if(pse.IsCapacityImpact__c == false){
                continue;
            }
            */
        //}  
    }
}