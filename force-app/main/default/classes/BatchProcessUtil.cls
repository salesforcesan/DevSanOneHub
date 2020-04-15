global without sharing class BatchProcessUtil {
	private static final String BATCH_STATUS_FAILED = 'Failed';
	global static void logBatchLevelError(String batchJobId, String requestor) {
		AsyncApexJob a = [SELECT
		                  Status,
		                  ExtendedStatus,
		                  ApexClass.Name,
		                  NumberOfErrors,
		                  JobItemsProcessed,
		                  TotalJobItems,
		                  CompletedDate
		                  FROM AsyncApexJob
		                  WHERE Id = :batchJobId];

		if (a.Status != BATCH_STATUS_FAILED && a.NumberOfErrors == 0 ) {
			//no need to log if finished properly.
			return;
		}

		AppLogBatch batchLog = AppLogBatch.createInstance().newBatchJobLog();
		if (a.Status == BATCH_STATUS_FAILED) {
			batchLog.setError().setMessageDetail('Batch Process Failed', a.ExtendedStatus);
		} else if (a.NumberOfErrors > 0) {
			batchLog.setWarning().setMessageDetail('Batch Process Incompleted', a.ExtendedStatus);
		}

		batchLog.setParameters('ApexClass', a.ApexClass.Name)
		.setParameters('processedJobItems', a.JobItemsProcessed)
		.setParameters('totalJobItems', a.TotalJobItems)
		.setParameters('CompletedDate', a.CompletedDate)
		.setRequestor(requestor)
		.addToBatch()
		.saveToDB();
	}
}