@isTest
public class DevUtilTest {
    public static testMethod void test_deleteProject() {
        List<Project__c> projects = new List<Project__c>();
        Project__c project = TestUtil.generateFullTestProject(ProjectType.MD, Date.today(),Date.today().addDays(2)); 
        DevUtil.deleteProject(project.id);
        projects = [SELECT Id From Project__c where id = :project.id];
        system.assert(projects.size() == 0);
    }

    public static testMethod void test_updateProjectReserved() {
        List<Project__c> projects = new List<Project__c>();
        Project__c project = TestUtil.generateFullTestProject(ProjectType.MD, Date.today(),Date.today().addDays(2)); 
        DevUtil.UpdateProjectStatus(project.id,'reserved');
        project = [SELECT status__c From Project__c where id = :project.id];
        system.assert(project.status__c != 'reserved');
    }

    public static testMethod void test_updateProject() {
        List<Project__c> projects = new List<Project__c>();
        Project__c project = TestUtil.generateFullTestProject(ProjectType.MD, Date.today(),Date.today().addDays(2)); 
        DevUtil.UpdateProjectStatus(project.id,'open');
        project = [SELECT status__c From Project__c where id = :project.id];
        system.assert(project.status__c == 'open');
    }
    
    public static testMethod void test_deleteProjects() {
        List<Project__c> projects = new List<Project__c>();
        Project__c project = TestUtil.generateFullTestProject(ProjectType.MD, Date.today(),Date.today().addDays(2)); 
        projects.add(project);
        DevUtil.deleteProjects(projects);
        projects = [SELECT Id From Project__c where id = :project.id];
        system.assert(projects.size() == 0);
    }    
}