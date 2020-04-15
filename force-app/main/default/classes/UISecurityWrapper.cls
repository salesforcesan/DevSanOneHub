public class UISecurityWrapper {
    
        @AuraEnabled
        public Map<String, Boolean> HiddenElements {get; set;}

        @AuraEnabled
        public Map<String, Boolean> EditableElements {get; set;}

        @AuraEnabled
        public Map<String, String> ProjectElements {get; set;}
        
        public UISecurityWrapper() {}        
        
        
        
    }