public with sharing class JobImportRequestService extends ProjectImportRequestService {
	public override String getImportTitles(){
        return AppUtil.JobImportHeaderDefinition;
    }

    public override Integer getChunkSize() {
        return AppUtil.JobImportChunkSize;
    }

    public override String getBulkImportType() {
        return 'Job';
    }

    public override void afterImport() {
        super.afterImport();
        if(!Test.isRunningTest()){
            JobActionsHelper.invokeJobImportBatch(this.ProjectId);
        }
    }
}