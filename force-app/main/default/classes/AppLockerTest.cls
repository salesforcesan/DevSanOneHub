@isTest
private class AppLockerTest {
	static final string OBJECT_TYPE = 'Project';
	static final string LOCKED_OBJECT_ID = '111111111';
	static final string TEST_OBJECT_ID = '2222222';
	static final string LOCKED_OBJECT_TOKEN;
	static final string LOCKED_REASON = 'test';
	static final string LOCK_REQUESTOR = 'import_job';
	static final AppLocker locker;

	static {
		locker = AppLocker.newInstance(OBJECT_TYPE, LOCKED_OBJECT_ID, LOCK_REQUESTOR);
		LOCKED_OBJECT_TOKEN = locker.getToken();
	}

	@testSetup
	static void setup() {
		locker.lock();
	}

	static AppLocker__c getLocker(String oId) {
		return [SELECT Id, Token__c, StartTime__c, RequestorId__c FROM
		        AppLocker__c WHERE ObjectId__c = :oId limit 1];
	}

	@isTest
	static void itShouldGetLockerFromReleasedLock() {
		//GIVEN
		String error = '';
		locker.release();
		QA.isTrue(!locker.isLocked(), 'not locked');
		AppLocker__c lock = getLocker(LOCKED_OBJECT_ID);
		QA.isTrue(String.isBlank(lock.Token__c),'no token assigned');

		//WHEN
		test.startTest();
		try {
			locker.lock();
		} catch (Exception ex) {
			error = ex.getMessage();
		}
		test.stopTest();

		//THEN
		QA.isTrue(String.isBlank(error), 'no error: ' + error);
	}

	@isTest
	static void itShouldGenLockRecordIfNotExisted() {
		//GIVEN
		List<AppLocker__c> logs = [SELECT Id from AppLocker__c];
		QA.isTrue(!logs.isEmpty(), 'should have setup lock record');
		DBX.doDelete(logs.get(0));

		//WHEN
		itShouldLockObjectProperly();
	}

	@isTest
	static void itShouldAcceptPassInToken() {
		//GIVEN
		String token = String.join(new String[] {OBJECT_TYPE, TEST_OBJECT_ID}, '_');
		AppLocker locker = AppLocker.newInstance(OBJECT_TYPE, TEST_OBJECT_ID, LOCK_REQUESTOR, token);

		//WHEN
		test.startTest();
		locker.lock();
		test.stopTest();

		//THEN
		QA.EQ(token, locker.getToken(), 'use the pass-in token');
	}

	@isTest
	static void itShouldLockObjectProperly() {
		// Given
		AppLocker locker = AppLocker.newInstance(OBJECT_TYPE, TEST_OBJECT_ID, LOCK_REQUESTOR);

		// When
		test.startTest();
		locker.lock();
		test.stopTest();

		// Then
		AppLocker__c sideEffect = getLocker(TEST_OBJECT_ID);
		QA.EQ(locker.getToken(), sideEffect.Token__c, 'token match');
		QA.EQ(LOCK_REQUESTOR, sideEffect.RequestorId__c, 'requestor match');
	}

	@isTest
	static void itShouldReleaseObjectProperly() {
		//GIVEN
		AppLocker locker = AppLocker.newInstance(OBJECT_TYPE, TEST_OBJECT_ID, LOCK_REQUESTOR);
		locker.lock();

		//WHEN
		test.startTest();
		locker.release();
		test.stopTest();

		//THEN
		AppLocker__c effect = getLocker(TEST_OBJECT_ID);

		QA.EQ(null, effect.Token__c, 'empty token');
		QA.EQ(null, effect.StartTime__c, 'empty starttime');
		QA.EQ(null, effect.RequestorId__c, 'empty requestor');
	}

	@isTest
	static void itShouldErrorOutIfTrytoLockTheLockedProject() {
		//GIVEN
		String error = '';
		AppLocker locker = AppLocker.newInstance(OBJECT_TYPE, TEST_OBJECT_ID, LOCK_REQUESTOR);
		locker.lock();

		//WHEN
		test.startTest();
		AppLocker locker1 = AppLocker.newInstance(OBJECT_TYPE, TEST_OBJECT_ID, LOCK_REQUESTOR);
		try {
			locker1.lock();
		} catch (Exception ex) {
			error = ex.getMessage();
		}

		test.stopTest();

		//THEN
		QA.isTrue(String.isNotBlank(error), 'exception logged into applog');
	}
}