public class ImportRequest {
    @AuraEnabled
    public String ParentId {get;set;}

    @AuraEnabled
    Public String ServiceName {get;set;}
   
    @AuraEnabled
    Public String AttachmentName {get;set;}

    @AuraEnabled
    public String JobName {get;set;}

    @AuraEnabled
    public Integer StartImport {get;set;}
    
    @AuraEnabled
    public Integer EndImport {get;set;}
    
    @AuraEnabled
    public List<String> Data {get;set;}
}