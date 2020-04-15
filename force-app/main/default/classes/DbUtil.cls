public class DbUtil{
    
     public static boolean verifySaveResults(Database.SaveResult[] srList){
        boolean result = true;
        for (Database.SaveResult sr : srList) {
            if (!sr.isSuccess()) {
                // Operation failed, so get all errors                
                for(Database.Error err : sr.getErrors()) {
                    System.debug('Share Error:'+err.getStatusCode() + ': ' + err.getMessage());
                }
                result = false;
            }
        }
        return result;
    }
    
}