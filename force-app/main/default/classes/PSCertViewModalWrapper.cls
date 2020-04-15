public class PSCertViewModalWrapper {
    @AuraEnabled
    public list<CertificationWrapper> AvailableCerts{get; set;}
    @AuraEnabled
    public list<ProjServCertificationWrapper> SelectedCerts{get; set;}
    @AuraEnabled
    public boolean isSuccess{get; set;}
    @AuraEnabled
    public string message{get; set;}
    
        
    public PSCertViewModalWrapper(){          
    }
    
    public PSCertViewModalWrapper(list<Certification__c> avlCertifications, list<ProjectServiceCertification__c> selCertifications){  
        try{
            system.debug('____inside wrapper _______'+avlCertifications+'____selCertifications_______'+selCertifications );
            AvailableCerts=new list<CertificationWrapper>();
            SelectedCerts=new list<ProjServCertificationWrapper>();
            
            if(avlCertifications!=null){
                for(Certification__c cert:avlCertifications){
                    AvailableCerts.add(new CertificationWrapper(cert));
                }
            }
            
            if(selCertifications!=null){
                for(ProjectServiceCertification__c cert:selCertifications){
                    SelectedCerts.add(new ProjServCertificationWrapper(cert));
                }                
            }
            isSuccess=true;
            message = 'Data loaded successfully !!';
        }
        catch(exception ex){
		    isSuccess=false;
            message = 'Data load failed. Please contact support team.';            
        }
    }
}