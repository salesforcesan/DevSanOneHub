public with sharing class LightningProjectEquipmentController {
    
    @AuraEnabled
    public static List<EquipmentWrapper> GetProjectServiceTools(String projectServiceId) {                
        List<EquipmentWrapper> ewList = new List<EquipmentWrapper>();
        for(Equipment__c e: [SELECT Name, Id, ToolIconClass__c, Description__c, isActive__c FROM Equipment__c WHERE EquipmentType__c = 'Tool' and isActive__c = true Order By Description__c]){
            EquipmentWrapper ew = new EquipmentWrapper();
            ew.Id = e.Id;
            ew.Name = e.Name;
            ew.ToolIconClass = e.ToolIconClass__c;
            ew.Description = e.Description__c;
            ew.IsActive = false;//e.isActive__c;  
            ewList.add(ew);
        }
        
        List<ProjectServiceEquipment__c> ps = [SELECT Equipment__c FROM ProjectServiceEquipment__c WHERE Equipment__r.EquipmentType__c = 'Tool' and ProjectService__c = :projectServiceId];
        
        /*if(ps.size()==0){
            for(EquipmentWrapper ew:ewList)
            {
                ew.IsActive=false;
            }
        }
        else{*/
            for(ProjectServiceEquipment__c p: ps) 
            {
                for(EquipmentWrapper ew:ewList)
                {
                    if(p.Equipment__c == ew.Id)
                    {
                        ew.IsActive=true;
                    }
                }
            }         
        //}
        

        
        
        return ewList;
    }
    
    
    @AuraEnabled
    public static void SetProjectServiceTool(String projectServiceId, String equipmentId, boolean checked) {
        
        try
        {
            
            List<ProjectServiceEquipment__c> equipment = [Select Id from ProjectServiceEquipment__c Where ProjectService__c =: projectServiceId and Equipment__c =: equipmentId ];
            if(checked)
            {
                if(equipment.isEmpty())
                {
                    system.debug('~~b4 insert~~~~~~');
                    ProjectServiceEquipment__c newEquipment = new ProjectServiceEquipment__c (ProjectService__c= projectServiceId, Equipment__c = equipmentId) ;   
                    insert newEquipment;
                    system.debug('~~after insert~~~~~~'+newEquipment.id);
                }            
            }
            else
            {
                if(!equipment.isEmpty())
                {
                    delete equipment;
                } 
            }
        }
        catch(Exception e)
        {
             throw new System.AuraHandledException(e.getMessage());   
        }
    }
}