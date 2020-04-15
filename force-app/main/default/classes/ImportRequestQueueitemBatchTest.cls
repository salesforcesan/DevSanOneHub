@isTest
private class ImportRequestQueueitemBatchTest {
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
	static void testNewAttachmentAPI() {
		//GIVEN
		ImportRequestQueueTestUtil.setupQueueTestData(false);
		String pid = TestProject.getProjects()[0].Id;
		ImportRequestQueueItem__c item = getQItems()[0];
		List<List<String>> content = new List<List<String>>();
		content.add(new String[]{'1'});
		
		//WHEN
		test.startTest();
		ImportRequestQueueItemBatchHandler handler = 
			ImportRequestQueueItemBatchHandler.newInstance(pid);
		String attId = handler.newAttachment(item, content);
		test.stopTest();

		//THEN
		QA.isTrue(String.isNotBlank(attId), 'att generated:' + getError());
	}

	@isTest
	static void testHandleFailToGetLockWithMaxRetry() {
		//GIVEN
		ImportRequestQueueTestUtil.setupQueueTestData(false);
		String pid = TestProject.getProjects()[0].Id;
		ImportRequestQueueItem__c item = getQItems()[0];

		//WHEN
		test.startTest();
		ImportRequestQueueItemBatchHandler.handleFailedToGetLock(
			item.Id, 'failed to get lock.', 100);
		test.stopTest();

		//THEN
		item = getItem(item.Id);
		QA.EQ('Failed', item.Status__c, 'status should changed to failed');
		QA.isTrue(item.Response__c.indexOf('The maximum of retry') != -1, 'max retry message logged.');
	}

	@isTest
	static void testHandleFailToGetLock() {
		//GIVEN
		ImportRequestQueueTestUtil.setupQueueTestData(false);
		String pid = TestProject.getProjects()[0].Id;
		ImportRequestQueueItem__c item = getQItems()[0];

		//WHEN
		test.startTest();
		ImportRequestQueueItemBatchHandler.handleFailedToGetLock(
			item.Id, 'failed', 1);
		test.stopTest();

		//THEN
		item = getItem(item.Id);
		QA.EQ(2, item.RetryCount__c, '2 retries');
		QA.EQ('Queued', item.Status__c, 'still queued');
	}

	@isTest
	static void testErrorAttachmentScenario() {
		//GIVEN
		ImportRequestQueueTestUtil.setupQueueTestData(false);
		String pid = TestProject.getProjects()[0].Id;
		ImportRequestQueueItem__c item = getQItems()[0];

		//WHEN
		test.startTest();
		ImportRequestQueueItemBatchHandler handler = 
			ImportRequestQueueItemBatchHandler.newInstance(pid);
			handler.handleEachQueueItem(item);
		test.stopTest();

		//THEN
		item = getItem(item.Id);
		QA.isTrue(String.isNotBlank(item.ErrorAttachment__c), 'error attached');
		QA.isTrue(item.ErrorCount__c == item.RecordCount__c, 'data errored');
	}

	@isTest
	static void itShouldLogErrorOnQueueItem() {
		//GIVEN
		ImportRequestQueueTestUtil.setupQueueTestData();
		String pid = TestProject.getProjects()[0].Id;
		ImportRequestQueueItem__c item = getQItems()[0];

		//WHEN
		ImportRequestQueueItemBatchHandler.canNotHandleQueueItem(
		  item.Id,
		  'Failed',
		  'demo',
		  1);

		//THEN
		item = getQItems()[0];
		QA.EQ('Failed', item.Status__c, 'failed');
		QA.EQ(2, item.RetryCount__c, 'one retry');
	}

	static void assignBatchJob(ImportRequestQueueItem__c item){
		ImportRequestQueueItem__c rec = new ImportRequestQueueItem__c(
				Id = item.Id,
				BatchJobId__c = '1',
				BatchJobAssigned__c = true
			);
		update rec;
	}

	@isTest
	static void itShouldRetryQueueItemAndUnAssignBatchJobId() {
		//GIVEN
		ImportRequestQueueTestUtil.setupQueueTestData();
		String pid = TestProject.getProjects()[0].Id;
		ImportRequestQueueItem__c item = getQItems()[0];
		assignBatchJob(item);

		//WHEN
		ImportRequestQueueItemBatchHandler.canNotHandleQueueItem(
		  item.Id,
		  'Queued',
		  'demo',
		  1);

		//THEN
		item = getQItems()[0];
		QA.EQ('Queued', item.Status__c, 'failed');
		QA.EQ(2, item.RetryCount__c, 'one retry');
		QA.EQ(false, item.BatchJobAssigned__c, 'unassligned batch job');
		QA.isTrue(String.isBlank(item.BatchJobId__c), 'batch job id empty');
	}


	@isTest
	static void itShouldTrackAppLogIfUpdateFailed() {
		//GIVEN
		ImportRequestQueueTestUtil.setupQueueTestData();
		String pid = TestProject.getProjects()[0].Id;

		//WHEN
		ImportRequestQueueItemBatchHandler.canNotHandleQueueItem(
		  '',
		  'Failed',
		  'demo',
		  1);

		//THEN
		String error = getError();
		QA.isTrue(String.isNotBlank(error), 'error should be logged.');
	}

	@isTest
	static void itShouldExcuteBatchProperly() {
		//GIVEN
		ImportRequestQueueTestUtil.setupQueueTestData();
		String pid = TestProject.getProjects()[0].Id;

		//WHEN
		test.startTest();
		ImportRequestQueueItemBatchHandler handler =
		  ImportRequestQueueItemBatchHandler.newInstance(pid);
		Database.executeBatch(handler);
		test.stopTest();

		//THEN
		List<ImportRequestQueueItem__c> items = getQItems();
		Integer[] counts = getCounts(items);
		QA.EQ(counts[0], counts[1] + counts[2], '-- total matched error:'
		      + getError()
		      + ' responses:'
		      + getResponse(items));
		QA.isTrue(counts[2] == 0, 'no error');
		QA.isTrue(isQueueItemsInStatus(items, 'Completed'), 'completed');
		AppLocker__c lock = getLock();
		QA.isTrue(String.isBlank(lock.Token__c), 'lock reset');
	}

	@isTest
	static void itShouldHandleInvalidDataProperly() {
		//GIVEN
		ImportRequestQueueTestUtil.setupQueueTestData(false);
		String pid = TestProject.getProjects()[0].Id;

		//WHEN
		test.startTest();
		ImportRequestQueueItemBatchHandler handler =
		  ImportRequestQueueItemBatchHandler.newInstance(pid);
		Database.executeBatch(handler);
		test.stopTest();

		//THEN
		List<ImportRequestQueueItem__c> items = getQItems();
		Integer[] counts = getCounts(items);
		QA.EQ(counts[0], counts[1] + counts[2], '-- total matched error:'
		      + getError()
		      + ' responses:'
		      + getResponse(items));
		QA.isTrue(counts[2] == 20, 'has 20 errors');
		QA.isTrue(isQueueItemsInStatus(items, 'Failed'), 'failed');
		AppLocker__c lock = getLock();
		QA.isTrue(String.isBlank(lock.Token__c), 'lock reset');
		QA.isTrue(isQueueItemsErrorAttached(items), 'errors attached:' + getResponse(items));
	}

	@isTest
	static void itShouldHandleEachQueueItemProperly() {
		// Given
		String batchJobId = '1';
		ImportRequestQueueTestUtil.setupQueueTestData();
		String pId = TestProject.getProjects()[0].Id;
		ImportRequestQueueItem__c queueItem = getQItems()[0];

		// When
		test.startTest();
		ImportRequestQueueItemBatchHandler handler =
		  ImportRequestQueueItemBatchHandler.newInstance(pid);
		handler.handleEachQueueItem(queueItem);
		test.stopTest();

		// Then
		queueItem = getQItems()[0];
		AppLocker__c lock = getLock();
		QA.isTrue(queueItem.Status__c == 'Completed', 'completed:' + getError() + ':' + JSON.serialize(queueItem));
		QA.EQ('ImportRequestQueueItemBatchHandler', lock.RequestorId__c, 'requestid:ImportRequestQueueItemBatchHandler');
		QA.isTrue(String.isNotBlank(lock.Token__c), 'token assigned');
	}

	static Boolean isQueueItemsInStatus(List<ImportRequestQueueItem__c> items, String status) {
		Boolean result = true;
		for (ImportRequestQueueItem__c item : items) {
			if (item.Status__c != status) {
				result = false;
				break;
			}
		}
		return result;
	}

	static Boolean isQueueItemsErrorAttached(List<ImportRequestQueueItem__c> items) {
		Boolean result = true;
		for (ImportRequestQueueItem__c item : items) {
			if (String.isBlank(item.ErrorAttachment__c)) {
				result = false;
				break;
			}
		}
		return result;
	}

	static AppLocker__c getLock() {
		return [
		         SELECT
		         Id,
		         StartTime__c,
		         Token__c,
		         RequestorId__c
		         FROM AppLocker__c
		         LIMIT 1
		       ];
	}

	static ImportRequestQueueItem__c getItem(String itemId){
		for(ImportRequestQueueItem__c item: getQItems()){
			if (item.Id == itemId){
				return item;
			}
		}
		return null;
	}

	static List<ImportRequestQueueItem__c> getQItems() {
		return [
		         SELECT
		         Project__c,
		         AttachmentId__c,
		         SuccessCount__c,
		         ErrorCount__c,
		         BatchJobId__c,
		         BatchJobAssigned__c,
		         RecordCount__c,
		         Status__c,
		         RetryCount__c,
		         ConsumerAppClassName__c,
		         ErrorAttachment__c,
		         Datasource__c,
		         Response__c,
		         StartTime__c,
		         EndTime__c
		         FROM ImportRequestQueueItem__c
		       ];
	}
	static Integer[] getCounts(List<ImportRequestQueueItem__c> items) {
		Decimal total = 0, success = 0, error = 0;
		for (ImportRequestQueueItem__c item : items) {
			total += item.RecordCount__c;
			success += item.SuccessCount__c;
			error += item.ErrorCount__c;
		}
		return new Integer[] {
		         Integer.valueOf(total),
		         Integer.valueOf(success),
		         Integer.valueOf(error)
		       };
	}

	static String getResponse(List<ImportRequestQueueItem__c> items) {
		List<String> result = new List<String>();
		for (ImportRequestQueueItem__c item : items) {
			result.add(item.Response__c);
		}
		return String.join(result, ' ');
	}

	static String getError() {
		List<AppLog__c> logs = [
		                         SELECT
		                         Message__c
		                         FROM AppLog__c
		                       ];
		List<String> errs = new List<String>();
		for (AppLog__c log : logs) {
			errs.add(log.Message__c);
		}
		return String.Join(errs, ' ');
	}
}