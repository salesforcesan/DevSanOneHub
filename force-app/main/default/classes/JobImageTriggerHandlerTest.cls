@isTest
public class JobImageTriggerHandlerTest {
    static string dupHash = '1234';

    @testSetup static void setup(){
        TriggerUtil.skipAllTriggers();
        TestDataUtil.init();
        TestDataUtil.initImageServiceSettings();
        TestProject.create('demo').addAll();
    }

    @isTest
    public static void test_ItShouldInsertProperly(){
        //GIVEN
        Project__c p = TestProject.getProjects()[0];
        ProjectService__c ps = TestProject.getServices(p.Id)[0];
        JobAttempt__c attempt = TestProject.getJobAttempts(p.Id)[0];

        //WHEN
        test.startTest();
        insertOneImage('','');
        test.stopTest();

        //THEN
        JobImage__c img = TestProject.getJobImages(p.Id)[0];
        QA.EQ(ps.Id, img.ProjectService__c,'project service is assigned.');
        QA.IsTrue(img.JobDateReported__c != null, 'report date inited.');
    }

    @isTest
    public static void test_ItShouldInsertJobReportDateProperly(){
        //GIVEN
        Datetime dttm = Datetime.now();
        Project__c p = TestProject.getProjects()[0];
        ProjectService__c ps = TestProject.getServices(p.Id)[0];
        JobAttempt__c attempt = TestProject.getJobAttempts(p.Id)[0];
        attempt.DateOriginallyReported__c = dttm;
        attempt.DateReported__c = null;
        update attempt;

        //WHEN
        test.startTest();
        insertOneImage('','');
        test.stopTest();

        //THEN
        JobImage__c img = TestProject.getJobImages(p.Id)[0];
        QA.EQ(ps.Id, img.ProjectService__c,'project service is assigned.');
        QA.IsTrue(img.JobDateReported__c != null, 'report date assigned from original report date.');
    }


    @isTest
    public static void test_ItShouldCheckDupIfHashDup(){
        //GIVEN
        Project__c p = TestProject.getProjects()[0];
        JobImage__c img1 = insertOneImage(dupHash,'');
        JobImage__c img2 = insertOneImage('','');
        List<JobImage__c> scope = new List<JobImage__c>();

        //WHEN
        test.StartTest();
        img2.PhotoHash__c = dupHash;
        scope.add(img2);
        PhotoViewerHashDetection.create(scope).run();
        test.StopTest();

        //THEN
        List<JobImage__c> imgs = [SELECT Id, IsDuplicated__c ,PoorQualityCheck__c FROM JobImage__c
        WHERE IsDuplicated__c = true AND PoorQualityCheck__c = true];
        QA.EQ(2, imgs.size(),'two duplicated images updated.');

        List<Task> ts = [SELECT Subject FROM Task WHERE WhatId=:p.Id];
        QA.EQ(1, ts.size(),'should have one task created for dup');
        QA.EQ('Duplicate photo Detected', ts[0].Subject,'the task subject should be matched');
    }

    @isTest
    public static void test_itShouldCheckBothDupIfBulkUpdate(){
        //GIVEN
        Project__c p = TestProject.getProjects()[0];
        JobImage__c img1 = insertOneImage('','');
        JobImage__c img2 = insertOneImage('','');
        List<JobImage__c> scope = new List<JobImage__c>();

        //WHEN
        test.startTest();
        List<JobImage__c> imgs = TestProject.getJobImages(p.Id);
        img1 = imgs[0];
        img2 = imgs[1];
        img1.PhotoHash__c = 'iLfOC7oWqeupCWqKQ74K+g==';
        img2.PhotoHash__c = 'iLfOC7oWqeupCWqKQ74K+g==';
        scope.add(img1);
        scope.add(img2);
        PhotoViewerHashDetection.create(scope).run();
        test.stopTest();

        //THEN
        List<JobImage__c> results = TestProject.getJobImages(p.Id);
        List<Task> tasks = getTasks(p.Id);
        QA.IsTrue(results.get(0).Project__c !=null, 'img project id is not null');
        QA.EQ(1, tasks.size(), 'one task created');
        QA.EQ(2, results.size(), '2 images inserted');
        QA.EQ(true, results[0].IsDuplicated__c,'dup');
        QA.EQ(results[0].IsDuplicated__c, results[1].IsDuplicated__c,'two dup');

    }

    @isTest
    static void itShouldMarkImageErrorFlagIfImageUrlIsInvalid() {
        //GIVEN
        Project__c p = TestProject.getProjects()[0];

        //WHEN
        test.startTest();
        insertOneImage('','true');
        test.stopTest();

        //THEN
        List<JobImage__c> results = TestProject.getJobImages(p.Id);
        QA.isTrue(results.size() > 0, 'has image inserted');
        JobImage__c img = results[0];
        QA.EQ(true, img.IsErrored__c, 'should error flagged');
        QA.EQ(true, img.PoorQualityCheck__c, 'poor quality marked.');
        QA.EQ('Invalid image url:true', img.ErrorMessage__c,'error message expected.');
    }

    @isTest
    static void itShouldNotMarkErrorFlagIfImageUrlIsValid() {
        //GIVEN
        Project__c p = TestProject.getProjects()[0];
        String imgUrl = 'http://www.yahoo.com/space.jpg';
        //WHEN
        test.startTest();
        insertOneImage('',imgUrl);
        test.stopTest();

        //THEN
        List<JobImage__c> results = TestProject.getJobImages(p.Id);
        QA.isTrue(results.size() > 0, 'has image inserted');
        JobImage__c img = results[0];
        QA.EQ(false, img.IsErrored__c, 'should not error flagged');
        QA.EQ(false, img.PoorQualityCheck__c, 'poor quality should not marked.');
        QA.EQ(imgUrl, img.ImageURL__c,'url should be assigned');
    }

    static List<Task> getTasks(Id projectId){
        return [SELECT WhatId FROM Task WHERE WhatId = :projectId AND Status != 'Completed'];
    }

    static JobImage__c insertOneImage(string hashCode, string imageUrl){
        Attachment att = new Attachment();
        att.ParentId = TestDataUtil.getAccount().Id;
        att.body = Blob.valueOf('data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAwAAAAFCAYAAABxeg0vAAAABHNCSVQICAgIfAhkiAAAAAlwSFlzAAAECwAABAsBkBCzYwAAABl0RVh0U29mdHdhcmUAd3d3Lmlua3NjYXBlLm9yZ5vuPBoAAACDSURBVAiZRc47DoFRGITh5z+dIy6JS0PzW4CKqFVahdJKJBpWINHahBWoaFUapUgoFHag+RJTzbyZTKbAAlNUscYKFWSccMQBZ3wKPDDCDGPU8UYDd5R4YYteQj/KGR1/3TBBDd9gzxTmijYukTNacW2PJebYwAAJu1jrBiuDQxNDpB+UHxLwweUDkAAAAABJRU5ErkJggg==');
        att.name = 'test.png';
        insert att;

        Project__c project = TestProject.getProjects().get(0);
        JobAttempt__c jobAttempt = TestProject.getJobAttempts(project.Id).get(0);
        JobImage__c img = new JobImage__c(
            Processed__c = false,
            AttachmentId__c = att.Id,
            JobAttempt__c = jobAttempt.Id,
            PhotoHash__c = hashCode,
            ImageUrl__c = imageUrl,
            IsDuplicated__c = false,
            ImageContentType__c = 'png'
        );
        insert img;
        return img;
    }
}