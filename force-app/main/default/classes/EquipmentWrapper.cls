public class EquipmentWrapper {
    
   	@AuraEnabled
    public Id Id{get;set;}
    
    @AuraEnabled
  	public String Name{get;set;}
        
    @AuraEnabled
    public String ToolIconClass{get;set;}
    
    @AuraEnabled
    public String Description{get;set;}
    
    @AuraEnabled
    public Boolean IsActive{get;set;}
    
}