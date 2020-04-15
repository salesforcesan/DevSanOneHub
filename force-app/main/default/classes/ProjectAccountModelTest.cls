@isTest
private class ProjectAccountModelTest
{
    static void offTrigger(){
        TriggerUtil.skipAllTriggers();
    }

    @testSetup
    static void setup(){
        offTrigger();
        TestDataUtil.init();
        TestProject.create('demo')
            .addAccounts(2);
    }

    @isTest
    static void itShouldGetRightAccounts()
    {
    	// Given
        offTrigger();
        String pId = TestProject.getProjects().get(0).Id;
        List<ProjectAccount__c> accounts = TestProject.getAccounts(pId);
        ProjectAccount__c primaryAccount = accounts.get(0);
        primaryAccount.IsPrimary__c = true;
        update primaryAccount;

    	// When
        Test.startTest();
        offTrigger();
        ProjectAccountModel model = ProjectAccountModel.create(pId);
        List<Map<String,Object>> result = model.getList();
        Test.stopTest();

    	// Then
        QA.EQ(accounts.size(), result.size(), 'same number of accounts');
        QA.EQ(true, Boolean.valueOf(result.get(0).get('isPrimary')), '1st is true');
    }
}