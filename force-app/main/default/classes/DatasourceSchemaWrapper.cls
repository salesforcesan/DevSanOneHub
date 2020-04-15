public with sharing class DatasourceSchemaWrapper {
    
    @AuraEnabled public String field {get;set;}
    @AuraEnabled public integer keyed {get;set;}
    @AuraEnabled public Integer groupBy {get;set;}
    @AuraEnabled public Integer required {get;set;}
    @AuraEnabled public String title {get;set;}
    @AuraEnabled public Integer updatable {get;set;}
    @AuraEnabled public String dataType {get;set;}
}