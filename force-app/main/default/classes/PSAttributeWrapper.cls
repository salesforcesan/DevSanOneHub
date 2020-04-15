public class PSAttributeWrapper {
    @AuraEnabled
    public string RecordID{get; set;}     
    @AuraEnabled
    public string Attributename{get; set;}
    @AuraEnabled
    public string AttributeNumber{get; set;}
    @AuraEnabled
    public decimal AttributeOrder{get; set;}
    @AuraEnabled
    public string AttributeTitle{get; set;}
    @AuraEnabled
    public string AttributeType{get; set;}
    @AuraEnabled
    public string AttributeValue{get; set;}    
    @AuraEnabled
    public string AttachFile{get; set;} 
    @AuraEnabled
    public string AttachFileLink{get; set;} 
    @AuraEnabled
    public String AttachmentURL{get;set;}
  
    
    public PSAttributeWrapper(){        
    }

    public PSAttributeWrapper(ProjectServiceAttribute__c psa)
    {
        RecordID = psa.ID;
        Attributename = psa.description__c;
        AttributeNumber= psa.AttributeNumber__c;
        AttributeOrder = psa.AttributeOrder__c;
        AttributeTitle = psa.AttributeTitle__c;
        AttributeType = psa.AttributeType__c;
        AttributeValue = (psa.AttributeValue__c!=null)?psa.AttributeValue__c:''; 
        AttachFile = psa.AttchFileName__c;
        AttachmentURL = psa.AttachmentURL__c;
 
        if(psa.AttributeValue__c!=null)
            AttachFileLink = '/servlet/servlet.FileDownload?file=' +string.valueOf(psa.AttributeValue__c).substringBefore('=') ;
        else
            AttachFileLink ='';
    }
    
}