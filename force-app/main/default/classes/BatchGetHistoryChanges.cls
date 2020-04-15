global class BatchGetHistoryChanges implements Database.Batchable<Object> {
    
    String entityName;
    
    public static String getNAMESPACE() {
        return CONSTANTS.CURRENTNAMESPACEPREFIX;
    }
    
    Map<String,List<String>> entities = new Map<String,List<String>>();  
    Map<String,List<String>> entityconditionfieldsmap = new Map<String,List<String>>();
    Map<String,Map<String,String>> entitieFieldMap = new Map<String,Map<String,String>>();   
    Map<String,List<EntityChangeType__c>> entityChangeTypeMap = new Map<String,List<EntityChangeType__c>>();        
    
    public BatchGetHistoryChanges()
    {                      

        //Get all the fields used in the condition logic so these fields can be retrieved
        //when we query history object
        List<EntityChangeType__c> ects = [SELECT Entity__c, ConditionField__c FROM EntityChangeType__c WHERE ConditionField__c != null];
        for (EntityChangeType__c ect: ects)
        {
            string conditionfield = ect.ConditionField__c;
            List<String> conditionfields = new List<String>();
            if (entityconditionfieldsmap.containsKey(ect.Entity__c))
            {
                conditionfields.addAll(entityconditionfieldsmap.get(ect.Entity__c));
            }
            conditionfields.add(conditionfield);
            
            entityconditionfieldsmap.put(ect.Entity__c,conditionfields);
        }
        
        List<EntityChangeLogSetting__c> logSettings = [Select Entity__c, Field__c, FieldKey__c FROM EntityChangeLogSetting__c];
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
    
    public List<Object> start(Database.BatchableContext context) {
        //OH2-1964
        List<EntityChangeType__c> listAccountsWithSupport = [SELECT Entity__c, EntityHistoryObject__c,EntityExecutionOrder__c FROM EntityChangeType__c 
                                                             Order By EntityExecutionOrder__c];
        
        Map<String, EntityChangeType__c> mapAccountsWithSupport = new Map<String, EntityChangeType__c>();
        
        //To get unique EntityChangeType__c
        for (EntityChangeType__c ec : listAccountsWithSupport){
            string fieldValue = (ec.Entity__c != null ? ec.Entity__c : '') 
                + (ec.EntityHistoryObject__c != null ? ec.EntityHistoryObject__c : '') 
                + (ec.EntityExecutionOrder__c != null ? ec.EntityExecutionOrder__c : 100);
            
            mapAccountsWithSupport.Put(fieldValue,ec);
        }
        
        List<EntityChangeType__c> entityList = new List<EntityChangeType__c>();
        for(EntityChangeType__c ec: mapAccountsWithSupport.values()) {
            entityList.add(ec);
        }
        
        return entityList;
    }
    
    public void execute(Database.BatchableContext context, List<Object> scope) { 
        
        if(scope[0] == null){return;}
        Datetime MaxDateTime = system.now();
        
        EntityChangeType__c ecType = (EntityChangeType__c)scope[0];
        entityName = ecType.Entity__c;
        String entityHistoryObjectName = ecType.EntityHistoryObject__c;
        if (entityHistoryObjectName == '') {return; }
        
        ProcessLastSyncTime__c lastSync = EntityHistoryActionHelper.GetLastSyncTime(entityName + 'ChangeTracking', context.getJobId());
        
        //If there's an existing process running, return
        if (lastSync == null) {return;}
        
        Datetime lastSyncDateTime = lastSync.SyncTime__c;    
        
        Map<String,String> fieldKey = new Map<String,String>();
        fieldKey = entitieFieldMap.get(entityName); 
        
        List<string> historyObjectFieldList = new List<String>{'Id', 'CreatedDate', 'Field', 'OldValue', 'NewValue'};                          
        List<String> extraFields = entities.get(entityName);
        List<String> conditionFields = entityconditionfieldsmap.get(entityName);        
        
        if (extraFields != null){
            historyObjectFieldList.addAll(extraFields);
        }        
        
        if (conditionFields != null){
            historyObjectFieldList.addAll(conditionFields);
        }       
                
        //Get only changes that happened 15 seconds ago so we don't overlap or miss then the ones that are still running and inserting changes.
        //We need to process all the changes that happened at the same time as a group.
        DateTime upperDateTime = DateTime.Now().addSeconds(-15);   
        
        // Get record count limit from custom setting.
        Integer recordLimit = AppUtil.HistoryRecordLimit;
        
        String query = 'SELECT ' + String.Join(historyObjectFieldList,',') + '  FROM ' + entityHistoryObjectName + ' WHERE CreatedDate >=: lastSyncDateTime and CreatedDate <= :upperDateTime ORDER BY CreatedDate Limit :recordLimit';
        
        List<SObject> historyLogList = Database.query(query);        
       
        //OH2-1964
        List<SObject> historyLogToDeleteList = [Select Id from EntityChangeLog__c where ChangeDateTime__c =: lastSyncDateTime and Entity__c =: entityName]; 
        delete historyLogToDeleteList;
        
        if (!historyLogList.isEmpty())
        {            
            EntityHistoryActionHelper.ProcessHistoryChanges(historyLogList, entityName , fieldKey);         
            MaxDateTime = datetime.valueOf(historyLogList[historyLogList.size()-1].get('CreatedDate'));
        }        
        
        //to get last sync time        
        EntityHistoryActionHelper.UpdateSyncTime(entityName + 'ChangeTracking', context.getJobId(),MaxDateTime);
        
    }
    
    public void finish(Database.BatchableContext BC) {                    
        system.debug(entityName + ' History Batch Finished');
    }
}