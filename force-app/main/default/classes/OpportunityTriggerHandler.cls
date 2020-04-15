public class OpportunityTriggerHandler extends TriggerHandler{
    
    public override void beforeUpdate() {
        if (TriggerUtil.skipOpportunity) return;
        
    }
    
    
    public override void beforeInsert() {
        
        if (TriggerUtil.skipOpportunity) return;
        
        Set<string> accountIds = new Set<string>();
        for (Opportunity op: (List <Opportunity>) Trigger.new) {
            
            accountIds.add(op.AccountId);
        }
        if(accountIds.size()>0)
        {
            updatePrjBuliderUser(accountIds);
        }
        
    }
    
    public override void afterInsert(){
        
        if (TriggerUtil.skipOpportunity) return;
        
        Set<String> opportunityIds = new Set<String>();
        
        for(Opportunity op :(List<Opportunity> )Trigger.new){
            
            if (op.AccountBudget__c != null){
                opportunityIds.add(op.Id);
            }            
        } 
        
        updateAccountBudgets(opportunityIds);
        
    }
    
    public override void afterUpdate(){
        if (TriggerUtil.skipOpportunity) return;   
        
        Map<String, string> oppToAssignedAB = new Map<String, string>();
        Map<String, string> oppToRemovedAB = new Map<String, string>();
        
        
        //Map<String, decimal> oppAmountToReduceInAB = new Map<String, decimal>();
        Map<String, decimal> oppAmountToIncludeInAB = new Map<String, decimal>();
        
        Set<String> accountBudgetIds = new Set<String>();
        
        Map<String, Opportunity> oppMap = new Map<String, Opportunity>();
        
        
        for(Opportunity op :(List<Opportunity> )Trigger.new){
            Opportunity oldOp = (Opportunity) Trigger.oldMap.get(op.Id);
            oppMap.put(op.Id,op);            
            
            if(op.AccountBudget__c != oldOp.AccountBudget__c){
                
                oppToAssignedAB.put(op.Id,op.AccountBudget__c);
                oppToRemovedAB.put(oldOp.Id,oldOp.AccountBudget__c);
                
                if (op.AccountBudget__c != null){
                    accountBudgetIds.add(op.AccountBudget__c);
                }
                if (oldOp.AccountBudget__c != null){
                    accountBudgetIds.add(oldOp.AccountBudget__c);
                }
            }
            
            //when account budget assignment has not changed but the total amount has changed 
            if(op.AccountBudget__c != null 
               && (op.AccountBudget__c == oldOp.AccountBudget__c) 
               && (op.Amount != oldOp.Amount)) {
                   
                   accountBudgetIds.add(oldOp.AccountBudget__c);
                   
                   decimal amt = 0.0;
                   if(oppAmountToIncludeInAB.ContainsKey(oldOp.AccountBudget__c))
                   {
                       amt = oppAmountToIncludeInAB.get(oldOp.AccountBudget__c);                    
                   }
                   
                   // To reduce the changed amount from account budget
                   amt = amt + (((oldOp.Amount != null) ? oldOp.Amount : 0.00) * -1);
                   
                   // To add new amount back to account budget
                   amt = amt + ((op.Amount != null) ? op.Amount : 0.00);
                   
                   oppAmountToIncludeInAB.put(oldOp.AccountBudget__c, amt);
               }
            
        }
        
        Map<String, AccountBudget__c> accountBudgetMap = new Map<String, AccountBudget__c>(
            [select id, PlannedAgainstBudget__c 
             from AccountBudget__c 
             Where ID IN :accountBudgetIds]);              
        
        List<AccountBudget__c> accountBudgetListToUpdate =  new List<AccountBudget__c>();
        
        for (String abId : oppAmountToIncludeInAB.keySet()){
            AccountBudget__c ab  = accountBudgetMap.get(abId);
            if (ab != null){
                ab.PlannedAgainstBudget__c = ab.PlannedAgainstBudget__c + oppAmountToIncludeInAB.get(abId);
                accountBudgetListToUpdate.add(ab);
            }
        }
        
        // To reduce the planned amount when account budget is removed
        for (String oppId : oppToRemovedAB.keySet()){
            AccountBudget__c ab  = accountBudgetMap.get(oppToRemovedAB.get(oppId));
            
            Opportunity op = oppMap.get(oppId);
            if(ab != null && accountBudgetMap.ContainsKey(oppToRemovedAB.get(oppId)) ){
                Double amount = op.Amount != null ? op.Amount : 0.0; 
                
                if(ab.PlannedAgainstBudget__c != null)
                {
                    ab.PlannedAgainstBudget__c = ab.PlannedAgainstBudget__c - amount;
                    accountBudgetListToUpdate.add(ab);
                }
            }
            
        }
        
        // To add the planned amount when account budget is added
        for (String oppId : oppToAssignedAB.keySet()){
            
            Opportunity op = oppMap.get(oppId);                                
            AccountBudget__c ab  = accountBudgetMap.get(oppToAssignedAB.get(oppId));
            system.debug('oppToAssignedAB ab' + ab);
            
            if( ab != null && accountBudgetMap.ContainsKey(oppToAssignedAB.get(oppId)) ){                
                
                Double amount = op.Amount != null ? op.Amount : 0.0; 
                ab.PlannedAgainstBudget__c = ab.PlannedAgainstBudget__c != null 
                    ? ab.PlannedAgainstBudget__c + amount
                    : amount;
                
                system.debug('oppToAssignedAB ' + oppId);
                accountBudgetListToUpdate.add(ab);
            }
            
        }        
        
        // To update all account budget
        update accountBudgetListToUpdate;
        
    }
    
    
    /*
public override void afterUpdate(){

if (TriggerUtil.skipOpportunity) return;        

//Account Budget to be removed from Opportunity Id's
Set<String> accBudgetToBeRemovedIds = new Set<String>();        

Set<String> opportunityIds = new Set<String>();

for(Opportunity op :(List<Opportunity> )Trigger.new){
Opportunity oldOp = (Opportunity) Trigger.oldMap.get(op.Id);

if (oldOp.AccountBudget__c != op.AccountBudget__c){
accBudgetToBeRemovedIds.add(oldOp.Id);
opportunityIds.add(op.Id);
}

} 
updateAccountBudgets(opportunityIds, true);
updateAccountBudgets(opportunityIds, false);

}

*/
    
    private void updatePrjBuliderUser(Set<String> accountIds)
    {
        Map<Id, Account> accountmap = new Map<Id, Account>([SELECT Id, Name, ProjectBuilder__c FROM Account where Id IN :accountIds]);    
        
        for (Opportunity opp: (List <Opportunity> ) Trigger.new) {
            if(accountmap.get(opp.accountid) != null)
            {
                opp.ProjectBuilderUser__c = accountmap.get(opp.accountid).ProjectBuilder__c;
            }
        }
    }
    
    
    
    private void updateAccountBudgets(Set<String> opportunityIds){
        
        Set<String> accountBudgetIds = new Set<String>();
        
        List<Opportunity> opportunityList = [Select Id,Amount,AccountBudget__c 
                                             From Opportunity 
                                             Where ID IN :opportunityIds 
                                             And AccountBudget__c != null];
        
        //To get all associated Account Budget
        for(Opportunity op : opportunityList){
            accountBudgetIds.add(op.AccountBudget__c);
        }
        
        Map<String, AccountBudget__c> accountBudgetMap = new Map<String, AccountBudget__c>(
            [select id, PlannedAgainstBudget__c 
             from AccountBudget__c 
             Where ID IN :accountBudgetIds]);
        
        List<AccountBudget__c> accountBudgetListToUpdate =  new List<AccountBudget__c>();
        
        //To update PlannedAgainstBudget__c field of associated Account Budget object 
        for(Opportunity op : opportunityList){
            
            AccountBudget__c ab = accountBudgetMap.get(op.AccountBudget__c);
            Double amount = op.Amount != null ? op.Amount : 0.0; 
            
            ab.PlannedAgainstBudget__c = ab.PlannedAgainstBudget__c != null 
                ? ab.PlannedAgainstBudget__c + amount
                : amount;
            
            accountBudgetListToUpdate.add(ab);
        }
        
        // To update all account budget
        update accountBudgetListToUpdate;
        
    }
    
}