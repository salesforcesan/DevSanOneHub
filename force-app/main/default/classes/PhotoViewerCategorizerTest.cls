@isTest
private class PhotoViewerCategorizerTest {
    @testSetup
    static void setup() {
        TriggerUtil.SkipAllTriggers();
        TestDataUtil.init();
        TestProject tp = TestProject.create('demo').addAll();
        tp.TestProjectServiceList[0].addSurvey();
        tp.addJobImages();
    }

    @isTest
    static void itShouldAssignRightLabelToPhoto() {
        // Given
        Project__c p = TestProject.getProjects()[0];
        List<JobImage__c> images = TestProject.getJobImages(p.Id);
        IAIImageClassifier classifier = new AIImageClassifierFake();

        // When
        test.startTest();
        PhotoViewerCategorizer.create(classifier, images).run();
        test.stopTest();

        // Then
        images = TestProject.getJobImages(p.Id);
        QA.isTrue(images.size() > 0, 'has images');
        JobImage__c image = images[0];
        QA.EQ('ShelfDisplay', image.ClassifiedLabel__c, 'labeled as ' + image.ClassifiedLabel__c);
    }

    @isTest
    static void itShouldCaptureException() {
        // Given
        Project__c p = TestProject.getProjects()[0];
        List<JobImage__c> images = TestProject.getJobImages(p.Id);
        IAIImageClassifier classifier = new AIImageClassifierFakeForNotMatch();

        // When
        test.startTest();
        PhotoViewerCategorizer.create(classifier, images).run();
        test.stopTest();

        // Then
        images = TestProject.getJobImages(p.Id);
        QA.isTrue(images.size() > 0, 'has images');
        JobImage__c image = images[0];
        QA.EQ(true, image.IsErrored__c, 'error flagged');
    }

}