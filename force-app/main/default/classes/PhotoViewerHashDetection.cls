public with sharing class PhotoViewerHashDetection {
    Map<Id, JobImage__c> results;
    List<JobImage__c> dataset;
    Set<String> inHashes;
    Set<Id> scopeIds;
    Set<Id> projectsForTaskCreation;
    Set<Id> projectIds;

	private PhotoViewerHashDetection(List<JobImage__c> scope) {
	
       this.inHashes = new Set<String>();
       this.projectsForTaskCreation = new Set<Id>();
       this.dataset = new List<JobImage__c>(scope);       
       this.scopeIds = new Set<Id>();

       for(JobImage__c img: scope) {
           this.scopeIds.add(img.Id);
           this.inHashes.add(img.PhotoHash__c);
       }
   }

    public static PhotoViewerHashDetection create(List<JobImage__c> images){
        return new PhotoViewerHashDetection(images);
    }

    public void run() {
        if (this.dataset.size() == 0){
            return;
        }

        addOutOfScopeDupsToDataset();
        findDupInDataset();
        doBatchUpdate();
        createProjectTasks(this.projectIds);
    }

    void addOutOfScopeDupsToDataset(){
        this.dataset.addAll(findDupAgainstOutOfScope());
    }

    void doBatchUpdate(){
        if(this.results.size() == 0){return;}
        update this.results.values();
    }

    void findDupInDataset(){

        List<JobImage__c> sourceToDup;
        JobImage__c img0;
        JobImage__c img1;
        boolean isDup;

        this.results = new Map<Id,JobImage__c>();
        this.projectIds = new Set<Id>();

        while(this.dataset.size() > 0){
            sourceToDup = new List<JobImage__c>();
            isDup = false;
            img0 = this.dataset.get(0);
            for(integer i=1; i < this.dataset.size(); i++) {
                img1 = this.dataset.get(i);
                if(img1.PhotoHash__c == img0.PhotoHash__c){
                    isDup = true;
                    this.results.put(img1.Id, genImage(img1.Id, true));
                    this.projectIds.add(img1.project__c);
                } else {
                    sourceToDup.add(img1);
                }
            }
            this.results.put(img0.Id, genImage(img0.id,isDup));

            if(isDup){
                this.projectIds.add(img0.Project__c);
            }

            this.dataset = sourceToDup;
        }
    }

    JobImage__c genImage(Id objId, boolean isDup){
        return new JobImage__c(
                Id = objId,
                IsDuplicated__c = isDup,
                PoorQualityCheck__c = isDup,
                Processed__c = true
            );
    }

    List<JobImage__c> findDupAgainstOutOfScope(){
       Set<Id> ids = this.scopeIds;
       Set<String> hashes = this.inHashes;

       return [SELECT Id, PhotoHash__c, IsDuplicated__c, Project__c FROM JobImage__c WHERE Id NOT IN :ids AND PhotoHash__c IN :hashes];
   }

   void createProjectTasks(Set<Id> projects){
       Set<Id> idsWithoutTask = this.findProjectsWithoutTask(projects);
       List<Task> tasks = new List<Task>();
       for(Id pid: idsWithoutTask){
           Task t = new Task();
           t.WhatId = pid;
           t.Subject = 'Duplicate photo Detected';
           t.Description = 'Duplicate photo Detected';
           tasks.add(t);
       }
       if(tasks.size() > 0){
           insert tasks;
       }
   }

   Set<Id> findProjectsWithoutTask(Set<Id> projects){
       Set<Id> idsHasTask = new Set<Id>();
       for(Task t: [SELECT WhatId FROM Task WHERE WhatId IN :projects AND Status != 'Completed']){
           if(t.WhatId != null){
               idsHasTask.add(t.WhatId);
           }
       }
       Set<Id> results = new Set<Id>();
       for(Id pid: projects){
           if(!idsHasTask.contains(pid)){
               results.add(pid);
           }
       }
       return results;
   }

}