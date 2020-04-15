@isTest
public class ProjectServiceTargetTriggerTest {
    
    
 	static testMethod void test_afterUpdate() {
        Project__c project = TestUtil.generateFullTestProject(ProjectType.MD, System.today().addDays(60), System.today().addDays(70));
        
        ProjectService__c ps = [SELECT PurchaseAmount__c FROM ProjectService__c WHERE Project__c=:project.Id LIMIT 1];
        
        ProjectServiceTarget__c psc = [SELECT Id, Quantity__c, Price__c, YieldPerUnit__c FROM ProjectServiceTarget__c WHERE ProjectService__c =: ps.Id LIMIT 1];
        psc.Quantity__c = 10;
        psc.Price__c = 10;
        TriggerUtil.skipProjectServiceTargetTrigger = false;
        update psc;
        
        ps = [SELECT PurchaseAmount__c FROM ProjectService__c WHERE Project__c=:project.Id LIMIT 1];
        System.assertEquals(ps.PurchaseAmount__c, 100 * 1.15);
    	
    }
    
        
}