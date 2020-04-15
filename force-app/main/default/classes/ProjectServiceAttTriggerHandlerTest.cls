@isTest
public class ProjectServiceAttTriggerHandlerTest {
    static testMethod void test_beforeInsert() {
        Project__c project = TestUtil.generateFullTestProject(ProjectType.MD, Date.Today().AddDays(10), Date.Today().AddDays(60)) ;
    }
    
    static testMethod void test_beforeUpdate() {
        Project__c project = TestUtil.generateFullTestProject(ProjectType.MD, Date.Today().AddDays(10), Date.Today().AddDays(60)) ;
        ProjectServiceAttribute__c psca = [select  AttributeValue__c from ProjectServiceAttribute__c LIMIT 1];
        psca.AttributeValue__c = 'Test';
        update psca;
        psca = [select  AttributeValue__c from ProjectServiceAttribute__c LIMIT 1];
        system.assertEquals(psca.AttributeValue__c, 'Test');
    }
    
}