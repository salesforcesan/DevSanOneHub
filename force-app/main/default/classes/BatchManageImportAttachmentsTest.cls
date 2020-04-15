@isTest
private class BatchManageImportAttachmentsTest {
    static Date START_DATE = Datetime.Now().Date();
    static Date END_DATE = Datetime.Now().addDays(14).Date();
    static Date SCHEDULE_DATE = Datetime.Now().addDays(2).Date();
    static String THREEPL_CONTACT_ID = '3PL1';

    @testSetup
    static void setup() {
        TriggerUtil.skipAllTriggers();
        TestDataUtil.init();
        TestProject tP = TestProject.create('demo', START_DATE, END_DATE, null)
                         .addAll();
        setupJobAttemptWorkersFor3PLAgentcy(tP.ProjectInstance.Id);
    }

    static void setupJobAttemptWorkersFor3PLAgentcy(string pId) {
        Contact uContact = [SELECT Id, AccountId from Contact LIMIT 1];
        List<JobAttemptWorker__c> jaws = TestProject.getJobAttemptWorkers(pId);
        for (JobAttemptWorker__c jaw : jaws) {
            jaw.ThirdPartyAgency__c = uContact.AccountId;
        }
        update jaws;
    }

    static void createAttachment(String name, String body, String parentId) {
        Attachment att = new Attachment();
        att.ParentId = parentId;
        att.Name = name;
        att.Body = Blob.valueOf(body);
        insert att;
    }

    static String genCSVStringForImportLocations(ProjectLocation__c pl,
            String oh3PLContactId) {
        List<Object> contents = new List<Object>();
        contents.add(pl.Name);
        contents.add(pl.LocationNumber__c);
        contents.add(pl.LocationName__c);
        contents.add(pl.Address__c);
        contents.add(pl.City__c);
        contents.add(pl.State__c);
        contents.add(pl.PostalCode__c);
        contents.add(pl.Status__c);
        contents.add(pl.StatusComments__c);
        contents.add('');
        contents.add('');
        contents.add(pl.ExecutionCompany__c);
        contents.add(SCHEDULE_DATE.format());
        contents.add(oh3PLContactId);
        contents.add('');

        return JSON.serialize(new String[] {String.join(contents, ',')});
    }

    @isTest
    static void itShouldNamifyProperly() {
        //GIVEN
        String fields = 'Name-1,' + TestDataUtil.SystemNameSpace + 'Job__c-2';

        //WHEN
        String result = TestDataUtil.namifyImportFields(fields);

        //THEN
        QA.EQ(result, fields, 'matched:' + fields);
    }

    @isTest
    static void itShouldNotSetScheduleDateWhenImportInvalid3PL() {
        //GIVEN
        Project__c p = TestProject.getProjects()[0];
        ProjectLocation__c pl = TestProject.getLocations(p.Id)[0];

        String csvString = genCSVStringForImportLocations(pl, THREEPL_CONTACT_ID);
        createAttachment('import_locations', csvString, p.Id);
        EmailNotifierFake fakeNotifier = new EmailNotifierFake(true, '');

        //WHEN
        test.startTest();
        BatchManageImportAttachments batch = new BatchManageImportAttachments(p.Id, 'locations', fakeNotifier);
        string batchProcessId = Database.ExecuteBatch(batch, 1);
        test.stopTest();

        //THEN
        pl = TestProject.getLocations(p.Id)[0];
        QA.isTrue(String.isBlank(pl.OneHubThirdPartyAgencyContactId__c), '3PLId should not be set');
        QA.isTrue(String.isBlank(String.valueOf(pl.LocationScheduledDate__c)), 'schedule date should not be set');

        ApexJobTracker tracker = TestProject.getApexJobTracker();
        QA.EQ(ApexJobTracker.TrackerStatus.Success, tracker.Status, 'process succeeded:' + tracker.Response);
        QA.EQ(true, tracker.failureNotified, 'email sent out:' + tracker.Response);
    }

    @isTest
    static void itShouldImportProjectLocations() {
        // Given: create attachment
        Project__c p = TestProject.getProjects()[0];
        ProjectLocation__c pl = TestProject.getLocations(p.Id)[0];

        String csvString = genCSVStringForImportLocations(pl, '');
        createAttachment('import_locations', csvString, p.Id);
        EmailNotifierFake fakeNotifier = new EmailNotifierFake(true, '');

        // When
        test.startTest();
        BatchManageImportAttachments batch = new BatchManageImportAttachments(p.Id, 'locations', fakeNotifier);
        string batchProcessId = Database.ExecuteBatch(batch, 1);
        test.stopTest();

        // Then
        pl = TestProject.getLocations(p.Id)[0];
        QA.isTrue(String.isBlank(pl.OneHubThirdPartyAgencyContactId__c), '3PLId should not be set');
        QA.EQ(SCHEDULE_DATE, pl.LocationScheduledDate__c, 'schedule date is set');

        ApexJobTracker tracker = TestProject.getApexJobTracker();
        QA.EQ(ApexJobTracker.TrackerStatus.Success, tracker.Status, 'process succeeded:' + tracker.Response);
        QA.EQ(true, tracker.failureNotified, 'email sent out:' + tracker.Response);
    }

    static String genCSVStringForImportJobs(Job__c job) {
        List<String> cntn = new List<String>();
        cntn.add(job.Name); // 0
        cntn.add(''); // 1
        cntn.add(''); // 2
        cntn.add(''); // 3
        cntn.add(''); // 4
        cntn.add(''); // 5
        cntn.add(''); // 6
        cntn.add(''); // 7
        cntn.add(''); // 8
        cntn.add(SCHEDULE_DATE.format()); // 9
        cntn.add(''); // 10
        cntn.add('123'); // 11
        cntn.add('100'); // 12

        return JSON.serialize(new String[] {String.join(cntn, ',')});
    }

    @isTest
    static void itShouldImportJobs() {
        //GIVEN
        Project__c p = TestProject.getProjects()[0];
        Job__c job = TestProject.getJObs(p.Id)[0];
        String csvString = genCSVStringForImportJobs(job);
        createAttachment('import_jobs', csvString, p.Id);
        EmailNotifierFake fakeNotifier = new EmailNotifierFake(true, '');

        //WHEN
        test.startTest();
        BatchManageImportAttachments batch = new BatchManageImportAttachments(p.Id, 'jobs', fakeNotifier);
        string batchProcessId = Database.ExecuteBatch(batch, 1);
        test.stopTest();

        //THEN
        ApexJobTracker tracker = TestProject.getApexJobTracker();
        QA.EQ(ApexJobTracker.TrackerStatus.Success, tracker.Status, 'process succeeded:' + tracker.Response);
        QA.EQ(true, tracker.failureNotified, 'email sent out:' + tracker.Response);

        job = TestProject.getJobs(p.Id)[0];
        QA.EQ(SCHEDULE_DATE, job.JobScheduledDate__c, 'schedule date set:' + tracker.Response);
        QA.EQ(100, job.EstimatedMinutesOverride__c, 'est time set');
        QA.EQ(123, job.PurchaseOverRideAmount__c, 'purchase amount set');
    }


    // orgSetting.JAWImportFields__c = 'Name-0,ECWorkerId__c-1,FirstName__c-2,LastName__c-3,ThirdPartyAgencyStatus__c-6,ECWorkerTime__c-14';
    // orgSetting.JAWImportTitle_c__c = ' Job Attempt Worker Name,EC Worker Id,First Name,Last Name,Project Number,Project Title,3PL Status,Estimated Minutes,Location Number,Location Name,Location Address,Location City,LocationState,Start Time,EC Worker Time';

    static String genCSVStringJobAttemptWorkers(JobAttemptWorker__c j) {
        List<String> cntn = new List<String>();

        cntn.add(j.Name); // 0
        cntn.add(''); // 1
        cntn.add('first'); // 2
        cntn.add('last'); // 3
        cntn.add(''); // 4
        cntn.add(''); // 5
        cntn.add('Executed'); // 6
        cntn.add(''); // 7
        cntn.add(''); // 8
        cntn.add(''); // 9
        cntn.add(''); // 10
        cntn.add(''); // 11
        cntn.add(''); // 12
        cntn.add(''); // 13
        cntn.add('10'); // 14

        return JSON.serialize(new String[] {String.join(cntn, ',')});
    }


    @isTest
    static void itShouldImportJobAttemptWorkers() {
        ////GIVEN
        // Project__c p = TestProject.getProjects()[0];
        // JobAttemptWorker__c jaw = TestProject.getJobAttemptWorkers(p.Id)[0];
        // Contact uContact = [SELECT Id, AccountId, Account.Name from Contact WHERE Id=:jaw.Contact__c];
        // String csvString = genCSVStringJobAttemptWorkers(jaw);
        // createAttachment('import_jobattemptworker', csvString, uContact.Id);
        // EmailNotifierFake fakeNotifier = new EmailNotifierFake(true, '');

        // Profile pfl = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        // User testUser = new User(Alias = 'standt', Email = 'test.user@test.com',
        //                          EmailEncodingKey = 'UTF-8', LastName = 'Testing', LanguageLocaleKey = 'en_US',
        //                          LocaleSidKey = 'en_US', ProfileId = pfl.Id,
        //                          ThirdPartyAgency__c = uContact.Account.Name,
        //                          Contact = uContact,
        //                          TimeZoneSidKey = 'America/Los_Angeles',
        //                          UserName = 'unit.tester@test.com');

        // //WHEN
        // test.startTest();
        // System.runAs(testUser) {
        //     BatchManageImportAttachments batch = new
        //     BatchManageImportAttachments(uContact.Id, 'thirdparty', fakeNotifier);
        //     string batchProcessId = Database.ExecuteBatch(batch, 1);
        // }
        // test.stopTest();

        // //THEN
        // ApexJobTracker tracker = TestProject.getApexJobTracker();
        // QA.EQ(ApexJobTracker.TrackerStatus.Success, tracker.Status, 'process succeeded:' + tracker.Response);
        // QA.EQ(true, tracker.failureNotified, 'email sent out:' + tracker.Response);
        // JobAttemptWorker__c result = [SELECT Name, FirstName__c, LastName__c FROM JobAttemptWorker__c WHERE Id=:jaw.Id];
        // QA.EQ('first', result.FirstName__c, result.Name + ': first name should be first.' + tracker.Response);
        // QA.EQ('last', result.LastName__c, 'last name set');
    }
}