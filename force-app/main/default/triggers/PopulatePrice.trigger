trigger PopulatePrice on Opportunity (before insert) {
/*
    if (TriggerUtil.isDRModeEnabled == true )
     {
            return;
     }
     
   
    if (TriggerUtil.skipOpportunityTrigger)return;
    
    Set<Id> accountIds = new Set<Id>();
    
    for (Opportunity opp: (List <Opportunity> ) Trigger.new)    
    {
        accountIds.add(opp.AccountId);
    }
    
    Map<Id, Account> accountmap = new Map<Id, Account>([SELECT Id, Name, ProjectBuilder__c FROM Account where Id IN :accountIds]);    

    for (Opportunity opp: (List <Opportunity> ) Trigger.new) {
        if(accountmap.get(opp.accountid) != null)
        {
            opp.ProjectBuilderUser__c = accountmap.get(opp.accountid).ProjectBuilder__c;
        }
    }*/
}