@isTest
public class TestProject {
  public static final Integer BUDGET_LOCATIONS_COUNT;
  public static final Integer END_DAYS_TO_START_DATE;
  public static final Integer APPROVAL_DAYS_TO_START_DATE;

  static {
    BUDGET_LOCATIONS_COUNT = 10;
    APPROVAL_DAYS_TO_START_DATE = -10;
    END_DAYS_TO_START_DATE = 7;
  }

  public Project__c ProjectInstance {get; private set;}
  public List<ProjectLocation__c> ProjectLocationList {get; private set;}
  public List<TestProjectService> TestProjectServiceList {get; private set;}

  //prevent new TestProject()
  private TestProject(Project__c project) {
    this.ProjectInstance = project;
    this.ProjectLocationList = new List<ProjectLocation__c>();
    this.TestProjectServiceList = new List<TestProjectService>();
  }

  //factory pattern
  public static TestProject create(
    String name,
    Date startDate,
    Date endDate,
    String project_type,
    String scheduleOptionCode) {

    return new TestProject(generateProject(name, startDate, endDate, project_type, scheduleOptionCode));
  }

  public static TestProject create(
    String name,
    Date startDate,
    Date endDate,
    String project_type) {

    return new TestProject(generateProject(name, startDate, endDate, project_type, null));
  }

  public static TestProject create(
    String name,
    Date startDate,
    Date endDate) {

    return new TestProject(generateProject(name, startDate, endDate, null, null));
  }

  public static TestProject create(String name) {
    return new TestProject(generateProject(name,
                                           TestDataUtil.CurrentDateInstance,
                                           TestDataUtil.CurrentDateInstance.addDays(END_DAYS_TO_START_DATE), null, null));
  }

  public static TestProject get(String id) {
    TestProject tProject = new TestProject(getProject(id));
    for (ProjectLocation__c pl : getLocations(id)) {
      tProject.ProjectLocationList.add(pl);
    }
    ProjectService__c pS = getServices(id)[0];
    tProject.TestProjectServiceList.add(TestProjectService.get(tProject.ProjectInstance, pS.Id));

    return tProject;
  }


  /////// public method /////////
  public Project__c getInstance() {
    return this.ProjectInstance;
  }

  public List<TestProjectService> getTestProjectServices() {
    return this.TestProjectServiceList;
  }

  public TestProject addAll() {
    this.addAccount()
           .addAttributes()
           .addService()
           .addLocations(1)
           .addJobs()
           .addJobAttempts()
           .addJobAttemptWorkers();
    return this;
  }

  public TestProject addAllWithoutJobAttempts() {
    this.addAccount()
            .addAttributes()
           .addLocations(1)
           .addService()
           .addJobs();
    return this;
  }

  public TestProject addAllWithoutJobAttempts(Integer numOfLocations) {
    this.addAccount()
            .addAttributes()
           .addLocations(numOfLocations)
           .addService()
           .addJobs();
    return this;
  }

  public TestProject addAccount() {
    return addAccounts(1);
  }

  public TestProject addAccounts(Integer howMany) {
    List<Account> acctList = TestDataUtil.getAccounts();
    if (howMany > acctList.size()) {
      throw new CustomException('There no enough accounts to add');
    }

    List<ProjectAccount__c> items = new List<ProjectAccount__c>();
    Boolean isPrimary = true;
    Integer idx = 0, count = acctList.size();
    Integer percent = 100 / (howMany < count ? howMany : count);

    for (Account a : acctList) {
      if (idx >= howMany) { break; }
      items.add(new ProjectAccount__c(
                  Account__c = a.Id,
                  isPrimary__c = isPrimary,
                  Project__c = this.ProjectInstance.Id,
                  SplitValue__c = percent
                ));
      isPrimary = false;
      idx++;
    }
    insert items;
    return this;
  }

  public TestProject addAttributes() {
    List<ProjectAttribute__c> attrList = new List<ProjectAttribute__c>();
    For(ProjectTypeAttribute__c ptAttr: TestDataUtil.getProjectTypeAttributes(
          ProjectInstance.ProjectType__c)) {
      attrList.add(new ProjectAttribute__c(
                     Project__c = ProjectInstance.Id,
                     Attribute__c = ptAttr.Attribute__c,
                     ProjectTypeAttribute__c  = ptAttr.Id
                   ));
    }
    insert attrList;
    return this;
  }

  public TestProject addLocations(Integer howMany) {
    List<Location__c> locations = TestDataUtil.getLocations();
    Integer idx = 0;
    List<ProjectLocation__c> locs = new List<ProjectLocation__c>();

    if ( howMany > locations.size()) {
      throw new CustomException('add too many locations.');
    }
    For(Location__c loc: locations) {
      if ( idx < howMany) {
        locs.add(new ProjectLocation__c (
                   Project__c = this.ProjectInstance.Id,
                   Location__c = loc.Id,
                   ExecutionCompany__c = null
                 ));
      }

      idx++;
    }
    insert locs;
    this.ProjectLocationList.addAll(locs);
    return this;
  }

  public TestProject addShiftService() {
    this.TestProjectServiceList.add(TestProjectService.createForShift(this.ProjectInstance));
    return this;
  }

  public TestProject addService() {
    this.TestProjectServiceList.add(TestProjectService.create(this.ProjectInstance));
    return this;
  }

  public TestProject addServices(Integer howMany) {
    List<Service__c> services = TestDataUtil.getServices();
    Integer idx = 0;
    for (Service__c s : services) {
      if (idx >= howMany) {break;}
      this.TestProjectServiceList.add(TestProjectService.create(this.ProjectInstance, s.Id));
      idx++;
    }
    return this;
  }

  public TestProject addJobs(String status) {
    this.addJobsByStatus(status);
    return this;
  }

  public TestProject addJobs() {
    this.addJobsByStatus('');
    return this;
  }

  void addJobsByStatus(string status) {

    if (this.ProjectLocationList.size() == 0) {
      throw new CustomException('There are no locations added.');
    }
    if (String.isBlank(status)) {
      status = CONSTANTS.JOB_STATUS_PENDING;
    }

    List<Job__c> jobs = new List<Job__c>();
    for (ProjectLocation__c pL : this.ProjectLocationList) {
      for (TestProjectService ps : this.TestProjectServiceList) {
        jobs.add(createJob(pL, ps.getInstance(), status));
      }
    }
    insert jobs;
  }

  Job__c createJob(ProjectLocation__c pL, ProjectService__c pS, String status) {

    return new job__c(
             Project__c = this.ProjectInstance.Id,
             JobStatus__c = status,
             JobCancelOverride__c = true,
             Location__c = pL.Location__c,
             ProjectLocation__c = pL.Id,
             ProjectService__c = pS.Id,
             Service__c = pS.Service__c,
             JobStartDate__c = this.ProjectInstance.StartDate__c,
             JobEndDate__c = this.ProjectInstance.EndDate__c,
             JobStartTime__c = pS.StartTime__c,
             JobEndTime__c = pS.EndTime__c,
             NumberOfWorkers__c = ps.NumberOfWorkers__c,
             ProjectScheduleOptionName__c = this.ProjectInstance.ProjectScheduleOption__r.Name
           );
  }

  public TestProject addJobAttempts() {
    this.addJobAttemptsByStatus('');
    return this;
  }

  public TestProject addJobAttempts(String status) {
    this.addJobAttemptsByStatus(status);
    return this;
  }

  void addJobAttemptsByStatus(String status) {
    List<JobAttempt__c> rs = new List<JobAttempt__c>();
    List<Job__c> jobsToUpdate = new List<Job__c>();
    Map<Id, Sobject> jobs = getRelatedMap('Job__c', this.ProjectInstance.Id);

    if (String.isBlank(status)) {
      status = CONSTANTS.JOB_ATTEMPT_STATUS_OPEN;
    }
    For(Sobject job: jobs.values()) {
      Job__c j = (Job__c)job;
      rs.add(new JobAttempt__c (
               IsActive__c = true,
               IsExecuted__c = false,
               Job__c = j.Id,
               ExpectedNumberofWorkers__c = j.NumberOfWorkers__c,
               AttemptStatus__c = status,
               DateReported__c = Datetime.now(),
               NumberOfReschedules__c = 0,
               UniqueKey__c = TestDataUtil.genUniqeKey('ja')
             ));
    }
    if (rs.size() > 0) {
      insert rs;

      for (JobAttempt__c att : rs) {
        if (jobs.containsKey(att.Job__c)) {
          jobsToUpdate.add(new Job__c(
                             Id = att.Job__c,
                             ActiveJobAttempt__c = att.Id
                           ));
        }
      }
      update jobsToUpdate;
    }
  }

  public TestProject addJobImages() {
    List<JobImage__c> images = new List<JobImage__c>();
    String pId = ProjectInstance.Id;

    Target__c target = [SELECT Id from Target__c limit 1];
    ProjectServiceQuestion__c psQuestion = [SELECT Question__c, Id FROM ProjectServiceQuestion__c LIMIT 1];
    for (Job__c job : [SELECT ProjectLocation__c, ProjectService__c, Id, ActiveJobAttempt__c FROM Job__c WHERE Project__c = :pId]) {

      images.add(new JobImage__c(
                   Project__c = pId,
                   ProjectLocation__c = job.ProjectLocation__c,
                   ProjectService__c = job.ProjectService__c,
                   Job__c = job.Id,
                   JobAttempt__c = job.ActiveJobAttempt__c,
                   Question__c = psQuestion.Question__c,
                   ProjectServiceQuestion__c = psQuestion.Id,
                   Target__c = target.Id,
                   ImageUrl__c = 'http://test.com/test.jpg',
                   ImageName__c = 'test.jpg'
                 ));
    }

    insert images;
    return this;
  }

  public TestProject addJobAttemptWorkers() {
    List<JobAttemptWorker__c> workers = new List<JobAttemptWorker__c>();
    Boolean hasTeamLead = false;
    List<Contact> contacts = getContacts();
    Map<Id, JobAttempt__c> attemptMap = new Map<Id, JobAttempt__c>([SELECT Id, PrimaryJobAttemptWorker__c FROM JobAttempt__c]);
    Account acct = [SELECT Id from Account LIMIT 1];

    for (Id jaId : attemptMap.keySet()) {
      for (Contact cnt : contacts) {
        workers.add(new JobAttemptWorker__c(
                      JobAttempt__c = jaId,
                      WorkerType__c = !hasTeamLead ? 'Team Lead' : 'Team Member',
                      FirstName__c = cnt.FirstName,
                      LastName__c = cnt.LastName,
                      Email__c = cnt.Email,
                      Contact__c = cnt.Id,
                      ThirdPartyAgency__c = acct.Id,
                      SupervisorEmail__c = 'no.reply@crossmark.com'

                    ));
        hasTeamLead = true;
      }
    }
    insert workers;
    for (JobAttemptWorker__c worker : workers) {
      if (worker.WorkerType__c == 'Team Lead') {
        attemptMap.get(worker.JobAttempt__c).PrimaryJobAttemptWorker__c = worker.Id;
      }
      update attemptMap.values();
    }
    return this;
  }

  public TestProjectService getTestProjectService() {
    if (this.TestProjectServiceList.size() == 0) {
      throw new CustomException('No service added.');
    }
    return this.TestProjectServiceList.get(0);
  }

  /////// Private Helper Method //////////
  static Project__c generateProject(String name, Date startDate, Date endDate, string project_type, String scheduleOptionCode) {
    if (String.isBlank(project_type)) {
      project_type = ProjectType.MD;
    }
    if (String.isBlank(scheduleOptionCode)) {
      scheduleOptionCode = CONSTANTS.SCHEDULE_OPTION_USER;
    }
    ProjectType__c pType = TestDataUtil.getProjectType(project_type);

    Project__c project = new Project__c(
      Name = name,
      Status__c = CONSTANTS.PROJECT_STATUS_PLANNING,
      StartDate__c = startDate,
      EndDate__c = endDate,
      IsVisibleToClient__c = true,
      ProjectLaunchDate__c = startDate.addDays(-7),
      ApprovalDate__c = startDate.addDays(APPROVAL_DAYS_TO_START_DATE),
      ProjectType__c = pType.Id,
      ProjectScheduleOption__c = TestDataUtil.getScheduleOptionByCode(scheduleOptionCode).Id,
      Retailer__c = TestDataUtil.getRetailer().Id,
      UpdateSequence__c = Crypto.getRandomInteger(),
      StoreCallTimeLimit__c = 123,
      BudgetedLocationsCount__c = BUDGET_LOCATIONS_COUNT

    );
    insert project;
    return getProject(project.Id);
  }

  /////// Public Utility APIs /////////////
  public static List<Project__c> getProjects() {
    String sql = TestUtil.genQuery('Project__c', new String[] {
                                     'ProjectScheduleOption__r.Code__c',
                                     'ProjectScheduleOption__r.Name',
                                     'ProjectType__r.Name'
                                   });

    return (List<Project__c>) Database.query(sql);
  }

  public static List<Contact> getContacts() {
    return [SELECT Id, FirstName, LastName, Email FROM Contact];
  }

  public static Project__c getProject(Id project) {
    String sql = TestUtil.genQuery('Project__c', new String[] {
                                     'ProjectScheduleOption__r.Code__c',
                                     'ProjectScheduleOption__r.Name',
                                     'ProjectType__r.Name'
                                   }) + ' WHERE Id=:project';
    return (Project__c) Database.query(sql);
  }

  static List<Sobject> getRelatedList(String sObjectType, Id project) {
    return Database.query(
             TestUtil.genQuery(sObjectType) + ' WHERE Project__c=:project'
           );
  }

  static Map<Id, SObject> getRelatedMap(String sObjectType, Id project) {
    return new Map<Id, Sobject>(
             Database.query(
               TestUtil.genQuery(sObjectType) + ' WHERE Project__c=:project'
             )
           );
  }

  public static void deleteServices() {
    List<ProjectService__c> services = [SELECT Id FROM ProjectService__c];
    delete services;
  }

  public static List<ProjectService__c> getServices(Id project) {
    return (List<ProjectService__c>) getRelatedList('ProjectService__c', project);
  }

  public static List<Job__c> getJobs(Id project) {
    return (List<Job__c>) getRelatedList('Job__c', project);
  }

  public static List<ProjectAccount__c> getAccounts(id project) {
    return (List<ProjectAccount__c>) getRelatedList('ProjectAccount__c', project);
  }

  public static List<ProjectLocation__c> getLocations(Id project) {
    return (List<ProjectLocation__c>) getRelatedList('ProjectLocation__c', project);
  }

  public static List<JobImage__c> getJobImages(Id project) {
    return Database.query(
             TestUtil.genQuery('JobImage__c') + ' WHERE Job__r.Project__c=:project'
           );
  }

  public static List<JobAttempt__c> getJobAttempts(Id project) {
    return Database.query(
             TestUtil.genQuery('JobAttempt__c') + ' WHERE Job__r.Project__c=:project'
           );
  }

  public static List<JobAttemptWorker__c> getJobAttemptWorkers(Id project) {
    Map<Id, JobAttempt__c> jobMap = new Map<Id, JobAttempt__c>([
          SELECT Id FROM JobAttempt__c WHERE Job__r.Project__c = :project]);
    Set<Id> keys = jobMap.keySet();

    return Database.query(
             TestUtil.genQuery('JobAttemptWorker__c') + ' WHERE JobAttempt__c in :keys'
           );
  }

  public static ApexJobTracker getApexJobTracker() {
    ApexJobTracker__c t = [SELECT Id FROM ApexJobTracker__c LIMIT 1];
    return ApexJobTracker.getById(t.Id);
  }
}