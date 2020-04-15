global without sharing class ContactActionsHelper {

    global static void RunContactHistoryGetter() {
    

        DateTime lastSyncTime;
        List<ProcessLastSyncTime__c> plsts = [Select Id, CurrentProcessId__c, SyncTime__c from ProcessLastSyncTime__c WHERE ProcessName__c = 'ContactChangeTracking' LIMIT 1];
        
        if (plsts.isEmpty())
        {
            ProcessLastSyncTime__c plst = new ProcessLastSyncTime__c();
            plst.SyncTime__c = DateTime.Now().addMinutes(-120);
            plst.CurrentProcessId__c = '';
            plst.ProcessName__c = 'ContactChangeTracking';
            plsts.add(plst);
            insert plsts;
        }

        lastSyncTime = plsts[0].SyncTime__c ;    
        //If there's an existing process running, return
        if (!string.isBlank(plsts[0].CurrentProcessId__c))
            return;

        
        
        
        BatchGetJobHistoryChanges batch = new BatchGetjobHistoryChanges(lastSyncTime);
        Id batchJobId = Database.ExecuteBatch(batch, 9000);        
        
        plsts[0].CurrentProcessId__c = string.valueOf(batchJobId);
        update plsts[0];
        
    }         
    
    
    global static void ProcessContactHistoryChanges(List<ContactHistory> chs) {
    
        Set<Id> contactIds = new Set<Id>();        
        Map<string, string> mapChangeTypes = new Map<string, string>();        
        
        for (ContactHistory ch : chs)
        {
            contactIds.add(ch.ContactId);
        }        

        
        List<Contact> contacts = [Select Id, Name, ContactId__c from Contact WHERE Id IN :contactIds];
        Map<Id, Contact> mapContacts = new Map<Id, Contact>(contacts);
        
        List<EntityChangeType__c> ects = [Select Id, Name, Field__c, Value__c, ChangeType__c from EntityChangeType__c WHERE Entity__c = 'Contact'];
       
        for (EntityChangeType__c ect : ects)
        {
            //Check for changes looking for a particular value or any        
            if (ect.Value__c == null)
                mapChangeTypes.put(ect.Field__c.toLowerCase(),ect.ChangeType__c); 
            else        
                mapChangeTypes.put(ect.Field__c.toLowerCase() + '-'+ ect.Value__c.toLowerCase(), ect.ChangeType__c); 
        }
        
        Map<string, string> newchanges = new Map<string, string>();

        List<EntityChangeLog__c> ecls = new List<EntityChangeLog__c>();
        EntityChangeLog__c ecl;
        
        for (ContactHistory ch : chs)
        {
            //Check if this is a field of interest to the system
            //Else ignore the change
            //Check with changes looking for a particular value or any
            string newValue = ch.NewValue==null?'': string.valueof(ch.NewValue).toLowerCase();     
                   
            if (mapChangeTypes.get(string.valueof(ch.Field).toLowerCase()) == null && 
                   mapChangeTypes.get(string.valueof(ch.Field).toLowerCase() + '-'+ newValue) == null )
                continue;
                

                string changeType = mapChangeTypes.get(string.valueof(ch.Field).toLowerCase() + '-'+ string.valueof(ch.NewValue).toLowerCase()) == null?
                    mapChangeTypes.get(string.valueof(ch.Field).toLowerCase()):mapChangeTypes.get(string.valueof(ch.Field).toLowerCase() + '-'+ string.valueof(ch.NewValue).toLowerCase());
                
                //INSERT UNIQUE CHANGES ONLY for the object and change type
                
            if (!newchanges.containskey(string.valueof(ch.ContactId) + changeType ))
            {
                ecl = new EntityChangeLog__c();
                ecl.Entity__c = 'Contact';
                ecl.ChangeDateTime__c = ch.CreatedDate;
                ecl.ChangeType__c = changeType;
                ecl.EntityId__c = mapContacts.get(ch.ContactId).ContactId__c;
                ecls.add(ecl);
                newchanges.put(string.valueof(ch.ContactId) + changeType, string.valueof(ch.ContactId) + changeType);
            }
        }
        
        if (ecls.size() > 0)        
        {
            insert ecls;
        }
                
    }     
}