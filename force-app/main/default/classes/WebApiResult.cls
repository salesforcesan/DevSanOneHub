public without sharing class WebApiResult {
    public static final Integer API_SUCCESS = 1;
    public static final Integer API_ERROR = 0;

    @AuraEnabled
    public Integer status {get;set;}

    @AuraEnabled
    public String message {get;set;}

    @AuraEnabled
    public Object data {get;set;}

    private WebApiResult(Integer Status, String message, Object data){
        this.status = status;
        this.message = message;
        this.data = data;
    }

    public static WebApiResult newInstance(Integer status, String message, Object data){
        return new WebApiResult(status, message, data);
    }

    public static WebApiResult newSuccess(String message, Object data){
        return new WebApiResult(API_SUCCESS, message, data);
    }

    public static WebApiResult newSuccess(String message){
        return new WebApiResult(API_SUCCESS, message, null);
    }

    public static WebApiResult newSuccess(){
        return new WebApiResult(API_SUCCESS, '', null);
    }

    public static WebApiResult newError(String message){
        return new WebApiResult(API_ERROR, message, null);
    }
}