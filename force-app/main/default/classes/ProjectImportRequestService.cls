public virtual with sharing class ProjectImportRequestService implements IImportRequestService {

    public static final string PROJECT_ID_MISSING = 'The project Id is missing.';
    public static final string PROJECT_NOT_FOUND = 'The project cannot be found.';
    public static final String PROJECT_IMPORT_PENDING = 'The project is pending for job import.';
    
    public String ProjectId {get; private set;}

    Project__c ProjectInstance {get; private set;}
    String AttachmentName {get; private set;}
    String JobName {get; private set;}

    public ProjectImportRequestService(){
        this.ProjectInstance = null;
    }

    void initProjectInstance(String projectId){
         if(String.isBlank(projectId)){
            throw new AuraHandledException(PROJECT_ID_MISSING);
        }

        List<Project__c> projects = [SELECT Id, PendingBulkImport__c, ApexJobName__c FROM Project__c WHERE Id=:projectId];
        if(projects.size() == 0){
            throw new AuraHandledException(PROJECT_NOT_FOUND);
        }

        this.ProjectInstance = projects.get(0);
    }

    public virtual void init(String parentId, String attachmentName, String jobName) {
        this.AttachmentName = attachmentName;
        this.JobName = jobName;
        this.ProjectId = parentId;
    }

    public String getId(){
        return this.ProjectId;
    }

    public virtual String getImportTitles() {
        return '';
    }

    public virtual Integer getChunkSize() {
        return 5000;
    }

    public String getAttachmentName() {
        return this.AttachmentName;
    }
    
    public String getJobName() {
        return this.JobName;
    }

    public virtual String getBulkImportType(){
        return '';
    }

    public virtual void canImport() {
        
        if(this.ProjectInstance == null){
            this.initProjectInstance(this.ProjectId);
        }

        if(!String.isBlank(this.ProjectInstance.PendingBulkImport__c)) {
            throw new AuraHandledException(PROJECT_IMPORT_PENDING);
        }
    }

    public virtual void afterImport() {
        TriggerUtil.SkipProjectTrigger = true;
        this.ProjectInstance.PendingBulkImport__c = this.getBulkImportType();
        this.ProjectInstance.ApexJobName__c = this.JobName;
        Database.SaveResult result  = Database.update(this.ProjectInstance);
        if(!result.isSuccess()){
            throw new AuraHandledException(genError(result));
        }
    }

    static String genError(Database.SaveResult sr){
        List<String> errors = new List<String>();
        for(Database.Error err : sr.getErrors()){
            errors.add(err.getStatusCode() + ': ' + err.getMessage());
        }
        return String.join(errors, '. ');
    }
}