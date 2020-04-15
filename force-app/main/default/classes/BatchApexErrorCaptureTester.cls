@isTest
global class BatchApexErrorCaptureTester implements Database.Batchable<sObject>, 
Database.RaisesPlatformEvents{
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator([Select Id, name from Account limit 10]);
    }
    
    global void execute(Database.BatchableContext BC, List<Account> scope) {
        
        if(Test.isRunningTest()){
            
            Database.insertImmediate(new BatchApexErrorEvent(AsyncApexJobId = '7071100001jAsSIAA0'));
         
        }
    }
    
    global void finish(Database.BatchableContext BC) {
    }
    
    static testMethod void testBatchApexErrorEvent() {
        
        try{
            insert new Account(Name = 'Test Account');
            Test.startTest();
            BatchApexErrorCaptureTester tb = new BatchApexErrorCaptureTester();
            Database.executeBatch(tb); 
            //Test.getEventBus().deliver();
            Test.stopTest();
        } catch(Exception e){
            
        }
        Test.getEventBus().deliver(); 
        //System.assertEquals(1, [SELECT Id FROM AppLog__c].size());
    }
    
    
}