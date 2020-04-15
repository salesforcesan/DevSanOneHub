//no one use this classs
global class Project{
  
    webservice static void DeleteAllLocations(string projectId){ 
    
        String pid = projectId.trim();
        List<Job__c> jobList = [SELECT Id, Name from Job__c where Project__c = :pid];
        List<ProjectLocation__c> plList = [SELECT Id, Name from ProjectLocation__c where Project__c = :pid];
        TriggerUtil.SkipAllTriggers();        
        delete jobList;
        delete plList;

    }
    
    webservice static void DeleteService(string projectId){ 
        List<ProjectService__c> psList = [SELECT Id from ProjectService__c where Project__c = :projectId];
        TriggerUtil.SkipAllTriggers();        
        delete psList;
    }
    
    webservice static void DeleteSelectedPS(String ProjServID){ 
        List<String> csvList = ProjServID.split(',') ;
        List<ProjectService__c> psList = [SELECT Id,project__c from ProjectService__c where id in :csvList ];
        Id[] PSIDArr =new List<Id>(new Map<Id, ProjectService__c>(psList).keySet());
        TriggerUtil.SkipAllTriggers();        
       
        project__c project = [select ApexJobName__c,BatchProcessId__c, RecordTypeId
                              from project__c where id=:psList[0].project__c ];
        //delete jobs
        system.debug('  ~~~PSIDArr~~~   '+ PSIDArr);
        List<Job__c> jobs = [select id from job__c where Projectservice__c IN: PSIDArr];
        Id[] JobIDArr =new List<Id>(new Map<Id, job__c>(jobs).keySet());
        
        system.debug('  ~~~JobIDArr~~~   '+ JobIDArr.size());
        
        if(JobIDArr.size()<JobActionsHelper.JOB_BATCH_SIZE )
            JobActionsHelper.deleteJobs(JobIDArr); 
         else{
             system.debug('  ~~~calling batch~~~   ');
             Id batchJobId = Database.executeBatch(new BatchDeleteJobs(JobIDArr), 200);
             ProjectActionsHelper.LockProject(project, 'Delete Service(s)', batchJobId);
             update project;
         }
         delete psList;
    } 
    
 }