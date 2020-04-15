public virtual without sharing class AccountImportRequestService implements IImportRequestService {
    
    public static final string ACCOUNT_ID_MISSING = 'Logged In User\'s 3pl Agency is missing.';
    public static final string USER3PLAGENCY_NOT_FOUND = 'Logged In User\'s 3pl Agency not found.';
    public static final String ACCOUNT_IMPORT_PENDING = 'Logged In User\'s 3PL Agency Previous Import Request Is pending.';
    
    public String AccountId {get; private set;}

    Account AccountInstance {get; private set;}
    String AttachmentName {get; private set;}
    String JobName {get; private set;}

    public AccountImportRequestService(){
        this.AccountInstance = null;
    }

    void initAccountInstance(String AccountId){
         if(String.isBlank(AccountId)){
            throw new AuraHandledException(ACCOUNT_ID_MISSING);
        }
        

        List<Account> lstaccounts = [SELECT Id, BulkImportStatus__c, ApexJobName__c FROM Account WHERE Id=:AccountId];
        if(lstaccounts.size() == 0){
            throw new AuraHandledException(USER3PLAGENCY_NOT_FOUND);
        }

        this.AccountInstance = lstaccounts.get(0);
    }

    public virtual void init(String parentId, String attachmentName, String jobName) {
        this.AttachmentName = attachmentName;
        this.JobName = jobName;
        this.AccountId = parentId;
    }

    public String getId(){
        return this.AccountId;
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
       if(this.AccountInstance == null){
          this.initAccountInstance(this.AccountId);
        }

        if(!String.isBlank(this.AccountInstance.BulkImportStatus__c)) {
            throw new AuraHandledException(ACCOUNT_IMPORT_PENDING);
        }
    }

    public virtual void afterImport() {
        TriggerUtil.skipJobAttemptWorkerTrigger = true;
        this.AccountInstance.BulkImportStatus__c = this.getBulkImportType();
        this.AccountInstance.ApexJobName__c = this.JobName;
        Database.SaveResult result  = Database.update(this.AccountInstance);
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