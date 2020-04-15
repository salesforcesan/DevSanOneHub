public without sharing class CancelJobExt {
    ApexPages.StandardSetController setCon;
    public String errorMessage {get;set;}
    public job__c j{get;set;}
    public string selVal{get;set;}
    public Project__c projObj{get;set;} 
    public string jobName{get;set;} 
    
    public CancelJobExt(ApexPages.StandardSetController controller) {
        setCon = controller;
        
        if(setCon.getSelected().size()==0)
        {
            errorMessage = 'No Job(s) selected'; 
        }
        else
        {
            j = (job__c)(setCon.getSelected()[0]);
            j = [select name,project__c,Jobcanceledreason__c from job__c where id=: j.id];
            projObj = [select name,status__c, ProjectCancelLeadTime__c from project__c where id=:j.project__c ];
        }    
        getjobName();
    }
    
    public string getjobName() { 
        jobName = '';               
        list<job__c> lstJobs = (list<job__c>)setCon.getSelected();
        for(job__c j: lstJobs)
        {            
            j = [select name,project__c from job__c where id=: j.id];
            jobName = jobName + j.Name + ' , ';
        }
        return jobName;         
    }
   

    
    public pagereference Cancel ()
    {
        Savepoint sp = Database.setSavePoint();        
            
        try
        {
        
                
            string selReason = (string)j.Jobcanceledreason__c;
            list<job__c> lstJobs = (list<job__c>)setCon.getRecords(); 
            
            Set<String> canceledJobsProjectServicesSet = new Set<String>();
            Set<Id> canceledJobsProjectLocationsSet = new Set<Id>();        
           
             
            Set<Id> jobsSet = new Set<Id>();
             
            for(job__c job: lstJobs)
            {
                jobsSet.Add(job.Id);
            }
             
            List<Job__c> cancellableJobs = [select id, name, JobStatus__c, Jobcanceledreason__c, ProjectLocation__c, ProjectService__c, JobStartDate__c from job__c where Id in :jobsSet and JobStatus__c != 'Completed' and jobstartdate__c > :Date.Today().addDays(Integer.ValueOf(projObj.ProjectCancelLeadTime__c))];                     


            for(job__c job: cancellableJobs)
            {
                job.JobStatus__c = 'Canceled';
                job.JobCanceledReason__c = selReason ;
                canceledJobsProjectServicesSet.Add(String.valueOf(job.ProjectService__c).substring(0, 15));
                canceledJobsProjectLocationsSet.Add(job.ProjectLocation__c);
            }
            
            
            
            TriggerUtil.SkipAllTriggers();
             
            update cancellableJobs;    

            
            
        }
        
        catch(Exception ex){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, ex.getMessage()));
            Database.rollback(sp);
            return null;
        }
        
        PageReference cancel = setCon.cancel();        
        return cancel;         
    }
    
    public pagereference DoNotCancel()
    {
        PageReference cancel = setCon.cancel();        
        return cancel;
    }
    
    
}