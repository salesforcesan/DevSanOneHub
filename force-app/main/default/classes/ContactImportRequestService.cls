public virtual with sharing class ContactImportRequestService implements IImportRequestService {
    
    public static final string CONTACT_ID_MISSING = 'Logged In User\'s Contact Id is missing.';
    public static final string CONTACT_NOT_FOUND = 'Logged In User\'s Contact cannot be found.';
    public static final String CONTACT_IMPORT_PENDING = 'Logged In User Previous 3pl Import Request  Is pending.';
    
    public String ContactId {get; private set;}

    Contact ContactInstance {get; private set;}
    String AttachmentName {get; private set;}
    String JobName {get; private set;}

    public ContactImportRequestService(){
        this.ContactInstance = null;
    }

    void initContactInstance(String ContactId){
         if(String.isBlank(ContactId)){
            throw new AuraHandledException(CONTACT_ID_MISSING);
        }
        

        List<Contact> contacts = [SELECT Id, BulkImportStatus__c, ApexJobName__c FROM Contact WHERE Id=:ContactId];
        if(contacts.size() == 0){
            throw new AuraHandledException(CONTACT_NOT_FOUND);
        }

        this.ContactInstance = contacts.get(0);
    }

    public virtual void init(String parentId, String attachmentName, String jobName) {
        this.AttachmentName = attachmentName;
        this.JobName = jobName;
        this.ContactId = parentId;
    }

    public String getId(){
        return this.ContactId;
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
       if(this.ContactInstance == null){
            system.debug('Contact ID:::'+ this.ContactId);
            this.initContactInstance(this.ContactId);
        }

        if(!String.isBlank(this.ContactInstance.BulkImportStatus__c)) {
            throw new AuraHandledException(CONTACT_IMPORT_PENDING);
        }
    }

    public virtual void afterImport() {
        TriggerUtil.skipJobAttemptWorkerTrigger = true;
        this.ContactInstance.BulkImportStatus__c = this.getBulkImportType();
        this.ContactInstance.ApexJobName__c = this.JobName;
        Database.SaveResult result  = Database.update(this.ContactInstance);
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