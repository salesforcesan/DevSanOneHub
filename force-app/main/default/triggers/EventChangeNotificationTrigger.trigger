trigger EventChangeNotificationTrigger on EventChangeNotification__e (after insert) {

    Map<String, JobAttempt__c> jas = new Map<String, JobAttempt__c>(); 
    Map<String,String> jobstatusMap = new Map<String,String>();
    // Iterate through each notification.
    for (EventChangeNotification__e en : Trigger.New) 
    {
        switch on en.EventType__c {
            when 'Status' {     
                if (en.EntityType__c.Trim().toLowerCase() == 'job')
                {
                    jobstatusMap.put(en.EntityId__c,en.EventParameter__c);
                    
                }
                
            }   
        }            
    }
    system.debug('JS Map: ' + jobstatusMap);
    if (!jobstatusMap.isEmpty())    
    {
        List<JobAttempt__c> jas = [Select Id, Name, AttemptStatus__c, Job__r.Name FROM JobAttempt__c WHERE IsActive__c = True AND Job__r.Name in :jobstatusMap.keySet()];

        if (!jas.isEmpty())        
        {
            for (JobAttempt__c ja : jas)
            {
                ja.AttemptStatus__c = jobstatusMap.get(ja.Job__r.Name);
            
            }
            update jas;
        }
    }

}