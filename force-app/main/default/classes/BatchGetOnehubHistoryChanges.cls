global class BatchGetOnehubHistoryChanges implements Database.Batchable<sObject>, Database.Stateful {
    
    String entityName;          
    DateTime lastSyncDateTime;        
        
    Map<String,List<String>> entities = new Map<String,List<String>>();        
    Map<String,Map<String,String>> entitieFieldMap = new Map<String,Map<String,String>>();   
    Map<String,List<EntityChangeType__c>> entityChangeTypeMap = new Map<String,List<EntityChangeType__c>>();
        
    DateTime MaxDateTime;   
    
    public BatchGetOnehubHistoryChanges(String entity,DateTime lastSync)
    {              
        entityName = entity;
		lastSyncDateTime = lastSync;        
        
        List<EntityChangeLogSetting__c> logSettings = [Select Entity__c, Field__c, FieldKey__c FROM EntityChangeLogSetting__c];// WHERE Entity__c =: entityName];         
        
        for(EntityChangeLogSetting__c logSetting: logSettings){
            
            if (entities.containskey(logSetting.Entity__c)){
                
                List<String> newValue = entities.get(logSetting.Entity__c);
                newValue.add(logSetting.Field__c);
                
                // To make entities based SOQL Query
                entities.put(logSetting.Entity__c,newValue);
                
                //To build field map based on entity
                Map<String,String> fieldKeyMap = entitieFieldMap.get(logSetting.Entity__c);
                fieldKeyMap.put(logSetting.FieldKey__c,logSetting.Field__c);
                entitieFieldMap.put(logSetting.Entity__c,fieldKeyMap);
                
            }
            else{
                
                List<String> newValue = new List<string>();
                newValue.add(logSetting.Field__c);
                entities.put(logSetting.Entity__c, newValue);                
                
                //To build field map based on entity
                Map<String,String> fieldKeyMap = new Map<String,String>();
                fieldKeyMap.put(logSetting.FieldKey__c,logSetting.Field__c);
                entitieFieldMap.put(logSetting.Entity__c,fieldKeyMap);
            }
        }
    }
    
    // instance member to retain state across transactions
    global Integer recordsProcessed = 0;
    /*global Database.QueryLocator start(Database.BatchableContext bc) {
        
        system.debug('entity start:::' + entityName);
        
        //To build and execute History Log SOQL
        changeLogs = new List<SObject>();
        
       	//Get only changes that happened 15 seconds ago so we don't overlap or miss then the ones that are still running and inserting changes.
       	//We need to process all the changes that happened at the same time as a group.
        DateTime upperDateTime = DateTime.Now().addSeconds(-15);                
                      
        List<string> fieldList = new List<String>{'Id', 'ParentId','CreatedDate', 'Field', 'OldValue', 'NewValue'};                          
        List<String> extraFields = entities.get(entityName);
        if (extraFields != null){
            fieldList.addAll(extraFields);
        }        
        
        String query = 'SELECT ' + String.Join(fieldList,',') + '  FROM '+ entityName + '__History WHERE CreatedDate >: lastSyncDateTime and CreatedDate <= :upperDateTime ORDER BY CreatedDate DESC';

        return Database.getQueryLocator(query);

    }      

    global void execute(Database.BatchableContext bc, List<SObject> scope){
        
        Map<String,String> fieldKey = new Map<String,String>();
        fieldKey = entitieFieldMap.get(entityName); 
        EntityHistoryActionHelper.ProcessHistoryChanges(entityName, fieldKey, scope);        
    }

*/
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        
        String query = 'Select Entity__c FROM EntityChangeLogSetting__c Group By Entity__c ';
        return Database.getQueryLocator(query);        
    }        
    
    
    global void execute(Database.BatchableContext bc, List<SObject> scope){
        EntityChangeLogSetting__c tx = (EntityChangeLogSetting__c)scope[0];
        entityName = tx.Entity__c;
        
        Map<String,String> fieldKey = new Map<String,String>();
        fieldKey = entitieFieldMap.get(entityName); 
        
        List<string> historyObjectFieldList = new List<String>{'Id', 'ParentId','CreatedDate', 'Field', 'OldValue', 'NewValue'};                          
            List<String> extraFields = entities.get(entityName);
        if (extraFields != null){
            historyObjectFieldList.addAll(extraFields);
        }        
                
       	//Get only changes that happened 15 seconds ago so we don't overlap or miss then the ones that are still running and inserting changes.
       	//We need to process all the changes that happened at the same time as a group.
        DateTime upperDateTime = DateTime.Now().addSeconds(-15);   
               
        String query = 'SELECT ' + String.Join(historyObjectFieldList,',') + '  FROM '+ entityName + '__History WHERE CreatedDate >: lastSyncDateTime and CreatedDate <= :upperDateTime ORDER BY CreatedDate DESC';        
        List<SObject> historyLogList = Database.query(query);
       	EntityHistoryActionHelper.ProcessHistoryChanges(historyLogList, entityName , fieldKey);
    }

    
    global void finish(Database.BatchableContext bc){        
		
        TriggerUtil.SkipAllTriggers();
        List<ProcessLastSyncTime__c> plsts = [Select Id, CurrentProcessId__c, SyncTime__c from ProcessLastSyncTime__c WHERE ProcessName__c = 'EntityHistoryTracking' LIMIT 1];
                
        AsyncApexJob a = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email FROM AsyncApexJob WHERE Id = :BC.getJobId()];    
        
        if (a.NumberOfErrors == 0 && MaxDateTime != null)
        {
            plsts[0].SyncTime__c = MaxDateTime;
        }
        
        plsts[0].CurrentProcessId__c = '';            
        update plsts[0];
        
        system.debug('Entity History Batch Finished');
    }    
}