public with sharing class EmailHelper {	
	
	public static String MessageBodyBuilder(String  messageBody, Map<String, String> valueMap){
		
		 if(valueMap != null && valueMap.size() > 0){
                for (String messageKey : valueMap.keySet())
                {
                    messageBody = messageBody.replace('{{'+ messageKey + '}}', valueMap.get(messageKey));
                }
            }
            return messageBody;
	}
	
	public static void SendEmail(String[] toAddresses,String subject,String  messageBody){    	         
        SendEmail(new Messaging.SingleEmailMessage(),toAddresses,subject,messageBody);
    }
    
    public static void SendEmail(String[] toAddresses,String subject,String  messageBody, Boolean isPlainTextBody){
    	    
    	Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
    	
	    //To Set plain \ html body type
        if (isPlainTextBody) {
       		mail.setPlainTextBody(messageBody);
        } 
        else {
        	mail.setHTMLBody(messageBody);
        }   
            
        SendEmail(mail,toAddresses,subject,messageBody);
    }
    
    public static void SendEmail(Messaging.SingleEmailMessage mail, String[] toAddresses,String subject, String  messageBody){
        
        try{       	
        	
            mail.setToAddresses(toAddresses);
            mail.setSubject(subject);                               
            mail.setHTMLBody(messageBody);
            if(!Test.isRunningTest()){
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });     
            }
        }
        catch(Exception ex){
            throw ex;
        }
        
    }
    
    public static void SendEmail(Messaging.SingleEmailMessage mail, String[] toAddresses,String subject, String  messageBody, Boolean isPlainTextBody){
        
        try{       	
        	
            mail.setToAddresses(toAddresses);
            mail.setSubject(subject);        
            
            //To Set plain \ html body type
	        if (isPlainTextBody) {
	       		mail.setPlainTextBody(messageBody);
	        } 
	        else {
	        	mail.setHTMLBody(messageBody);
	        }                          
	            
            if(!Test.isRunningTest()){
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });     
            }
        }
        catch(Exception ex){
            throw ex;
        }
        
    }
    
    public static string getEmailDistribution(){
        OrgCustomSettings__c setting = [SELECT ErrorNotificationEmail__c FROM OrgCustomSettings__c LIMIT 1];
        return setting.ErrorNotificationEmail__c;
    }
}