public class ProjServCertificationWrapper {
  	@AuraEnabled
    public string RecordID{get; set;}     
    @AuraEnabled
    public string Name{get; set;}    
    @AuraEnabled
    public id ProjectServiceID{get; set;}
  	@AuraEnabled
    public string CertificationName{get; set;}     
    @AuraEnabled
    public id CertificationID{get; set;}    
    @AuraEnabled
    public boolean IsLocked{get; set;}   
    
    public ProjServCertificationWrapper(){        
    }

    public ProjServCertificationWrapper(ProjectServiceCertification__c cert){
        RecordID=cert.id;
        Name= cert.Name;
        ProjectServiceID=cert.ProjectService__c;
        CertificationName= cert.CertificationName__c;
        CertificationID= cert.Certification__c;
        IsLocked= cert.IsLocked__c;        
    }
}