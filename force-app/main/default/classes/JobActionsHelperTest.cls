@isTest
private class JobActionsHelperTest
{
  static Integer MAX_CONTACTS = 10;
  static Date CURRENT_DATE = Datetime.now().Date();

  @testSetup static void init(){
    TriggerUtil.skipAllTriggers();
    TestUtil.initBaseData();
    TestUtil.setupJobTestData(
      CONSTANTS.JOB_ATTEMPT_STATUS_OPEN,
      CONSTANTS.JOB_STATUS_PENDING);
  }

//--Test CreateAttempt API
  @isTest static void testCreateAttemptsWhenJobsSizeTooBigItShouldReturnErrorResponse(){
    //given
    String err='Please use a batch call for jobs size';
    List<ID>jobs = new List<ID>();
    for(Integer i=0; i<JobActionsHelper.JOB_BATCH_SIZE +10; i++){
      jobs.add('a0E41000000LHABEA4');
    }

    //when
    List<ActionResponse> res = JobActionsHelper.CreateAttempts(jobs, CURRENT_DATE, 'reason');

    //then
    ActionResponse r = res.get(0);
    System.assertEquals(false, r.IsSuccessful, 'IsSuccessful should be false');
    System.assertEquals(true, r.ResponseMessage.indexOf(err) != -1, 'Expected error message should return');
  }

  @isTest static void testCreateAttempsWhenCancledOrClosedJobsPassedInItSHouldReturnErrorResponses(){
    //given
    List<ID> jobs= createJobData();
    setJobsStatus(CONSTANTS.JOB_STATUS_CANCELED);
    String error = 'Cannot create attempt. Invalid job status.';

    //when
    Test.startTest();
    List<ActionResponse> res = JobActionsHelper.CreateAttempts(jobs, CURRENT_DATE, 'reason');
    Test.stopTest();

    //then
    System.assertEquals(true, checkResponseStatus(res, false), 'all responses should be false');
    System.assertEquals(true, checkResponsesMessage(res, error), 'all response should return expected error msg.');
  }

  @isTest static void testCreateAttemptsWhenCorrectJObsPassedInItShouldReturnSuccessResponses(){
    //given
    List<ID> jobs= createJobData();
    Project__c p = TestProject.getProjects()[0];
    QA.isTrue(p.ProjectScheduleOptionCode__c != 'EC', 'not ec project:' + p.ProjectScheduleOptionCode__c);
    TriggerUtil.skipAllTriggers();
    List<Job__c> jobList = TestProject.getJobs(p.Id);
    Date sDate = Datetime.now().addDays(2).date();
    for(Job__c j: jobList) {
      j.JobScheduledDate__c = sDate;
    }
    update jobList;


    //when
    Test.startTest();
    List<ActionResponse> res = JobActionsHelper.CreateAttempts(jobs, CURRENT_DATE.addDays(3), 'reason');
    Test.stopTest();

    //then
    System.assertEquals(true, checkResponseStatus(res, true),'all responses should be successful:' + JSON.serialize(res));
  }

//-- test cancelJobs API
@isTest static void testCancelJobsWhenEmptyJobsPassInItShouldReturnErrorResponse(){
  //given
  List<ID> ids = new List<ID>();
  //when
  List<ActionResponse> res = JobActionsHelper.cancelJobs(ids, 'Other', 'comment');
  //then
  System.assertEquals(true, checkResponseStatus(res, false),'it should return false');
  System.assertEquals(true, checkResponsesMessage(res,'No jobs in the list to cancel.'),'it should return expected error msg');
}
@isTest static void testCancelJobsWhenReasonIsOtherWithoutCommentItShouldReturnError(){
  //given
  List<ID>jobs = new List<ID>();
  jobs.add('a0E41000000LHABEA4');
  //when
  List<ActionResponse> res = JobActionsHelper.cancelJobs(jobs, 'Other', '');
  //then
  System.assertEquals(true, checkResponseStatus(res, false),'it should return false');
  System.assertEquals(true, checkResponsesMessage(res,'Please provide cancel comments when cancel reason is Other.'),'it should return expected error msg');
}
static void setJobCancelLeadTime(Integer hours) {
  ProjectType__c pT = [SELECT Id, JobCancelLeadTime__c FROM ProjectType__c limit 1];
  pT.JobCancelLeadTime__c = hours;
  update pT;
}

static void setJobOverrideTrue() {
  List<Job__c> jobs = [SELECT Id, JobCancelOverride__c from Job__C];
  for(Job__c j: jobs){
    j.JobCancelOverride__c = true;
  }
  update jobs;
}

@isTest static void testCancelJobsWhenJobIsNotCancelleableItShouldReturnErrors(){
  //given
  TriggerUtil.skipAllTriggers();
  List<ID> jobs = createJobData();
  Project__c p = [SELECT Id, Status__c FROM Project__c limit 1];
  p.Status__c = 'Booked';
  update p;

  String err = 'Cannot cancel job. Invalid Project status or not enough lead time.';

  //when
  Test.startTest();
  List<ActionResponse> res = JobActionsHelper.cancelJobs(jobs, 'Other', 'comment');
  Test.stopTest();

  //then
  String msg = JSON.serialize(res);
  System.assertEquals(true, checkResponseStatus(res, false), 'it should return false:' + msg);
  System.assertEquals(true, checkResponsesMessage(res, err), 'it should return expected error.' + msg);
}

@isTest static void testCancelJobWhenNonReportedCancellableJobPassedInItShouldSetJobCancelled(){
  //given
  TestUtil.turnOffTrigger();
  List<ID> jobIds = createJobData();
  Project__c p = (Project__c) TestUtil.getRecord('Project__c');
  p.Status__c = CONSTANTS.PROJECT_STATUS_INPROGRESS;
  update p;
  List<Job__c> jobs = (List<Job__c>) TestUtil.getRecordset('Job__c');
  for(Job__c j: jobs){
    j.JobCancelOverride__c = true;
  }
  update jobs;

  //when
  Test.startTest();
  List<ActionResponse> res = JobActionsHelper.cancelJobs(jobIds, 'Other', 'comment');
  Test.stopTest();

  //then
  jobs = (List<Job__c>) TestUtil.getRecordset('Job__c');

  String msg = JSON.serialize(res);
  System.assertEquals(true, checkResponseStatus(res, true),'It should return true:' + msg);
  System.assertEquals(true, checkJobsStatus(CONSTANTS.JOB_STATUS_CANCELED),'job should be cancelled:' + msg);
}
@isTest static void testCancelJobWhenReportedCancellableJobPassedInItShouldSetJobClosed(){
  //given
  TestUtil.turnOffTrigger();
  List<ID> jobIds = createJobData();
  Project__c p = (Project__c) TestUtil.getRecord('Project__c');
  p.Status__c = CONSTANTS.PROJECT_STATUS_INPROGRESS;
  update p;
  List<Job__c> jobs = (List<Job__c>) TestUtil.getRecordset('Job__c');
  for(Job__c j: jobs){
    j.JobCancelOverride__c = true;
    j.JobScheduledDate__c = CURRENT_DATE.addDays(8);
    j.JobStatus__c = CONSTANTS.JOB_STATUS_REPORTED;
  }
  update jobs;

  //when
  Test.startTest();
  List<ActionResponse> res = JobActionsHelper.cancelJobs(jobIds, 'Other', 'comment');
  Test.stopTest();

  //then
  System.debug(TestUtil.genQuery('Job__c'));
  jobs = (List<Job__c>) TestUtil.getRecordset('Job__c');
  System.debug(jobs);

  System.assertEquals(true, checkResponseStatus(res, true),'It should return true:' + JSON.serialize(res));
  System.assertEquals(true, checkJobsStatus(CONSTANTS.JOB_STATUS_CLOSED),'job should be closed.');
}

//-- test deleteJobs API
@isTest static void ItShouldReturnErrorWhenPassingInEmptyJobListToDeleteJobs(){
  //given
  List<ID> jobIds = new List<ID>();
  String err = 'No jobs in the list to delete.';
  //when
  List<ActionResponse> res = JobActionsHelper.deleteJobs(jobIds);
  //then
  System.assertEquals(true, checkResponseStatus(res, false), 'It should return false');
  System.assertEquals(true, checkResponsesMessage(res, err),'It should return expected error.');
}

@isTest static void ItShouldReturnErrorsWhenProjectNotInPlanningAndTryToDeleteJobs(){
  //given
  List<ID> jobIds = createJobData();
  String err = 'Invalid Project status. Cannot delete job.';
  Project__c p = (Project__c) TestUtil.getRecord('Project__c');
  p.Status__c = CONSTANTS.PROJECT_STATUS_BOOKED;
  update p;

  //when
  List<ActionResponse> res = JobActionsHelper.deleteJobs(jobIds);

  //then
  System.assertEquals(true, checkResponseStatus(res, false),'It should return false');
  System.assertEquals(true, checkResponsesMessage(res, err), 'It should return expected error.');
}

@isTest static void ItShouldReturnSuccessWhenDeleteJobsWithValidJobs(){
  //given
  List<ID> jobIds = createJobData();
  Project__c p = (Project__c) TestUtil.getRecord('Project__c');
  p.Status__c = CONSTANTS.PROJECT_STATUS_PLANNING;
  update p;

  //when
  Test.startTest();
  List<ActionResponse> res = JobActionsHelper.deleteJobs(jobIds);
  Test.stopTest();

  //then
  System.assertEquals(true, checkResponseStatus(res, true),'It should return true');
  List<Job__c> jobs = TestUtil.getRecordset('Job__c');
  System.assertEquals(0, jobs.size(),'There should no jobs.');
}

//-- test closeJobs API
@isTest static void ItShouldReturnErrorWhenEmptyJobsPassIn(){
  //given
  List<ID> jobIds = new List<ID>();
  String err='No jobs in the list to close.';
  //when
  List<ActionResponse> res = JobActionsHelper.closeJobs(jobIds, false);

  //then
  System.assertEquals(true, checkResponseStatus(res, false), 'It should return false');
  System.assertEquals(true, checkResponsesMessage(res, err),'It should return expected error.');
}

@isTest static void ItShouldReturnErrorsWhenClosedOrCancelledJobsPassedIn(){
  //given
  TestUtil.turnOffTrigger();
  List<ID> jobIds = createJobData();
  setJobsStatus(CONSTANTS.JOB_ATTEMPT_STATUS_CLOSED);
  String err = 'Job already in closed/canceled status. Cannot close job.';
  //when
   List<ActionResponse> res = JobActionsHelper.closeJobs(jobIds, false);

  //then
  System.assertEquals(true, checkResponseStatus(res, false), 'It should return false');
  System.assertEquals(true, checkResponsesMessage(res, err),'It should return expected error.');
}

@isTest static void ItShouldReturnErrorWhenValidJobsPassedIn(){
  //given
  TestUtil.turnOffTrigger();
  List<ID> jobIds = createJobData();
  List<ProjectService__c> ps = (List<ProjectService__c>) TestUtil.getRecordSet('ProjectService__c');
  for(ProjectService__c s: ps){
    s.RefreshSummary__c = false;
  }
  update ps;

  //when
  Test.startTest();
  List<ActionResponse> res = JobActionsHelper.closeJobs(jobIds, false);
  Test.stopTest();

  //then
  Job__c job = (Job__c) TestUtil.getRecord('Job__c');
  IPredicateBuilder filter = PredicateBuilder.newBuilder()
    .addPredicate('Id', SQLDataType.sqlString, SQLQueryOperator.sqlEqual,job.ProjectService__c);
  ProjectService__c svc = (ProjectService__c) TestUtil.findRecord('ProjectService__c', filter);

  System.assertEquals(true, checkResponseStatus(res, true), 'It should return true');
  System.assertEquals(true, checkJobsStatus(CONSTANTS.JOB_STATUS_CLOSED), 'all jobs should be closed.');
  System.assertEquals(true, checkAttemptsStatus(CONSTANTS.JOB_ATTEMPT_STATUS_CLOSED), 'all attempts should be close');

  //Project Summary refresh does not happen anymore
  //System.assertEquals(true, svc.RefreshSummary__c, 'Project Service RefreshSummary should be true.');
}

//-- test setScheduledDate API
@isTest static void ItShouldReturnErrorWhenEmptyJobsPassedIn(){
  //given
  List<ID> jobIds = new List<ID>();
  String err='No jobs in the list to set scheduled date.';
  //when
  List<ActionResponse> res = JobActionsHelper.setScheduledDate(jobIds, CURRENT_DATE);

  //then
  System.assertEquals(true, checkResponseStatus(res, false),'It should return false');
  System.assertEquals(true, checkResponsesMessage(res, err),'It should return expected error.');
}


static Boolean checkJobScheduledDateSet(Date expected){
  Boolean result  = false;
  List<Job__c> jobs = (List<Job__c>) TestUtil.getRecordset('Job__c');
  for(Job__c j: jobs){
    result = j.JobScheduledDate__c == expected ? true : false;
    if(!result){
      break;
    }
  }
  return result;
}
////////////////////////////////////////////////////////////////////
//-- Help APIs
  static Boolean checkAttemptsStatus(String status){
    Boolean result = false;
    List<JobAttempt__c> data = (List<JobAttempt__c>) TestUtil.getRecordset('JobAttempt__c');
    for(JobAttempt__c j: data){
      result = (status.equalsIgnoreCase(j.AttemptStatus__c)) ? true : false;
      if (!result) {
        break;
      }
    }
    return result;
  }

  static Boolean checkResponseStatus(List<ActionResponse> res, Boolean expected){
    Boolean result = false;
    for(ActionResponse r: res){
      result = r.IsSuccessful == expected;
      if (!result){
        break;
      }
    }
    return result;
  }
  static Boolean checkResponsesMessage(List<ActionResponse> res, String expected){
    Boolean result = false;
    for(ActionResponse r: res){
      result = r.ResponseMessage.indexOf(expected) != -1 ? true : false;
      if (!result){
        break;
      }
    }
    return result;
  }

  static List<ID> createJobData() {
    Job__c job = (JOb__c) TestUtil.getRecord('Job__c');
    TestUtil.generateJobs(job.Project__c, job.ProjectLocation__c, job.ProjectService__c, 10);
    List<ID> ids = new List<ID>();
    For(Job__c j: (List<Job__c>) TestUtil.getRecordset('Job__c')){
      ids.add(j.Id);
    }
    return ids;
  }
  static Boolean checkJobsStatus(String status){
    Boolean result = false;
    List<Job__c> jobs = (List<Job__c>) TestUtil.getRecordset('Job__c');
    for(Job__c j: jobs){
      result = status.equalsIgnoreCase(j.JobStatus__c) ? true: false;
      if(!result) {
        break;
      }
    }
    return result;
  }

  static void setJobsStatus(String status) {
    List<Job__c> jobs = (List<Job__c>) TestUtil.getRecordset('Job__c');
    for(Job__c j: jobs){
      j.JobStatus__c = status;
    }
    update jobs;
  }

}