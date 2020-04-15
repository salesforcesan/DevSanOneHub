global class ImportRequestQueueItemBatchHandler implements Database.Batchable<sObject>,
	Database.Stateful, Database.RaisesPlatformEvents {
	private String pid;
	private AppLocker locker;
	private Map<String, DatasourceWrapper> datasources;
	private static final String APP_ID = 'ImportRequestQueueItemBatchHandler';

	private ImportRequestQueueItemBatchHandler(String projectId) {
		this.pid = projectId;
		this.datasources = new Map<String, DatasourceWrapper>();
		this.locker = AppLocker.newInstance('Project', projectId, APP_ID);
	}

	global static ImportRequestQueueItemBatchHandler newInstance(String projectId) {
		return new ImportRequestQueueItemBatchHandler(projectId);
	}

	global Database.QueryLocator start(Database.BatchableContext BC) {
		String projectId = this.pid;
		return Database.getQueryLocator([SELECT
		                                 Id,
		                                 AttachmentId__c,
		                                 Requestor__c,
		                                 RecordCount__c,
		                                 RetryCount__c,
		                                 ConsumerAppClassName__c,
		                                 Datasource__c
		                                 FROM ImportRequestQueueItem__c
		                                 WHERE  Project__c = :projectId
		                                     AND Status__c = 'Queued'
		                                         AND Queue__r.Status__c IN ('Queued', 'Processing')
		                                         ORDER BY CreatedDate ASC]);
	}

	//it handle each queue item per transaction
	global void execute(Database.BatchableContext BC , List<ImportRequestQueueItem__c> items) {
		for (ImportRequestQueueItem__c item : items) {
			handleEachQueueItem(item);
		}
	}



	@testVisible
	void handleEachQueueItem(ImportRequestQueueItem__c item) {
		//step 1: ensure consumer app class is defined
		if (String.isBlank(item.ConsumerAppClassName__c)) {
			canNotHandleQueueItem(item.Id, 'Failed', 'No consumer application class configured.', 0);
			return;
		}

		//step 2: ensure project is locked
		if (!locker.isLocked()) {
			try {
				locker.lock();
				beginHandleQueueItem(item.Id);
			} catch (AppLockException lockEx) {
				handleFailedToGetLock(item.Id, lockEx.getMessage(), Integer.valueOf(item.RetryCount__c));
				return;
			}	catch (Exception ex) {
				canNotHandleQueueItem(item.Id, 'Failed', ex.getMessage(), Integer.valueOf(item.RetryCount__c));
				return;
			}
		}

		Savepoint sp = Database.setSavepoint();
		try {
			DBResult response = tryToConsumeQueueItem(item);
			deleteAttachment(item.AttachmentId__c, response);
			endHandleQueueItem(item, response);
		} catch (CustomException custEx) {
			Database.rollback(sp);
			canNotHandleQueueItem(item.Id, 'Failed', custEx.getMessage(), Integer.valueOf(item.RetryCount__c));
		} catch (Exception ex) {
			Database.rollback(sp);
			canNotHandleQueueItem(item.Id, 'Failed', ex.getMessage() + ': ' + ex.getStackTraceString(), Integer.valueOf(item.RetryCount__c));
		}
	}

	global void finish(Database.BatchableContext BC) {

		try {
			if (locker.isLocked()) {
				locker.release();
			}
		} catch (Exception ex) {
			AppLogBatch.appError(ex, 'Project:' + pid, APP_ID);
		}

		BatchProcessUtil.logBatchLevelError(BC.getJobId(), APP_ID);
	}

	DBResult tryToConsumeQueueItem(ImportRequestQueueItem__c item ) {
		List<List<String>> content;

		Savepoint sp = Database.setSavepoint();
		try {
			DatasourceWrapper datasource = getDatasource(item.Datasource__c);
			content = getAttachContent(item.AttachmentId__c);
			IExecutor consumer = (IExecutor) Reflection.newInstance(datasource.consumerClass);

			DBResult result = consumer.doExecute(new Object[] {
			                                       item.Id,
			                                       datasource,
			                                       content
			                                     });
			return result.addData('errors', consumer.getFailedContent());
		} catch (CustomException custEx) {
			Database.rollback(sp);
			return DBResult.error(content.size(), custEx.getMessage());
		} catch (AuraHandledException auraEx) {
			Database.rollback(sp);
			return DBResult.error(content.size(), auraEx.getMessage());
		} catch (Exception ex) {
			Database.rollback(sp);
			return DBResult.error(content.size(), ex.getMessage() + ':' + ex.getStackTraceString());
		}
	}

	DatasourceWrapper getDatasource(String datasourceId) {
		if (datasources.containsKey(datasourceId)) {
			return (DatasourceWrapper) datasources.get(datasourceId);
		}
		DatasourceWrapper wrapper = DatasourceWrapper.createInstance(datasourceId);
		datasources.put(datasourceId, wrapper);
		return wrapper;
	}

	static void beginHandleQueueItem(String queueItemId) {
		try {
			ImportRequestQueueItem__c q = new ImportRequestQueueItem__c(
			  Id = queueItemId,
			  StartTime__c = Datetime.now(),
			  SuccessCount__c = 0,
			  ErrorCount__c = 0,
			  EndTime__c = null,
			  Status__c = 'Processing',
			  Response__c = ''
			);
			DBX.doUpdate(q);
		} catch (Exception ex) {
			AppLogBatch.batchError(ex, 'QueueItemId:' + queueItemId , APP_ID);
		}
	}

	void endHandleQueueItem(ImportRequestQueueItem__c item, DBResult result) {

		try {
			String errorAttachmentId = result.IsSucceeded()
				? ''
				: newAttachment(item, (List<List<String>>) result.getData('errors'));
			ImportRequestQueueItem__c q = new ImportRequestQueueItem__c(
			  Id = item.Id,
			  SuccessCount__c = result.SuccessCount,
			  ErrorCount__c = result.ErrorCount,
			  EndTime__c = Datetime.now(),
			  ErrorAttachment__c = errorAttachmentId,
			  Status__c = result.IsSucceeded() ? 'Completed' : 'Failed',
			  Response__c = result.Message
			);
			DBX.doUpdate(q);
		} catch (Exception ex) {
			AppLogBatch.batchError(ex, 'QueueItemId:' + item.Id, APP_ID);
		}
	}

	@testVisible
	String newAttachment(ImportRequestQueueItem__c item, List<List<String>> content) {
		if (content == null || content.isEmpty()) {return '';}
		
		String body = addHeaderToContent(item.Datasource__c, content);
		Attachment att = new Attachment();
		att.ParentId = item.Id;
		att.Body = Blob.valueOf(body);
		att.ContentType = 'text/csv';
		att.Name = 'error_' + item.Id + '.csv';
		att = (Attachment) DBX.doInsert(att);
		return att.Id;
	}

	@testVisible
	String addHeaderToContent(String datasourceId, List<List<String>> content){
		List<String> result = new List<String>();
		List<String> header = new List<String>();
		DatasourceWrapper datasource = getDatasource(datasourceId);
		for(DatasourceSchemaWrapper col: datasource.schemas){
			header.add(col.title);
		}
		result.add(listToCSVString(header));
		for(List<String> r: content){
			result.add(listToCSVString(r));
		}
		
		return String.join(result,'\n');
	}

	String listToCSVString(List<String> value){
		return '"' + String.join(value, '","') + '"';
	}

	@testVisible
	static void handleFailedToGetLock(String queueItemId, String msg, Integer retryCount) {
		OrgCustomSettings__c setting = OrgCustomSettings__c.getInstance('Setting');
		Integer maxRetries = setting.MaximumRetryCount__c != null
		                     ? Integer.valueOf(setting.MaximumRetryCount__c)
		                     : 5;
		String status = 'Queued';
		String message = msg;
		if (retryCount >= maxRetries) {
			status = 'Failed';
			message = 'The maximum of retry (' + maxRetries + ') is reached. ' + msg;
		}
		canNotHandleQueueItem(queueItemId, status, message, retryCount);
	}

	@testVisible
	static void canNotHandleQueueItem(String queueItemId, String status, String msg, Integer retryCount) {
		try {
			ImportRequestQueueItem__c q = new ImportRequestQueueItem__c (
			  Id = queueItemId,
			  StartTime__c = Datetime.now(),
			  EndTime__c = Datetime.now(),
			  Status__c = status,
			  RetryCount__c = retryCount + 1,
			  Response__c = msg
			);

			if (status == 'Queued'){
				q.BatchJobAssigned__c = false;
			  q.BatchJobId__c = '';
			}

			DBX.doUpdate(q);
		} catch (Exception ex) {
			AppLogBatch.batchError(ex, 'QueueItemId:' + queueItemId , APP_ID);
		}
	}

	static List<List<String>> getAttachContent(String attId) {
		Attachment att = getAttachment(attId);
		List<List<String>> content = (List<List<String>>) JSON.deserialize(att.body.toString(), List<List<String>>.class);
		if (content.isEmpty()) {
			throw new CustomException('The attachment failed to deserialized.');
		}
		return content;
	}

	static Attachment getAttachment(String attId) {
		List<Attachment> attList = [SELECT Body, BodyLength FROM Attachment WHERE Id = :attId];
		if (attList.isEmpty()) {
			throw new CustomException('Attachment Not Found');
		}
		if (attList.get(0).BodyLength == 0) {
			throw new CustomException('Attachment Is Empty');
		}
		return attList.get(0);
	}

	static void deleteAttachment(String attId, DBResult result) {
		if (result.IsSucceeded()) {
			Attachment att = new Attachment(Id = attId);
			DBX.doDelete(att);
		}
	}
}