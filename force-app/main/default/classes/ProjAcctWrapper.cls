public class ProjAcctWrapper {
        @AuraEnabled
        public string StreetAddress{get; set;}
        @AuraEnabled
        public string CityAddress{get; set;}
        @AuraEnabled
        public string StateAddress{get; set;}
        @AuraEnabled
        public string PostalCodeAddress{get; set;}
        @AuraEnabled
        public string ContactName{get; set;}
        @AuraEnabled
        public string ContactPhone{get; set;}
		@AuraEnabled
        public string AccountName{get; set;}
        @AuraEnabled
        public string ProjectNum{get; set;}
    	@AuraEnabled
        public string ProjectName{get; set;}
    	@AuraEnabled
        public string Id{get; set;}
    	@AuraEnabled
        public string AccountId{get; set;}
    	@AuraEnabled
        public string LawsonId{get; set;}
    	
        @AuraEnabled
        public string ProjectStatus{get; set;}
       
       @AuraEnabled 
       public Boolean CanSetPrimary{get;set;}
        @AuraEnabled 
       public Boolean canDelete{get;set;}
    	
        @AuraEnabled
        public string IsPrimary{get; set;}
    
    
    Public ProjAcctWrapper(){}
        
    	public ProjAcctWrapper(projectAccount__c PA){
            
            ProjectName = PA.Name;
            ProjectNum = string.valueOf(PA.Project__r.projectnumber__c);
            StreetAddress = PA.Account__r.BillingStreet;
            CityAddress = PA.Account__r.BillingCity;
            StateAddress = PA.Account__r.BillingState;
            PostalCodeAddress = PA.Account__r.BillingPostalCode;
            ContactName = PA.Account__r.Owner.Name;
            AccountName = PA.Account__r.Name;
            AccountId = PA.Account__r.Id;
            Id = PA.Id;
            LawsonId = PA.Account__r.CMKOneHubAccountID__c;
            ProjectStatus = PA.Project__r.Status__c;
            IsPrimary = string.valueOf(PA.IsPrimary__c);
            CanSetPrimary = !UIConfig.checkFieldHidden(PA.Project__r.Status__c, 'ProjectAccount__c.SetPrimary');
            canDelete= !UIConfig.checkFieldHidden(PA.Project__r.Status__c, 'ProjectAccount__c.Delete');
        }        
}