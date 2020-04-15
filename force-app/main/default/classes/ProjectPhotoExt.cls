global with sharing class ProjectPhotoExt {
    static Boolean isTest;
    global Project__c projectRecord {get;private set;}
    public List<ProjectService__c> services {get; private set;}
    global Cloudinary_Setting__mdt cloudinarySettings {get; private set;}

    static {
        Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
        Schema.SObjectType obj = gd.get('Job_Survey_Answer__x');
        isTest = (obj !=  null) ? false : true;
    }

    global ProjectPhotoExt(ApexPages.StandardController stdController) {
        //Get Project Name for photo title
        this.projectRecord = (Project__c)stdController.getRecord();
        projectRecord = [SELECT Id, Name FROM Project__c WHERE id =: projectRecord.Id];
        services = [SELECT Service__c, Name, ServiceName__c FROM ProjectService__c WHERE Project__c=:ProjectRecord.Id];
        //Get API Settings
        //Retrieve Cloudinary Cloud Name and API Key from Cloudinary_Setting__mdt
        cloudinarySettings = [SELECT Id, DeveloperName, Cloud_Name__c, API_Key__c FROM Cloudinary_Setting__mdt WHERE DeveloperName = 'Global'];     
    }

    static String getString(Map<String,String> args, String key){
        Object val = args.get(key);
        return getString(val);
    }

    static String getString(Object obj){
        return (obj != null) ? String.valueOf(obj) : '';
    }

    static String getName(Object lastName, Object firstName){
        String f = getString(firstName), l = getString(lastName);
        if (String.isBlank(f) && String.isBlank(l)){
            return 'n/a';
        }
        return f + ', ' + l;
    }
    
    @RemoteAction
    global static Map<String,String> getPhotoDetail(Map<String,String> query) {
        Map<String,String> res = new Map<String,String>();
        String jobId = getString(query,'jobId');
        if (String.isBlank(jobId)){
            return res;
        }
        Job__c job = [SELECT Name, 
            ReportedContactFirstName__c, 
            ReportedContactLastName__c, 
            ReportedContactId__c,
            ReportedContactTitle__c,
            ReportedEmployeeId__c,
            Location__r.LocationNumber__c,
            Location__r.Address__c,
            Location__r.City__c, 
            Location__r.State__c,
            Location__r.PostalCode__r.Name
            FROM Job__c WHERE Id=:jobId];
        if (job != null){
            res.put('workerName', getName(job.ReportedContactFirstName__c, job.ReportedContactLastName__c));
            res.put('workerTitle', job.ReportedContactTitle__c);
            res.put('workerEmployeeId', job.ReportedEmployeeId__c);
            res.put('workerContactId', job.ReportedContactId__c);
            res.put('jobNumber', job.Name);
            res.put('jobLocationNumber', job.Location__r.LocationNumber__c);
            res.put('jobAddress', job.Location__r.Address__c);
            res.put('jobCity', job.Location__r.City__c);
            res.put('jobState', job.Location__r.State__c);
            res.put('jobPostalCode', job.Location__r.PostalCode__r.Name);
        }
        String questionId = getString(query, 'questionId');
        if (String.isBlank(questionId)) {
            return res;
        }
        Question__c q = [SELECT QuestionText__c FROM Question__c WHERE Id =:questionId];
        if (null != q){
            res.put('photoQuestion', q.QuestionText__c);
        }

        return res;
    }

    @RemoteAction
    global static List<String[]> searchPhotos(Map<String,String> query){
        String projectId = getString(query,'projectId');
        if (String.isBlank(projectId)){
            throw new ProjectPhotoException('ProjectId can\'t be empty.');
        }

        String serviceId = getString(query, 'serviceId');
        String locations = getString(query,'locations');
        if(String.isBlank(serviceId)){
            throw new ProjectPhotoException('Please select one service.');
        }

        if(String.isBlank(locations)){
            return getPhotosByService(projectId, serviceId);
        }

        return getPhotosByServiceLocations(projectId, serviceId, locations);
    }

    static List<String[]> getPhotosByService(String projectId, String serviceId){
        Set<Id> jobIds = getRelatedJobsByProjectService(projectId, serviceId);
        Set<Id> questionIds = getRelatedQuestionsByProjectService(projectId, serviceId);
        return getPhotos(jobIds, questionIds);
    }

    static List<String[]> getPhotosByServiceLocations(String projectId, String serviceId, String locations){
        set<Id> relatedJobs = getRelatedJobsByProjectServiceLocations(projectId, serviceId, locations);
        set<Id> questionIds = getRelatedQuestionsByProjectService(projectId, serviceId);
        return getPhotos(relatedJobs, questionIds);
    }

    static Set<Id> getRelatedJobsByProject(String projectId) {
        Id pId = Id.valueOf(projectId);
        return (new map<Id,Job__c>([SELECT Id from Job__c WHERE Project__c = :pId])).keyset();
    }

    static Set<Id> getRelatedJobsByProjectService(String projectId, String serviceId) {
        Id pId = Id.valueOf(projectId),
            sId = Id.valueOf(serviceId);
        return (new map<Id, Job__c>([SELECT Id from Job__c WHERE Project__c = :pId AND Service__c=:sId])).keyset();
    }

    static Set<Id> getRelatedJobsByProjectServiceLocations(String projectId, String serviceId, String locations) {
        Id pId = Id.valueOf(projectId);
        Id sId = Id.valueOf(serviceId);
        Set<String> locIdSet = getLocNumSet(locations);
        return (new map<Id, Job__c>([SELECT Id from Job__c WHERE Project__c = :pId  AND Service__c=:sId AND LocationNumber__c in :locIdSet])).keyset();
    }

    static set<String> getLocNumSet(String locations){
        String tmp = locations + '';
        Set<String> locIdSet = new Set<String>();
        for(String loc: tmp.split(',')){
            locIdSet.add(loc.trim());
        }
        return locIdSet;
    }

    static Set<Id> getRelatedQuestionsByProject(String projectId){
        Set<Id> result = new Set<Id>();
        String photoType = 'Photo';
        Id pId = Id.valueOf(projectId);
        for(ProjectServiceQuestion__c q: [SELECT Question__c from ProjectServiceQuestion__c WHERE ProjectService__r.Project__c = :pId AND QuestionType__c =:photoType]){
            result.add(q.Question__c);
        }
        return result;
    }

    static Set<Id> getRelatedQuestionsByProjectService(String projectId, String serviceId){
        Id pId = Id.valueOf(projectId),
            sId = Id.valueOf(serviceId);
         Set<Id> result = new Set<Id>();
        String photoType = 'Photo';
        for(ProjectServiceQuestion__c q: [SELECT Question__c from ProjectServiceQuestion__c WHERE ProjectService__r.Project__c = :pId AND ProjectService__r.Service__c=:sId AND QuestionType__c =:photoType]){
            result.add(q.Question__c);
        }
        return result;
    }

     static List<String[]> getPhotosByTable(Set<Id> jobIds, Set<Id> questionIds, String tableName){
        List<String[]> res = new List<String[]>();
        String dt;
         String sql = 'SELECT job__c, response__c, question__c, date_modified__c FROM ' + tableName + ' WHERE question__c in :questionIds and job__c in :jobIds LIMIT 10000';
        try {
            //todo need to replace Job_Survey_Answer__c to Job_Survey_Answer__x
            for(sObject o: database.query(sql)){
            dt = o.get('date_modified__c') != null ? Datetime.valueOf(o.get('date_modified__c')).format('MM/dd/YYYY'): '';
            res.add(new String[]{
                (String)o.get('response__c'),
                (String)o.get('job__c'),
                (String)o.get('question__c'),
                dt
                });
          }    
        }catch(Exception e){
            System.debug('The following exception has occurred: ' + e.getMessage());
            throw new ProjectPhotoException(e.getMessage());
        }
        return res;
    }

    static List<String[]> getPhotos(Set<Id> jobIds, Set<Id> questionIds){
        String table = (isTest) ? 'Job_Survey_Answer__c' : 'Job_Survey_Answer__x';
        return getPhotosByTable(jobIds, questionIds, table);
    }

    //notice: this API is deprecated. do not use it. use getPhotoUrls to get data
    @RemoteAction
    @ReadOnly
    global static String[] PhotoURLs(String projectId) {
        return new String[] {};
    }
    
    @RemoteAction
    @ReadOnly
    global static List<String[]> getPhotoURLs(String projectId){
        set<Id> relatedJobs = getRelatedJobsByProject(projectId);
        set<Id> questionIds = getRelatedQuestionsByProject(projectId);
        return getPhotos(relatedJobs, questionIds);
    }
    global class ProjectPhotoException extends Exception {} 
}