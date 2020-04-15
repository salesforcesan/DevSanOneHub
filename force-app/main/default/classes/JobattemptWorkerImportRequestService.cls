public without sharing class JobattemptWorkerImportRequestService extends ThirdPartyLockerImportRequestService {
    
    
     public override String getImportTitles(){
        return AppUtil.JAWImportHeaderDefinition;
    }

    public override Integer getChunkSize() {
        return AppUtil.JAWImportChunkSize;
    }

    public override String getBulkImportType() {
        return Constants.JOB_ATTEMPT_WORKER_STATUS_PENDING;
    }

    public override void afterImport() {
        super.afterImport();
        if(!Test.isRunningTest()){
           JobAttemptWorkerActionsHelper.invoke3PLImportBatch(this.AccId);
        }
    }
    
 
}