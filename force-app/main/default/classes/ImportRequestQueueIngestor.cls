global class ImportRequestQueueIngestor implements Schedulable {
	private static final String APP_ID = 'ImportRequestQueueIngestor';

	global static String scheduleToRun(String cronSetting) {
		return scheduleToRun(APP_ID, cronSetting);
	}

	global static String scheduleToRun(String jobName, String cronSetting) {
		ImportRequestQueueIngestor ingestor = new ImportRequestQueueIngestor();
		String cron_exp = String.isNotBlank(cronSetting)
		                  ? cronSetting
		                  : '0 15 * * * ?';
		return System.schedule(APP_ID + jobName, cron_exp, ingestor);
	}

	global void execute(SchedulableContext SC) {
		AggregateResult[] queues = getQueueItemProjectGroups();
		if (queues.size() == 0) {
			return;
		}
		List<ImportRequestQueueItem__c> qItems = new List<ImportRequestQueueItem__c>();
		String jobId;
		String projectId;
		String triggerId = SC.getTriggerId();

		for (AggregateResult que : queues) {
			if (Integer.valueOf(que.get('total')) > 0) {
				projectId = String.valueOf(que.get('projectId'));
				jobId = enqueueBatchJob(projectId, true);
				List<ImportRequestQueueItem__c> unassignedQueueItems = getBatchJobNotAssignedQueueItem(projectId);
				if (String.isNotBlank(jobId)) {
					for (ImportRequestQueueItem__c item : unassignedQueueItems) {
						qItems.add(new ImportRequestQueueItem__c(
						             Id = item.Id,
						             BatchJobId__c = jobId,
						             BatchJobAssigned__c = true
						           ));
					}
				}
			}
		}
		assignBatchJobToQueueItem(triggerId, qItems);
	}

	@testVisible
	static void assignBatchJobToQueueItem(String triggerId, List<ImportRequestQueueItem__c> qItems) {
		if (qItems.isEmpty()) return;
		try {
			DBResult result = DBX.doBulkUpdate(qItems);
			String subject = 'assignBatchJobToQueueItem: success:' + String.valueOf(result.SuccessCount) +
			                 String.valueOf(result.ErrorCount);
			if (!result.IsSucceeded()) {
				AppLogBatch.batchError(subject, result.Message, triggerId, APP_ID);
			}
		} catch (AuraHandledException auraEx) {
			AppLogBatch.batchError('Failed to assignBatchJobToQueueItem', auraEx.getMessage(), triggerId , APP_ID);
		} catch (Exception ex) {
			AppLogBatch.batchError(ex, triggerId, APP_ID);
		}
	}

	@testVisible
	static String enqueueBatchJob(String projectId, Boolean batchPerProject) {
		String jobId = '';

		try {
			ImportRequestQueueItemBatchHandler batcher =
			  ImportRequestQueueItemBatchHandler.newInstance(projectId);
			if (batchPerProject) {
				jobId = Database.executeBatch(batcher, 1);
			} else {
				jobId = Database.executeBatch(batcher);
			}

			if (jobId == '000000000000000') {
				jobId = '';
				AppLogBatch.batchWarn('Faild to submit batch job', 'The executeBatch call fails and will resbumit in the next wakeup cycle.', projectId, APP_ID);
			}
		} catch (Exception ex) {
			jobId = '';
			AppLogBatch.batchError(ex, projectId, APP_ID);
		}
		return jobId;
	}

	@testVisible
	static List<ImportRequestQueueItem__c> getBatchJobNotAssignedQueueItem(String projectId) {
		return [
		         SELECT
		         Id
		         FROM ImportRequestQueueItem__c
		         WHERE  Status__c = 'Queued'
		                            AND BatchJobAssigned__c != true
		                            AND Queue__r.Status__c IN ('Queued', 'Processing')
		                            AND Project__c = :projectId];
	}

	@testVisible
	static AggregateResult[] getQueueItemProjectGroups() {
		Integer limitSize = getMaxProjectsToHandle();
		return [
		         SELECT
		         Project__c projectId,
		         Count(Id) total
		         FROM ImportRequestQueueItem__c
		         WHERE Status__c = 'Queued'
		                           AND Queue__r.Status__c IN ('Queued', 'Processing')
		                           AND BatchJobAssigned__c != true
		                           GROUP BY Project__c
		                           LIMIT :limitSize
		       ];
	}

	@testVisible
	static Integer getMaxProjectsToHandle() {
		OrgCustomSettings__c setting = OrgCustomSettings__c.getInstance('Setting');
		return setting.MaxProjectsPerWakeup__c > 0
		       ? Integer.valueOf(setting.MaxProjectsPerWakeup__c)
		       : 50;
	}
}