@isTest
public class TestUtil {

    public static void initBaseData() {
        TestDataUtil.init();
    }

    public static List < Project__c > generateProjects(Integer count) {
        return generateProjects(count, System.today().addDays(60), System.today().addDays(90), '');
    }

    public static List < Project__c > generateProjects(Integer count, Date startDate, Date endDate) {
        return generateProjects(count, startDate, endDate, '');
    }

    public static List < Project__c > generateProjects(Integer count, Date startDate, Date endDate, String typeOfProject) {
        if (String.isBlank(typeOfProject)) {
            typeOfProject = ProjectType.MD;
        }
        List < Project__c > projects = new List < Project__c > ();
        for (Integer i = 0; i < count; i++) {
            projects.add(createProject('Project' + i, typeOfProject, startDate, endDate));
        }
        insert projects;

        generateProjectAccounts(projects);
        return projects;
    }

    static void generateProjectAccounts(List<Project__c> projects) {
        Account acct = TestDataUtil.getAccount();
        List<ProjectAccount__c> accounts = new List<ProjectAccount__c>();

        for (Project__c p : projects) {
            accounts.add(new ProjectAccount__c(
                             Account__c = acct.Id,
                             isPrimary__c = true,
                             Project__c = p.Id,
                             SplitValue__c = 100
                         ));
        }
        insert accounts;
    }

    public static List < ProjectLocation__c > generateProjectLocations(Integer count, Id projectId, String status) {
        List<ProjectLocation__c> projLocs = new List < ProjectLocation__c > ();
        List<Location__c > locs = TestDataUtil.getLocations();
        if (count > locs.size()) {
            throw new CustomException('count is too large.');
        }

        for (Integer i = 0; i < count; i++) {
            projLocs.add(new ProjectLocation__c (
                             Project__c = projectId,
                             Location__c = locs[i].Id,
                             Status__c = status
                         ));
        }
        insert projLocs;
        return projLocs;
    }

    public static Project__c generateProjectwithJobs(String projectType, Date startDate, Date endDate) {
        Project__c project = TestUtil.generateFullTestProject(projectType, startDate,  endDate);
        Id projectid = project.Id;
        //what heck we are doing here. it is wrong. we are not testing this batch job here.
        //we are setup job test data.
        SchedulingStrategy schedulingStrategyObject = SchedulingStrategyFactory.getSchedulingStrategy(projectType);
        List<ProjectLocation__c> scope = Database.query(schedulingStrategyObject.getSchedulableLocationsQuery(project, ''));
        SchedulingStrategyObject.ScheduleLocations(scope, project.ID);
        return project;
    }

    static Project__c createProject(string name, string projectType, Date startDate, Date endDate) {
        return new Project__c(
                   Name = name,
                   Status__c = 'Planning',
                   StartDate__c = startDate,
                   EndDate__c = endDate,
                   ApprovalDate__c = startDate.addDays(-1000),
                   ProjectType__c = TestDataUtil.getProjectType(projectType).Id,
                   ProjectScheduleOption__c = TestDataUtil.getProjectScheduleOption().Id,
                   Retailer__c = TestDataUtil.getRetailer().Id,
                   UpdateSequence__c = Crypto.getRandomInteger(),
                   BudgetedLocationsCount__c = 5000
               );
    }

    static Project__c genProject(String name, String projectType, Date startDate, Date endDate) {
        Project__c project = createProject(name, projectType, startDate, endDate);
        insert project;
        return project;
    }

    public static Project__c generateFullTestProject(String projectType, Date startDate, Date endDate) {
        TestUtil.turnOffTrigger();
        initBaseData();

        Project__c project = genProject('Test Project', projectType, startDate, endDate);
        List <ProjectService__c> ps = generateProjectServices(1, project.id);
        generateProjectLocations(1, project.id, '');
        List<Target__c> coll = createProducts();

        ProjectServiceTarget__C pscObj = new ProjectServiceTarget__C ();
        pscObj.ProjectService__c = ps[0].id;
        pscObj.Target__c = coll[0].id;
        pscObj.Type__c = 'Primary';
        pscObj.Quantity__c = 0;
        pscObj.Price__c = 0;
        pscObj.YieldPerUnit__c = 0;
        insert pscObj;

        ID serviceId = ps[0].Service__c;
        List<ProjectServiceAttribute__c> pscaList = new List<ProjectServiceAttribute__c>();

        for (ServiceAttribute__c sa : [SELECT Id, Attribute__c, Service__c FROM ServiceAttribute__c WHERE Service__c = :serviceId]) {
            ProjectServiceAttribute__c psca = new ProjectServiceAttribute__c();
            psca.Attribute__c = sa.Attribute__c;
            psca.AttributeValue__c   = '';

            psca.ProjectService__c = ps[0].id;
            psca.Service__c = sa.Service__c;
            psca.ServiceAttribute__c = sa.Id;
            pscaList.add(psca);
        }
        insert pscaList;

        List<Attribute__c> attchAttr = getAttributes(CONSTANTS.ATTRIBUTE_PHOTO);
        Attachment myAttachment  = new Attachment();
        myAttachment.Body = blob.valueOf('iVBORw0KGgoAAAANSUhEUgAAABQAAAAUCAYAAACNiR0NAAAACXBIWXMAAAsTAAALEwEAmpwYAAAKT2lDQ1BQaG90b3Nob3AgSUNDIHByb2ZpbGUAAHjanVNnVFPpFj333vRCS4iAlEtvUhUIIFJCi4AUkSYqIQkQSoghodkVUcERRUUEG8igiAOOjoCMFVEsDIoK2AfkIaKOg6OIisr74Xuja9a89');
        myAttachment.Name = 'delete.png';
        myAttachment.ParentId = attchAttr[0].Id;
        insert myAttachment;

        myAttachment  = new Attachment();
        myAttachment.Body = blob.valueOf('iVBORw0KGgoAAAANSUhEUgAAABQAAAAUCAYAAACNiR0NAAAACXBIWXMAAAsTAAALEwEAmpwYAAAKT2lDQ1BQaG90b3Nob3AgSUNDIHByb2ZpbGUAAHjanVNnVFPpFj333vRCS4iAlEtvUhUIIFJCi4AUkSYqIQkQSoghodkVUcERRUUEG8igiAOOjoCMFVEsDIoK2AfkIaKOg6OIisr74Xuja9a89');
        myAttachment.Name = 'delete.jpg';
        myAttachment.ParentId = attchAttr[0].Id;
        insert myAttachment;

        myAttachment  = new Attachment();
        myAttachment.Body = blob.valueOf('iVBORw0KGgoAAAANSUhEUgAAABQAAAAUCAYAAACNiR0NAAAACXBIWXMAAAsTAAALEwEAmpwYAAAKT2lDQ1BQaG90b3Nob3AgSUNDIHByb2ZpbGUAAHjanVNnVFPpFj333vRCS4iAlEtvUhUIIFJCi4AUkSYqIQkQSoghodkVUcERRUUEG8igiAOOjoCMFVEsDIoK2AfkIaKOg6OIisr74Xuja9a89');
        myAttachment.Name = 'delete.pdf';
        myAttachment.ParentId = attchAttr[0].Id;
        insert myAttachment;

        return project;
    }

    static List<Attribute__c> getAttributes(String type) {
        return String.isBlank(type) ? [Select Id, Name, AttributeType__c from Attribute__c] :
               [Select Id, Name, AttributeType__c from Attribute__c where AttributeType__c = :type];
    }

    public static JobAttempt__c generateJobAttempt(Job__c parent, String attemptStatus) {
        JobAttempt__c oneTry = new JobAttempt__c ();
        oneTry.IsActive__c = true;
        oneTry.IsExecuted__c = false;
        oneTry.Job__c = parent.Id;
        oneTry.AttemptStatus__c = attemptStatus;
        oneTry.NumberOfReschedules__c = 0;
        oneTry.UniqueKey__c = 'UK' + String.valueOf(Crypto.getRandomInteger());
        insert oneTry;

        return oneTry;
    }

    public static void generateJobAttemptWorkers(JobAttempt__c parent, Integer count) {

        List<JobAttemptWorker__c> jaws = new List<JobAttemptWorker__c>();
        for (Integer i = 0; i < count; i++) {
            String workerType;
            if (i == 0)
                workerType = CONSTANTS.JOB_ATTEMPT_WORKER_WORKER_TYPE_TEAM_LEAD;
            else
                workerType = CONSTANTS.JOB_ATTEMPT_WORKER_WORKER_TYPE_TEAM_MEMBER;

            JobAttemptWorker__c jaw = new JobAttemptWorker__c ();
            jaw.JobAttempt__c = parent.Id;
            jaw.WorkerType__c = workerType;
            jaws.add(jaw);
        }
        if (jaws.size() > 0)
            insert jaws;

    }

    public static void createJobAttemptWorkerTimeEntry(JobAttemptWorker__c parent, String timeEntryType) {

        JobAttemptWorkerTimeEntry__c jawte = new JobAttemptWorkerTimeEntry__c();
        jawte.JobAttemptWorker__c = parent.Id;
        jawte.TimeEntryType__c = timeEntryType;
        jawte.StartTime__c = DateTime.now();

        insert jawte;
    }



    private static Date parseDate(Object dateValue) {
        return dateValue != null ? Date.valueOf(dateValue) : null;
    }

    public static List < ProjectLocation__c > LocationsAddViewToProject(Id projectID, List < Location__c > locs) {

        List < ProjectLocation__c > projLocs = new List < ProjectLocation__c > ();

        for (Integer i = 0; i < locs.size(); i++) {
            ProjectLocation__c projLoc = new ProjectLocation__c();
            projLoc.Project__c = projectID;
            projLoc.Location__c = locs.get(i).Id;
            projLocs.add(projLoc);
        }
        insert projLocs;
        return projLocs;
    }

    static List<Service__c> getServices() {
        return [SELECT Id FROM Service__c];
    }

    public static List < ProjectService__c > generateProjectServices(Integer count, Id projectID) {

        List < ProjectService__c > projServs = new List < ProjectService__c > ();
        List < Service__c > servs = getServices();
        Project__c proj = [SELECT StartDate__c FROM Project__c WHERE id = :projectID];
        for (Integer i = 0; i < count; i++) {
            ProjectService__c projServ = new ProjectService__c();
            projServ.Project__c = projectID;
            projServ.service__c = servs[i].id;
            projServ.ServiceTitle__c = 'Service Ttile ' + i;
            projServ.UniqueKey__c = 'psuk' + Crypto.getRandomLong();

            projServ.TargetType__c = 'Brand';

            projServ.JobManual__c = 'Standard';
            projServ.OneHubRetailerId__c = 'WALGREENS';
            projServs.add(projServ);
        }
        insert projServs;

        ProjectServiceEquipment__c pse = new ProjectServiceEquipment__c();
        pse.Equipment__c = TestDataUtil.getEquipment(CONSTANTS.EQUIPMENT_ASSET).Id;
        pse.ProjectService__c = projServs[0].Id;
        pse.Quantity__c = 1;
        pse.UniqueKey__c = 'pseuk' + Crypto.getRandomLong();
        //pse.IsCapacityImpact__c = true;
        insert pse;

        for (Integer i = 0; i < projServs.size(); i++) {
            List<ServiceQuestion__c> templateQuestions = [SELECT Id, Name, Question__c, QuestionNumber__c, QuestionText__c, QuestionType__c FROM ServiceQuestion__c Where service__c = : projServs[i].service__c ];
            List<ProjectServiceQuestion__c> surveyQuestions = [SELECT Id FROM ProjectServiceQuestion__c where ProjectService__c = : projServs[i].id];
            if (surveyQuestions.size() > 0 ) delete  surveyQuestions;

            for (integer j = 0; j < templateQuestions.size(); j++) {
                ProjectServiceQuestion__c psq = new ProjectServiceQuestion__c();
                //surveyQn.Name = tempQnsList[0].Name;
                psq.QuestionNumber__c = templateQuestions[j].QuestionNumber__c;
                psq.ServiceQuestion__c = true;
                psq.Question__c = templateQuestions[j].Question__c;
                psq.ProjectService__c = projServs[i].id;
                upsert psq;

            }
        }
        return projServs;
    }

    public static List < Opportunity > generateOpportunities(Integer count) {
        List < Opportunity > mts = new List < Opportunity > ();
        List <User> users = generateUsers(1);

        for (Integer i = 0; i < count; i++) {
            Opportunity rt = new Opportunity();
            rt.Name = 'Opportunity ' + i;
            rt.CloseDate = System.Today().AddDays(30);
            rt.StageName = 'Planning';
            //rt.AccountId = accnts[0].Id;
            mts.add(rt);
        }
        insert mts;
        return mts;
    }

    public static ProjectServiceMaterial__c generateProjectServiceMaterial(Id ps, Material__c m) {
        ProjectServiceMaterial__c psm = new ProjectServiceMaterial__c();
        psm.ProjectService__c = ps;
        psm.Material__c = m.Id;
        psm.Quantity__c = 1;
        psm.MaterialDescription__c = m.Description__c;
        insert psm;
        return psm;
    }

    public static List < ProjectType__c > getRoadShowProjectType() {
        return [Select Id, Name FROM ProjectType__c LIMIT 1];
    }

    public static String generateRandomString(Integer len) {
        String hashString = '1000' + String.valueOf(Datetime.now().formatGMT('yyyy-MM-dd HH:mm:ss.SSS'));
        Blob hash = Crypto.generateDigest('MD5', Blob.valueOf(hashString));
        String hexDigest = Math.Random() + EncodingUtil.convertToHex(hash);
        return hexDigest.substring(0, len);
    }

    public static List < ProjectServiceQuestion__c > generateSurveyQuestions(Integer count, Id projectServiceID) {

        List < ProjectServiceQuestion__c > surveyQuestions = new List < ProjectServiceQuestion__c > ();

        for (Integer i = 0; i < count; i++) {
            Question__c q = generateSurveyQuestionBank();
            ProjectServiceQuestion__c surveyQuestion = new ProjectServiceQuestion__c();
            surveyQuestion.QuestionNumber__c = i;
            surveyQuestion.ProjectService__c = projectServiceID;
            surveyQuestion.Question__c = q.Id;
            surveyQuestion.UniqueKey__c = generateRandomString(20);
            surveyQuestions.add(surveyQuestion);
        }
        insert surveyQuestions;
        return surveyQuestions;
    }

    public static List < ProjectServiceQuestion__c > generateSurveyQuestions(Integer count, Id projectServiceID, String type) {
        return generateSurveyQuestions(count, projectServiceID);
    }

    public static job__c generateJobs(id projectID, id projectLocationID, id projectServiceID) {
        Job__c job = newJob(projectID, projectLocationID, projectServiceID);
        insert job;
        return job;
    }

    private static Job__c newJob(id projectID, id projectLocationID, id projectserviceID) {
        projectlocation__c ploc = [select location__c from ProjectLocation__c where id = : projectLocationID];
        projectservice__c ps = [SELECT Name, Service__c FROM ProjectService__c where id = : projectserviceID and Service__c != null LIMIT 1];
        Project__c project = [SELECT Id, StartDate__c from project__c where id = :projectID];
        job__c job = new job__C();
        job.project__c = projectID;
        job.JobStatus__c = CONSTANTS.JOB_STATUS_OPEN;
        job.Location__c = ploc.Location__c;
        job.ProjectLocation__c = ploc.Id;
        job.ProjectService__c = ps.Id;
        job.Service__c = ps.Service__c;
        job.JobStartDate__c = project.StartDate__c;
        job.JobEndDate__c = project.StartDate__c;
        job.ProjectScheduleOptionName__c = CONSTANTS.SCHEDULE_OPTION_EC;
        return job;
    }

    public static job__c generateJob(id projectID, id projectLocationID, id projectServiceID, String status) {
        Job__c job = newJob(projectID, projectLocationID, projectServiceID);
        job.JobStatus__c = status;
        insert job;
        return job;
    }

    public static list < job__c > generateJobs(id projectID, id projectLocationID, id projectserviceID, Integer cnt) {
        projectlocation__c ploc = [select location__c from ProjectLocation__c where id = : projectLocationID];
        projectservice__c ps = [SELECT Name, Service__c FROM ProjectService__c where id = : projectserviceID];
        Project__c project = [SELECT Id, StartDate__c from project__c where id = :projectID];
        job__c job;
        list < job__C > lstJobs = new list < job__C > ();
        for (Integer i = 0; i < cnt; i++) {
            job = new job__C();
            job.project__c = projectID;
            job.JobStatus__c = CONSTANTS.JOB_STATUS_PENDING;
            job.Location__c = ploc.Location__c;
            job.ProjectLocation__c = ploc.Id;
            job.ProjectService__c = projectserviceID;
            job.Service__c = ps.Service__c;
            job.JobStartDate__c = project.StartDate__c;
            job.JobEndDate__c = project.StartDate__c;
            job.ProjectScheduleOptionName__c = CONSTANTS.SCHEDULE_OPTION_EC;
            lstJobs.add(job);
        }
        insert lstJobs;
        return lstJobs;
    }

    public static List < User > generateUsers(Integer count) {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User'];
        List < User > users = new List < User > ();
        for (Integer i = 0; i < count; i++) {
            User u = new User(Alias = 'rsal' + i, Email = 'retailsolutiontest' + i + '@testorg.com',
                              EmailEncodingKey = 'UTF-8', LastName = 'Testing' + i, LanguageLocaleKey = 'en_US',
                              LocaleSidKey = 'en_US', ProfileId = p.Id,
                              TimeZoneSidKey = 'America/Los_Angeles', UserName = 'retailsolutiontest' + i + '@testorg.com');
            users.add(u);
        }
        insert users;
        return users;
    }

    public static List<Target__c> createProducts() {
        list<Target__c> lstColl = new list<Target__c>();

        Target__c obj = new Target__c();
        obj.Name = 'CHEF SHAMY - Garlic Butter';
        obj.Targettype__c = 'Product';
        obj.departmentname__c = 'Dairy';
        obj.PackageSizeQty__c = 1;
        obj.PackageSizeUnits__c = 'oz';
        obj.StockCode__c =  generateRandomString(8);
        obj.upc__c = generateRandomString(12);
        lstColl.add(obj);

        obj = new Target__c();
        obj.Name = 'Wheat Crackers';
        obj.Targettype__c = 'Product';
        obj.departmentname__c = 'Dairy';
        obj.PackageSizeQty__c = 1;
        obj.PackageSizeUnits__c = 'oz';
        obj.StockCode__c = generateRandomString(8);
        obj.upc__c = generateRandomString(12);
        lstColl.add(obj);

        insert lstColl;
        return lstColl;
    }



    public static ServiceQuestion__c generateTemplateQuestion(Id serviceId, integer uniqueVal) {
        Question__c q = generateSurveyQuestionBank();

        ServiceQuestion__c tq = new ServiceQuestion__c();
        tq.QuestionNumber__c = 1;
        tq.Question__c = q.Id;
        tq.Service__c = serviceId;
        insert tq;
        return tq;
    }

    public static Question__c generateSurveyQuestionBank() {
        list<question__c> qs = [select id, name, questiontext__c, questiontype__c, OneHubQuestionId__c  from question__c];
        if (qs.size() > 0) {
            return qs[0];
        }

        Question__c tq = new Question__c();
        tq.QuestionText__c = 'Q1';
        tq.QuestionType__c = 'Number';
        tq.OneHubQuestionId__c = 'OHQ' + crypto.getRandomLong();
        insert tq;
        return tq;
    }


    public static QuestionDefinedResponse__c generateTemplateDefinedResponse(Id tqId, Id qId) {
        QuestionDefinedResponse__c qdr = new QuestionDefinedResponse__c();
        qdr.Question__c = qId;
        qdr.DefinedResponseOrder__c = 1;
        qdr.DefinedResponseText__c = 'DR Text';
        qdr.OneHubAnswerId__c = 'OHQI' + String.valueOf(Crypto.getRandomInteger());
        insert qdr;
        return qdr;
    }


    public static QuestionDefinedResponse__c generateTemplateDefinedResponse(Id qId) {
        QuestionDefinedResponse__c qdr = new QuestionDefinedResponse__c();
        qdr.Question__c = qId;
        qdr.OneHubAnswerId__c = 'OHQI' + String.valueOf(Crypto.getRandomInteger());
        qdr.DefinedResponseOrder__c = 1;
        qdr.DefinedResponseText__c = 'DR Text';
        insert qdr;
        return qdr;
    }

    public static String getProjectType(Id projectId) {
        return [SELECT ProjectType__r.Name FROM Project__c WHERE Id = :projectId].ProjectType__r.Name;
    }

    public static String getProjectType(Project__c project) {
        return getProjectType(project.Id);
    }

    public static Location__c buildLocation(Id retailerId) {

        return new Location__c(
                   Name = 'Location ' + retailerId
                          , LocationReference1__c = generateRandomString(20)
                                  , City__c = 'City ' + retailerId
                                              , LocationNumber__c = generateRandomString(10)
                                                      , Retailer__c = retailerId
               );
    }

    public static JobAttempt__c setupJobTestData(String attemptStatus, String jobStatus) {
        TriggerUtil.SkipAllTriggers();
        Date START_DATE = Datetime.Now().Date();
        Date END_DATE = Datetime.Now().addDays(14).Date();

        Project__c project = TestUtil.generateFullTestProject(
                                 ProjectType.MD, START_DATE, END_DATE);

        ProjectLocation__c location = [SELECT Id FROM ProjectLocation__c WHERE Project__c = :project.Id LIMIT 1];
        ProjectService__c service = [SELECT Id FROM ProjectService__c WHERE Project__c = :project.Id LIMIT 1];

        Job__c job = TestUtil.generateJob(
                         project.Id,
                         location.Id,
                         service.Id,
                         jobStatus);
        JobAttempt__c attempt = generateJobAttempt(job, attemptStatus);
        job.ActiveJobAttempt__c = attempt.Id;
        update Job;

        return attempt;
    }

    public static List<Contact> prepareContacts() {
        List<Contact> contacts = new List<Contact>();
        Integer i = 0;
        for (Contact contact : [SELECT Id, ContactId__c FROM Contact]) {
            contact.ContactId__c = 'CD-' + String.valueOf(i++);
            contacts.add(contact);
        }
        update contacts;
        return contacts;
    }

    public static void turnOffTrigger() {
        TriggerUtil.SkipAllTriggers();
    }

    public static void turnOnJobTrigger() {
        TriggerUtil.skipJobTrigger = false;
        TriggerUtil.skipJobDeleteTrigger = false;
        TriggerUtil.skipJobUpdateTrigger = false;
        TriggerUtil.skipJobAttemptTrigger = false;
    }

    public static JobAttempt__c getAttempt(ID id) {
        if (null == id) {
            return [SELECT Id, IsActive__c, AttemptScheduledDate__c, AttemptType__c, DateReported__c, AttemptStatus__c, AttemptScheduleDate__c, Job__c, ExceptionCode__c, ExceptionComments__c, ExceptionReason__c, IsExecuted__c, NumberOfReschedules__c, AttemptedDate__c, DateStarted__c, DateAssigned__c, AssignedContactId__c, AssignedContact__c, ReportedContact__c, ECAttemptId__c, DateOriginallyReported__c FROM JobAttempt__c LIMIT 1];
        }
        return [SELECT Id, IsActive__c, AttemptScheduledDate__c, AttemptType__c, DateReported__c, AttemptStatus__c, AttemptScheduleDate__c, Job__c, ExceptionCode__c, ExceptionComments__c, ExceptionReason__c, IsExecuted__c, NumberOfReschedules__c, AttemptedDate__c, DateStarted__c, DateAssigned__c, AssignedContactId__c, AssignedContact__c, ReportedContact__c, ECAttemptId__c, DateOriginallyReported__c FROM JobAttempt__c WHERE Id = :id];
    }

    public static Job__c getJob(ID id) {
        return [SELECT Id, JobAttemptedDate__c, JobDateReported__c, JobStatus__c, IsScheduled__c, ActiveJobAttempt__c, JobCommittedDate__c, JobScheduledDate__c, JobExecutedDate__c, Project__c, ActiveJobAttempt__r.AttemptScheduleDate__c, IsRescheduled__c, Service__c, JobCompletedDate__c, CompletionStatus__c, JobDateAssigned__c, JobDateStarted__c, JobDateOriginallyAssigned__c, JobFirstAttemptDate__c, IsExecuted__c FROM Job__c WHERE Id = :id];
    }

    public static Project__c getProject(ID id) {
        return [SELECT Id, Status__c, PendingJobImportRequest__c, ApexJobName__c, ProjectScheduleOption__c FROM Project__c WHERE Id = :id];
    }

    public static List<Project__c> getProjects() {
        return [SELECT Id, Status__c, PendingJobImportRequest__c, ApexJobName__c, ProjectScheduleOption__c FROM Project__c];
    }

    public static List<ProjectAccount__c> getProjectAccounts() {
        return [SELECT Id, SplitValue__c, Account__c, IsPrimary__c FROM ProjectAccount__c];
    }

    public static List<ProjectLocation__c> getProjectLocations(Id projectId) {
        return [SELECT Id, Name From ProjectLocation__c Where Project__c = :projectId];
    }
    public static ProjectAccount__c getPrimaryAccount(Id projectId) {
        return [SELECT Id, Name From ProjectAccount__c Where Project__c = :projectId And IsPrimary__c = true ];
    }


    public static List<ProjectService__c> getProjectServices(Id projectId) {
        return [SELECT Id, Name from ProjectService__c Where Project__c = :projectId];
    }

    public static List<Job__c> getJobs(Id projectId) {
        return [SELECT Id, Name from Job__c where Project__c = :projectId];
    }

    public static List<Attachment> getAttachments(List<String> predicates) {
        String sql = 'SELECT Id, Name, Body,BodyLength, ContentType, ParentId FROM Attachment ';
        if (predicates.size() == 0) {
            return Database.query(sql + 'LIMIT 100');
        }
        return Database.query(sql + 'WHERE ' + String.join(predicates, ' AND ') + ' LIMIT 100');
    }

    public static ID getScheduleOptionId(String scheduleOption) {
        return [SELECT Id FROM ScheduleOption__c WHERE Code__c = :scheduleOption limit 1].Id;
    }

    public static Map<Boolean, Exception__c> getExceptionsByService(ID serviceId) {
        Map<Boolean, Exception__c> result = new Map<Boolean, Exception__c>();
        for (ServiceException__c se : [SELECT IsExecuted__c, Exception__c, Exception__r.Name, Exception__r.ExceptionCode__c FROM ServiceException__c WHERE Service__c = :serviceId]) {
            result.put(se.IsExecuted__c, new Exception__c(
                           Id = se.Exception__c,
                           Name = se.Exception__r.Name,
                           ExceptionCode__c = se.Exception__r.ExceptionCode__c
                       ));
        }
        return result;
    }

    public static Attachment genAttachment(Id parentId, String name, string contentType, String content) {
        Attachment att = new Attachment(
            name = name,
            ParentId = parentId,
            contentType = contentType,
            Body = Blob.valueOf(content)
        );
        insert att;
        return att;
    }

//---- GET API ----
    public static List<SObject> getRecordset(String sObjectType) {
        String sql =  genQuery(sObjectType);
        return Database.query(sql);
    }

    public static SObject getRecord(String sObjectType) {
        List<SObject> result = getRecordset(sObjectType);
        return result.size() > 0 ? result.get(0) : null;
    }

    public static List<SObject> findRecordSet(String sObjectType, IPredicateBuilder builder) {
        String sql = genQuery(sObjectType) + ' ' + builder.build();
        return Database.query(sql);
    }

    public static SObject findRecord(String sObjectType, IPredicateBuilder builder) {
        List<SObject> result = findRecordset(sObjectType, builder);
        return result.size() > 0 ? result.get(0) : null;
    }

    public static String genQuery(String sObjectType) {
        return genQuery(sObjectType, new List<String>());
    }

    public static String genQuery(String sObjectType, List<String> additionals) {
        String recordName = namify(sObjectType);
        Schema.DescribeSObjectResult meta = Schema.describeSObjects(new String[] {recordName}).get(0);
        Map<String, Schema.SObjectField> fieldMap = meta.fields.getMap();
        List<String> fieldNames = new List<String>();
        List<Schema.SObjectField> fields = fieldMap.values();
        String fielfName;
        fieldNames.add('Id');
        fieldNames.add('Name');
        for (SObjectField f : fields) {
            fielfName = f.getDescribe().getName();
            if (fielfName.indexOf('__c') != -1) {
                fieldNames.add(fielfName);
            }
        }
        for (String col : additionals) {
            fieldNames.add(col);
        }
        return 'SELECT ' + String.join(fieldNames, ',') + ' FROM ' + recordName;
    }

    static string parseField(String field){
        if (field.indexOf('.') == -1){
            return namify(field);
        }

        List<String> items = field.split('\\.');
        List<String> result = new List<String>();
        for(String item: items){
            result.add(namify(item));
        }
        return String.join(result,'.');
    }

    public static Integer countQuery(String sObjectType, List<String>fields, List<String>values) {
        String sql = 'SELECT Count(Id) cnt FROM ' + namify(sObjectType);
        List<String> predicates = new List<String>();

        for(Integer i=0; i < fields.size(); i++){
            predicates.add(parseField(String.valueOf(fields.get(i))) + '=' + values[i]);
        }
        if (!predicates.isEmpty()){
            sql += ' WHERE ' + String.join(predicates, ' AND ');
        }

        AggregateResult[] results = Database.query(sql);
        if(results.size() > 0){
            return Integer.valueOf(results[0].get('cnt'));
        }

        return 0;
    }

    public static String namify(String name) {
        String namespace = CONSTANTS.CURRENTNAMESPACEPREFIX;
        if (String.isBlank(name) || name.indexOfIgnoreCase(namespace) == 0) return name;
        
        if (name.indexOfIgnoreCase('__c') != -1 
            || name.indexOfIgnoreCase('__r') != -1){
            return namespace + name;    
        }
        return name;
    }

    public static void EQ(object expected, object result, String msg) {
        System.assertEquals(expected, result, msg);
    }

    public static void OK(Boolean condition, String msg) {
        System.assertEquals(true, condition, msg);
    }
}