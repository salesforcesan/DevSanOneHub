public class LightningPSCertificationController {
    @AuraEnabled
    public static PSCertViewModalWrapper GetPSCertifications(String projectServiceId) {
        PSCertViewModalWrapper pscWrapper;
        try{
            String pscQuery = QueryUtil.FetchQuery('ProjectServiceCertification__c') + ' WHERE ProjectService__c= \'' + projectServiceId + '\' ORDER BY Name ';
            System.debug(' >>>>>>>>>>>>>>>>>> pscQuery >>>>>>>>>>>>>> ' + pscQuery);
            List<ProjectServiceCertification__c> selCertifications = Database.query(pscQuery);    
            if(selCertifications==null)
                selCertifications= new  List<ProjectServiceCertification__c>();
            
            set<id> ExistingCertIDs = new set<id>();
            for(ProjectServiceCertification__c psc : selCertifications){
                ExistingCertIDs.add(psc.Certification__c);
            }
            
            
            
            String certQuery = QueryUtil.FetchQuery('Certification__c');
            certQuery += ' where id not IN : ExistingCertIDs order by name ';
            System.debug(' >>>>>>>>>>>>>>>>>> certQuery >>>>>>>>>>>>>> ' + certQuery);
            List<Certification__c> avlCertifications  = Database.query(certQuery); 
            
            
            System.debug(' >>>>>>>>>>>>>>>>>>avlCertifications >>>>>>>>>>>>>> ' + avlCertifications);
            if(avlCertifications==null)
                avlCertifications= new  List<Certification__c>();
            
            pscWrapper = new PSCertViewModalWrapper(avlCertifications,selCertifications);
            
        }
        catch(exception ex){
            pscWrapper= new PSCertViewModalWrapper();
            pscWrapper.isSuccess = false;
			pscWrapper.message = ex.getMessage();
        }
        return pscWrapper;
    }
    
    @AuraEnabled
    public static String getNamespaceApex() {
        return CONSTANTS.CURRENTNAMESPACEPREFIX;
    }        
        
    
    @AuraEnabled
    public static PSCertViewModalWrapper SavePSCertifications(String projectServiceId,string cert) {
        PSCertViewModalWrapper pscWrapper;
        try{
            ProjectServiceCertification__c psc = new ProjectServiceCertification__c();
            psc.ProjectService__c = projectServiceId;
            psc.Certification__c = cert;
            psc.IsLocked__c = false;
            insert psc; 
            pscWrapper = GetPSCertifications(projectServiceId);
            pscWrapper.message = 'Certification successfully Added !!';
        }
        catch(exception ex){
            pscWrapper= new PSCertViewModalWrapper();
            pscWrapper.isSuccess = false;
			pscWrapper.message = ex.getMessage();
        }
        return pscWrapper;
    }
    
    @AuraEnabled
    public static PSCertViewModalWrapper DeletePSCertifications(String pscID,string psID) {
        PSCertViewModalWrapper pscWrapper;
        try{
            String query = 'SELECT id from ProjectServicecertification__c where id = \'' + pscID + '\'';
            list<ProjectServicecertification__c> returnVals = Database.query(query);
            system.debug('~~~'+returnVals);
            delete returnVals;
            pscWrapper = GetPSCertifications(psID);
            pscWrapper.message = 'Certification successfully Deleted!!';
        }
        catch(exception ex){
            pscWrapper= new PSCertViewModalWrapper();
            pscWrapper.isSuccess = false;
            pscWrapper.message = ex.getMessage();
        }
        return pscWrapper;
    }
}