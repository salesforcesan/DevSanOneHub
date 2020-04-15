@isTest
private class JobImageHandlerTest
{
    @testSetup
    static void setup(){
        TriggerUtil.skipAllTriggers();
        TestDataUtil.init();
        TestDataUtil.initImageServiceSettings();
        TestProject.create('demo').addAll();
        initJobImageData();
    }

    static void initJobImageData(){
        Attachment att = new Attachment();
        att.ParentId = TestDataUtil.getAccount().Id;
        att.body = Blob.valueOf('data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAwAAAAFCAYAAABxeg0vAAAABHNCSVQICAgIfAhkiAAAAAlwSFlzAAAECwAABAsBkBCzYwAAABl0RVh0U29mdHdhcmUAd3d3Lmlua3NjYXBlLm9yZ5vuPBoAAACDSURBVAiZRc47DoFRGITh5z+dIy6JS0PzW4CKqFVahdJKJBpWINHahBWoaFUapUgoFHag+RJTzbyZTKbAAlNUscYKFWSccMQBZ3wKPDDCDGPU8UYDd5R4YYteQj/KGR1/3TBBDd9gzxTmijYukTNacW2PJebYwAAJu1jrBiuDQxNDpB+UHxLwweUDkAAAAABJRU5ErkJggg==');
        att.name = 'test.png';
        insert att;

        Project__c project = TestProject.getProjects().get(0);
        JobAttempt__c job = TestProject.getJobAttempts(project.Id).get(0);

        JobImage__c img = new JobImage__c(
            Processed__c = false,
            AttachmentId__c = att.Id,
            JobAttempt__c = job.Id,
            ImageContentType__c = 'image/png'
            );
        insert img;
    }


	@isTest
	static void itShouldGetOneJobImage()
	{
		// Given
        JobImage__c img = [SELECT Id, Name FROM JobImage__c LIMIT 1];

		// When
        test.startTest();
        List<JobImage__c> results = JobImageHandler.getJobImages();
        test.stopTest();

		// Then
        TestUtil.EQ(1, results.size(), 'one job image');
        TestUtil.EQ(img.Name, results.get(0).Name, 'name matched');

	}

    @isTest 
    static void itShouldGenUrl(){
        // GIVEN
        JobImage__c img = [SELECT Id, AttachmentId__c, Name FROM JobImage__c LIMIT 1];        
        List<JobImage__c> imgList = new List<JobImage__c>{img};
        
        // WHEN
        test.startTest();
        JobImageHandler.InvokeBatchJobImages(imgList);
        test.stopTest();

        // THEN
        JobImage__c result = [SELECT ImageUrl__c, IsErrored__c, ErrorMessage__c from JobImage__c Limit 1];
        List<Attachment> atts = [select id from Attachment where id = :img.AttachmentId__c];

        QA.EQ('http://www.yahoo.com', result.ImageURL__c, 'test url');
        QA.isTrue(atts.isEmpty(),'attach purged');
    }


}