public class JobImportRequest {
        @AuraEnabled
        public Integer StartImport {get;set;}
        @AuraEnabled
        public Integer EndImport {get;set;}
	@AuraEnabled
        public String ProjectId {get;set;}
        @AuraEnabled
        public List<String> Jobs {get;set;}
}