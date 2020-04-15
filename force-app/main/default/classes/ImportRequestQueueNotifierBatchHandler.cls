global class ImportRequestQueueNotifierBatchHandler implements
	Database.Batchable<Sobject>,Database.Stateful, Database.RaisesPlatformEvents {
	private static final String APP_ID = 'ImportRequestQueueNotifierBatchHandler';
	private final String emailNotifierApexClass;

	global ImportRequestQueueNotifierBatchHandler(Type emailNotifierType) {
		emailNotifierApexClass = emailNotifierType.getName();
	}

	global Database.QueryLocator start(Database.BatchableContext BC) {
		return Database.getQueryLocator([
		                                  SELECT
		                                  Id,
		                                  Status__c,
		                                  Notified__c,
		                                  Requestor__c
		                                  FROM ImportRequestQueue__c
		                                  WHERE Status__c IN ('Queued', 'Processing')
		                                  ORDER BY CreatedDate
		                                ]);
	}

	global void execute(Database.BatchableContext BC, List<ImportRequestQueue__c> scope) {
		for (ImportRequestQueue__c queue : scope) {
			handleQueue(queue);
		}
	}

	@testVisible
	void handleQueue(ImportRequestQueue__c queue) {
		try {
			ImportRequestQueueNotifierState handleState = ImportRequestQueueNotifierState.newInstance();
			analyzeQueueItems(queue, handleState);
			if (handleState.shouldNotifyUser()) {
				notifiyUser(queue, handleState);
			}
			syncQueueChanges(queue, handleState);
		} catch (Exception ex) {
			AppLogBatch.batchError(ex, String.valueOf(queue.Id), APP_ID);
		}
	}

	static Integer toInteger(Decimal count) {
		if (count == null) return 0;
		return Integer.valueOf(count);
	}

	@testVisible
	void analyzeQueueItems(ImportRequestQueue__c queue, ImportRequestQueueNotifierState context) {
		List<ImportRequestQueueItem__c> items = getQueueItems(queue.Id);
		Integer completedCount = 0, failedCount = 0, processingCount = 0, cancelCount = 0, queuedCount = 0;

		for (ImportRequestQueueItem__c item : items) {
			context.plusTotalCount(toInteger(item.RecordCount__c));
			context.plusSuccessCount(toInteger(item.SuccessCount__c));
			context.plusErrorCount(toInteger(item.ErrorCount__c));

			if (String.isNotBlank(item.Response__c)) {
				context.addError(item.Response__c);
			}

			if (String.isNotBlank(item.ErrorAttachment__c)) {
				context.addErrorAttachment(item.ErrorAttachment__c);
			}

			if (item.Status__c == 'Completed') {
				completedCount++;
			} else if (item.Status__c == 'Failed') {
				failedCount++;
			} else if (item.Status__c == 'Canceled') {
				cancelCount++;
			} else if (item.Status__c == 'Processing') {
				processingCount++;
			} else if (item.Status__c == 'Queued') {
				queuedCount++;
			}
		}

		//analyze count result
		Integer itemCount = items.size();
		if (completedCount > 0 && 
				(completedCount == itemCount || 
					(completedCount + failedCount) == itemCount)) {
			context.markCompleted();
			return;
		}

		if (failedCount == itemCount) {
			context.markFailed();
			return;
		}

		if (queuedCount == itemCount) {
			context.markQueued();
			return;
		}

		context.markProcessing();
	}

	@testVisible
	void notifiyUser(ImportRequestQueue__c queue, ImportRequestQueueNotifierState context) {
		String subject = 'Import Job From Program';
		IEmailNotifier1 notifier = (IEmailNotifier1) Reflection.newInstance(emailNotifierApexClass);
		Boolean notified = notifier.setSubject(subject)
		                   .setRecipientByUserId(queue.Requestor__c)
		                   .setBody(genBodyMessage(context))
		                   .setAttachments(context.getErrorAttachments())
		                   .sendAsHtml();
		if (notified) {
			context.markEmailNotified();
		} else {
			AppLogBatch.createInstance()
			.newBatchJobLog()
			.setError()
			.setRequestor(APP_ID)
			.setMessageDetail('Failed to notify user', notifier.getErrorString())
			.setReplayId(String.valueOf(queue.Id))
			.addToBatch()
			.saveToDB();
		}
	}

	String genBodyMessage(ImportRequestQueueNotifierState context) {
		if (context.isSucceeded()) {
			return StringBuilder.newInstance()
			       .append('Importing jobs from the program is completed successfully.')
			       .append('<br><br>')
			       .append('Total Jobs:' + String.valueOf(context.getTotalCount()))
			       .append('<br>')
			       .append('Imported Jobs:' + String.valueOf(context.getSuccessCount()))
			       .append('<br><br>')
			       .append(context.getErrorString())
			       .build(' ');
		}
		return StringBuilder.newInstance()
		       .append('Importing jobs from the program is completed with some errors.')
		       .append('<br><br>')
		       .append('Total Jobs:' + String.valueOf(context.getTotalCount()))
		       .append('<br>')
		       .append('Imported Jobs:' + String.valueOf(context.getSuccessCount()))
		       .append('<br>')
		       .append('Failed Jobs:' + String.valueOf(context.getErrorCount()))
		       .append('<br><br>')
		       .append(context.getErrorString())
		       .build(' ');
	}

	@testVisible
	void syncQueueChanges(ImportRequestQueue__c queue, ImportRequestQueueNotifierState context) {
		ImportRequestQueue__c updateQueue = new ImportRequestQueue__c(
		  Id = queue.Id
		);
		if (context.shouldNotifyUser()) {
			updateQueue.Status__c = context.getStatus();
			updateQueue.EndTime__c = Datetime.now();
			updateQueue.Notified__c = context.getEmailNotified();
			updateQueue.Response__c = genBodyMessage(context);
		} else if (queue.Status__c != context.getStatus()) {
			updateQueue.Status__c = context.getStatus();
			updateQueue.Response__c = genBodyMessage(context);
		} else {
			updateQueue.Response__c = context.getStatus();
		}
		DBX.doUpdate(updateQueue);
	}

	List<ImportRequestQueueItem__c> getQueueItems(String queId) {
		return [
		         SELECT
		         Status__c,
		         ErrorCount__c,
		         SuccessCount__c,
		         RecordCount__c,
		         ErrorAttachment__c,
		         Response__c
		         FROM ImportRequestQueueItem__c
		         WHERE Queue__c = :queId
		       ];
	}


	global void finish(Database.BatchableContext BC) {
		BatchProcessUtil.logBatchLevelError(BC.getJobId(),APP_ID);
	}

}