public without sharing class ImportRequestQueueWrapper {
    @AuraEnabled
    public String queueId {get;set;}

    @AuraEnabled
    public String datasource {get;set;}
    
    @AuraEnabled
    public string name {get;set;}
    
    @AuraEnabled
    public string queueDate {get;set;}

    @AuraEnabled
    public string status {get;set;}
    
    @AuraEnabled
    public string requestor {get;set;}

    @AuraEnabled
    public string response {get;set;}

    @AuraEnabled
    public string startTime {get;set;}

    @AuraEnabled
    public string endTime {get;set;}

    private ImportRequestQueueWrapper(String queueId) {
        ImportRequestQueue__c q = [SELECT Id, Name,Datasource__c, Status__c, Requestor__r.Name, RequestDate__c, Response__c, StartTime__c, EndTime__c FROM ImportRequestQueue__c WHERE Id = :queueId LIMIT 1];

        this.queueId = q.Id;
        this.name = q.Name;
        this.datasource = q.Datasource__c;
        this.queueDate = formatDate(q.RequestDate__c);
        this.requestor = q.Requestor__r.Name;
        this.status = q.Status__c;
        this.response = q.Response__c;
        this.startTime = formatDate(q.StartTime__c);
        this.endTime = formatDate(q.EndTime__c);
    }

    private String formatDate(Datetime dttm){
        return dttm != null 
            ? dttm.formatLong()
            : '';
    }

    public static ImportRequestQueueWrapper newInstance(String queueId){
        return new ImportRequestQueueWrapper(queueId);
    }
}