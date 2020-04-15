@isTest
private class ApexJobTrackerTest
{
    @testSetup
    static void setup() {
        TriggerUtil.skipAllTriggers();
        TestDataUtil.init();
        TestProject.create('demo')
            .addAll();
    }

	@isTest
	static void itShouldInsertTracker()
	{
		// Given
        Project__c p = TestProject.getProjects()[0];
        Job__c job = TestProject.getJobs(p.Id)[0];

		// When
        test.startTest();
        ApexJobTracker tracker = ApexJobTracker.create(p.Id, ApexJobTracker.TrackerTarget.Job, ApexJobTracker.TrackerOperation.Delete_Job);
        tracker.setId1('id1')
            .setId2('id2')
            .setId3('id3')
            .setStatus(ApexJobTracker.TrackerStatus.Initial)
            .setParameters('parameters')
            .save();
        test.stopTest();

		// Then
        String trackerId = tracker.TrackerId;
        tracker = ApexJobTracker.getById(trackerId);
        QA.EQ('id1', tracker.Id1, 'id1 set');
        QA.EQ('id2', tracker.Id2, 'id2 set');
        QA.EQ(ApexJobTracker.TrackerStatus.Initial, tracker.Status, 'new');
        QA.EQ('parameters', tracker.parameters, 'parameters set');
        QA.isTrue(tracker.StartTime != null, 'start time set');
        QA.EQ(ApexJobTracker.TrackerOperation.Delete_Job, tracker.Operation, 'is delete job');
	}

    @isTest
    static void itShouldRetryWithoutFailure() {
        //GIVEN
        Project__c p = TestProject.getProjects()[0];
        Job__c j = TestProject.getJobs(p.Id)[0];

        ApexJobTracker tracker = ApexJobTracker.create(p.Id, ApexJobTracker.TrackerTarget.Job, 
            ApexJobTracker.TrackerOperation.Delete_Job);
        tracker.setId1('id1')
            .setId2('id2')
            .setId3('id3')
            .setClassName('AppClassTestFake')
            .setStatus(ApexJobTracker.TrackerStatus.Initial)
            .setParameters('parameters')
            .save();
        Datetime startTime = tracker.StartTime;
        Double tryCount = tracker.TryCount;

        //WHEN
        test.startTest();
        tracker = ApexJobTracker.getById(tracker.TrackerId);
        tracker.retry();
        test.stopTest();

        //THEN
        QA.isTrue(startTime < tracker.StartTime, 'retry reset starttime');
        QA.EQ(tryCount + 1, tracker.TryCount, 'cound incremented');
        QA.EQ(ApexJobTracker.TrackerOperation.Delete_Job, tracker.Operation, 'operation:delete job');
    }

    static String getTestResponse() {
        List<Integer> r = new List<Integer>();
        for(Integer i=0; i < 131090; i++){
            r.add(i);
        }
        return String.join(r, ',');
    }

    @isTest
    static void itShouldEndProperly() {
        //GIVEN
        Project__c p = TestProject.getProjects()[0];
        Job__c j = TestProject.getJobs(p.Id)[0];
        String message = getTestResponse();

        ApexJobTracker tracker = ApexJobTracker.create(p.Id, 
            ApexJobTracker.TrackerTarget.Job,
            ApexJobTracker.TrackerOperation.Import_Jobs);
        tracker.setId1('id1')
            .setId2('id2')
            .setId3('id3')
            .setClassName('AppClassTestFake')
            .setStatus(ApexJobTracker.TrackerStatus.Initial)
            .setParameters('parameters')
            .save();

        //WHEN
        test.startTest();
        tracker = ApexJobTracker.getById(tracker.TrackerId);
        tracker.setResponse(message)
            .end();
        test.stopTest();

        //THEN
        tracker = ApexJobTracker.getById(tracker.TrackerId);
        QA.isTrue(tracker.EndTime != null, 'endtime set');
        QA.EQ(1, tracker.TryCount, 'cound = 1');
        String expectedResponse = message.substring(0, 131072);
        QA.EQ(expectedResponse, tracker.Response, 'response truncated properly.');
    }

    @isTest
    static void itShouldInsertEvenIfParentIdIsNotProjectId() {
        //GIVEN
        Project__c p = TestProject.getProjects()[0];
        Job__c j = TestProject.getJobs(p.Id)[0];

        ApexJobTracker tracker = ApexJobTracker.create(j.Id, 
            ApexJobTracker.TrackerTarget.Job,
            ApexJobTracker.TrackerOperation.Import_Jobs);
        tracker.setId1('id1')
            .setId2('id2')
            .setId3('id3')
            .setClassName('AppClassTestFake')
            .setStatus(ApexJobTracker.TrackerStatus.Initial)
            .setParameters('parameters')
            .save();

        //WHEN
        test.startTest();
        tracker = ApexJobTracker.getById(tracker.TrackerId);
        tracker.setResponse('ok')
            .setStatus(ApexJobTracker.TrackerStatus.Success)
            .end();
        test.stopTest();

        //THEN
        QA.isTrue(tracker.EndTime != null, 'endtime set');
        QA.EQ(1, tracker.TryCount, 'cound = 1');
        QA.EQ(j.Id, tracker.ParentId, 'parent is is job id');
        QA.isTrue(ApexJobTracker.isCompleted(j.Id,ApexJobTracker.TrackerTarget.Job,
            ApexJobTracker.TrackerOperation.Import_Jobs), 'tracker should be done');
    }
}