@isTest
private class JobAttemptWorkerActionsHelperTest {
	final static String INIT_FIRST_NAME = 'test';
	final static String INIT_LAST_NAME = 'test';

	@testSetup static void setup() {
		TriggerUtil.skipAllTriggers();
		TestDataUtil.init();
		TestProject.create('demo')
		.addAll();
		setupOrgCustSetting();
	}

	static void setupOrgCustSetting() {
		OrgCustomSettings__c org = [
		                             SELECT
		                             JAWImportFields__c,
		                             JAWImportTitle_c__c
		                             FROM OrgCustomSettings__c
		                             LIMIT 1
		                           ];
		org.JAWImportFields__c =
		  TestDataUtil.namifyImportFields('Name-0,FirstName__c-1-1,LastName__c-2-1');
		org.JAWImportTitle_c__c = 'Name,FirstName,LastName';
		update org;
	}

	static Account getAccount() {
		return [Select
		        Id,
		        Name,
		        ApexJobName__c,
		        BulkImportStatus__c
		        FROM Account
		        Order By Name  LIMIT 1];
	}

	static void setup3PLWorkers(Account acct, String status) {
		skipTrigger(true);
		List<JobAttemptWorker__c> workers = [
		                                      SELECT
		                                      Id,
		                                      FirstName__c,
		                                      LastName__c,
		                                      ThirdPartyAgency__c,
		                                      ThirdPartyAgencyStatus__c
		                                      FROM JobAttemptWorker__c
		                                    ];
		for (JobAttemptWorker__c w : workers) {
			w.ThirdPartyAgency__c = acct.Id;
			w.ThirdPartyAgencyStatus__c = status;
			w.FirstName__c = INIT_FIRST_NAME;
			w.LastName__c = INIT_LAST_NAME;
		}

		update workers;
	}

	static void setup3PLWorkersWithSomeNotMatched(Account acct, String status) {
		skipTrigger(true);
		List<JobAttemptWorker__c> workers = [
		                                      SELECT
		                                      Id,
		                                      FirstName__c,
		                                      LastName__c,
		                                      ThirdPartyAgency__c,
		                                      ThirdPartyAgencyStatus__c
		                                      FROM JobAttemptWorker__c
		                                    ];
		Integer index = 0;
		for (JobAttemptWorker__c w : workers) {
			w.ThirdPartyAgency__c = acct.Id;
			w.ThirdPartyAgencyStatus__c = status;
			w.FirstName__c = INIT_FIRST_NAME;
			w.LastName__c = INIT_LAST_NAME;
			index++;
			if (Math.mod(index, 3) == 0) {
				w.ThirdPartyAgency__c = null;
			}
		}

		update workers;
	}

	@isTest
	static void itShouldParse3PLIdsProperly() {
		// Given
		List<String> content = new String[] {
		  '1,test1',
		  '2,test2'
		};

		// When
		test.startTest();
		Set<String> data = JobAttemptWorkerActionsHelper.parseBody3PLIds(content, 0);
		test.stopTest();

		// Then
		List<String> result = new List<String>(data);
		QA.EQ('1', result[0], 'first is 1');
		QA.EQ('2', result[1], 'second is 2');
	}

	static List<String> genTestBody(String firstName, String lastName) {
		List<JobAttemptWorker__c> workers = [
		                                      SELECT
		                                      Name,
		                                      FirstName__c,
		                                      LastName__c
		                                      FROM JobAttemptWorker__c
		                                    ];
		List<String> body = new List<String>();
		for (JobAttemptWorker__c worker : workers) {
			List<String> content = new List<String>();
			content.add(worker.Name);
			content.add(firstName);
			content.add(lastName);
			body.add(String.join(content, ','));
		}

		return body;
	}

	static User genTestUser(Account acct) {
		Profile pfl = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
		return new User(Alias = 'standt',
		                Email = 'test.user@test.com',
		                EmailEncodingKey = 'UTF-8',
		                LastName = 'Testing',
		                LanguageLocaleKey = 'en_US',
		                LocaleSidKey = 'en_US', ProfileId = pfl.Id,
		                ThirdPartyAgency__c = acct.Name,
		                TimeZoneSidKey = 'America/Los_Angeles',
		                UserName = 'unit.tester@test.com');

	}

	static void skipTrigger(Boolean yes) {
		TriggerUtil.skipJobAttemptWorkerTrigger = yes;
	}

    /*
	@istest static void itShouldImport3PLIfFirstLastNameBothAssigned() {
		//GIVEN
		String firstName = 'louise';
		String lastName = 'tester';
		String status = CONSTANTS.JOB_ATTEMPT_WORKER_3PL_STATUS_COMMITTED;
		List<String> testBody = genTestBody(firstName, lastName);
		Account acct = getAccount();
		setup3PLWorkers(acct, CONSTANTS.JOB_ATTEMPT_WORKER_3PL_STATUS_ACCEPTED);
		User tester = genTestUser(acct);

		//WHEN
		test.startTest();
		skipTrigger(false);
		List<ActionResponse> responses;
		System.runAs(tester) {
			responses =
			  JobAttemptWorkerActionsHelper.update3plWorkersFromFile(testBody);
		}
		test.stopTest();

		//THEN
		String message = JSON.serialize(responses);
		for (JobAttemptWorker__c worker : [
		       SELECT
		       FirstName__c,
		       LastName__c,
		       ThirdPartyAgencyStatus__c
		       FROM JobAttemptWorker__c
		     ]) {
			QA.EQ(firstName, worker.FirstName__c, 'First Name update:' + message);
			QA.EQ(lastName, worker.LastName__c, 'Last name Update:' + message);
			QA.EQ(status, worker.ThirdPartyAgencyStatus__c, '3PL agency committed:' + message);
		}

	}

	*/
    
	@istest static void itShouldIgnoreFirstLastNameIfOneOfThemEmpty() {
//GIVEN
		String firstName = 'san';
		String lastName = '';
		String status = CONSTANTS.JOB_ATTEMPT_WORKER_3PL_STATUS_ACCEPTED;
		List<String> testBody = genTestBody(firstName, lastName);
		Account acct = getAccount();
		setup3PLWorkers(acct, status);
		User tester = genTestUser(acct);

		//WHEN
		test.startTest();
		skipTrigger(false);
		List<ActionResponse> responses;
		System.runAs(tester) {
			responses =
			  JobAttemptWorkerActionsHelper.update3plWorkersFromFile(testBody);
		}
		test.stopTest();

		//THEN
		String message = JSON.serialize(responses);
		for (JobAttemptWorker__c worker : [
		       SELECT
		       FirstName__c,
		       LastName__c,
		       ThirdPartyAgencyStatus__c
		       FROM JobAttemptWorker__c
		     ]) {
			QA.EQ(INIT_FIRST_NAME, worker.FirstName__c, 'First Name Not Update:' + message);
			QA.EQ(INIT_LAST_NAME, worker.LastName__c, 'Last Name Not Update:' + message);
			QA.EQ(status, worker.ThirdPartyAgencyStatus__c, '3PL Agency Status Not Committed:' + message);
		}
	}

	static List<String> genTestBodyForResponseVerification() {
		List<JobAttemptWorker__c> workers = [
		                                      SELECT
		                                      Name,
		                                      FirstName__c,
		                                      LastName__c
		                                      FROM JobAttemptWorker__c
		                                    ];
		Integer index = 0;
		List<String> body = new List<String>();
		body.add('');
		for (JobAttemptWorker__c worker : workers) {
			List<String> content = new List<String>();
			content.add(worker.Name);
			content.add('first');
			index++;
			if (Math.mod(index, 2) == 0) {
				content.add('last');
			} else {
				content.add('');
			}

			body.add(String.join(content, ','));
		}

		return body;
	}

  /*  
	@istest static void itShouldReturnProperResponses() {
		//GIVEN
		String status = CONSTANTS.JOB_ATTEMPT_WORKER_3PL_STATUS_ACCEPTED;
		List<String> testBody = genTestBodyForResponseVerification();
		Account acct = getAccount();
		setup3PLWorkersWithSomeNotMatched(acct, status);
		User tester = genTestUser(acct);

		//WHEN
		test.startTest();
		skipTrigger(false);
		List<ActionResponse> responses;
		System.runAs(tester) {
			responses =
			  JobAttemptWorkerActionsHelper.update3plWorkersFromFile(testBody);
		}
		test.stopTest();

		//THEN
		String msg = JSON.serialize(responses);
		Boolean hasNoMatch = false;
		Boolean hasMissingfield = false;
		Boolean hasOK = false;

		for (ActionResponse res : responses) {
			if (res.ResponseMessage.indexOf('succeeded') != -1) {
				hasOK = true;
				continue;
			}
			if (res.ResponseMessage.indexOf('missing') != -1) {
				hasMissingfield = true;
				continue;
			}
			if (res.ResponseMessage.indexOf('not matched') != -1) {
				hasNoMatch = true;
			}
		}
		QA.isTrue(hasOK, 'some succeeded');
		QA.isTrue(hasMissingfield, 'some missing first or last name');
		QA.isTrue(hasNoMatch, 'some not matched.');
	}
*/
	@isTest static void itShouldBehaveForActionResponseClass() {

		//GIVEN
		//WHEN
		test.startTest();
		ActionResponse rOk1 = ActionResponse.newInstance(null, true, 'ok');
		ActionResponse rOk2 = ActionResponse.succeeded('ok');
		ActionResponse rOk = ActionResponse.succeeded(null, 'ok');
		ActionResponse rBad = ActionResponse.failed(null, 'bad');
		ActionResponse rBad1 = ActionResponse.failed('bad');
		test.stopTest();

		//THEN
		QA.isTrue(rOk1.isSuccessful, 'succeeded');
		QA.EQ('ok', rOk1.ResponseMessage, 'ok msg');
		QA.isTrue(rOk2.isSuccessful, 'succeeded');
		QA.EQ('ok', rOk2.ResponseMessage, 'ok msg');
		QA.isTrue(rOk.isSuccessful, 'succeeded');
		QA.EQ('ok', rOk.ResponseMessage, 'ok msg');
		QA.isTrue(!rBad.isSuccessful, 'bad msg');
		QA.EQ('bad', rBad.ResponseMessage, 'bad nsg');
		QA.isTrue(!rBad1.isSuccessful, 'bad msg');
		QA.EQ('bad', rBad1.ResponseMessage, 'bad nsg');
	}

	@isTest static void itShouldWorkAsExpectedForResultAggregator() {
		//GIVEN
		ResultAggregator aggr = ResultAggregator.createInstance();

		//WHEN
		test.startTest();
		aggr.defineResult('1', 'ok')
		.addValue('1', 't1')
		.addValue('1', 't2');
		test.stopTest();

		//THEN
		QA.EQ(2, aggr.getTotalCount(), 'total:2');
		QA.EQ(1, (aggr.getKeys()).size(), 'one key');
		QA.EQ(2, (aggr.getValues('1')).size(), '2 values');
		QA.EQ('t1,t2', aggr.getValues('1', ','), 't1,t2 returned');
	}

    /*
	@isTest static void itShouldUnlockAccount() {
		//GIVEN
		Account acct = getAccount();
		acct.ApexJobName__c = '3PLImport';
		acct.BulkImportStatus__c = 'Queued';

		//WHEN
		test.startTest();
		JobAttemptWorkerActionsHelper.unlockAccount(acct.Id);
		test.stopTest();

		//THEN
		acct = getAccount();
		QA.isTrue(String.isBlank(acct.ApexJobName__c), 'apex job name reset');
		QA.isTrue(String.isBlank(acct.BulkImportStatus__c), 'bulk import status reset');
	}
*/
}