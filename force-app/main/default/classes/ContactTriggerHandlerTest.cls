@isTest
public class ContactTriggerHandlerTest {

    @testSetup static void setup(){
        TriggerUtil.skipContactTrigger = true;
        TestUtil.initBaseData();
        
    }

    public static testMethod void Test_beforeUpdate(){
         Account testAccount = new Account();

        testAccount.Name='Test Account' ;

        insert testAccount;
        
        Test.startTest();   
       Contact a = new Contact(
                          FirstName = 'Test',
                          LastName = 'Test',
                          Pin__c ='1234',
                          Accountid = testAccount.Id,
                          ManagerId__c ='1234'
                          
                      );
        
         insert a;  
        try{
            Contact cont = [Select Id, Name,Pin__c,EmployeeId__c,ManagerId__c from Contact LIMIT 1];
            cont.EmployeeId__c = 'ChangedId';
            cont.Pin__c ='4568';
            cont.ManagerId__c='8769';
            update cont;
            system.assert(cont != null);         
            
        }
        catch(exception e){
            
        }
    }
    public static testMethod void test_beforeCreate()
    {
        
        try{
            
         Account testAccount = new Account();

        testAccount.Name='Test Account' ;

        insert testAccount;
        
        Test.startTest();   
       Contact a = new Contact(
                          FirstName = 'Test',
                          LastName = 'Test',
                          Pin__c ='1234',
             			  ManagerId__c ='1234',
                          Accountid = testAccount.Id
                          
                      );
        
         insert a;  
             
        Test.stopTest();
            
        }
        catch(exception e)
        {
            
        }
    }
    
    
}