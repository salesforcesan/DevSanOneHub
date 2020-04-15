@isTest

public class JobTriggerHandlerTest {
    static Date START_DATE = Datetime.Now().Date();
    static Date END_DATE = Datetime.Now().addDays(14).Date();
    static final Integer MAX_CONTACTS = 10;
    
    @testSetup static void setup() {
        TestUtil.turnOffTrigger();
        TestUtil.initBaseData();
        TestUtil.setupJobTestData(CONSTANTS.JOB_ATTEMPT_STATUS_OPEN, CONSTANTS.JOB_STATUS_PENDING);
        
    }
    static void triggersOff(){
        TriggerUtil.skipAllTriggers();
        
    }
    @isTest static void itShouldEncryptJob(){
        TestUtil.turnOffTrigger();
        String expName = 'demo';
        TestProject testP = TestProject.create(expName);
        testP.addLocations(1);
        testP.addJobs();
        //When
        Test.startTest();
        testP.addJobs();
        Test.stopTest();
        project__c result =TestProject.getProjects()[0];
        system.debug('project Id'+ result.Id);
        List<job__c> projJobs = TestProject.getJobs(result.Id);
        // system.assert(projLocations.size()>0);
        // system.debug('project Locations Size' +projLocations.size());
        system.assert(projJobs[0].SurveyPhotoViewerEncodedId__c != null);  
        
        
    }
    
    
    @isTest static void testIfJobNotCompletedThenCompletedDateShouldBeNull(){
        
        //given
        TestUtil.turnOffTrigger();
        JobAttempt__c attempt = TestUtil.getAttempt(null);
        Job__c job = TestUtil.getJob(attempt.Job__c);
        job.JobStatus__c = CONSTANTS.JOB_STATUS_OPEN;
        job.CompletionStatus__c = CONSTANTS.JOB_COMPLETION_STATUS_NOT_COMPLETED;
        job.JobCompletedDate__c = START_DATE.addDays(10);
        update job;
        
        //when
        TestUtil.turnOnJobTrigger();
        TEST.startTest();
        job.JobStatus__c = CONSTANTS.JOB_STATUS_OPEN;
        update job;
        TEST.stopTest();
        
        //then
        job = TestUtil.getJob(job.Id);
        System.assertEquals(null, job.JobCompletedDate__c, 'Job completed date should not be assigned.');
    }
    
    @isTest static void testIfJobCompeletedThenCompletedDateShouldBeNotNull(){
        
        //given
        TestUtil.turnOffTrigger();
        JobAttempt__c attempt = TestUtil.getAttempt(null);
        Job__c job = TestUtil.getJob(attempt.Job__c);
        Job.JobStatus__c = CONSTANTS.JOB_STATUS_STARTED;
        job.CompletionStatus__c = CONSTANTS.JOB_COMPLETION_STATUS_NOT_COMPLETED;
        job.JobCompletedDate__c = null;
        update job;
        
        //when
        TestUtil.turnOnJobTrigger();
        Test.startTest();
        job.CompletionStatus__c = CONSTANTS.JOB_COMPLETION_STATUS_COMPLETED;
        update job;
        Test.stopTest();
        
        //then
        job = TestUtil.getJob(job.Id);
        System.assertNotEquals(null, job.JobCompletedDate__c, 'Job completed date should be assigned.');
    }
    
    @isTest static void testIfJobNotExecutedThenExecutedDateShouldBeNull() {
        
        //given
        TestUtil.turnOffTrigger();
        JobAttempt__c attempt = TestUtil.getAttempt(null);
        Job__c job = TestUtil.getJob(attempt.Job__c);
        job.JobStatus__c = CONSTANTS.JOB_STATUS_OPEN;
        job.JobExecutedDate__c = START_DATE.addDays(3);
        update job;
        
        //when
        Test.startTest();
        TestUtil.turnOnJobTrigger();
        job.JobStatus__c = CONSTANTS.JOB_STATUS_REPORTED;
        job.IsExecuted__c = false;
        update job;
        Test.stopTest();
        
        //then
        job = TestUtil.getJob(job.Id);
        System.assertEquals(null, job.JobExecutedDate__c, 'Job executed date should not be assigned.');
    }
    
    @isTest static void testIfJobStartedThenJobStartedDateIsAssigned() {
        
        //given
        TestUtil.turnOffTrigger();
        JobAttempt__c attempt = TestUtil.getAttempt(null);
        Job__c job = TestUtil.getJob(attempt.Job__c);
        job.JobStatus__c = CONSTANTS.JOB_STATUS_PENDING;
        update job;
        
        //when
        Test.startTest();
        TestUtil.turnOnJobTrigger();
        Datetime today = Datetime.now().addDays(10);
        job.JobStatus__c = CONSTANTS.JOB_STATUS_STARTED;
        job.JobDateStarted__c = START_DATE;
        update job;
        Test.stopTest();
        
        //then
        job = TestUtil.getJob(job.Id);
        System.assertEquals(job.JobStatus__c, CONSTANTS.JOB_STATUS_STARTED, 'Job Status = Started');
        System.assertEquals(START_DATE, job.JobDateStarted__c,'Job started date assigned');
    }
    
    @isTest static void testIfJobAssignedThenDateAssigned() {
        
        //given
        TestUtil.turnOffTrigger();
        JobAttempt__c attempt = TestUtil.getAttempt(null);
        Job__c job = TestUtil.getJob(attempt.Job__c);
        job.JobStatus__c = CONSTANTS.JOB_STATUS_PENDING;
        update job;
        
        //when
        TestUtil.turnOnJobTrigger();
        Test.startTest();
        job.JobStatus__c = CONSTANTS.JOB_STATUS_ASSIGNED;
        update job;
        Test.stopTest();
        
        //then
        job = TestUtil.getJob(job.Id);
        System.assertEquals(CONSTANTS.JOB_ATTEMPT_STATUS_ASSIGNED, job.JobStatus__c, 'status assigned');
        System.assertNotEquals(null, job.JobDateAssigned__c,'Assigned Date set');
        System.assertNotEquals(null, job.JobDateOriginallyAssigned__c,'Originally Assigned Date set');
    }
    
    //scenario: <oh435: Job status is not updated to reported from open/assigned when job attempt is reported > ----
    @isTest static void testJobStatusTobeReported() {
        
        //--given--
        TestUtil.turnOffTrigger();
        JobAttempt__c attempt = TestUtil.getAttempt(null);
        Job__c job = TestUtil.getJob(attempt.Job__c);
        job.JobStatus__c = CONSTANTS.JOB_STATUS_OPEN;
        update job;
        
        //--when--
        TestUtil.turnOnJobTrigger();
        Test.startTest();
        job.JobStatus__c = CONSTANTS.JOB_STATUS_REPORTED;
        update job;
        Test.stopTest();
        
        //--then--
        Job__c r = TestUtil.getJob(job.Id);
        System.assertEquals(CONSTANTS.JOB_STATUS_REPORTED, r.JobStatus__c, 'Job Status is updated as Reported');
    }
        

    @istest static void testWhenJobScheduledSecondTimeRescheduleFlagShouldbeTrue() {
        // given
        TestUtil.turnOffTrigger();
        ID jobId = TestUtil.getAttempt(null).Job__c;
        Job__c job = TestUtil.getJob(jobId);
        Job.IsReScheduled__c = false;
        Job.JobScheduledDate__c = START_DATE.addDays(1);
        update job;
        
        // when
        Test.startTest();
        TestUtil.turnOnJobTrigger();
        job.JobScheduledDate__c = START_DATE.addDays(2);
        update job;
        Test.stopTest();
        
        // then
        Job__c result = TestUtil.getJob(jobId);
        System.assertEquals(true, result.IsReScheduled__c, 'IsReScheduled should be true');
    }
    
}