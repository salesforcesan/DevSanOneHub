public class JobCommentTriggerHandler extends TriggerHandler {
    
    public override void beforeInsert(){

        set<Id> jobAttemptIds = new set<Id>();
        for (JobComment__c ji :(List<JobComment__c> ) Trigger.new) {
             if(!(string.isEmpty(ji.JobAttempt__c)))
             {
              	jobAttemptIds.add(ji.JobAttempt__c); 
             }
                        
        }
        
        Map<Id,JobAttempt__c> jobattemptMap = new Map<Id,JobAttempt__c>([Select Id,name,Job__c,Job__r.ProjectLocation__c, job__r.Project__c, Job__r.ProjectService__c   from JobAttempt__c where Id IN : jobAttemptIds]);
        
        for(Jobcomment__c jc :(List<JobComment__c> ) Trigger.new)
        {
            if(jobattemptMap.containsKey(jc.JobAttempt__c)){
                
                jc.Job__c = jobattemptMap.get(jc.JobAttempt__c).Job__c;
                jc.ProjectLocation__c = jobattemptMap.get(jc.JobAttempt__c).Job__r.ProjectLocation__c;
                jc.Project__c = jobattemptMap.get(jc.JobAttempt__c).Job__r.Project__c;
                jc.ProjectService__c = jobattemptMap.get(jc.JobAttempt__c).Job__r.ProjectService__c;
            }
               
        }
      
   }
}