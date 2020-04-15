public with sharing class ServiceWrapper {
    public ServiceWrapper(){
        
    }
    @AuraEnabled
    public Id Id {get;set;}
    @AuraEnabled
    public String Name {get;set;}
    @AuraEnabled
    public String ServiceDescription {get;set;}   
}