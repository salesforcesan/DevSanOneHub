global class ActionResponse
{
    public Id RecordId {get; set;}
    public Boolean IsSuccessful {get; set;}
    public string ResponseMessage {get; set;}
    public Boolean IsBatched {get;set;}
    
    global ActionResponse(Id pRecordId, Boolean pIsSuccessful, String pResponseMessage) 
    {
        RecordId = pRecordId;
        IsSuccessful = pIsSuccessful;
        ResponseMessage = pResponseMessage;
    }    

    global static ActionResponse newInstance(Id pRecordId, Boolean pIsSuccessful, String pResponseMessage) {
        return new ActionResponse (pRecordId, pIsSuccessful, pResponseMessage);
    }

    global static ActionResponse failed(Id recordId, String message) {
        return new ActionResponse(recordId, false, message);
    }
    
    global static ActionResponse succeeded(Id recordId, String message) {
        return new ActionResponse(recordId, true, message);
    }

    global static ActionResponse failed(String message) {
        return new ActionResponse(null, false, message);
    }
    
    global static ActionResponse succeeded(String message) {
        return new ActionResponse(null, true, message);
    }
}