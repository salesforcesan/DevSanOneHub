@isTest
public class ImportRequestQueueNotifierTest {
	public static final String SCHEDULE_DATE = '2019-01-01';
	public static final String START_TIME = '10:00 AM';
	public static final Integer TIME_ESTIMATE = 55;
	public static final Integer NUM_OF_WORKERS = 1;
	public static final Double PURCHASE_AMOUNT = 35.55;
	public static final Integer TOTAL_COUNT = 1000;
	public static final String ERROR_MSG = 'error';

	@testSetup
	static void setupTestData() {
		TriggerUtil.skipAllTriggers();
		TestDataUtil.init();
		TestProject.create('demo')
		.addAllWithoutJobAttempts(20);
		setProjectUnbundled();
	}

	static void setProjectUnbundled() {
		String pid = TestProject.getProjects()[0].Id;
		Project__c p = new Project__c(
		  Id = pid,
		  BundleServices__c = false
		);
		update p;
	}


	@isTest
	static void itShouldManageCompletedQueue() {
		//GIVEN
		ImportRequestQueueTestUtil.setupQueueTestData();
		setQueueItemsStatus('Completed');

		//WHEN
		test.startTest();
		String apexJobId = runBatch();
		test.stopTest();

		//THEN
		QA.isTrue(String.isNotBlank(apexJobId), 'job id returned');

		List<AppLog__c> logs = AppLogBatch.getAll();
		QA.isTrue(logs.size() == 0, 'no error');

		ImportRequestQueue__c result = getQueues()[0];
		QA.EQ('Completed', result.Status__c, 'status completed:' + result.Response__c);
		QA.isTrue(result.Notified__c, 'email sent out');
	}

	@isTest
	static void itShouldManageQueueInProcessingWhenAnalyzeQueueItems() {
		//GIVEN
		ImportRequestQueueTestUtil.setupQueueTestData();
		setQueueItemsWithMixedStatus(new String[] {'Completed', 'Queued'});
		ImportRequestQueueNotifierBatchHandler handler =
		  new ImportRequestQueueNotifierBatchHandler(EmailNotifierFake1.class);
		ImportRequestQueueNotifierState context = ImportRequestQueueNotifierState.newInstance();
		ImportRequestQueue__c oldQueue = getQueues()[0];

		//WHEN
		test.startTest();
		handler.analyzeQueueItems(oldQueue, context);
		test.stopTest();

		//THEN
		QA.isTrue(oldQueue.Status__c == 'Queued', 'old queued');
		QA.isTrue(context.getStatus() == 'Processing', 'context status is processing:' + context.getStatus());
		QA.isTrue(context.shouldNotifyUser() == false, 'should not notify user');
	}

	@isTest
	static void itShouldManageQueueInCompletedWhenNotifierUser() {
		//GIVEN
		ImportRequestQueueTestUtil.setupQueueTestData();
		setQueueItemsStatus('Completed');

		ImportRequestQueueNotifierBatchHandler handler =
		  new ImportRequestQueueNotifierBatchHandler(EmailNotifierFake1.class);
		ImportRequestQueueNotifierState context = ImportRequestQueueNotifierState.newInstance();
		ImportRequestQueue__c oldQueue = getQueues()[0];

		//WHEN
		test.startTest();
		handler.analyzeQueueItems(oldQueue, context);
		handler.notifiyUser(oldQueue, context);
		test.stopTest();

		//THEN
		QA.isTrue(oldQueue.Status__c == 'Queued', 'old queued');
		QA.EQ(true, context.getEmailNotified(), 'email sent');
	}


	@isTest
	static void itShouldManageFailedQueue() {
		//GIVEN
		ImportRequestQueueTestUtil.setupQueueTestData();
		setQueueItemsStatus('Failed');

		//WHEN
		test.startTest();
		String apexJobId = runBatch();
		test.stopTest();

		//THEN
		ImportRequestQueue__c result = getQueues()[0];
		QA.EQ('Failed', result.Status__c, 'queue failed');
		QA.isTrue(String.isNotBlank(result.Response__c), 'error message set');
		QA.isTrue(result.Notified__c, 'email should sent');
	}


	public static void setQueueItemsStatus(String status) {
		Integer successCount = 0, errorCount = 0,
		        recordCount = TOTAL_COUNT / 2;
		String errorMsg = '';

		if (status == 'Completed') {
			successCount = recordCount;
		} else {
			errorMsg = ERROR_MSG;
			errorCount = recordCount;
		}

		List<ImportRequestQueueItem__c> items = [
		    SELECT Id, Status__c, RecordCount__c,
		    ErrorCount__c, SuccessCount__c,
		    Response__c FROM ImportRequestQueueItem__c];

		for (ImportRequestQueueItem__c i : items) {
			i.Status__c = status;
			i.RecordCount__c = recordCount;
			i.SuccessCount__c = successCount;
			i.ErrorCount__c = errorCount;
			i.Response__c = errorMsg;
		}
		update items;
	}

	public static void setQueueItemsWithMixedStatus(String[] arrStatus) {
		Integer i = 0;
		List<ImportRequestQueueItem__c> items = [
		    SELECT Id, Status__c FROM ImportRequestQueueItem__c];
		for (ImportRequestQueueItem__c item : items) {
			item.Status__c = arrStatus[Math.mod(i++, 2)];
		}
		update items;
	}

	static String runBatch() {
		ImportRequestQueueNotifierBatchHandler handler =
		  new ImportRequestQueueNotifierBatchHandler(EmailNotifierFake1.class);
		return Database.executeBatch(handler, 1);
	}

	public static List<ImportRequestQueue__c> getQueues() {
		return (List<ImportRequestQueue__c>) Database.query(AppUtil.genQuery('ImportRequestQueue__c'));
	}
}