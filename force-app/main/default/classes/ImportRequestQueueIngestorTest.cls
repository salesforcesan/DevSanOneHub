@isTest
private class ImportRequestQueueIngestorTest {
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
	static void itShouldExecutedAsExpected() {
		//GIVEN
		//WHEN
		test.startTest();
		ImportRequestQueueIngestor provider = new ImportRequestQueueIngestor();
		provider.execute(new ScheduleContextFake());
		test.stopTest();

		//THEN
		QA.EQ(true, qItemsBatchJobAssigned(), 'batchjob assigned');
		QA.EQ(true, qItemsBatchJobIdAssigned(), 'batch job id assigned');
	}

	@isTest
	static void ensureBatchJobAssigned() {
		//GIVEN
		ImportRequestQueueTestUtil.setupQueueTestData();
		List<ImportRequestQueueItem__c> qItems = getQItems();
		for (ImportRequestQueueItem__c item : qItems) {
			item.BatchJobAssigned__c = true;
			item.BatchJobId__c = '1';
		}
		//WHEN
		test.startTest();
		ImportRequestQueueIngestor.assignBatchJobToQueueItem('1', qItems);
		test.stopTest();

		//THEN
		QA.EQ(true, qItemsBatchJobAssigned(), 'batchjob assigned');
	}


	@isTest
	static void itShouldGetGroupResult() {
		// Given
		ImportRequestQueueTestUtil.setupQueueTestData();

		// When
		test.startTest();
		AggregateResult[] result = ImportRequestQueueIngestor.getQueueItemProjectGroups();
		test.stopTest();

		// Then
		QA.EQ(1, result.size(), 'one project');
	}

	@isTest
	static void itShouldProcessQueues() {
		// Given
		ImportRequestQueueTestUtil.setupQueueTestData();
		String pId = TestProject.getProjects()[0].Id;

		// When
		test.startTest();
		ImportRequestQueueIngestor.enqueueBatchJob(pId, false);
		test.stopTest();

		// THEN
		QA.isTrue(ImportRequestQueueTestUtil.isQueueItemsCompleted(), 'completed:'
		          + ImportRequestQueueTestUtil.getQueueItemsStatus()  );
	}

	static List<ImportRequestQueueItem__c> getQItems() {
		return [
		         SELECT
		         Id,
		         BatchJobAssigned__c,
		         BatchJobId__c
		         FROM ImportRequestQueueItem__c
		       ];
	}

	static boolean qItemsBatchJobAssigned() {
		Boolean assigned = true;
		for (ImportRequestQueueItem__c item : getQItems()) {
			if (item.BatchJobAssigned__c != true) {
				assigned = false;
			}
		}
		return assigned;
	}

	static boolean qItemsBatchJobIdAssigned() {
		Boolean assigned = true;
		for (ImportRequestQueueItem__c item : getQItems()) {
			if (String.isBlank(item.BatchJobId__c)) {
				assigned = false;
			}
		}
		return assigned;
	}

	class ScheduleContextFake implements SchedulableContext {
		public String getTriggerId() {
			return '1';
		}
	}
}