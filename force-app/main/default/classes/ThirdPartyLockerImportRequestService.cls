public virtual without sharing class ThirdPartyLockerImportRequestService implements IImportRequestService {
    
    public static final string ACCOUNT_ID_MISSING = 'Logged In User\'s 3pl Agency is missing.';
    public static final string USER3PLAGENCY_NOT_FOUND = 'Logged In User\'s 3pl Agency not found.';
    public static final String ACCOUNT_IMPORT_PENDING = 'Logged In User\'s 3PL Agency Previous Import Request Is pending.';
    
    public String AccId {get; private set;}

    ThirdpartyAgencyRecordsLocker__c ThirdPartyInstance {get; private set;}
    String AttachmentName {get; private set;}
    String JobName {get; private set;}

    public ThirdPartyLockerImportRequestService(){
        this.ThirdPartyInstance = null;
    }

    void initThirdPartyInstance(String AccountId){
         if(String.isBlank(AccountId)){
            throw new AuraHandledException(ACCOUNT_ID_MISSING);
        }
        

        List<ThirdpartyAgencyRecordsLocker__c> lst3plRec = [SELECT Id,Account__c,BulkImportStatus__c,ApexJobName__c FROM ThirdpartyAgencyRecordsLocker__c WHERE Account__c=:AccId];
        if(lst3plRec.size() == 0){
            throw new AuraHandledException(USER3PLAGENCY_NOT_FOUND);
        }

        this.ThirdPartyInstance = lst3plRec.get(0);
    }

    public virtual void init(String parentId, String attachmentName, String jobName) {
        this.AttachmentName = attachmentName;
        this.JobName = jobName;
        this.AccId = parentId;
    }

    public String getId(){
        return this.AccId;
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
       if(this.ThirdPartyInstance == null){
          this.initThirdPartyInstance(this.AccId);
        }

        if(!String.isBlank(this.ThirdPartyInstance.BulkImportStatus__c)) {
            throw new AuraHandledException(ACCOUNT_IMPORT_PENDING);
        }
    }

    public virtual void afterImport() {
        TriggerUtil.skipJobAttemptWorkerTrigger = true;
        this.ThirdPartyInstance.BulkImportStatus__c = this.getBulkImportType();
        this.ThirdPartyInstance.ApexJobName__c = this.JobName;
        Database.SaveResult result  = Database.update(this.ThirdPartyInstance);
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