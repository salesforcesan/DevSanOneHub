@isTest
private class ProjectSubmitRequestModelTest
{
    @testSetup
    static void setup() {
        TriggerUtil.skipAllTriggers();
        TestDataUtil.init();
        Date startDate = (Datetime.now()).addDays(10).date();
        Date endDate = (Datetime.now()).addDays(20).date();
        TestProject tP = TestProject.create('demo',startDate, endDate)
            .addAllWithoutJobAttempts();
        tP.TestProjectServiceList[0].addAll();
    }
    
	@isTest
	static void itShouldGetProjectWithoutError()
	{
		// Given
        Project__c p = TestProject.getProjects()[0];
        ProjectSubmitRequestModel model = new ProjectSubmitRequestModel();
        Map<String,Object> parameters = new Map<String,Object>();
        parameters.put('projectId', p.Id);

		// When
        test.startTest();
        Map<String,Object> result = (Map<String,Object>) model.get(parameters);
        test.stopTest();

		// Then
        QA.EQ(CONSTANTS.STATUS_WARN, result.get('status'), JSON.serialize(result));
	}

    @isTest
    static void itShouldSubmitProjectWithoutError()
    {
        // Given
        Project__c p = TestProject.getProjects()[0];
        ProjectSubmitRequestModel model = new ProjectSubmitRequestModel();
        Map<String,Object> parameters = new Map<String,Object>();
        parameters.put('projectId', p.Id);

        // When
        test.startTest();
        Map<String,Object> result = (Map<String,Object>) model.modify(parameters);
        test.stopTest();

        // Then
        p = TestProject.getProjects()[0];
        QA.EQ(CONSTANTS.STATUS_WARN, result.get('status'), JSON.serialize(result));
        QA.EQ(CONSTANTS.PROJECT_STATUS_BOOKED, p.Status__c, 'project booked.');
    }
}