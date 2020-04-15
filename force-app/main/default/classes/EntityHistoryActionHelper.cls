global without sharing class EntityHistoryActionHelper {
    
    public static void RunEntityHistoryGetter() {
        BatchGetHistoryChanges batch = new BatchGetHistoryChanges();      
        Id batchJobId = Database.ExecuteBatch(batch, 1);        
    }

    global static void RunEntityHistoryGetter(String entity) {
        BatchGetHistoryChanges batch = new BatchGetHistoryChanges();      
        Id batchJobId = Database.ExecuteBatch(batch, 1);            
    }            
    
    public static ProcessLastSyncTime__c GetLastSyncTime(String entity, Id batchJobId){
        
        List<ProcessLastSyncTime__c> plsts = [Select Id, CurrentProcessId__c, SyncTime__c from ProcessLastSyncTime__c WHERE ProcessName__c =: entity LIMIT 1];
        if (plsts.isEmpty())
        {
            ProcessLastSyncTime__c plst = new ProcessLastSyncTime__c();
            plst.SyncTime__c = DateTime.Now().addMinutes(-120);
            plst.CurrentProcessId__c = '';
            plst.ProcessName__c = entity;
            plsts.add(plst);
            insert plsts;
        }
                
        //If there's an existing process running, return
        if (!string.isBlank(plsts[0].CurrentProcessId__c))
            return null; 
                        
        plsts[0].CurrentProcessId__c = string.valueOf(batchJobId);
        update plsts[0];
        
        return plsts[0];        
    }
            
    public static void UpdateSyncTime(String entity, Id jobId, Datetime syncTime){
        
        TriggerUtil.SkipAllTriggers();
        List<ProcessLastSyncTime__c> plsts = [Select Id, CurrentProcessId__c, SyncTime__c from ProcessLastSyncTime__c WHERE ProcessName__c =: entity LIMIT 1];
                
        AsyncApexJob a = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email FROM AsyncApexJob WHERE Id = : jobId];    

        if (a.NumberOfErrors == 0 && syncTime != null)
        {
            plsts[0].SyncTime__c = syncTime;
        }
        
        plsts[0].CurrentProcessId__c = '';            
        update plsts[0];
    }
    
    global static void ProcessHistoryChanges(List<SObject> historyLogList, String entity, Map<String,String> fieldKey) {                                                       
         
        Map<string, string> mapChangeTypes = new Map<string, string>();     
        Map<string, string> mapChangeTypesToConditionField = new Map<string, string>();             
        
        List<EntityChangeLog__c> entityChangeLogList = new List<EntityChangeLog__c>();
        EntityChangeLog__c entityChangeLog;                                                  
        
        Map<string, string> newchanges = new Map<string, string>();
        
        List<EntityChangeType__c> entityChangeTypes = [Select Id, Name, Field__c, Value__c, ChangeType__c, ConditionField__c FROM EntityChangeType__c 
                                                       WHERE Entity__c =: entity];
		
        //boolean PostJobCancellation = true; //create an entry for job cancellation only for project that are  "In Progress"
        
        for (EntityChangeType__c entityChangeType : entityChangeTypes)
        {
            string changetypekey = '';
            
            //Check for changes looking for a particular value or any        
            if (entityChangeType.Value__c == null)
                changetypekey = entityChangeType.Field__c.toLowerCase();
            else
                changetypekey = entityChangeType.Field__c.toLowerCase() + '-'+ entityChangeType.Value__c.toLowerCase();
            mapChangeTypes.put(changetypekey, entityChangeType.ChangeType__c);
            
            if (entityChangeType.ConditionField__c != null)
                mapChangeTypesToConditionField.put(changetypekey, entityChangeType.ConditionField__c);
        }
        
        for (SObject historyLog : historyLogList)
        { 
            string newValue = historyLog.get('NewValue') == null? '' : string.valueof(historyLog.get('NewValue')).toLowerCase();                       
            
            if (mapChangeTypes.get(string.valueof(historyLog.get('Field')).toLowerCase()) == null && 
                mapChangeTypes.get(string.valueof(historyLog.get('Field')).toLowerCase() + '-'+ newValue) == null )
                continue;                
            
            boolean dateLaunchedValidation = true;
            
            // For some entity we might not need Date Launched check, if dateLaunchedValidation is needed we would need to set it up in the EntityChangeSettings__c
            if (! String.isBlank(fieldKey.get('DateLaunched'))){                 
                dateLaunchedValidation = datetime.valueOf(historyLog.get('CreatedDate')) >= datetime.valueOf(getObjectValue(fieldKey.get('DateLaunched'),historyLog));                
            }            
            
            List<Job__c> jobs;  
            id jobID = Id.valueof(string.valueof(historyLog.get('ParentId')).toLowerCase());
            
            /*if(historyLog.get('ChangeType__c')=='JobCanceled'){
                jobs = [Select Id,ProjectStatus__c,IsCancellable__c  from Job__c WHERE Id = :jobID];            	
                PostJobCancellation = (jobs[0].ProjectStatus__c== constants.PROJECT_STATUS_INPROGRESS && jobs[0].IsCancellable__c == true ? true  : false);                                       
            }*/
            
            
            if (dateLaunchedValidation)                
            {
				string changetypekey = '';
                string changeType = '';
				
                if (mapChangeTypes.get(string.valueof(historyLog.get('Field')).toLowerCase() + '-'+ string.valueof(newValue).toLowerCase()) == null)
                {
                    changetypekey = string.valueof(historyLog.get('Field')).toLowerCase();
                }
                else
                {
                    changetypekey = string.valueof(historyLog.get('Field')).toLowerCase() + '-'+ string.valueof(newValue).toLowerCase();
                }
                
                changeType = mapChangeTypes.get(changetypekey);
                string conditionfield = mapChangeTypesToConditionField.get(changetypekey) == null?'':mapChangeTypesToConditionField.get(changetypekey);
                
                if (!String.isEmpty(conditionfield))
                {
                    Boolean allowLog = false;
                    if (getObjectValue(conditionfield,historyLog) != null && Boolean.valueOf(getObjectValue(conditionfield,historyLog)))
                    {
                        allowLog = true;
                    }
                    
                    //If the condition rule is false, then skip this change.
                    if (!allowLog)
                        continue;
                }
                
                //INSERT UNIQUE CHANGES ONLY for the object and change type                
                if (!newchanges.containskey(string.valueof(historyLog.get('ParentId')) + changeType ))
                {
                    entityChangeLog = new EntityChangeLog__c();
                    entityChangeLog.Entity__c = entity;
                    entityChangeLog.ChangeDateTime__c = datetime.valueOf(historyLog.get('CreatedDate'));
                    entityChangeLog.ChangeType__c = changeType;
                    
                    if (fieldKey.containskey('EntityId')){
                        entityChangeLog.EntityId__c = string.valueOf(getObjectValue(fieldKey.get('EntityId'),historyLog));
                    }
                    
                    if (fieldKey.containskey('JobId')){   
                        entityChangeLog.Job__c = string.valueof(getObjectValue(fieldKey.get('JobId'),historyLog));
                    }
                    
                    if (fieldKey.containskey('ProjectId')){ 
                        entityChangeLog.Project__c = string.valueof(getObjectValue(fieldKey.get('ProjectId'),historyLog));
                    }
                    
                    if (fieldKey.containskey('ProjectServiceId')){ 
                        entityChangeLog.ProjectService__c = string.valueof(getObjectValue(fieldKey.get('ProjectServiceId'),historyLog));
                    }
                    
                    if(fieldKey.containskey('ProjectType')){
                        entityChangeLog.ProjectType__c = string.valueof(getObjectValue(fieldKey.get('ProjectType'),historyLog));
                    }
                                        
                    String uri = AppUtil.EntityChangeLogURI;
                    
                    if(!String.isBlank(uri)){
                        
                        if (fieldKey.containskey('ProjectId')){ 
                            uri = uri + '/Project/' + entityChangeLog.Project__c;
                        }
                        
                        if (fieldKey.containskey('ServiceId')){ 
                            uri = uri + '/Service/' + string.valueof(getObjectValue(fieldKey.get('ServiceId'),historyLog));
                        }
                        
                        if(fieldKey.containskey('JobId')){
                            uri = uri + '/Job/' + entityChangeLog.Job__c;
                        }
                        
                        entityChangeLog.URI__c = uri;
                    }                    
                    
                    entityChangeLog.Status__c = 'Hold';
                    
                    entityChangeLogList.add(entityChangeLog);    
                                                           
                    newchanges.put(string.valueof(historyLog.get('ParentId')) + changeType, string.valueof(historyLog.get('ParentId')) + changeType);
                }
            }
        }
        
        if (entityChangeLogList.size() > 0)        
        {              
            insert entityChangeLogList;                
        }                
    }
   
            
    global static void ProcessHistoryChanges(String entity, Map<String,String> fieldKey,List<SObject> historyLogList) {               
      
        Map<string, string> mapChangeTypes = new Map<string, string>();     
        
        List<EntityChangeLog__c> entityChangeLogList = new List<EntityChangeLog__c>();
        EntityChangeLog__c entityChangeLog;                                                  
        
        Map<string, string> newchanges = new Map<string, string>();
        String entityToProcess;
        
        for (SObject historyLog : historyLogList)
        { 
            
            //When entity changes populate mapChangeTypes with respective EntityChangeType config info
            String key = string.valueof(historyLog.getSObjectType()).replace('__History', '');
            if (entityToProcess != key){
                
                entityToProcess = key;
                
                List<EntityChangeType__c> entityChangeTypes = [Select Id, Name, Field__c, Value__c, ChangeType__c FROM EntityChangeType__c 
                                         WHERE Entity__c =: entity]; //entityChangeTypeMap.get(key);
                for (EntityChangeType__c entityChangeType : entityChangeTypes)
                {
                    //Check for changes looking for a particular value or any        
                    if (entityChangeType.Value__c == null)
                        mapChangeTypes.put(entityChangeType.Field__c.toLowerCase(),entityChangeType.ChangeType__c); 
                    else        
                        mapChangeTypes.put(entityChangeType.Field__c.toLowerCase() + '-'+ entityChangeType.Value__c.toLowerCase(), entityChangeType.ChangeType__c); 
                }
            }  
            
            string newValue = historyLog.get('NewValue') == null? '' : string.valueof(historyLog.get('NewValue')).toLowerCase();                       
            
            if (mapChangeTypes.get(string.valueof(historyLog.get('Field')).toLowerCase()) == null && 
                mapChangeTypes.get(string.valueof(historyLog.get('Field')).toLowerCase() + '-'+ newValue) == null )
                continue;                
            
            boolean dateLaunchedValidation = true;
            
            // For some entity we might not need Date Launched check, if dateLaunchedValidation is needed we would need to set it up in the EntityChangeSettings__c
            if (! String.isBlank(fieldKey.get('DateLaunched'))){                 
                dateLaunchedValidation = datetime.valueOf(historyLog.get('CreatedDate')) >= datetime.valueOf(getObjectValue(fieldKey.get('DateLaunched'),historyLog));                
            }            
                
            if (dateLaunchedValidation)                
            {                
                string changeType = mapChangeTypes.get(string.valueof(historyLog.get('Field')).toLowerCase() + '-'+ string.valueof(newValue).toLowerCase()) == null?
                    mapChangeTypes.get(string.valueof(historyLog.get('Field')).toLowerCase()):mapChangeTypes.get(string.valueof(historyLog.get('Field')).toLowerCase() + '-'+ string.valueof(newValue).toLowerCase());
                
                //INSERT UNIQUE CHANGES ONLY for the object and change type                
                if (!newchanges.containskey(string.valueof(historyLog.get('ParentId')) + changeType ))
                {   
                    entityChangeLog = new EntityChangeLog__c();
                    entityChangeLog.Entity__c = key;
                    entityChangeLog.ChangeDateTime__c = datetime.valueOf(historyLog.get('CreatedDate'));
                    entityChangeLog.ChangeType__c = changeType;
                    entityChangeLog.EntityId__c = string.valueOf(getObjectValue(fieldKey.get('EntityId'),historyLog));
                                        
                    if (fieldKey.containskey('JobId')){   
                        entityChangeLog.Job__c = string.valueof(getObjectValue(fieldKey.get('JobId'),historyLog));
                    }
                    
                    if (fieldKey.containskey('ProjectId')){ 
                        entityChangeLog.Project__c = string.valueof(getObjectValue(fieldKey.get('ProjectId'),historyLog));
                    }
                    
                    if (fieldKey.containskey('ProjectServiceId')){ 
                        entityChangeLog.ProjectService__c = string.valueof(getObjectValue(fieldKey.get('ProjectServiceId'),historyLog));
                    }
                    
                    if(fieldKey.containskey('ProjectType')){
                        entityChangeLog.ProjectType__c = string.valueof(getObjectValue(fieldKey.get('ProjectType'),historyLog));
                    }
                    
                    String uri = AppUtil.EntityChangeLogURI;
                                        
                    if (!string.isEmpty(uri))
                    {
                        if (fieldKey.containskey('ProjectId')){ 
                            uri = uri + '/Project/' + entityChangeLog.Project__c;
                        }
                        
                        if (fieldKey.containskey('ServiceId')){ 
                            uri = uri + '/Service/' + string.valueof(getObjectValue(fieldKey.get('ServiceId'),historyLog));
                        }
                        
                        if(fieldKey.containskey('JobId')){
                            uri = uri + '/Job/' + entityChangeLog.Job__c;
                        }
                        
                        entityChangeLog.URI__c = uri;
                    }
                    
                    entityChangeLog.Status__c = 'Hold';
                    entityChangeLogList.add(entityChangeLog);
                    
                    newchanges.put(string.valueof(historyLog.get('ParentId')) + changeType, string.valueof(historyLog.get('ParentId')) + changeType);
                }
            }
        }
        
        if (entityChangeLogList.size() > 0)        
        {              
            insert entityChangeLogList;                
        }                
    }

    
    global static Object getObjectValue(string feildRef, SObject sobj){       
        
        string[] myArray = feildRef.Split('\\.');
        
        SObject obj = sobj;
        for (Integer i = 0; i < myArray.Size() -  1; i++){
            
            obj = obj.getSobject(myArray[i]);
            
        }
        return obj.get(myArray[myArray.Size() - 1]); 
    }
    
}