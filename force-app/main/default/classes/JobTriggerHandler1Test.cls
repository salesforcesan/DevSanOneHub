@isTest
private class JobTriggerHandler1Test
{
    @testSetup
    static void setup(){
        TriggerUtil.skipAllTriggers();

        Date dtStart = datetime.now().date();
        Date dtEnd = datetime.now().addDays(10).date();
        TestDataUtil.init();
        TestProject tP = TestProject.create('demo', dtStart, dtEnd);
        tP.addAccount()
        .addService()
        .addLocations(2)
        .addJobs()
        .addJobAttempts('');
    }

    @isTest
    static void itShouldNotUpdateJobScheduledDateIfLessThanProjectStartDate()
    {
        // Given
        Date dtSchedule = datetime.now().addDays(-1).date();
        Project__c p = [SELECT Id from Project__c limit 1];
        List<Job__c> jobs = TestProject.getJobs(p.Id);
        for(Job__c job: jobs){
            job.JobScheduledDate__c = dtSchedule;
        }

        String err = '';
        // When
        test.startTest();
        try{
            update jobs;            
        }
        catch (DmlException dml){
            err = dml.getMessage();
        }
        test.stopTest();

        // Then
        QA.isTrue(err.length() > 0, 'should not set schedule date');
    }

    @isTest
    static void itShouldSetJobScheduledDateIfLaterThanProjectStartDate()
    {
        // Given
        Date dtSchedule = datetime.now().addDays(5).date();
        Project__c p = [SELECT Id from Project__c limit 1];
        List<Job__c> jobs = TestProject.getJobs(p.Id);
        for(Job__c job: jobs){
            job.JobScheduledDate__c = dtSchedule;
        }

        // When
        test.startTest();
        update jobs;
        test.stopTest();

        // Then
        jobs = TestProject.getJobs(p.Id);
        QA.EQ(2, jobs.size(), '2 jobs created.');
        QA.EQ(dtSchedule, jobs[0].JobScheduledDate__c, 'scheduled date should be set');
        QA.EQ(dtSchedule, jobs[1].JobScheduledDate__c, 'scheduled date should be set');
    }
}