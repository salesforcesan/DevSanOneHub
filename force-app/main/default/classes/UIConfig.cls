public class UIConfig {
    
    public final static Map<String, Boolean> HiddenElements {get;set;}
    static 
    {
    	HiddenElements = getHiddenUIElements();
    }    
    
    public static Map<String, boolean> getHiddenUIElements()
    {
        Map<String, boolean> results = new Map<String, boolean>();
        List<UIConfig__c> uic = [SELECT Id, Status__c, UIElement__c,Access__c  FROM UIConfig__c WHERE Access__c = 'Hidden'];
        for(UIConfig__c c:uic){
            if (String.isNotBlank(c.UIElement__c))
            {
                results.put(c.UIElement__c,true);
            }
        }
        return results;
    }        
    
    public static boolean isEditale(String status, String elementName){
        List<UIConfig__c> uic = [SELECT Id, UI_Element__c,Access__c FROM UIConfig__c WHERE UI_Element__c = :elementName AND Status__c =:status];
        if(status == 'Create' || (uic.size() > 0 && uic[0].Access__c == 'Editable')){
            return true;
        }
        return false;
    }
    
    public static Map<String, boolean> getHiddenElements(String status){
        Map<String, boolean> results = new Map<String, boolean>();
        List<UIConfig__c> uic = [SELECT Id, UI_Element__c,Access__c  FROM UIConfig__c WHERE Access__c = 'Hidden' 
                        AND Status__c =:status];
        for(UIConfig__c c:uic){
            if (String.isNotBlank(c.UI_Element__c))
            {
                results.put(c.UI_Element__c,true);
            }
        }
        return results;
    }    

    public static Boolean checkFieldHidden(String status, String uiElementName){
        string concatElement = uiElementName + '-' + status;
        return HiddenElements.get(concatElement) != null? True : False;
    }
    
    public static Map<String, boolean> getHiddenElements(){
        Map<String, boolean> results = new Map<String, boolean>();
        List<UIConfig__c> uic = [SELECT Id, Status__c, UI_Element__c,Access__c  FROM UIConfig__c WHERE Access__c = 'Hidden'];
        for(UIConfig__c c:uic){
            if (String.isNotBlank(c.UI_Element__c))
            {
                results.put(c.UI_Element__c,true);
            }
        }
        return results;
    }    


    public static Map<String, boolean> getEditableElements(String status){
        List<UIConfig__c> uic = [SELECT Id, UI_Element__c,Access__c  FROM UIConfig__c WHERE Access__c = 'Editable' 
                                 AND Status__c =:status];
        Map<String, boolean> results = new Map<String, boolean>();

        for(UIConfig__c c:uic){
            if (String.isNotBlank(c.UI_Element__c))
            {
                results.put(c.UI_Element__c,true);
            }
        }
        return results;
        
    }


    public static Map<String, boolean> isEditale(String status, Set<String> elementNames){
        List<UIConfig__c> uic = [SELECT Id, UI_Element__c,Access__c  FROM UIConfig__c WHERE UI_Element__c = :elementNames AND Status__c =:status];
        Map<String, boolean> results = new Map<String, boolean>();
        Boolean result = (status == 'Create') ? true : false;
        for(String ename :elementNames){
            results.put(ename,result);
        }
        if(status == 'Create'){
            return results;       
        }
        system.debug('status::::'+status);
        for(UIConfig__c c:uic){
            if(status == 'Create' || (c.Access__c == 'Editable' && results.containsKey(c.UI_Element__c))){
                results.put(c.UI_Element__c,true);
            }
        }
        return results;
    }
    
    public static Map<String, boolean> isHidden(String status, Set<String> elementNames){
        Map<String, boolean> results = new Map<String, boolean>();
        for(String ename :elementNames){
            results.put(ename,false);
        }
        List<UIConfig__c> uic = [SELECT Id, UI_Element__c,Access__c  FROM UIConfig__c WHERE UI_Element__c = :elementNames AND Access__c = 'Hidden' AND Status__c =:status];
        for(UIConfig__c c:uic){
            if(results.containsKey(c.UI_Element__c)){
                results.put(c.UI_Element__c,true);
            }
        }
        return results;
    }
    
    
    public static Map<String, boolean> getProjectEditableFields(String status){
        List<UIConfig__c> uic = [SELECT Id, UI_Element__c,Access__c  FROM UIConfig__c WHERE Status__c =:status AND Access__c = 'Editable' AND UI_Element__c LIKE 'Project__c.%'];
        Map<String, boolean> results = new Map<String, boolean>();
        for(UIConfig__c c:uic){
            results.put(c.UI_Element__c,true);
        }
        if(results.size() == 0){
            return null;    
        }
        return results;
    }
    
    public static boolean isVisible(String status, String elementName){
        List<UIConfig__c> uic = [SELECT Id, UI_Element__c,Access__c FROM UIConfig__c WHERE UI_Element__c = :elementName];
        if(uic.size()>0 && uic[0].Access__c == 'Hidden'){
            return false;
        }
        return true;
    }
    
    public static Map<String, boolean> isVisible(String status, Set<String> elementNames){
        List<UIConfig__c> uic = [SELECT Id, UI_Element__c,Access__c FROM UIConfig__c WHERE UI_Element__c = :elementNames];
        Map<String, boolean> results = new Map<String, boolean>();
        for(String ename :elementNames){
            results.put(ename, true);
        }
        for(UIConfig__c c:uic){
            if(c.Access__c == 'Hidden' && results.containsKey(c.UI_Element__c)){
                results.put(c.UI_Element__c, false);
            }
        }
        return results;
    }

}