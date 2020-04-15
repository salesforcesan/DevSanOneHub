public class CertificationWrapper {
  	@AuraEnabled
    public string RecordID{get; set;}     
    @AuraEnabled
    public string Name{get; set;}
    @AuraEnabled
    public string Description{get; set;}
    
    public CertificationWrapper(){        
    }

    public CertificationWrapper(Certification__c cert){
        RecordID=cert.id;
        Name= cert.Name;
        Description = cert.Description__c;
    }
}