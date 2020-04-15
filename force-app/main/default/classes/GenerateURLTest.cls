@isTest
public class GenerateURLTest {

    public static testMethod void Method_Test(){
        Project__c project = TestUtil.generateFullTestProject(ProjectType.MD, System.today().addDays(60), System.today().addDays(70));    
        projectservice__c ps = [select id from projectservice__c where project__c = : project.id limit 1];
        ProjectServiceAttribute__c psca = [select id from ProjectServiceAttribute__c limit 1];
        //Attachment attmnt = [Select ID, ParentID, body, Name from Attachment limit 1];
        //system.debug('~~~~'+attmnt.id);
        //Test.startTest();
        for(Attachment attmnt : [Select ID, ParentID, body, Name from Attachment])
        {
            GenerateURL.GenerateNewURL(psca.ID, attmnt.id);
            //GenerateURL.UpdateURL('https://api.crossmark.com/ImageService/test', attmnt.id);    
        }
        //Test.stopTest();         
    }  
    public static testMethod void Method_Test2(){
        Project__c project = TestUtil.generateFullTestProject(ProjectType.MD, System.today().addDays(60), System.today().addDays(70));    
        projectservice__c ps = [select id from projectservice__c where project__c = : project.id limit 1];
        ProjectServiceAttribute__c psca = [select id from ProjectServiceAttribute__c limit 1];
        //Attachment attmnt = [Select ID, ParentID, body, Name from Attachment limit 1];
        //system.debug('~~~~'+attmnt.id);
        //Test.startTest();
        for(Attachment attmnt : [Select ID, ParentID, body, Name from Attachment])
        {
            //GenerateURL.GetURL(psca.ID, attmnt.id);
            //GenerateURL.UpdateURL('https://api.crossmark.com/ImageService/test', attmnt.id);    
        }
        //Test.stopTest();         
    }    
    
}