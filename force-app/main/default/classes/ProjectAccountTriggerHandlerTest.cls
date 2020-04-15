@isTest
public class ProjectAccountTriggerHandlerTest {
    static void triggersOff(){
        TriggerUtil.skipProjectAccountTrigger = true;
    }
    static void triggerOn(){
        TriggerUtil.skipProjectAccountTrigger = false;
    }

    @testSetup
    static void init(){
        triggersOff();
        TestDataUtil.init();     
    }
    
    @isTest
    static void itShouldUpdatePrimaryAccount(){
        //Given
      //  Integer expCount = 1;
        String expName = 'demo';
        TestProject testP = TestProject.create(expName);
       //When
        Test.startTest();
        //testP.addAccounts(1);
        testP.addAccount();
        Test.stopTest();
        project__c result =TestProject.getProjects()[0];
        List<ProjectAccount__c> accounts = TestProject.getAccounts(result.Id);   
       // projectAccount__c pa =  TestUtil.getPrimaryAccount(result.Id);
        //System.assertEquals(accounts[0].Id,pa.Id, 'not primary blank');
        system.assertEquals(result.PrimaryAccount__c,accounts[0].Id);
       
    }
    
    @isTest
    static void itShouldProjectPrimaryAccountFieldWhenSelectProjectPrimaryAccunt(){
        //given
        TestProject.create('demo')
            .addAccounts(2);
        Project__c p = TestProject.getProjects()[0];
        List<ProjectAccount__c> acctList = TestProject.getAccounts(p.Id);
        QA.EQ(2, acctList.size(), '2 accounts created.');
        QA.EQ(p.PrimaryAccount__c, acctList[0].Id, 'current primary account id matched.');

        //when
        test.startTest();
        Boolean isPrimary = true;
        List<ProjectAccount__c> aL = new List<ProjectAccount__c>();
        for(ProjectAccount__c a: acctList) {
            aL.add(new ProjectAccount__c(
                    Id = a.Id,
                    IsPrimary__c = !isPrimary
                ));
            isPrimary =false;
        }
        update aL;
        test.stopTest();

        //then
        p = TestProject.getProjects()[0];
        QA.EQ(p.PrimaryAccount__c, acctList[1].Id, 'matech to 2nd account.');
    }
    
    
}