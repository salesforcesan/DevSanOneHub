@isTest
public class OpportunityTriggerHandlerTest {

    @testSetup static void setup(){
        TriggerUtil.skipAllTriggers();
        Account acct = setupAccount();
        setupAccountBudgets(acct);
    }   

    static Account setupAccount() {
        Account acct = new Account (
                name = '7up'
            );
        insert acct;
        return acct;
    } 

    static void setupAccountBudgets(Account acct) {
        List<AccountBudget__c> budgets = new List<AccountBudget__c>();

        AccountBudget__c ab = new AccountBudget__c();
        ab.Name = 'budget=500';        
        ab.Account__c = acct.Id;        
        ab.PlannedAgainstBudget__c = 500;
        ab.Amount__c = 500;
        ab.BudgetType__c = 'Annual';
        ab.PeriodStartDate__c = Date.today();
        ab.PeriodEndDate__c = Date.today().addDays(10);       
        ab.SubCategory__c = 'test'; 
        budgets.add(ab);
        
        AccountBudget__c ab2 = new AccountBudget__c();
        ab2.Name = 'budget=null';
        ab2.Account__c = acct.Id;
        ab2.Amount__c = 500;
        ab2.BudgetType__c = 'Annual';
        ab2.PeriodStartDate__c = Date.today();
        ab2.PeriodEndDate__c = Date.today().addDays(10);
        ab2.SubCategory__c = 'test1'; 
        budgets.add(ab2);

        insert budgets;
    }

    @isTest static void itShouldNotThrowExceptionIfOpprAmountEqualTo0() {
        //GIVEN  
        Account acct = [select id from account limit 1];
        AccountBudget__c ab = [SELECT Id, PlannedAgainstBudget__c from AccountBudget__c where PlannedAgainstBudget__c = 500];

        Opportunity opp = new Opportunity();
        opp.AccountId = acct.Id;
        opp.Name = 'test opp 1';
        opp.StageName = 'Prospecting';      
        opp.CloseDate  = (Datetime.now()).date().addDays(20);  
        
        //WHEN                                        
        test.startTest();
        opp.AccountBudget__c = ab.Id;         
        insert opp;
                      
        //THEN
        List<AccountBudget__c> abList = [Select PlannedAgainstBudget__c from AccountBudget__c where id = : ab.Id];
        System.assertEquals(true, abList[0].PlannedAgainstBudget__c == 500);
    }
    
    @isTest
    public static void itShouldUpdateAccountBudgetPlanAgainstBudgetAmount(){
        
        //GIVEN  
        Account acct = [select id from account limit 1];
        AccountBudget__c ab = [SELECT Id, PlannedAgainstBudget__c from AccountBudget__c where PlannedAgainstBudget__c = 500];

        Opportunity opp = new Opportunity();
        opp.AccountId = acct.Id;
        opp.Amount = 300;
        opp.Name = 'test opp 1';
        opp.StageName = 'Prospecting';      
        opp.CloseDate  = (Datetime.now()).date().addDays(20);  
        
        //WHEN                                        
        test.startTest();
        opp.AccountBudget__c = ab.Id;         
        insert opp;
                      
        //THEN
        List<AccountBudget__c> abList = [Select PlannedAgainstBudget__c from AccountBudget__c where id = : ab.Id];
        System.assertEquals(true, abList[0].PlannedAgainstBudget__c == 800);
    }
}