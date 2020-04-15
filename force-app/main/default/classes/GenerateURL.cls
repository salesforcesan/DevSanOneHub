global with sharing class GenerateURL
{
    
    @future(callout=true)
    public static void GenerateNewURL(string pscaID, string attachmentID)
    {
        DoGenerateNewURL(pscaID, attachmentID);
    }
    
    public static void GenerateNewURLNonFutureCall(string pscaID, string attachmentID)
    {
        DoGenerateNewURL(pscaID, attachmentID);
    }
    
    
    @future(callout=true)
    public static void UpdateURL(string pscaID,string attachUrl, string attachmentID)
    {
        ImageServiceSettings__c imgSvc = ImageServiceSettings__c.getValues('ImageService');
        System.debug('   attachUrl   '+ attachUrl);
        System.debug('   attachmentID  '+ attachmentID);
        if(attachmentID.indexOf('=')!=-1)
        {
            attachmentID = attachmentID.split('=')[0];
        }
        Attachment attmnt = [Select ID, ParentID, body, Name from Attachment where Id = :attachmentID limit 1];
        string cntType;
        String ext = string.valueof(attmnt.Name).split('\\.')[1].toLowerCase();
        
        if(attmnt.Name.toLowerCase().contains('pdf'))
        {
            cntType = 'application/pdf';
            ext = 'pdf';        
        }
        else if(attmnt.Name.toLowerCase().contains('jpg'))
        {
            cntType = 'image/jpeg';    
            ext = 'jpg';
        }  
        else 
            cntType = 'image/'+ ext;

        system.debug(' !!!! values ' + ext+'___'+cntType);
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint(attachUrl);
        req.setMethod('PUT');
        String userName = imgSvc.UserName__c;//
        String password = imgSvc.Password__c;
        
        //create basicAuth header
        Blob headerValue = Blob.valueOf(userName + ':' + password);
        String authorizationHeader = 'Basic ' + EncodingUtil.base64Encode(headerValue);
        // set headers
        req.setHeader('Authorization', authorizationHeader);
        req.setHeader('Content-Type',cntType);
        req.setHeader('Accept', 'application/json');
        req.setHeader('if-match', '\"*\"');
        
        //set body
        System.debug('   attmnt.body   '+ attmnt.body);
        req.setBodyAsBlob(attmnt.body);
        
        //Send request
        Http http = new Http();
        HttpResponse res = new HttpResponse();
        if(!Test.isRunningTest())
        {        
            res = http.send(req);
        }
        
        //analyze the result
        System.debug('dvid result 1   '+ res.getStatus());
        System.debug('dvid result 2  '+ res.getHeader('Location'));
        
        ProjectServiceAttribute__c psca = [select AttachmentExt__c,AttachmentURL__c,AttchFileName__c from ProjectServiceAttribute__c where id=: pscaID limit 1 ];        
        psca.AttachmentExt__c = ext;
        psca.AttchFileName__c = attmnt.Name;
        update psca;
        
        
    }
    
    
    private static void DoGenerateNewURL(string pscaID, string attachmentID)
    {
		ImageServiceSettings__c imgSvc = ImageServiceSettings__c.getValues('ImageService');
        Attachment attmnt = [Select ID, ParentID, body, Name from Attachment where Id = :attachmentID limit 1];
        
        string cntType;
        String ext = string.valueof(attmnt.Name).split('\\.')[1].toLowerCase();
        
        
        if(attmnt.Name.toLowerCase().contains('pdf'))
        {
            cntType = 'application/pdf';
            ext = 'pdf';        
        }
        else if(attmnt.Name.toLowerCase().contains('jpg'))
        {
            cntType = 'image/jpeg';    
            ext = 'jpg';
        }  
        else 
            cntType = 'image/'+ ext;

        system.debug(' !!!! values ' + ext+'___'+cntType);
        String attachUrl = imgSvc.URL__c; 
        String userName = imgSvc.UserName__c;
        String password = imgSvc.Password__c;
        system.debug('~~~~' + attachUrl+'~~~~' +  imgSvc.UserName__c+  '~~~~' + imgSvc.Password__c);
        //create basicAuth header
        Blob headerValue = Blob.valueOf(userName + ':' + password);
        String authorizationHeader = 'Basic ' + EncodingUtil.base64Encode(headerValue);
        system.debug('~~~~' + authorizationHeader);        
        
        // create new attachment URL
        HttpRequest req = new HttpRequest();        
        req.setEndpoint(attachUrl);
        req.setMethod('POST');

        // set headers
        req.setHeader('Authorization', authorizationHeader);
        req.setHeader('Content-Type', cntType);
        req.setHeader('Accept', 'application/json');
        
        //set body
        //Blob body = Blob.valueOf(a.body);        
        req.setBodyAsBlob(attmnt.body);
        
        //Send request
        HttpResponse res = new HttpResponse();
        if(!Test.isRunningTest())
        {
            Http http = new Http();
            res = http.send(req);
        }        
        
        //analyze the result
        System.debug('dvid result 1   '+ res.getStatus());
        System.debug('dvid result 2  '+ res.getHeader('Location'));
        ProjectServiceAttribute__c psca = [select AttachmentExt__c,AttachmentURL__c,AttchFileName__c,projectservice__c,attributetitle__c, IsClonedAttachment__c from ProjectServiceAttribute__c where id=: pscaID limit 1];
        psca.AttachmentURL__c = res.getHeader('Location');
        psca.AttachmentExt__c = ext;
        psca.IsClonedAttachment__c = false;
        //psca.AttchFileName__c = attmnt.Name;
        update psca;
        
        if(psca.attributetitle__c==CONSTANTS.MANUAL){
        //update ps
            TriggerUtil.skipAllTriggers();
            projectservice__c ps = [select id,JobManualURL__c,IncludeAutoGenManual__c,JobManualFileName__c,JobManual__c,isManualGenInProgress__c from projectservice__C where id=:psca.projectservice__c limit 1];
            ps.JobManualURL__c = res.getHeader('Location');
            ps.IncludeAutoGenManual__c = false;
            ps.isManualGenInProgress__c=false;
            ps.JobManualFileName__c = attmnt.Name; 
        	update ps;
        }
    

        
    }
    
 
}