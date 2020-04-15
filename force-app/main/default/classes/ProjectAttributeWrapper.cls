public class ProjectAttributeWrapper {
    @AuraEnabled
    public string RecordID{get; set;}     
    @AuraEnabled
    public id Project{get; set;}
    @AuraEnabled
    public id Attribute{get; set;}
    @AuraEnabled
    public string AttributeValue{get; set;}    
    @AuraEnabled
    public string AttributeType{get; set;}    
    @AuraEnabled
    public id  ProjectTypeAttribute {get; set;} 
    @AuraEnabled
    public string  AttributeName {get; set;} 
    @AuraEnabled
    public string  AttributeDescription {get; set;} 
    @AuraEnabled
    public boolean  isRequired {get; set;}     
    @AuraEnabled
    public boolean  isReadOnly {get; set;}     
    @AuraEnabled
    public string  DefaultValue {get; set;}         
    @AuraEnabled
    public Id  DefaultDefinedReferenceValue {get; set;}         
    
    @AuraEnabled    
    public list<AttributeDefinedResponseWrapper>  ResponsesList {get; set;} 
    
    
    public ProjectAttributeWrapper(){}

    public ProjectAttributeWrapper(ProjectAttribute__c psa)
    {
        RecordID = psa.ID;
        Project = psa.Project__c;
        Attribute= psa.Attribute__c;
        AttributeValue = (psa.AttributeValue__c != null) ? htmlDecode(psa.AttributeValue__c) : ''; 
        AttributeType = psa.AttributeType__c;
        AttributeName =psa.AttributeName__c;
        isRequired = psa.IsRequired__c;
        ProjectTypeAttribute = psa.ProjectTypeAttribute__c;        
        AttributeDescription = psa.AttributeDescription__c;
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