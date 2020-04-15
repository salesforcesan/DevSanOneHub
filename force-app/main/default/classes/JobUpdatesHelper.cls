public class JobUpdatesHelper {
    public static void createJobMaterials(List<Job__c> jobs, List<ProjectServiceMaterial__c> psmList) {
        system.debug('IN createJobMaterials:::: ' + jobs.size());
        system.debug('IN psmList:::: ' + psmList.size());
        if(jobs.size() > 0) {
            
            List<Job__c> jobsp = [Select Id, DayNumber__c, ProjectService__c FROM Job__c WHERE Id IN :jobs];
            List<JobMaterial__c> jmList = new List<JobMaterial__c>();
            for (Job__c job: jobsp) {
                
                for (ProjectServiceMaterial__c psm: psmList) {
                    if(psm.ProjectService__c  == job.ProjectService__c){
                        JobMaterial__c jm = new JobMaterial__c();
                        jm.Job__c = job.Id;
                        jm.Material__c = psm.Material__c;
                        jm.ProjectServiceMaterial__c = psm.id;
                        jm.Status__c = 'Pending';
                        jmList.add(jm);
                    }
                }
            }
            TriggerUtil.skipJobTrigger = true;
            system.debug('IN jmList.size():::: ' + jmList.size());
            if(jmList.size()>0){
                insert jmList;               
            }
        }
    }
    
    public static void createJobMaterials(List<Job__c> jobs, ProjectServiceMaterial__c psm) {
        createJobMaterials(jobs, new List<ProjectServiceMaterial__c>{ psm });
    }
    
    public static Set<String> createJobRelatedRecords(Id[] jobIds, Set<String> materalAddedJobs) {
        
        //Create materials only for the first day in
        //a multi day job

        Job__c[] jobs = [SELECT Id, JobStatus__c, ProjectService__c, ProjectLocation__c, Project__c, Project__r.Status__c 
                         FROM Job__c WHERE Id IN :jobIds];

        if (!jobs.isEmpty()) {
            List<JobMaterial__c> jmList = new List<JobMaterial__c>();
            Set<Id> projectIds = new Set<Id>();
            Map<Id, ProjectServiceMaterial__c[]> projectIdToServiceMaterials = new Map<Id, ProjectServiceMaterial__c[]>();

            for (Job__c job : jobs) projectIds.add(job.Project__c);
            for (ProjectServiceMaterial__c psm : [SELECT Id, Material__c, ProjectService__c, ProjectService__r.Project__c FROM ProjectServiceMaterial__c WHERE ProjectService__r.Project__c IN :projectIds]) {

                Id projId = psm.ProjectService__r.Project__c;
                if (!projectIdToServiceMaterials.containsKey(projId)) projectIdToServiceMaterials.put(projId, new ProjectServiceMaterial__c[]{});
                projectIdToServiceMaterials.get(projId).add(psm);
            }
            
            for (Job__c job : jobs) {
                if (projectIdToServiceMaterials.containsKey(job.Project__c)) {
                    for (ProjectServiceMaterial__c psm : projectIdToServiceMaterials.get(job.Project__c)) {
                        if(psm.ProjectService__c  == job.ProjectService__c){
                            JobMaterial__c jm = new JobMaterial__c();
                            jm.Job__c = job.Id;
                            jm.Material__c = psm.Material__c;
                            jm.ProjectServiceMaterial__c = psm.id;
                            jm.Status__c = 'Pending';
                            jmList.add(jm);
                        }
                    }
                }
            }
			TriggerUtil.skipJobTrigger = true;
            if(jmList.size()>0){
                insert jmList;               
            }
        }
        
        return materalAddedJobs;
    }

 
    public static Integer getJobUpdateBatchHandlerBatchSize(Project__c[] projects) {
        Integer psmCount = [SELECT count() FROM ProjectServiceMaterial__c WHERE ProjectService__r.Project__c IN :projects];
        if(psmCount == 0){
            return 2000;
        }
        Integer batchSize = 10000/psmCount;
        return batchSize < 2000 ? batchSize : 2000;
    }
    
    public static Integer getJobUpdateBatchHandlerBatchSize(Project__c p) {
		Integer psmCount = [SELECT count() FROM ProjectServiceMaterial__c WHERE ProjectService__r.Project__c = :p.Id];
        if(psmCount == 0){
            return 2000;
        }
        Integer batchSize = 10000/psmCount;
        return batchSize < 2000 ? batchSize : 2000;
    }
}