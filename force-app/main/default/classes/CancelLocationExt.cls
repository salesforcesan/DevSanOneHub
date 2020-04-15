public without sharing class CancelLocationExt {
    ApexPages.StandardSetController setCon;
    public String errorMessage {get;set;}
    public ProjectLocation__c locationObj{get;set;}
    public string locationName{get;set;}
    public Project__c projObj{get;set;} 
    
    public CancelLocationExt(ApexPages.StandardSetController controller) {
        setCon = controller;
        locationObj=new ProjectLocation__c();
        if(setCon.getSelected().size()==0)
        {
            errorMessage = 'No locations selected'; 
        }
        else
        {
            ProjectLocation__c loc = (ProjectLocation__c)(setCon.getSelected()[0]);
            loc = [select name,project__c from ProjectLocation__c where id=: loc.id];
            projObj = [select name, status__c,ProjectCancelLeadTime__c from project__c where id=:loc.project__c ];
        }    
        getlocationName();
    }
    
    
    public string getlocationName() {                
        locationName='';
        list<ProjectLocation__c> lstlocations = (list<ProjectLocation__c>)setCon.getSelected();

        
        for(ProjectLocation__c j: lstlocations)
        {            
            j = [select name,project__c from ProjectLocation__c where id=: j.id];
            locationName = locationName + j.Name + ' , ';
        }
        return locationName;         
    }
    
    
    
    
    public pagereference cancel()
    {
    
        Savepoint sp = Database.setSavePoint();        
        try{
        
            string selReason = (string)locationObj.CancelReason__c;
            list<ProjectLocation__c> lstlocations = (list<ProjectLocation__c>)setCon.getRecords(); 
            String projstatus = [select project__r.status__c from ProjectLocation__c where id=:lstlocations[0].id limit 1].project__r.status__c ;
            
            
            
            Set<Id> executedprojectLocationsSet = new Set<Id>();
            Set<String> canceledJobsProjectServicesSet = new Set<String>();
            Set<Id> canceledJobsProjectLocationsSet = new Set<Id>();        
            
                    
            for(ProjectLocation__c loc: lstlocations)
            {
                canceledJobsProjectLocationsSet.add(loc.Id);
            
            }
    
            
            List<Job__c> cancellableJobs = [select id, name, jobStatus__c, Jobcanceledreason__c, ProjectLocation__c, ProjectService__c, JobStartDate__c from job__c where Project__c =: projObj.Id  and projectlocation__c in :canceledJobsProjectLocationsSet and jobStatus__c != 'Completed' and jobstartdate__c > :Date.Today().addDays(Integer.ValueOf(projObj.ProjectCancelLeadTime__c))];            
            List<Job__c> executedJobs = [select id, name, jobStatus__c, Jobcanceledreason__c, ProjectLocation__c, ProjectService__c from job__c where Project__c =: projObj.Id  and projectlocation__c in :canceledJobsProjectLocationsSet and (jobStatus__c = 'Completed' OR jobstartdate__c <= :Date.Today().addDays(Integer.ValueOf(projObj.ProjectCancelLeadTime__c)))];                        
    
    
            for(job__c job: cancellableJobs )
            {
                job.jobStatus__c = 'Canceled';
                job.Jobcanceledreason__c= selReason ;
                job.JobDateCanceled__c = Date.Today();
                canceledJobsProjectServicesSet.Add(String.valueOf(job.ProjectService__c).substring(0, 15));
            }
    
            for(job__c job: executedJobs )
            {
                executedprojectLocationsSet.Add(job.ProjectLocation__c);
            }
            
            canceledJobsProjectLocationsSet.RemoveAll(executedprojectLocationsSet);
            
            List<ProjectLocation__c> cancellableProjectLocations = [Select Id, Name, Status__c, CancelReason__c from ProjectLocation__c where Id in :canceledJobsProjectLocationsSet];        
            
            for(ProjectLocation__c loc:cancellableProjectLocations)
            {            
                loc.Status__c = 'Canceled';
                loc.CancelReason__c = selReason ;
            }
            
            
            TriggerUtil.SkipAllTriggers();    
            update cancellableJobs ;            
            update cancellableProjectLocations;
            
            //projObj.ReservedLocationsCount__c = [SELECT count() FROM ProjectLocation__c WHERE Project__c =: projObj.Id and Status__c = 'Booked'];
            update projObj; 
            
        }
        catch(Exception ex){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, ex.getMessage()));
            Database.rollback(sp);
            return null;
        }

        PageReference cancel = setCon.cancel();        
        system.debug('cancel::'+cancel);
        return cancel;           
    
        
    }
    
    public pagereference DoNotCancel()
    {
        /*PageReference cancel = setCon.cancel();        
        return cancel;*/
        
        PageReference pageRef  = new ApexPages.StandardController(projObj).view();
        pageRef.setRedirect(true);
        return pageRef;
        
    }

    
}