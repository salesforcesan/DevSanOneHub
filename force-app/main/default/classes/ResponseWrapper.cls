public class ResponseWrapper {

    public string State {get; set;}
    public string Message {get; set;}
    public object Data {get; set;}

    private ResponseWrapper(string type, string message) 
    {
        this.State = type;
        this.Message = message;
    }

    private ResponseWrapper(string type, string message, object data) 
    {
        this.State = type;
        this.Message = message;
        this.data = data;
        
    }

    public static ResponseWrapper createInstance(string state, string message) 
    {
        return  new ResponseWrapper(state, message);
    }        
    
    public static ResponseWrapper getInstance(string state, string message, object data ) 
    {
        return  new ResponseWrapper(state, message, data);
    } 

        
}