@isTest
public class PDFTemplateControllerExtTest {

    @TestSetup
    static void setup(){
        Project__c project = TestUtil.generateFullTestProject(ProjectType.MD, Date.today().addDays(10), Date.today().addDays(20));
    }

    static Project__c getProject(){
        return [SELECT Id, Name, Status__c, StartDate__c, EndDate__c, ApprovalDate__c, ProjectType__c,
            ProjectScheduleOption__c, Retailer__c, UpdateSequence__c, BudgetedLocationsCount__c from Project__c LIMIT 1];
    }
    
    public static testMethod void test_PDFTemplateControllerExt_Job(){
        //Project__c project = getProject();
        
        //ProjectService__c ps = [SELECT Id, Service__c FROM ProjectService__c WHERE Project__c = :project.Id LIMIT 1];
        //ProjectLocation__c pl = [SELECT Id FROM ProjectLocation__c LIMIT 1];

        //List<Target__c> coll =[select Id from Target__c];
        
        //ProjectServiceTarget__C pscObj = new ProjectServiceTarget__C ();
        //pscObj.ProjectService__c = ps.id;
        //pscObj.Target__c = coll[0].id;
        //pscObj.Type__c = 'Halo';
        //pscObj.Quantity__c = 0;
        //pscObj.Price__c = 0;
        //pscObj.YieldPerUnit__C=0;
        //insert pscObj;
        
        //ProjectServiceTarget__C pscObj2 = new ProjectServiceTarget__C ();
        //pscObj2.ProjectService__c = ps.id;
        //pscObj2.Target__c = coll[1].id;
        //pscObj2.Type__c = 'Backup';
        //pscObj2.Quantity__c = 0;
        //pscObj2.Price__c = 0;
        //pscObj2.YieldPerUnit__C=0;
        //insert pscObj2;
        
        
        //List<Attribute__c> attributes = [Select Id, Name, AttributeType__c from Attribute__c];
        //List<ProjectServiceAttribute__c> pscaList = new List<ProjectServiceAttribute__c>();
        //for(Attribute__c attr : attributes){
        //    ProjectServiceAttribute__c psca = new ProjectServiceAttribute__c();
        //    psca.Attribute__c = attr.id;
        //    psca.AttributeValue__c   = '123';
            
        //    psca.ProjectService__c =ps.id;
        //    psca.Service__c= ps.Service__c;
        //    pscaList.add(psca);
            
        //    ProjectServiceAttribute__c psca2 = new ProjectServiceAttribute__c();
        //    psca2.Attribute__c = attr.id;
        //    psca2.AttributeValue__c   = '123';
   
        //    psca2.ProjectService__c =ps.id;
        //    psca2.Service__c= ps.Service__c;
        //    pscaList.add(psca2);
            
        //}
        //insert pscaList;

        //Job__c  job = TestUtil.generateJobs(project.Id, pl.Id, ps.Id);
        //TestUtil.generateJobAttempt(job, job.JobStatus__c);
        
        //Test.startTest();
        //PageReference pageRef = Page.ProjectDetailsView;
        //pageRef.getParameters().put('jobId', job.Id);
        //pageRef.getParameters().put('psId', ps.Id);
        //Test.setCurrentPage(pageRef);
        //ApexPages.StandardController sc = new ApexPages.standardController(ps);
        //PDFTemplateControllerExt ctrl = new PDFTemplateControllerExt(sc);
        //Boolean result = ctrl.initData();
        //Test.stopTest();

        //System.assertEquals(true, result);
        
    }
    
    public static testMethod void test_PDFTemplateControllerExtPreview_ps(){
       
       //TriggerUtil.skipAllTriggers();
       //Project__c project = getProject();
        
       // ProjectService__c ps = [SELECT Id FROM ProjectService__c WHERE Project__c = :project.Id LIMIT 1];
       // List<Target__c> coll =[select id,stockcode__c from Target__c];
        
       // ProjectServiceTarget__C pscObj = new ProjectServiceTarget__C ();
       // pscObj.ProjectService__c = ps.id;
       // pscObj.Target__c = coll[0].id;
       // pscObj.Type__c = 'Halo';
       // pscObj.Quantity__c = 0;
       // pscObj.Price__c = 0;
       // pscObj.YieldPerUnit__C=0;
       // insert pscObj;
        
       // ProjectServiceTarget__C pscObj2 = new ProjectServiceTarget__C ();
       // pscObj2.ProjectService__c = ps.id;
       // pscObj2.Target__c = coll[1].id;
       // pscObj2.Type__c = 'Backup';
       // pscObj2.Quantity__c = 0;
       // pscObj2.Price__c = 0;
       // pscObj2.YieldPerUnit__C=0;
       // insert pscObj2;
        
       // Test.startTest();
       // PageReference pageRef = Page.ProjectDetailsView;
       // pageRef.getParameters().put('psId', ps.Id);
       // Test.setCurrentPage(pageRef);
       // ApexPages.StandardController sc = new ApexPages.standardController(ps);
       // PDFTemplateControllerExt ctrl = new PDFTemplateControllerExt(sc);
       // Boolean result= ctrl.initData();
       // Test.stopTest();

       // System.assertEquals(true, ctrl.initData());
        
    }
}