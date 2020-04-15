public class AttributeDefinedResponseWrapper {
    @AuraEnabled
    public id responseID {get; set;}   
    @AuraEnabled
    public String responseValue {get; set;}       
    @AuraEnabled
    public boolean isActive{get; set;}   
    
    public AttributeDefinedResponseWrapper(){}
    
    public AttributeDefinedResponseWrapper(Id objID, String objVal, Boolean objAct){
        responseID=objID;
        responseValue =objVal;
        isActive= objAct;
    }
    
    public AttributeDefinedResponseWrapper(AttributeDefinedResponse__c obj){               
       responseID =  obj.id;
       responseValue = htmlDecode(string.valueOf(obj.DefinedResponse__c));
       isActive =  obj.IsActive__c;
    }
     public static String htmlDecode (String s) {  

    Map<String, String> htmlDecodingMap = new Map<String, String>();
    htmlDecodingMap.put('&lt;', '<');
    htmlDecodingMap.put('&gt;', '>');
    htmlDecodingMap.put('&amp;quot;', '"');
    htmlDecodingMap.put('&amp;', '&');
    htmlDecodingMap.put('&#39;', '\'');
    
   for (String token : htmlDecodingMap.keySet()) {
        s = s.replace(token, htmlDecodingMap.get(token));
    }
    return s;
}
}