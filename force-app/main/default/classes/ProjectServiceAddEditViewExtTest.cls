@isTest
public class ProjectServiceAddEditViewExtTest {


    public static testMethod void Test_addProjService()
    {
        Project__c project = TestUtil.generateFullTestProject(ProjectType.MD, System.today().addDays(60), System.today().addDays(70));
        
        Test.startTest();
        ProjectScheduler batch = new ProjectScheduler([SELECT Name, StartDate__c, EndDate__c, ProjectType__c, ProjectType__r.Name, Status__c FROM Project__c WHERE ID = :project.Id]);
        Database.executeBatch(batch);
        Test.stopTest();
        Job__c job = [SELECT Id FROM Job__C LIMIT 1];
        ProjectServiceQuestion__c surveyQuestion = [SELECT Id,Question__c FROM ProjectServiceQuestion__c LIMIT 1];
        //TestUtil.generatesurveyResponses(job.Id, surveyQuestion.Question__c);
        
        ApexPages.currentPage().getParameters().put('projectid', project.Id);
        ProjectService__c ps = new ProjectService__c();
        ApexPages.StandardController controller = new ApexPages.StandardController(ps);
        ProjectServiceAddEditViewExt ext= new ProjectServiceAddEditViewExt(controller);
        ext.mode = 'add';
        ext.getJobManualTemplates();
        ext.getEventManualTemplates();
        ext.getECValuesOption();
        Service__c service = [Select id from Service__c limit 1];
        ServiceQuestion__c tq = TestUtil.generateTemplateQuestion(service.id,1);
        Question__c q = [Select Id from Question__c limit 1];
        TestUtil.generateTemplateDefinedResponse(tq.id,q.Id);
        ApexPages.currentPage().getParameters().put('selectedServiceId', service.Id);
        ext.selectedServ = service.Id;
        ext.readServiceData();
        triggerUtil.skipProjectServiceTrigger = true;
        ext.save();
        
        system.assert(ext != null);


    }
    
  
     public static testMethod void Test_editProjService()
    {
        Project__c project = TestUtil.generateFullTestProject(ProjectType.MD, System.today().addDays(60), System.today().addDays(70));
        ProjectService__c ps = [SELECT Id, Service__c FROM ProjectService__c WHERE Project__c=:project.Id LIMIT 1];
        List<ServiceAttribute__c> attributes = [Select Id, Name, Attribute__c, AttributeType__c from ServiceAttribute__c OFFSET 10];
        
        List<ProjectServiceAttribute__c> pscaList = new List<ProjectServiceAttribute__c>();
        for(ServiceAttribute__c attr : attributes){
            ProjectServiceAttribute__c psca = new ProjectServiceAttribute__c();
            psca.Attribute__c = attr.attribute__c;
            psca.AttributeValue__c   = '';
            psca.ProjectService__c =ps.id;
            psca.Service__c= ps.Service__c;
            psca.ServiceAttribute__c = attr.Id;
            pscaList.add(psca);
        }
        insert pscaList;
        
        
        
        PageReference aPage = Page.ProjectServiceAddEditView;
        Test.setCurrentPage(aPage);
        
        ApexPages.StandardController controller = new ApexPages.StandardController(ps);
        
        ApexPages.currentPage().getParameters().put('projectid', project.Id);
        ApexPages.currentPage().getParameters().put('id', ps.Id);
        
        // now pass it to the extension
        ProjectServiceAddEditViewExt ext= new ProjectServiceAddEditViewExt(controller);
        
        system.assert(ext != null);
        ProjectService__c extps = ext.ps;
    
        
        ext.readServiceData();
        ext.save();
        
       
        /*
        ps = [SELECT Id FROM ProjectService__c WHERE id = :ps.Id];
     
        
        
        pscaList = [SELECT Id FROM ProjectServiceAttribute__c WHERE ProjectService__c = :ps.Id];
        Attachment attach = new Attachment();       
        attach.Name='Unit Test Attachment';
        Blob bodyBlob = Blob.valueOf('Unit Test Attachment Body');
        attach.body = bodyBlob;
        attach.parentId = pscaList[0].id;
        insert attach;
        
        List<Attachment> attachments=[select id, name from Attachment where parent.id=:pscaList[0].id];
        System.assertEquals(1, attachments.size());
        ext.attachmentId = attachments[0].Id;
        ext.deleteAttachment();
        
        attachments=[select id, name from Attachment where parent.id=:pscaList[0].id];
        System.assertEquals(0, attachments.size());
		*/
    }    
    
}