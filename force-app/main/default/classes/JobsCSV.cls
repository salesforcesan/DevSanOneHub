public with sharing class JobsCSV {

    Map<String, Integer> JobKeyIndexMap {get;set;}
    List<Job__c> Jobs {get;set;}
    List<ProjectLocation__c> ProjectLocations {get;set;}
    List<ProjectService__c> ProjectServices {get;set;}

    public String get(string projectId) {
        loadProjectServices(projectId);
        loadProjectLocations(projectId);
        loadJobs(projectId);
        setJobKeyIndexMap();
        return exportJobs();
    }

    void loadProjectServices(String projectId){
        this.ProjectServices =[SELECT ID,Name, ProjectNumber__c, ServiceName__c,ServiceTitle__c 
            FROM ProjectService__c  WHERE Project__c = :projectId AND Status__c != 'Canceled'];     
        if(this.ProjectServices.size() == 0)        
        {
            throw new AuraHandledException('there are no services for this project to export the  jobs');
        }
    }

    void loadProjectLocations(string projectId){
        this.ProjectLocations =[SELECT ID,Name,LocationName__c,State__c, City__c,LocationNumber__c,
            Location__r.Banner__c FROM  ProjectLocation__c  
            WHERE  Project__c = :projectId AND Status__c != 'Canceled'
            ORDER BY Location__r.Banner__c, LocationNumber__c LIMIT 10000];
        if(this.ProjectLocations.size() == 0){
            throw new AuraHandledException('There are no valid project locations.');
        }
    }

    void loadJobs(String projectId) {
        this.Jobs = [Select id, EstimatedMinutes__c, ProjServiceName__c,ProjLocationName__c,
            AccountableExecutionCompany__r.Name,NumberOfWorkers__c,JobStartDate__c,JobStartTime__c, 
            ProjectService__c,ProjectLocation__c, PurchaseAmount__c,Name,JobScheduledDate__c 
            from Job__c WHERE Project__c = :projectId  
            AND JobStatus__c !='Canceled'
            AND ProjectService__c IN (SELECT Id from ProjectService__c WHERE Project__c=:projectId 
            AND Status__c != 'Canceled') 
            AND ProjectLocation__c IN (SELECT Id from ProjectLocation__c WHERE Project__c=:projectId 
            AND Status__c != 'Canceled') LIMIT 200000];
    }

    void setJobKeyIndexMap(){        
        this.JobKeyIndexMap = new Map<string,Integer>();
        Integer count = this.Jobs.size();
        Job__c job;

        for(Integer i=0; i < count; i++)
        {
            job = this.Jobs.get(i);
            this.JobKeyIndexMap.put(genUniqueKey(job.ProjectService__c,job.ProjectLocation__c), i);
        }
    }

    static String genUniqueKey(Id psId, Id plId){
        return String.valueOf(psId) + String.valueOf(plId);
    }

    String exportJobs(){
        List<String> data = new  List<String>();
        data.add('"Project Service","Service Title","Project Location","State","City","Location Number","Banner","Job","Number Of Workers","Job Start Date","Job Start Time","Purchase Amount"');
        for(ProjectLocation__c pl :this.ProjectLocations)
        {
            for(ProjectService__c ps :this.ProjectServices) 
            {                
                data.add(transformJobs(ps,pl));
            }
        }
        return  String.join(data,'\n');
    }

    String transformJobs(ProjectService__c ps ,ProjectLocation__c pl){
        Job__c job;
        List<String> rec = new List<String>();
        string uniqueKey = genUniqueKey(ps.Id, pl.Id);

        rec.add('"' + ps.name + '"');
        rec.add('"' + ps.ServiceTitle__c + '"');
        rec.add('"' + pl.name + '"');
        rec.add('"' + pl.State__c + '"');
        rec.add('"' + pl.City__c + '"');
        rec.add('"' + pl.LocationNumber__c + '"');
        rec.add('"' + pl.Location__r.Banner__c + '"');
        
        if (this.JobKeyIndexMap.size() == 0 || !this.JobKeyIndexMap.containsKey(uniqueKey)){
            rec.add('""');
            rec.add('""');
            rec.add('""');
            rec.add('""');
            rec.add('""');
            return String.join(rec,',');
        } 

        job = this.Jobs.get(this.JobKeyIndexMap.get(uniqueKey));
        rec.add('"' + (String.isBlank(job.Name) ? '' : job.Name) + '"');
        rec.add('"' + (String.isBlank(String.valueOf(job.NumberOfWorkers__c)) ? '' : String.valueOf(job.NumberOfWorkers__c)) + '"');
        rec.add('"' + (job.JobStartDate__c != null ? String.valueOf(job.JobStartDate__c) : '') + '"');
        rec.add('"' + (String.isBlank(job.JobStartTime__c) ? '' : job.JobStartTime__c) + '"');
        rec.add('"' + (String.isBlank(String.valueOf(job.PurchaseAmount__c)) ? '': String.valueOf(job.PurchaseAmount__c)) + '"');
        return String.join(rec,',');
    }
}