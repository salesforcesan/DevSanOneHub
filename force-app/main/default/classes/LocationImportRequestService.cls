public with sharing class LocationImportRequestService extends ProjectImportRequestService {
	
    public override String getImportTitles(){
        return AppUtil.LocationImportHeaderDefinition;
    }

    public override Integer getChunkSize() {
        return AppUtil.LocationImportChunkSize;
    }

    public override String getBulkImportType() {
        return 'Location';
    }

    public override void afterImport() {
        super.afterImport();
        if(!Test.isRunningTest()){
            ProjectLocationActionsHelper.invokeLocationImportBatch(this.ProjectId);
        }
    }
}