public class ProjectAccountServiceDataAccessWrapper {
                
    public ProjectAccountServiceDataAccessWrapper(){}
    
    @AuraEnabled
    public String Id{get;set;}
    
    @AuraEnabled
    public id ProjectAccount{get; set;}
    
    @AuraEnabled
    public id ProjectService{get; set;}
    
    @AuraEnabled
    public String AccountName{get; set;}

    @AuraEnabled
    public String AccessLevel{get; set;}
    
    @AuraEnabled
    public ProjectAccountService[] ProjectAccountService;    
    
	public class ProjectAccountService {
        @AuraEnabled
		public Boolean Access;
        
        @AuraEnabled
		public String ExternalId;
        
        @AuraEnabled
        public String ServiceName;
        
        @AuraEnabled
        public String AccountName;
        
        @AuraEnabled
		public String ProjectAccoutId;	
        
        @AuraEnabled
		public String ProjectServiceId;        
        
        @AuraEnabled
        public String ProjectAccountServiceAccessId;
        
        @AuraEnabled
        public ProjectAccountServiceAccess__c PASAccess;
	}        
   
    public static ProjectAccountServiceDataAccessWrapper parse(String json){
		return (ProjectAccountServiceDataAccessWrapper) System.JSON.deserialize(json, ProjectAccountServiceDataAccessWrapper.class);
	}
}