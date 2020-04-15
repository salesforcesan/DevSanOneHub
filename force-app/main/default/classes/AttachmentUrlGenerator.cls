/*
* this API is used to call APEX PageReference to generate PDF content 
* and send to image service for attachment
*/
@RestResource(urlMapping='/generateAttachmentUrl/*')
global without sharing class AttachmentUrlGenerator {
    
    @HttpGet
    global static void generateUrl() {
        RestResponse res = RestContext.response;
        try{
            String projectId = parseProjectId();
            generateJobManualFutureCall(projectId);
            res.statusCode = 201;
            
        } catch(Exception ex) {
            res.statusCode = 500;
            system.debug(ex);
            res.responseBody = Blob.valueof(ex.getMessage());
        }
    }
    
    
    public static void generateJobManualFutureCall(string projectId)
    {
        TriggerUtil.SkipProjectTrigger = true;
	 Integer maxservices = getMaxServicesForManualGeneration();                
                
        list<projectservice__c> projectservices = [select id, JobManual__c from projectservice__c where project__C=:projectId];            
        if (projectservices.size() <= maxservices)            
        {
            for(projectservice__c ps : projectservices)
            {
                if(ps.JobManual__c == CONSTANTS.JOB_MANUAL_STANDARD_TEMPLATE){
                    generateJobManual(ps.Id);    
                }
            }
        }

    }  
    
    
    @future (callout=true)
    public static void generateJobManual(string psId)
    {
        TriggerUtil.SkipAllTriggers();

        projectservice__c ps = [select name,project__c, JobManualURL__c,service__c,IncludeAutoGenManual__c,project__r.ProjectTypeName__c, Project__r.Retailer__c,JobManual__c from projectservice__C where id=: psId];
        Blob pdf = getPdfContent(ps);
       if(ps.IncludeAutoGenManual__c!=false)
        {
          if(ps.JobManualURL__c==null){
                string urlData = callImageServiceToPostAttachment(pdf);
                updateDetails(ps,urlData);    
            }
            else{
                system.debug('  JobManualURL not blank ' +ps.JobManualURL__c);                    
                Integer statusCode =  callImageServiceToPutAttachment(ps.JobManualURL__c,pdf);
                updateDetails(ps,ps.JobManualURL__c);                      
            }
        }
    }
    
    public static void generateJobManualNonFutureCall(string projectId)
    {
        TriggerUtil.SkipProjectTrigger = true;

		Integer maxservices = getMaxServicesForManualGeneration();                
                
        list<projectservice__c> projectservices = [select id,JobManual__c from projectservice__c where project__C=:projectId];            
        if (projectservices.size() <= maxservices)            
        {
            for(projectservice__c ps : projectservices)
            {
                  if(ps.JobManual__c == CONSTANTS.JOB_MANUAL_STANDARD_TEMPLATE){
                     generateJobManualNonFuture(ps.Id); 
                  }
            }
        
        }        
    }    
    
    
    public static void generateJobManualNonFuture(string psId)
    {
        TriggerUtil.SkipProjectTrigger = true; 
        TriggerUtil.SkipProjectServiceTrigger = true;
        TriggerUtil.skipProjectServiceTargetAttributeTrigger = true;
        projectservice__c ps = [select name,project__c, JobManualURL__c,service__c,IncludeAutoGenManual__c,project__r.ProjectTypeName__c, Project__r.Retailer__c,JobManual__c from projectservice__C where id=: psId for update];
        Blob pdf = getPdfContent(ps);
        if(ps.IncludeAutoGenManual__c!=false)
        {
            if(ps.JobManualURL__c==null){
                string urlData = callImageServiceToPostAttachment(pdf);
                updateDetails(ps,urlData);    
            }
            else{
                system.debug('  ps.JobManualURL__c  ' +ps.JobManualURL__c);                    
                Integer statusCode =  callImageServiceToPutAttachment(ps.JobManualURL__c,pdf);
                updateDetails(ps,ps.JobManualURL__c);                      
            }
        }
    }
    
    
    private static string parseProjectId(){
        RestRequest req = RestContext.request;
        return req.requestURI.substring(req.requestURI.lastIndexOf('/') + 1);
    }
    
    private static Blob getPdfContent(ProjectService__c ps) {        
        PageReference reference;        
       if(ps.JobManual__c != null){
            string pdfTemplateUrl = '/apex/' + CONSTANTS.CURRENTNAMESPACEPREFIX + 'pdftemplate?psId='+ps.Id;
            
            reference = New PageReference(pdfTemplateUrl);
            if(Test.isRunningTest())
                return Blob.valueOf(pdfTemplateUrl);
            return reference.getContentAsPDF();
        }   
        
        return  Blob.valueof('Error: Job Manual template may not be configured');
    }
    
    
    public static String callImageServiceToPostAttachment(Blob pdf) {
        try{
        
            ImageServiceSettings__c imgSvc = ImageServiceSettings__c.getValues('ImageService');
            HttpRequest req = new HttpRequest();
            req.setEndpoint(imgSvc.URL__c);  //req.setEndpoint(IMAGE_SERVICE_ENDPOINT);  
            req.setMethod('POST');
            String userName =  imgSvc.UserName__c; //'external\\m3.testing';
            String password =  imgSvc.Password__c; //'Password1';
            system.debug(userName +' ~~~up~~~ '+password );
            
            //create basicAuth header
            Blob headerValue = Blob.valueOf(userName + ':' + password);
             String authorizationHeader = 'Basic ' + EncodingUtil.base64Encode(headerValue);
            // set headers
            req.setHeader('Authorization', authorizationHeader);
            req.setHeader('Content-Type', 'application/pdf');
            req.setHeader('Accept', 'application/json');
            req.setBodyAsBlob(pdf);
            //Send request
            Http http = new Http();
            HttpResponse res = http.send(req);
            
            system.debug(' ~~~res~~~ '+res);
            system.debug(' ~~~res.getHeader(Location)~~~ '+res.getHeader('Location'));
            
            return res.getHeader('Location');   
        }
        catch(exception ex){
            system.debug('----' + ex.getMessage() );
            return null;
        }
    }
    
    public static Integer callImageServiceToPutAttachment(string attachUrl,Blob pdf) {
        try{
            ImageServiceSettings__c imgSvc = ImageServiceSettings__c.getValues('ImageService');
            HttpRequest req = new HttpRequest();
            req.setEndpoint(attachUrl);
            system.debug('----image url:' + attachUrl);
            req.setMethod('PUT');
            String userName = imgSvc.UserName__c; //'external\\m3.testing';
            String password = imgSvc.Password__c; //'Password1';
            
            //create basicAuth header
            Blob headerValue = Blob.valueOf(userName + ':' + password);
            String authorizationHeader = 'Basic ' + EncodingUtil.base64Encode(headerValue);
            // set headers
            req.setHeader('Authorization', authorizationHeader);
            req.setHeader('Content-Type', 'application/pdf');
            req.setHeader('Accept', 'application/json');
            req.setHeader('If-Match','"*"');
            req.setBodyAsBlob(pdf);
            //Send request
            Http http = new Http();
            HttpResponse res = http.send(req);
            system.debug('----etag:' + res.getHeader('Etag'));
            return res.getStatusCode();   
        }
        catch(exception ex){
            system.debug('----' + ex.getMessage() );
            return null;
        }
    }
    
    public static void updateDetails(projectservice__c ps,string URLdata)
    {
        try{
            system.debug('---URLdata---' + URLdata);
            attribute__c attr = [SELECT Id,Name, Attributetitle__c,Active__c,AttributeMaxLength__c,AttributeType__c FROM Attribute__c WHERE Attributetitle__c = 'Job Manual' limit 1 FOR UPDATE];
            system.debug('---attr.id---' + attr.id);
            ps.JobManualURL__c = URLdata;
            ProjectServiceAttribute__c psca = new ProjectServiceAttribute__c();
            list<ProjectServiceAttribute__c> pscaLst = [SELECT AttachmentURL__c,AttributeTitle__c,AttachmentExt__c FROM ProjectServiceAttribute__c WHERE ProjectService__c =:ps.id and Attribute__c =: attr.id FOR UPDATE];
            if(pscaLst!=null && pscaLst.size() > 0)
            {
                psca =  pscaLst[0];    
                system.debug('---pscaLst[0]---' + pscaLst[0]);
            }
            
            psca.AttachmentURL__c = URLdata;
            psca.service__C = ps.service__c;
            psca.Attribute__c= attr.id;
            psca.AttachmentExt__c='pdf';
            upsert psca;        
            
            system.debug('~~ psca update end !!! ~~');
            
            update ps;
        } catch(Exception ex) {
            system.debug('----' + ex.getMessage() + ':' + ex.getStackTraceString());
        }
    }
   
    private static Integer getMaxServicesForManualGeneration(){
        List<OrgCustomSettings__c> settings = [SELECT MaxServicesforManualGeneration__c FROM OrgCustomSettings__c LIMIT 1];
        if(settings == null || settings.size() == 0 || settings[0] == null || settings[0].MaxServicesforManualGeneration__c == null){
            return 20;
        }
        return integer.valueOf(settings[0].MaxServicesforManualGeneration__c);
    }        
    
    
}