@isTest
public class EventChangeNotificationTest {
    
    @isTest 
    static void testValidEventChangeNotification_JobStarted() {
        
        // Create a test event instance
        EventChangeNotification__e en = new EventChangeNotification__e(EventType__c='JobStarted', 
                                             EntityType__c='Job', 
                                             EntityId__c='JOB-0123456');
        
        Test.startTest();
        
        // Publish test event
        Database.SaveResult sr = EventBus.publish(en);
        
        Test.stopTest();
        
        // Verify SaveResult value
        System.assertEquals(true, sr.isSuccess());
        
        //Check if the corresponding job attempt changed the status and DateStarted
        
    }
}