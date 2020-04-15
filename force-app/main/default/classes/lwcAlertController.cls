public without sharing class lwcAlertController {
    @AuraEnabled
    public static Integer checkVisible(String recordId, String objectName, String rules){
        //todo: need to desing rule engines. right now we just hard code to handle visibility for opportunity only
        return handleOpportunity(recordId);
    }

    static Integer handleOpportunity(String recordId){
        if (String.isBlank(recordId)) {
            return 0;
        }

        List<Opportunity> opprs = [
            SELECT 
            Id, 
            AccountId, 
            ParentOpportunity__c, 
            ParentOpportunity__r.AccountId 
            FROM Opportunity 
            WHERE Id = :recordId 
            OR ParentOpportunity__c = :recordId];

        String parentAccount = '';
        for(Opportunity op: opprs){
            if (op.Id == recordId){
                if (String.isNotBlank(op.ParentOpportunity__r.AccountId) && op.AccountId == op.ParentOpportunity__r.AccountId){
                      return 1;
                }  
            }
            if (op.ParentOpportunity__c == recordId){
                if (String.isNotBlank(op.AccountId) 
                    && op.AccountId == op.ParentOpportunity__r.AccountId )
                {
                      return 1;
                }  
            }
        }

        return 0;
    }
}