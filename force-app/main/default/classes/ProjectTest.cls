@isTest
public class ProjectTest
{
  
  
  public static testMethod void test_DeleteAllLocations()
  {
      //call oppty
      list<opportunity> ops = TestUtil.generateOpportunities(2);
          
      Project__c prj = TestUtil.generateFullTestProject(ProjectType.MD, Date.today().addDays(10), Date.today().addDays(20));  
      List<ProjectLocation__c> pls = [Select Id from ProjectLocation__c where Project__c = :prj.Id LIMIT 1];
      List<ProjectService__c> pss = [Select Id from ProjectService__c where Project__c = :prj.Id LIMIT 1];
      Job__c job = TestUtil.generateJobs(prj.Id, pls[0].Id, pss[0].Id);

      pls = [Select Id, Name from ProjectLocation__c where Project__c = :prj.Id] ;
      List<Job__c> jobs = [Select Id, Name from Job__c where Project__c = :prj.Id] ;

      System.assert(pls.size() != 0);
      System.assert(jobs.size() != 0);
      
      
      Project.DeleteAllLocations(String.ValueOf(prj.Id));

      pls = [Select Id, Name from ProjectLocation__c where Project__c = :prj.Id] ;
      jobs = [Select Id, Name from Job__c where Project__c = :prj.Id] ;
      
      System.assertEquals(pls.size(), 0);
      System.assertEquals(jobs.size(), 0);
	
  }
}