@isTest
private class JobAttemptTriggerHandlerTest {
    @testSetup static void setup() {
    	TriggerUtil.SkipAllTriggers();
    	TestDataUtil.init();
    	TestProject.create('demo')
    		.addAll();
		}
		
    static Job__c getOneJob(string projectId) {
    	return [SELECT Id, NumberOfWorkers__c, ActiveJobAttempt__c from job__c where project__c = :projectId limit 1];
    }

    static JobAttempt__c getAttempt(String jobId) {
    	return [SELECT Id, ExpectedNumberofWorkers__c from JobAttempt__c 
    	where Job__c = :jobId];
    }
    static Integer getAttempWorkerCount(String attemptId) {
    	List<JobAttemptWorker__c> workers = [
    		SELECT 
    			Id 
    		from JobAttemptWorker__c 
    		where JobAttempt__c = :attemptId and Status__c != :CONSTANTS.JOB_ATTEMPT_WORKER_STATUS_CANCELED ];
    	
    	return workers.size();
		}
		
		@isTest
    static void testNumberOfWorkerDecreaseBehavior() {
    	//GIVEN
    	TriggerUtil.SkipAllTriggers();
    	Project__c p = TestProject.getProjects()[0];
    	p.BundleServices__c = false;
    	update p;

    	List<Contact> contacts = TestProject.getContacts();
    	Integer expectedCount = contacts.size() -4;
    	
    	Job__c job = getOneJob(p.Id);
    	job.NumberOfWorkers__c = contacts.size();
    	update job;
    	
    	JobAttempt__c attempt = getAttempt(job.Id);
    	attempt.ExpectedNumberofWorkers__c = contacts.size();
    	update attempt;

    	//WHEN
			test.startTest();
			TriggerUtil.skipJobTrigger = false;
			TriggerUtil.SkipJobUpdateTrigger = false;
			TriggerUtil.skipJobAttemptTrigger = false;

    	job = getOneJob(p.Id);
    	job.NumberOfWorkers__c = expectedCount;
    	update job;
    	test.stopTest();
    	
    	//THEN
    	QA.EQ(job.ActiveJobAttempt__c, attempt.Id, 'job active attempt is the one that we test');

        job = getOneJob(p.Id);
    	QA.EQ(expectedCount, job.NumberOfWorkers__c, 'NumOfWorker@job decreased');
    	attempt = getAttempt(job.Id);
    	QA.EQ(expectedCount, attempt.ExpectedNumberofWorkers__c, 'expected NumOfWorker@Attemp decreased');
    	
        Integer workerCount = getAttempWorkerCount(attempt.Id);
    	QA.EQ(expectedCount, workerCount, 'job attempt worker count decreased');
    }

//// code coverage purpose
//@isTest static void testBeforeUpdateHandler() {
//    //given
//    Contact contact = TestUtil.prepareContacts()[MAX_CONTACTS -1];
//    TestUtil.turnOffTrigger();
//    Map<ID, JobAttempt__c> newMap = new Map<ID, JobAttempt__c>(), oldMap = new Map<ID, JobAttempt__c>();
//    JobAttempt__c newA = TestUtil.getAttempt(null), oldA = TestUtil.getAttempt(newA.Id);
//    Job__c job = TestUtil.getJob(newA.Job__c);

//    newA.AssignedContactId__c = contact.ContactId__c;
//    newA.ReportedContactId__c = contact.ContactId__c;
//    newA.AttemptScheduleDate__c = START_DATE.addDays(1);
//    oldA.AttemptScheduleDate__c = START_DATE.addDays(2);
//    Map<Boolean, Exception__c> exceptionMap = TestUtil.getExceptionsByService(job.Service__c);
//    newA.ExceptionCode__c = exceptionMap.get(false).ExceptionCode__c;

//    newMap.put(newA.Id, newA);
//    oldMap.put(oldA.Id, oldA);
//    ISobjectTriggerEventHandler handler = JobAttemptTriggerBeforeUpdateHandler.newInstance(newMap, oldMap);
//    runCodeCoverage(handler, newMap, oldMap);
//}

//static void runCodeCoverage(ISobjectTriggerEventHandler handler, Map<ID,JobAttempt__c>newMap, Map<ID, JobAttempt__c> oldMap) {
//    JobAttempt__c a = newMap.values()[0];
//    a.AttemptStatus__c = CONSTANTS.JOB_STATUS_ASSIGNED;
//    update a;
//    handler.execute();
//    a.AttemptStatus__c = CONSTANTS.JOB_ATTEMPT_STATUS_OPEN;
//    update a;
//    handler.execute();
//    a.AttemptedDate__c = START_DATE;
//    a.AttemptStatus__c = CONSTANTS.JOB_ATTEMPT_STATUS_REPORTED;
//    update a;
//    handler.execute();
//    handler.execute();
//    a.AttemptStatus__c = CONSTANTS.JOB_ATTEMPT_STATUS_STARTED;
//    update a;
//    handler.execute();
//}

//@isTest static void testAfterUpdateHandler() {
//    //given
//    TestUtil.turnOffTrigger();
//    Map<ID, JobAttempt__c> newMap = new Map<ID, JobAttempt__c>(), oldMap = new Map<ID, JobAttempt__c>();
//    JobAttempt__c a = TestUtil.getAttempt(null);
//    newMap.put(a.Id, a);
//    oldMap.put(a.Id, a);
//    ISobjectTriggerEventHandler handler = JobAttemptTriggerAfterUpdateHandler.newInstance(newMap, oldMap);
//    runCodeCoverage(handler, newMap, oldMap);
//}

//// Scenario: (OH536) Incorrect Exception code is displayed for Job attempt reported with Exception
//    @isTest
//    static void WhenECSendNewExceptionCodeCommentsAndReasonForReportedJobAttemptItshouldBeupdated()
//    {        
//        String option= CONSTANTS.SCHEDULE_OPTION_EC;
//        Date expected = START_DATE.addDays(10);
//        String expectedComment = 'Manager Refused';
        
//        // Given
//        TestUtil.turnOffTrigger();
//        JobAttempt__c attempt = TestUtil.getAttempt(null);
//        Job__c job = TestUtil.getJob(attempt.Job__c);
//        Map<Boolean, Exception__c> exceptionMap = TestUtil.getExceptionsByService(job.Service__c);


//        Project__c project = TestUtil.getProject(job.Project__c);
//        project.Status__c = CONSTANTS.PROJECT_STATUS_LAUNCHED;
//        project.ProjectScheduleOption__c = TestUtil.getScheduleOptionId(option);
//        update project;
        
//        attempt.ExceptionCode__c = exceptionMap.get(false).ExceptionCode__c;
//        attempt.AttemptStatus__c = CONSTANTS.JOB_ATTEMPT_STATUS_REPORTED;
//        attempt.ExceptionComments__c = 'Anything possible';
//        update attempt;
        
//        // When
//        TestUtil.turnOnJobTrigger();
//        Test.startTest();
//        attempt.ExceptionCode__c = exceptionMap.get(true).ExceptionCode__c;
//        attempt.AttemptStatus__c = CONSTANTS.JOB_ATTEMPT_STATUS_REPORTED;
//        attempt.ExceptionComments__c = expectedComment;
//        update attempt;
//        Test.stopTest();

//        // Then
//        JobAttempt__c result = TestUtil.getAttempt(attempt.Id);
//        System.assertEquals(exceptionMap.get(true).ExceptionCode__c, result.ExceptionCode__c, 'Should See Manager Refused as exception code.');
//       System.assertEquals(exceptionMap.get(true).Name, result.ExceptionReason__c, 'ExceptionReason iS Manager Refused');
//        System.assertEquals(true, result.IsExecuted__c,'Attempt is executed.');
//        System.assertEquals(expectedComment, result.ExceptionComments__c, 'ExceptionComments is Manager Resfused.');
//    }


////----<OH217 Open Job Attempt>----
//    //scneario: positive test: when a job attempt is open/reopen, assignment, attempt date should be null
//        @isTest static void TestOpenJobAttemptWhenAlreadyAssigned() {

//            //--given--
//            TestUtil.turnOffTrigger();
//            List<Contact> contacts = TestUtil.prepareContacts();
//            JobAttempt__c attempt = TestUtil.getAttempt(null);
//            attempt.AttemptStatus__c = CONSTANTS.JOB_ATTEMPT_STATUS_ASSIGNED;
//            attempt.attemptType__c = CONSTANTS.JOB_ATTEMPT_TYPE_ORIGINAL;
//            attempt.DateStarted__c = START_DATE.addDays(1);
//            attempt.AttemptedDate__c = START_DATE.addDays(2);
//            attempt.DateAssigned__c = START_DATE.addDays(-10);
//            attempt.AssignedContactId__c = contacts[0].ContactId__c;
//            update attempt;
//            Job__c job = TestUtil.getJob(attempt.Job__c);
//            job.JobStatus__c = CONSTANTS.JOB_STATUS_ASSIGNED;
//            job.JobDateAssigned__c = START_DATE.addDays(-10);
//            update job;

//            //--when--
//            TestUtil.turnOnJobTrigger();
//            Test.startTest();
//            attempt.AttemptStatus__c = CONSTANTS.JOB_ATTEMPT_STATUS_OPEN;
//            update attempt;
//            Test.stopTest();

//            //--then--
//            JobAttempt__c at = TestUtil.getAttempt(attempt.Id);
//            System.assertEquals(null, at.AssignedContact__c, 'Assigned Contact Should be unassigned');
//            System.assertEquals(null, at.AssignedContactId__c, 'Assigned contact Id should be null');
//            System.assertEquals(null, at.DateStarted__c, 'started date is null');
//            System.assertEquals(null, at.DateAssigned__c, 'assigned date should be null');
//            System.assertEquals(null, at.DateReported__c, 'reported date should be null');
//            job = TestUtil.getJob(job.Id);
//            System.assertEquals(CONSTANTS.JOB_STATUS_OPEN, job.JobStatus__c, 'Job should be open');
//            System.assertEquals(null, job.JobDateAssigned__c, 'job date assign is null');
//        }

//    //scenario: negative test: when reopening a job attempt (not in started, assigned, open), it shoud throw an error
//        @isTest static void TestShouldFailToReOpenJobAttemptWhenAlreadyCanceled() {
            
//            //--given--
//            TestUtil.turnOffTrigger();
//            JobAttempt__c attempt = TestUtil.getAttempt(null);
//            attempt.AttemptStatus__c = CONSTANTS.JOB_ATTEMPT_STATUS_CANCELED;
//            update attempt;
//            Job__c job = TestUtil.getJob(attempt.Job__c);
//            job.JobStatus__c = CONSTANTS.JOB_STATUS_STARTED;
//            update job;

//            //--when--
//            Exception expected;
//            String expectedError = 'A job attempt can be open only if it is assigned, started or open.';
//            try {
//                TestUtil.turnOnJobTrigger();
//                Test.startTest();
//                attempt.AttemptStatus__c = CONSTANTS.JOB_ATTEMPT_STATUS_OPEN;
//                update attempt;
//                Test.stopTest();
//                throw new DmlException('Reopening a canceled job attempt should fail. But didn\'t happen');
//            }
//            catch(Exception ex) {
//                expected = ex;
//            }

//            //--then--
//            System.assertNotEquals(-1, expected.getMessage().indexOf(expectedError), 'Reopen should failed.');
//        }
/////////////////////////////////////////////////////////////////////////////////


////OH218: As a Product Owner, I want the Attempt Status set to STARTED when an Execution Company 
//  //indicates that they have started working a Job so that I know that my Job has started as expected.
    
//    @isTest static void testStartAJobAttempt() {

//        //given
//        TestUtil.turnOffTrigger();
//        String jobStatus = CONSTANTS.JOB_STATUS_PENDING,
//            attemptStatus = CONSTANTS.JOB_ATTEMPT_STATUS_OPEN;
//        JobAttempt__c att = TestUtil.getAttempt(null);
//        att.AttemptStatus__c = attemptStatus;
//        att.DateReported__c = null;
//        att.ECAttemptId__c = null;
//        update att;
//        Job__c job = TestUtil.getJob(att.Job__c);
//        job.JobStatus__c = jobStatus;
//        update job;

//        //when
//        Test.startTest();
//        TestUtil.turnOnJobTrigger();
//        att.AttemptStatus__c = CONSTANTS.JOB_ATTEMPT_STATUS_STARTED;
//        att.ECAttemptId__c = 'ecid';
//        att.AssignedContact__c = null;
//        update att;
//        Test.stopTest();

//        //then
//        JobAttempt__c result = TestUtil.getAttempt(att.Id);
//        Job__c resultJob = TestUtil.getJob(att.Job__c);
//        System.Assert(CONSTANTS.JOB_ATTEMPT_STATUS_STARTED.equalsIgnoreCase(result.AttemptStatus__c), 'AttemptStatus Changed to Started');
//        System.Assert(CONSTANTS.JOB_STATUS_STARTED.equalsIgnoreCase(resultJob.JobStatus__c), 'job status is restarted');
//        System.assertNotEquals(null, result.DateStarted__c, 'Attempt Started Date is Not null');
//        System.Assert(result.ReportedContact__c == null, 'Executed Contact is null');
//        System.Assert(result.ECAttemptId__c == 'ecid', 'ECAttemptId Assigned');
//        System.Assert(resultJob.JobDateStarted__c == result.DateStarted__c, 'Job And Attempt has the same started Datetime');
//        System.Assert(result.DateReported__c == null, 'ReportedDate Not Assigned');
//    }

//    @isTest static void testHandleFirstJobAttempt() {
//        String jobStatus = CONSTANTS.JOB_STATUS_PENDING,
//            attemptStatus = CONSTANTS.JOB_ATTEMPT_STATUS_STARTED;

//        //given
//        TestUtil.turnOffTrigger();
//        JobAttempt__c att = TestUtil.getAttempt(null);
//        att.AttemptStatus__c = attemptStatus;
//        att.DateReported__c = null;
//        att.ECAttemptId__c = null;
//        update att;
//        Job__c job = TestUtil.getJob(att.Job__c);
//        job.JobStatus__c = jobStatus;
//        update job;

//        //when
//        Test.startTest();
//        TestUtil.turnOnJobTrigger();
//        att.AttemptStatus__c = CONSTANTS.JOB_ATTEMPT_STATUS_STARTED;
//        att.ECAttemptId__c = 'ecid';
//        att.AssignedContact__c = null;
//        att.AttemptedDate__c = START_DATE.addDays(-1);
//        update att;
//        Test.stopTest();

//        JobAttempt__c result = TestUtil.getAttempt(att.Id);
//        Job__c resultJob = TestUtil.getJob(att.Job__c);
//        System.Assert(CONSTANTS.JOB_ATTEMPT_STATUS_STARTED.equalsIgnoreCase(result.AttemptStatus__c), 'AttemptStatus Changed to Started');
//        System.Assert(CONSTANTS.JOB_STATUS_STARTED.equalsIgnoreCase(resultJob.JobStatus__c), 'job status is restarted');
//        System.assertNotEquals(null, result.DateStarted__c, 'Attempt Started Date is Not null');
//        System.assertEquals(result.AttemptedDate__c, resultJob.JobFirstAttemptDate__c, 'job frist attempt date is set');
//    }

////OH215: As a Product Owner, I want to set the status of an active attempt to ASSIGNED 
//    //so that I know that a Job is currently staffed.
//    @isTest static void testAssignAJobAttempt() {
//        String jobStatus = CONSTANTS.JOB_STATUS_OPEN, 
//            attemptStatus = CONSTANTS.JOB_ATTEMPT_STATUS_OPEN;
//        Date expectedDateStarted = START_DATE.addDays(1);
//        Date expectedDateReported = START_DATE.addDays(10);

//        //given
//        TestUtil.turnOffTrigger();
//        JobAttempt__c att = TestUtil.getAttempt(null);
//        Contact expectedContact = TestUtil.prepareContacts()[MAX_CONTACTS-5];
//        att.DateReported__c = expectedDateReported;
//        att.DateStarted__c = expectedDateStarted;
//        att.ReportedContact__c = expectedContact.Id;
//        att.ECAttemptId__c = null;
//        att.AttemptStatus__c = attemptStatus;
//        update att;
//        Job__c job = TestUtil.getJob(att.Job__c);
//        job.JobStatus__c = jobStatus;
//        update job;

//        //when
//        TestUtil.turnOnJobTrigger();
//        Test.startTest();
//        att.AttemptStatus__c = CONSTANTS.JOB_ATTEMPT_STATUS_ASSIGNED;
//        att.ECAttemptId__c = 'ecid';
//        att.AssignedContactId__c = expectedContact.ContactId__c;
//        update att;
//        Test.stopTest();

//        //then
//        JobAttempt__c result = TestUtil.getAttempt(att.Id);
//        Job__c resultJob = TestUtil.getJob(att.Job__c);
//        System.Assert(result.AttemptStatus__c == CONSTANTS.JOB_ATTEMPT_STATUS_Assigned, 'AttemptStatus Changed to Assigned');
//        System.Assert(result.AssignedContact__c == expectedContact.Id, 'Assigned Contact Set');
//        System.Assert(result.ECAttemptId__c == 'ecid', 'ECAttemptId Assigned');
//        System.Assert(result.ReportedContact__c == null, 'ExecutedContact Not Assigned');
//        System.Assert(result.DateStarted__c == null, 'Attempt StartDate Not Assigned');
//        //System.Assert(result.DateReported__c == null, 'ReportedDate Not Assigned');
//        System.Assert(resultJob.JObDateAssigned__c != null, 'Job DateAssigned Set');
//        System.assertEquals(resultJob.JobDateOriginallyAssigned__c, resultJob.JObDateAssigned__c, 'assign with original equal');
//        System.Assert(CONSTANTS.JOB_STATUS_ASSIGNED.equalsIgnoreCase(resultJob.JobStatus__c), 'job status is assigned');
//    }

//     @isTest static void testAssignAlreadyAssignedJobAttemptWithDifferentAssignedContactId() {
//        String jobStatus = CONSTANTS.JOB_STATUS_PENDING, 
//            attemptStatus = CONSTANTS.JOB_ATTEMPT_STATUS_STARTED;
        
//        //given
//        TestUtil.turnOffTrigger();
//        JobAttempt__c att = TestUtil.getAttempt(null);
//        Contact expectedContact = TestUtil.prepareContacts()[MAX_CONTACTS-4];
//        att.AttemptStatus__c = attemptStatus;
//        att.DateStarted__c = START_DATE.addDays(1);
//        att.DateReported__c = START_DATE.addDays(2);
//        att.AssignedContactId__c = null;
//        att.ECAttemptId__c = null;
//        update att;
//        Job__c job = TestUtil.getJob(att.Job__c);
//        job.JobStatus__c = jobStatus;
//        update job;

//        //when
//        TestUtil.turnOnJobTrigger();
//        Test.startTest();
//        att.AttemptStatus__c = CONSTANTS.JOB_ATTEMPT_STATUS_ASSIGNED;
//        att.ECAttemptId__c = 'ecid';
//        att.AssignedContactId__c = expectedContact.ContactId__c;
//        update att;
//        Test.stopTest();

//        //then
//        JobAttempt__c result = TestUtil.getAttempt(att.Id);
//        Job__c resultJob = TestUtil.getJob(att.Job__c);
//        System.Assert(result.AttemptStatus__c == CONSTANTS.JOB_ATTEMPT_STATUS_Assigned, 'AttemptStatus Changed to Assigned');
//        System.Assert(result.AssignedContact__c == expectedContact.Id, 'Assigned Contact Set');
//        System.Assert(result.ECAttemptId__c == 'ecid', 'ECAttemptId Assigned');
//        System.Assert(result.ReportedContact__c == null, 'ExecutedContact Not Assigned');
//        System.Assert(result.DateStarted__c == null, 'Attempt StartDate Not Assigned');
//        //System.Assert(result.DateReported__c == null, 'ReportedDate Not Assigned');
//        System.Assert(resultJob.JObDateAssigned__c != null, 'Job DateAssigned Set');
//        System.assertNotEquals(null, result.DateAssigned__c, 'Assigned date is set');
//        System.assertNotEquals(null, resultJob.JobDateOriginallyAssigned__c, 'job original assigned date not null.');
//        System.assertNotEquals(null, resultJob.JobDateAssigned__c, 'job assigned date not null.');
//        System.Assert(CONSTANTS.JOB_STATUS_ASSIGNED.equalsIgnoreCase(resultJob.JobStatus__c), 'job status is assigned');
//    }

//    @isTest static void testWhenJobAttemptIsAssignedWithoutAssignmentContactThenJobShouldBeAssigned() {
//        //given
//        TestUtil.turnOffTrigger();
//        JobAttempt__c att = TestUtil.getAttempt(null);
//        att.AttemptStatus__c = CONSTANTS.JOB_ATTEMPT_STATUS_OPEN;
//        att.AssignedContactId__c = null;
//        att.AssignedContact__c = null;
//        update att;
//        Job__c job = TestUtil.getJob(att.Job__c);
//        job.JobStatus__c = CONSTANTS.JOB_STATUS_OPEN;
//        update job;

//        //when
//        Test.startTest();
//        TestUtil.turnOnJobTrigger();
//        att.AttemptStatus__c = CONSTANTS.JOB_ATTEMPT_STATUS_ASSIGNED;
//        update att;
//        Test.stopTest();

//        //then
//        att = TestUtil.getAttempt(att.Id);
//        System.assertEquals(true, CONSTANTS.JOB_ATTEMPT_STATUS_ASSIGNED.equalsIgnoreCase(att.AttemptStatus__c),'Attempt Status  Should be Assigned');

//        Job__c result= TestUtil.getJob(att.Job__c);
//        System.assertEquals(true, CONSTANTS.JOB_STATUS_ASSIGNED.equalsIgnoreCase(result.JobStatus__c), 'Job Should be assigned');
//    }

////OH216: As a Product Owner, I want to the Job Attempt status set to REPORTED 
//    //when an Execution Company reports an attempt so that I know that other actions should occur.
    
//    //scenario: when reporting a job attempt, ensure IsExecuted is set with/without exeption code properly.
//        @isTest static void testReportAJobAttempt() {
//            //--given--
//            TestUtil.turnOffTrigger();
//            JobAttempt__c att = TestUtil.getAttempt(null);
//            att.AttemptStatus__c = CONSTANTS.JOB_ATTEMPT_STATUS_OPEN;
//            update att;
//            Job__c job = TestUtil.getJob(att.Job__c);
//            job.JobStatus__c = CONSTANTS.JOB_STATUS_OPEN;
//            update job;
//            String expectedECAttemptId = 'ZYZ123123';
//            String exceptedExceptionComment = 'hi, test';
//            Contact expectedContact = TestUtil.prepareContacts()[MAX_CONTACTS - 3];
//            Map<Boolean, Exception__c> exceptionMap = TestUtil.getExceptionsByService(job.Service__c);
//            Exception__c expectedException = exceptionMap.get(true);

//            //--when--
//            TestUtil.turnOnJobTrigger();
//            TEST.startTest();
//            att.AttemptStatus__c = CONSTANTS.JOB_ATTEMPT_STATUS_REPORTED;
//            att.ECAttemptId__c = expectedECAttemptId;
//            Datetime dtNow = Datetime.now().addDays(-2);
//            att.AttemptedDate__c = dtNow.Date();
//            att.ReportedContactId__c = expectedContact.ContactId__c;
//            att.ExceptionCode__c =  expectedException.ExceptionCode__c;
//            att.ExceptionComments__c = exceptedExceptionComment;
//            update att;
//            TEST.stopTest();
            
//            //--then--
//            JobAttempt__c r = TestUtil.getAttempt(att.Id);
//            Job__c rJob = TestUtil.getJob(att.Job__c);
//            System.assert(expectedException.Name == r.ExceptionReason__c, 'Reason is assigned:' + r.ExceptionReason__c);
//            System.assertEquals(r.DateReported__c, r.DateOriginallyReported__c, 'date reported == date originally reported.');
//            System.assert(CONSTANTS.JOB_ATTEMPT_STATUS_REPORTED.equalsIgnoreCase(r.AttemptStatus__c), 'a job attempt was reported.');
//            System.assertEquals(expectedECAttemptId, r.ECAttemptId__c,'EC AttemptId assigned');
//            System.assertEquals(expectedContact.Id, r.ReportedContact__c, 'Reported Contact Assigned');
//            System.assertEquals(CONSTANTS.JOB_STATUS_REPORTED, rJob.JobStatus__c,'job reported');
//            System.assertEquals(rJob.IsExecuted__c, r.IsExecuted__c, 'attempt and job execution status should be same');
//            System.assertNotEquals(null, rJob.Service__c, 'Service Is set');
//            System.assertEquals(dtNow.date(), r.AttemptedDate__c, 'job attempted date is set');
//            System.assertEquals(true, r.IsExecuted__c, 'attempt IsExecuted should be true');
//            System.assertNotEquals(null,rJob.JobExecutedDate__c, 'executed date assigned if executed flag is true');
//            System.assertEquals(exceptedExceptionComment, r.ExceptionComments__c, 'exception comment is expected.');
//        }

//        @isTest static void testReportAJobWithInvalidExceptionCode() {
//            //--given--
//            TestUtil.turnOffTrigger();
//            JobAttempt__c att = TestUtil.getAttempt(null);
//            att.AttemptStatus__c = CONSTANTS.JOB_ATTEMPT_STATUS_ASSIGNED;
//            update att;
//            Job__c job = TestUtil.getJob(att.Job__c);
//            job.JobStatus__c = CONSTANTS.JOB_STATUS_PENDING;
//            update job;

//            //--when--
//            TestUtil.turnOnJobTrigger();
//            String expectedError = 'The exception code:ZYZ is invalid';
//            Exception expected;
//            try {
//                TEST.startTest();
//                att.ExceptionCode__c = 'ZYZ';
//                att.AttemptStatus__c = CONSTANTS.JOB_ATTEMPT_STATUS_REPORTED;
//                update att;
//                TEST.stopTest();
//                throw new DmlException('ReportAJobWithInvalidExceptionCode should throw an exception.');
//            } 
//            catch(Exception ex) {
//                expected = ex;
//            }

//            //--then--
//           System.assert(expected.getMessage().indexOf(expectedError) != -1, 'ReportWithInvalidExceptionCodeShouldThrowAnError.');
//        }
     
//        /* This requirement is not valid anymore - RN
//        @isTest static void TestReportAJobOnlyIfInOpenStartedAssignedReportedStatus() {
//            string attemptStatus = CONSTANTS.JOB_ATTEMPT_STATUS_CANCELED,
//                jobStatus = CONSTANTS.JOB_STATUS_STARTED;

//            //--given--
//            TestUtil.turnOffTrigger();
//            JobAttempt__c att = TestUtil.getAttempt(null);
//            att.AttemptStatus__c = attemptStatus;
//            update att;
//            Job__c job = TestUtil.getJob(att.Job__c);
//            job.JobStatus__c = jobStatus;
//            update job;
//            Contact expectedContact = TestUtil.prepareContacts()[MAX_CONTACTS-6];

//            //--when--
//            TestUtil.turnOnJobTrigger();
//            try {
//                Test.startTest();
//                att.AttemptStatus__c = CONSTANTS.JOB_ATTEMPT_STATUS_REPORTED;
//                att.ReportedContact__c = expectedContact.Id;
//                update att;
//                Test.stopTest();
//                throw new DmlException('When an active canceled job attempt is reported, an error should occur but it doesn\'t happen.');
//            } catch(Exception e) {
//                System.assert(e.getMessage().indexOf('An active job attempt can be reported only when the attempt status is Open, Started, Reported or Assigned.') != -1, e.getMessage());
//            }
//        }
//        */
////////////////////////////////////////////////////////////////////////////////////////////////
//// Scenario: when EC set schedule date, it should be assigned to attempt and job
//    @isTest
//    static void WhenECSetScheduleDateAttemptAndJobScheduledDateShouldBeAssigned()
//    {        
//        IPredicateBuilder jobFilter, filter;
//        String option= CONSTANTS.SCHEDULE_OPTION_EC;
//        Date expected = START_DATE.addDays(10);

//        // Given
//        TestUtil.turnOffTrigger();
//        JobAttempt__c attempt = (JobAttempt__c) TestUtil.getRecord('JobAttempt__c');
//        jobFilter = PredicateBuilder.newBuilder()
//                .addPredicate('Id', SQLDataType.sqlString, SQLQueryOperator.sqlEqual, attempt.Job__c);
//        Job__c job = (Job__c)TestUtil.findRecord('Job__c',jobFilter);
//        filter = PredicateBuilder.newBuilder()
//            .addPredicate('Id', SQLDataType.sqlString, SqlQueryOperator.sqlEqual, job.Project__c);
//        Project__c project = (Project__c)TestUtil.findRecord('Project__c', filter);
//        project.Status__c = CONSTANTS.PROJECT_STATUS_PLANNING;
//        project.ProjectScheduleOption__c = TestUtil.getScheduleOptionId(option);
//        update project;

//        // When
//        Test.startTest();
//        TestUtil.turnOnJobTrigger();
//        attempt.AttemptScheduleDate__c = expected;
//        update attempt;
//        Test.stopTest();

//        // Then
//        job = TestUtil.getJob(job.Id);
//        SObject aResult = TestUtil.getAttempt(attempt.Id);
//        //System.assertEquals(expected, aResult.get(TestUtil.namify('AttemptScheduleDate__c')), 'Attemp scheduledate is set');
//        System.assertEquals(expected, job.JobScheduledDate__c,'job scheduled date is set correctly.');
//        System.assertEquals(expected, job.ActiveJobAttempt__r.AttemptScheduleDate__c, 'attempt schedule date from active attempt is set');
//        System.assertEquals(aResult.get('Id'), job.ActiveJobAttempt__c, 'Active Job Attempt is assigned');
//        System.assertEquals(true, job.IsScheduled__c, 'isScheduled == true');
//        //System.assertNotEquals(null, aResult.get(TestUtil.namify('AttemptScheduledDate__c')), 'system attempt scheduled date set');
//    }

//// Scenario: when EC reschedule date, it should be assigned to attempt and job and reschedule flag should be true
//    @isTest
//    static void WhenECSetReScheduleDateAttemptItShouldBeThatNumberOfRescheduleAndJobRescheduleFlagAreTrue()
//    {        
//        String option= CONSTANTS.SCHEDULE_OPTION_EC;
//        Date expected = START_DATE.addDays(10);
//        Date expectedCommittedDate = START_DATE.addDays(5);

//        // Given
//        TestUtil.turnOffTrigger();
//        JobAttempt__c attempt = TestUtil.getAttempt(null);
//        attempt.NumberOfReschedules__c = null;
//        update attempt;

//        Job__c job = TestUtil.getJob(attempt.Job__c);
//        Project__c project = TestUtil.getProject(job.Project__c);
//        project.Status__c = CONSTANTS.PROJECT_STATUS_INPROGRESS;
//        project.ProjectScheduleOption__c = TestUtil.getScheduleOptionId(option);
//        update project;
        
//        // When
//        Test.startTest();
//        TestUtil.turnOnJobTrigger();
//        attempt.AttemptScheduleDate__c = expectedCommittedDate;
//        update attempt;
//        attempt.AttemptScheduleDate__c = expected;
//        update attempt;
//        Test.stopTest();

//        // Then
//        job = TestUtil.getJob(attempt.Job__c);
//        attempt = TestUtil.getAttempt(attempt.Id);
//        System.assertEquals(expected, attempt.AttemptScheduleDate__c, 'Attemp scheduledate is set');
//        System.assertEquals(expected, job.JobScheduledDate__c,'job scheduled date is set correctly.');
//        System.assertEquals(expected, job.ActiveJobAttempt__r.AttemptScheduleDate__c, 'attempt schedule date from active attempt is set');
//        System.assertEquals(expectedCommittedDate, job.JobCommittedDate__c, 'committed date should not be changed');
//        System.assertEquals(attempt.Id, job.ActiveJobAttempt__c, 'Active Job Attempt is assigned');
//        System.assertEquals(true, job.IsReScheduled__c,'Job Reschedule Flag is true');
//        System.assertEquals(1, attempt.NumberOfReschedules__c, 'Job attempt Reschedule count is add by 1');
//    }

////----<OH280: Setting Job Committed Date> ----
//    @isTest static void testJobExecutedOnDateLogicForECWithProjectInProgress(){
//        Date expected = Datetime.now().Date();

//        // given
//        TestUtil.turnOffTrigger();
//        JobAttempt__c attempt = TestUtil.getAttempt(null);
//        attempt.AttemptStatus__c = CONSTANTS.JOB_ATTEMPT_STATUS_REPORTED;
//        update attempt;
        
//        Job__c job = TestUtil.getJob(attempt.Job__c);
//        Job.JobCommittedDate__c = null;
//        Job.JobExecutedDate__c = null;
//        Job.IsExecuted__c = true;
//        update job;

//        Project__c project = TestUtil.getProject(job.Project__c);
//        project.Status__c = CONSTANTS.PROJECT_STATUS_INPROGRESS;
//        project.ProjectScheduleOption__c = TestUtil.getScheduleOptionId(CONSTANTS.SCHEDULE_OPTION_EC);
//        update project;

//        // when
//        TestUtil.turnOnJobTrigger();
//        Test.startTest();
//        attempt.AttemptScheduleDate__c =  expected;
//        attempt.IsExecuted__c = true;
//        attempt.AttemptedDate__c = expected;
//        update attempt;
//        Test.stopTest();

//        // then
//        job = TestUtil.getJob(attempt.Job__c);
//        System.assertEquals(expected, job.JobCommittedDate__c,'Job Committed Date Should be assigned'); 
//        System.assertEquals(expected, job.JobExecutedDate__c, 'Job Executed Date should be assigned');
//    }

//    //oh427
//    @isTest static void testSetCommittedWhenProjectInProgressForEC(){
//        Date expected = START_DATE.addDays(3);

//        //given
//        TestUtil.turnOffTrigger();
//        JobAttempt__c a = TestUtil.getAttempt(null);
//        Job__c j = TestUtil.getJob(a.Job__c);
//        Project__c p = TestUtil.getProject(j.Project__c);
//        p.ProjectScheduleOption__c = TestUtil.getScheduleOptionId(CONSTANTS.SCHEDULE_OPTION_EC);
//        p.Status__c = CONSTANTS.PROJECT_STATUS_INPROGRESS;
//        update p;

//        //when
//        TestUtil.turnOnJobTrigger();
//        a.AttemptScheduleDate__c = expected;
//        update a;

//        //then
//        j = TestUtil.getJob(a.Job__c);
//        System.assertEquals(expected, j.JobCommittedDate__c, 'job committed date should be set.');
//        System.assertEquals(expected, j.JobScheduledDate__c, 'job scheduled date should be set.');
//    }

    
//    @isTest static void testSetCommittedWhenProjectLaunchedForUser(){
//        //Date expected = START_DATE.addDays(3);

//        ////given
//        //TestUtil.turnOffTrigger();
//        //JobAttempt__c a = TestUtil.getAttempt(null);
//        //Job__c j = TestUtil.getJob(a.Job__c);
//        //Project__c p = TestUtil.getProject(j.Project__c);
//        //p.ProjectScheduleOption__c = TestUtil.getScheduleOptionId(CONSTANTS.SCHEDULE_OPTION_USER);
//        //update p;

//        //p.Status__c = CONSTANTS.PROJECT_STATUS_LAUNCHED;
//        //update p;

//        ////when
//        //TestUtil.turnOnJobTrigger();
//        //a.AttemptScheduleDate__c = expected;
//        //update a;

//        ////then
//        //j = TestUtil.getJob(a.Job__c);
//        //System.assertEquals(expected, j.JobCommittedDate__c, 'job committed date should be set.');
//        //System.assertEquals(expected, j.JobScheduledDate__c, 'job scheduled date should be set.');
//    }
//    @isTest static void testCommittedDateNotSetWhenProjectNotInRightState(){
//        //Date expected = START_DATE.addDays(3);

//        ////given
//        //TestUtil.turnOffTrigger();
//        //JobAttempt__c a = TestUtil.getAttempt(null);
//        //Job__c j = TestUtil.getJob(a.Job__c);
//        //Project__c p = TestUtil.getProject(j.Project__c);
//        //p.ProjectScheduleOption__c = TestUtil.getScheduleOptionId(CONSTANTS.SCHEDULE_OPTION_USER);
//        //update p;
        
//        //p.Status__c = CONSTANTS.PROJECT_STATUS_PENDING;
//        //update p;

//        ////when
//        //TestUtil.turnOnJobTrigger();
//        //a.AttemptScheduleDate__c = expected;
//        //update a;

//        ////then
//        //j = TestUtil.getJob(a.Job__c);
//        //System.assertNotEquals(expected, j.JobCommittedDate__c, 'job committed date should not be set.');
//        //System.assertEquals(expected, j.JobScheduledDate__c, 'job scheduled date should be set.');
//    }

//    //story #
//    @isTest static void testWhenASMSendRescheduleJobAttemptTriggerBeforeUpdateRunIntoException() {
//        //given
//        TestUtil.turnOffTrigger();
//        JobAttempt__c att = TestUtil.getAttempt(null);
//        att.AttemptScheduleDate__c = START_DATE.addDays(1);
//        att.attemptStatus__c = CONSTANTS.JOB_ATTEMPT_STATUS_ASSIGNED;
//        Contact contact = TestUtil.prepareContacts()[MAX_CONTACTS - 5];
//        att.AssignedContactId__c = contact.ContactId__c;
//        update att;

//        Job__c job = TestUtil.getJob(att.Job__c);
//        job.JobStatus__c = CONSTANTS.JOB_STATUS_ASSIGNED;
//        job.JobScheduledDate__c = START_DATE.addDays(1);
//        update job;

//        //when
//        TestUtil.turnOnJobTrigger();
//        att.AssignedContactId__c = 'CMK-US319670';
//        att.AttemptScheduleDate__c = START_DATE.addDays(3);
//        update att;

//        //then
//        att = TestUtil.getAttempt(att.Id);
//        System.assertEquals(START_DATE.addDays(3), att.AttemptScheduleDate__c, 'scheduledDate should be reassigned.');
//        System.assertNotEquals(null, att.DateAssigned__c, 'AssignDate Should be set');
//        System.assertEquals(1, att.NumberOfReschedules__c, 'rescheduled is 1');
//    }
    
//    //OH485
//    @isTest static void testWhenJobAssignedAndReportedJobAssignDateAndStartDateShouldBePopulated() {
//        //given
//        TestUtil.turnOffTrigger();
//        Contact c = TestUtil.prepareContacts()[MAX_CONTACTS - 2];
//        JobAttempt__c a = TestUtil.getAttempt(null);
//        a.AttemptStatus__c = CONSTANTS.JOB_ATTEMPT_STATUS_OPEN;
//        a.AssignedContactId__c = null;
//        a.AssignedContact__c = null;
//        a.DateAssigned__c = null;
//        a.DateStarted__c = null;
//        update a;

//        Job__c j = TestUtil.getJob(a.Job__c);
//        j.JobStatus__c = CONSTANTS.JOB_STATUS_STARTED;
//        j.JobDateAssigned__c = null;
//        j.JobDateStarted__c = null;
//        update j;

//        Project__c p = TestUtil.getProject(j.Project__c);
//        p.Status__c = CONSTANTS.PROJECT_STATUS_INPROGRESS;
//        update p;

//        //when
//        TestUtil.turnOnJobTrigger();
//        a.AttemptStatus__c = CONSTANTS.JOB_ATTEMPT_STATUS_REPORTED;
//        a.AssignedContactId__c = c.ContactId__c;
//        update a;

//        //then
//        a = TestUtil.getAttempt(a.Id);
//        System.assertEquals(CONSTANTS.JOB_ATTEMPT_STATUS_REPORTED, a.AttemptStatus__c,'Attempt Reported.');
//        System.assertNotEquals(null, a.DateReported__c,'Attempt DateReported Is Set.');
//        System.assertEquals(c.Id, a.AssignedContact__c, 'Attempt Assignee Is Set.');
//        System.assertNotEquals(null, a.DateStarted__c, 'Attempt DateStarted Is Set.');
//        System.assertNotEquals(null, a.DateAssigned__c, 'Attempt DateAssigned Is Set');
//        j = TestUtil.getJob(a.Job__c);
//        System.assertNotEquals(null, j.JobDateStarted__c, 'Job DateStarted Is Set.');
//        System.assertNotEquals(null, j.JObDateAssigned__c, 'Job DateAssigned Is Set.');
//        System.assertNotEquals(null, j.JobDateReported__c, 'Job DateReported Is Set.');
//    }

//    //OH580:Fields First attempt date and Last attempt date for Job are not updated.
//    @isTest static void testWhenJobReportedJobFirstAttemptAndLastAttemptDateAssigned() {
//        //given
//        TestUtil.turnOffTrigger();
//        Contact c = TestUtil.prepareContacts()[MAX_CONTACTS - 2];
//        JobAttempt__c a = TestUtil.getAttempt(null);
//        a.AttemptStatus__c = CONSTANTS.JOB_ATTEMPT_STATUS_OPEN;
//        a.AssignedContactId__c = null;
//        a.AssignedContact__c = null;
//        a.DateAssigned__c = null;
//        a.DateStarted__c = null;
//        update a;

//        Job__c j = TestUtil.getJob(a.Job__c);
//        j.JobStatus__c = CONSTANTS.JOB_STATUS_STARTED;
//        j.JobDateAssigned__c = null;
//        j.JobDateStarted__c = null;
//        update j;

//        Project__c p = TestUtil.getProject(j.Project__c);
//        p.Status__c = CONSTANTS.PROJECT_STATUS_INPROGRESS;
//        update p;

//        //when
//        TestUtil.turnOnJobTrigger();
//        Date firstAttemptDate= START_DATE.addDays(2), lastAttemptDate = START_DATE.addDays(4);
//        a.AttemptStatus__c = CONSTANTS.JOB_ATTEMPT_STATUS_REPORTED;
//        a.AssignedContactId__c = c.ContactId__c;
//        a.AttemptedDate__c = firstAttemptDate;
//        update a;
//        a.AttemptedDate__c = lastAttemptDate;
//        update a;

//        //then
//        a = TestUtil.getAttempt(a.Id);
//        j = TestUtil.getJob(a.Job__c);
//        System.assertEquals(firstAttemptDate, j.JobFirstAttemptDate__c, 'Job 1st attempt date is set.');
//        System.assertEquals(lastAttemptDate, j.JobAttemptedDate__c, 'Job last attempt date is set.');
//        System.assertEquals(a.AttemptedDate__c, lastAttemptDate, 'Attempt attempt date is last attempt date');
//    }
}