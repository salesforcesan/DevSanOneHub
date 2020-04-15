@isTest
public class ProjectLocationTriggerHandlerTest {
     static void triggersOff(){
        TriggerUtil.skipAllTriggers();

    }
    @testSetup
    static void init(){
        triggersOff();
        TestDataUtil.init();
               
    }
  
    public static testMethod void Test_beforeUpdate(){
        try{
            system.debug(' @@@ '+ userinfo.getname());
            Project__c project = TestUtil.generateProjectwithJobs(ProjectType.MD, System.today().addDays(60), System.today().addDays(70));
            project.Status__c = 'In Progress';
            update project;
            list<projectlocation__c> pllist = [SELECT Id, Status__c, SurveyPhotoViewerEncodedId__c FROM ProjectLocation__c WHERE Project__c = :project.Id];
            integer oldcount = pllist.size();
            system.assert(pllist[0].SurveyPhotoViewerEncodedId__c != null);  
            system.debug('~~~~  pllist.size() ~~~~'+pllist.size());
            pllist[0].Status__c = 'Booked';
            update pllist;
            system.debug('~~~~  pllist.size() ~~~~'+pllist.size());
            system.assertNotEquals(pllist.size(),0);
        }
        catch(exception e){
            System.Assert(e.getMessage().contains('FIELD_CUSTOM_VALIDATION_EXCEPTION'));
        }
    }
    
    public static testMethod void Test_afterUpdate(){
            try{
            system.debug(' @@@ '+ userinfo.getname());
            Project__c project = TestUtil.generateFullTestProject(ProjectType.MD, System.today().addDays(60), System.today().addDays(70));
            project.Status__c = 'In Progress';
            update project;
            list<projectlocation__c> pllist = [SELECT Id, Status__c,LocationScheduledDate__c FROM ProjectLocation__c WHERE Project__c = :project.Id];
            pllist[0].LocationScheduledDate__c = Date.today();
            update pllist;
            integer oldcount = pllist.size();
           
        }
        catch(exception e){
            System.Assert(e.getMessage().contains('FIELD_CUSTOM_VALIDATION_EXCEPTION'));
        }
        
    }

    public static testMethod void Test_beforeDelete(){
        try{
            system.debug(' @@@ '+ userinfo.getname());
            Project__c project = TestUtil.generateFullTestProject(ProjectType.MD, System.today().addDays(60), System.today().addDays(70));
            project.Status__c = 'In Progress';
            update project;
            list<projectlocation__c> pllist = [SELECT Id, Status__c FROM ProjectLocation__c WHERE Project__c = :project.Id];
            integer oldcount = pllist.size();
            system.debug('~~~~  pllist.size() ~~~~'+pllist.size());
            delete pllist;
            system.debug('~~~~  pllist.size() ~~~~'+pllist.size());
            system.assertNotEquals(pllist.size(),0);
        }
        catch(exception e){
            System.Assert(e.getMessage().contains('FIELD_CUSTOM_VALIDATION_EXCEPTION'));
        }
          
    }    
    

}