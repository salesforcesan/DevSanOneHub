public with sharing class JobCSVModel {
    public static final string IMPORT_JOB_ATTACHMENT_NAME = '%import_jobs%';
    public static final string PROJECT_ID_MISSING = 'The project Id is missing.';
    public static final string PROJECT_NOT_FOUND = 'The project cannot be found.';
    public static final String PROJECT_IMPORT_PENDING = 'The project is pending for job import.';
    public static final String PROJECT_APEX_JOBNAME = 'Import Job';

    Project__c ProjectInstance {get;set;}

    private JobCSVModel(string prjId) {
    	this.checkAndInitProject(prjId);
    }

    public static JobCSVModel createInstance(String projectId){
        return new JobCSVModel(projectId);
    }

    public void endImport(){
        this.checkCanImportJob();

        this.ProjectInstance.PendingJobImportRequest__c = true;
        this.ProjectInstance.ApexJobName__c = PROJECT_APEX_JOBNAME;
        TriggerUtil.SkipProjectTrigger = true;
        update this.ProjectInstance;
        if(!Test.isRunningTest()){
            JobActionsHelper.invokeJobImportBatch(this.ProjectInstance.Id);
        }
    }

    public void startImport(){
        this.checkCanImportJob();
        this.deleteAttachments();
    }

    void checkCanImportJob(){ 
        if(this.ProjectInstance.PendingJobImportRequest__c == true){
            throw new AuraHandledException(PROJECT_IMPORT_PENDING);
        }
    }

    public void deleteAttachments(){
        Id projectId = this.ProjectInstance.Id;
        List<Attachment> attachments= [SELECT Id FROM Attachment WHERE  ParentId=:projectId AND Name=:IMPORT_JOB_ATTACHMENT_NAME];
        if(attachments.size() > 0){
            delete attachments;
        }
    }

    public void importJobs(List<String> jobs){
        this.checkCanImportJob();
        
        Attachment att = new Attachment();
        att.ParentId = this.ProjectInstance.Id;
        att.Body = Blob.valueOf(JSON.serialize(jobs));
        att.ContentType = 'application/json';
        att.Name = IMPORT_JOB_ATTACHMENT_NAME;

        DataBase.SaveResult result = Database.Insert(att);
        if(!result.isSuccess()){
            throw new AuraHandledException(getError(result));
        }
    }

    String getError(Database.SaveResult result){
        List<String> errors = new List<string>();
        errors.add('Failed to insert attachment.');
        for(Database.Error e: result.getErrors()){
            errors.add(e.getMessage());
        }
        return String.join(errors, ' ');
    }

    void checkAndInitProject(String prjId){
        if(String.isBlank(prjId)){
            throw new AuraHandledException(PROJECT_ID_MISSING);
        }

        List<Project__c> projects = [SELECT Id, PendingJobImportRequest__c, ApexJobName__c FROM Project__c WHERE Id=:prjId];
        if(projects.size() == 0){
            throw new AuraHandledException(PROJECT_NOT_FOUND);
        }

        this.ProjectInstance = projects.get(0);
    }
}