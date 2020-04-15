@isTest
private class ImportQueueItemConsumerTest
{
	@testSetup
	static void beforeTest(){
		TriggerUtil.skipAllTriggers();
		TestDataUtil.init();
		TestProject.create('demo')
		.addAllWithoutJobAttempts(20);
		ImportRequestQueueTestUtil.setupDatasource();
		setNonBundledProject();
	}

	static void setNonBundledProject(){
		String pid = [SELECT Id FROM Project__c LIMIT 1].Id;
		Project__c p = new Project__c (
			BundleServices__c = false,
			Id = pid
		);
		update p;
	}

	@isTest
	static void itShouldUpdateAllJobsThePositiveWay()
	{
		// Given
		String dsId = [SELECT Id FROM Datasource__c LIMIT 1].Id;
		DatasourceWrapper datasource = 
			DatasourceWrapper.createInstance(dsId);
		List<List<String>> bodyContent = ImportRequestQueueTestUtil.genAttachmentContent();
		
		// When
		test.startTest();
		IExecutor consumer = new ImportQueueItemConsumer();
		DBResult result = consumer.doExecute(new Object[] {
			'test',
			datasource,
			bodyContent
			});
		test.stopTest();
		
		// Then
		QA.isTrue(result.IsSucceeded(), 'updated:' + result.Message);
		QA.EQ(20, result.SuccessCount, '20 jobs updated');
	}

	static boolean jobUpdated(){
		Boolean result = true;
		List<Job__c> jobs = ImportRequestQueueTestUtil.getJobs();
		for(Job__c job: jobs) {
			if (
					job.JobStartTime__c != ImportRequestQueueTestUtil.START_TIME
				|| job.PurchaseOverRideAmount__c != ImportRequestQueueTestUtil.PURCHASE_AMOUNT
				|| job.EstimatedMinutesOverride__c != ImportRequestQueueTestUtil.TIME_ESTIMATE
				|| job.NumberOfWorkers__c != ImportRequestQueueTestUtil.NUM_OF_WORKERS					
				) {
				result = false;
			}
  	}	
		return result;
	}
}