public with sharing class LightningActionResponse { 
    
    @AuraEnabled public Boolean isSuccess {get;  set;}
    @AuraEnabled public string message {get;  set;}    
    @AuraEnabled public Map<Object, Object> values { get; set; }
    
    public LightningActionResponse(Boolean isSuccess, String msg) 
    {        
        this.isSuccess = isSuccess;
        this.message = msg;
        this.values = new Map<Object,Object>();
    }
    
    public LightningActionResponse newInstance(Boolean isSuccess, String msg) {
        return new LightningActionResponse (isSuccess, msg);
    }
}