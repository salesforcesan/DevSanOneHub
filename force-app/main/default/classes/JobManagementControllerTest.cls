@isTest
private class JobManagementControllerTest {

	static testmethod void testGreeting() {
		system.assert(!String.isBlank(JobManagementController.greeting()));
	}

	static testmethod void testFilterJobs() {

		Project__c testProject = TestUtil.generateProjectwithJobs(ProjectType.MD, Date.today().addDays(60), Date.today().addDays(70));
		System.assertNotEquals(0, [SELECT count() FROM Job__c WHERE Project__c = :testProject.Id]);

		Test.setCurrentPage(Page.JobManagement);
		JobManagementController cont = new JobManagementController(new ApexPages.StandardController(testProject));
		System.assertEquals(cont.project.Id, testProject.Id);

		JobManagementController.JobFilter[] filters = JobManagementController.getJobFilters(testProject.Id);
		System.assert(!filters.isEmpty(), 'Expected to receive a list of JobFilters from JobManagementController.getJobFilters(), received an empty list');

		Map<String, String> testFilterValues = new Map<String, String>();
		for (JobManagementController.JobFilter filter : filters) {
			if (filter.type.toLowerCase() == 'text') {
				testFilterValues.put(filter.label, 'Test');
			}
			else if (filter.type.toLowerCase() == 'date') {
				testFilterValues.put(filter.label, JobManagementController.getUSLocale(Date.today()));
			}
			else if (!filter.options.isEmpty()) {
				testFilterValues.put(filter.label, filter.options[0].value);
			}
		}

		JobManagementController.FilterJobsResponse jobResponse = JobManagementController.filterJobs(testProject.Id, testFilterValues);

		System.assertEquals(0, jobResponse.jobs.size());
	}

	static testmethod void testRetrieveJobs() {

		Project__c testProject = TestUtil.generateProjectwithJobs(ProjectType.MD, Date.today().addDays(60), Date.today().addDays(70));

		Test.setCurrentPage(Page.JobManagement);
		JobManagementController cont = new JobManagementController(new ApexPages.StandardController(testProject));

		JobManagementController.FilterJobsResponse jobResponse = JobManagementController.filterJobs(testProject.Id, null);
		System.assertEquals([SELECT count() FROM Job__c WHERE Project__c = :testProject.Id], jobResponse.jobs.size());
	}

	static testmethod void testCreateAttempts() {

		Project__c testProject = TestUtil.generateProjectwithJobs(ProjectType.MD, Date.today().addDays(60), Date.today().addDays(70));
		Id[] jobIds = new Id[]{ [SELECT Id FROM Job__c WHERE Project__c = :testProject.Id LIMIT 1].Id };

		ActionResponse[] responses = JobManagementController.createAttempts(jobIds,'');
		System.assertEquals(1, responses.size());
	}

	static testmethod void testScheduleDate() {

		Project__c testProject = TestUtil.generateProjectwithJobs(ProjectType.MD, Date.today().addDays(60), Date.today().addDays(70));
		Id[] jobIds = new Id[]{ [SELECT Id FROM Job__c WHERE Project__c = :testProject.Id LIMIT 1].Id };

		ActionResponse[] responses = JobManagementController.setScheduledDate(jobIds, JobManagementController.getUSLocale(Date.today().addDays(7)));
        //commented TODO code for USER option
		//System.assertEquals(1, responses.size());
	}

	static testmethod void testCancelJobs() {

		String[] cancelReasons = JobManagementController.cancelReasons();
		System.assert(!cancelReasons.isEmpty(), 'Expected to retrieve Job cancel reasons from JobManagementController.cancelReasons(), received empty list.');

		Project__c testProject = TestUtil.generateProjectwithJobs(ProjectType.MD, Date.today().addDays(60), Date.today().addDays(70));
		Id[] jobIds = new Id[]{ [SELECT Id FROM Job__c WHERE Project__c = :testProject.Id LIMIT 1].Id };
		
		ActionResponse[] responses = JobManagementController.cancelJobs(jobIds, cancelReasons[0], 'Test');
		System.assertEquals(1, responses.size());
	}

	static testmethod void testDeleteJobs() {

		Project__c testProject = TestUtil.generateProjectwithJobs(ProjectType.MD, Date.today().addDays(60), Date.today().addDays(70));
		Id[] jobIds = new Id[]{ [SELECT Id FROM Job__c WHERE Project__c = :testProject.Id LIMIT 1].Id };

		ActionResponse[] responses = JobManagementController.deleteJobs(jobIds);
		System.assertEquals(1, responses.size());
	}
}