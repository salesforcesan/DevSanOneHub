@isTest
public class cdlinkTriggerHandlerTest {
    @testSetup static void setup(){
        TriggerUtil.skipAllTriggers();
        TestDataUtil.init();
        TestProject.create('demo').addAll();
    }
    @isTest
    public static void test_ItShouldInsertProjectProperly(){
     Account testAcct = new Account (Name = 'My Test Account');
     insert testAcct;

    // Creates first opportunity
    Opportunity oppt = new Opportunity(Name ='New mAWS Deal',
                            AccountID = testAcct.ID,
                            StageName = 'Customer Won',
                            Amount = 3000,
                            CloseDate = System.today()
                            
                            );

   insert oppt;
      
        ContentVersion contentVersion = new ContentVersion(
            Title = 'test',
            PathOnClient = 'test.jpg',
            VersionData = Blob.valueOf('data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAwAAAAFCAYAAABxeg0vAAAABHNCSVQICAgIfAhkiAAAAAlwSFlzAAAECwAABAsBkBCzYwAAABl0RVh0U29mdHdhcmUAd3d3Lmlua3NjYXBlLm9yZ5vuPBoAAACDSURBVAiZRc47DoFRGITh5z+dIy6JS0PzW4CKqFVahdJKJBpWINHahBWoaFUapUgoFHag+RJTzbyZTKbAAlNUscYKFWSccMQBZ3wKPDDCDGPU8UYDd5R4YYteQj/KGR1/3TBBDd9gzxTmijYukTNacW2PJebYwAAJu1jrBiuDQxNDpB+UHxLwweUDkAAAAABJRU5ErkJggg=='),
            IsMajorVersion = true
        );
        insert contentVersion;   
        List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];
        //create ContentDocumentLink  record 
        Project__c p = TestProject.getProjects()[0];
       // p.Opportunity__c =oppt.Id;
        update p;
        ContentDocumentLink cdl = New ContentDocumentLink();
        cdl.LinkedEntityId = oppt.Id;
        cdl.ContentDocumentId = documents[0].Id;
        cdl.shareType = 'V';
        insert cdl;
        
        
        
    }

}