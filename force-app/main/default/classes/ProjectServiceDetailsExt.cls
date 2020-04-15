public with sharing class ProjectServiceDetailsExt {
    
    public ApexPages.StandardController controller;
    public Boolean showPageMessage {get;set;}
    public string url {get;set;}
    public String eventManualUrl{get;set;}
    public ID projectid {get;set;}
    public Project__c proj {get;set;}
    public service__c ServiceObj{get;set;}
    public ProjectService__c ps{get;set;}
    public List<ServiceAttributeValue> pscas {get; set;}
    public Boolean showEditProjectServiceButton {
        get;
        private set;
    }
    public Map<String,Boolean> hiddenMap {get;set;}
    public class ServiceAttributeValue
    {
        public string name {get; set;}
        public string value {get; set;}
        public string type {get; set;}
        public string attachmentname {get; set;}
        public string attachmentId {get; set;}
        
        public Boolean isImage {
            get {
                return AttachmentAnalyzer.isImage(attachmentId, attachmentname, type);
            }
        }
        public Boolean isFile {
            get {
                return AttachmentAnalyzer.isFile(attachmentId, type);
            }
        }
    }
    public Boolean hasLeadTime{get;set;}
    public string succmsg{get;set;}
    private void addMessage(ApexPages.Severity severity, String message){
        if (Apexpages.getMessages().size() == 0){
            Apexpages.addMessage(new ApexPages.Message(severity, message));
        }
    }
    
    private void initJobManualUrl() {
        string tempURL; 
        
        if(ps.JobManualTemplate__c == 'Standard'){
            tempURL = 'pdftemplate';
            eventManualUrl= '/apex/' + tempURL  + '?psId='+ps.Id;
        }
        else{
            tempURL = ps.JobManualURL__c;
            eventManualUrl= ps.JobManualURL__c;
        }
        
    }
    
    public ProjectServiceDetailsExt(ApexPages.StandardController controller) {
        //ID psID =   ((ProjectService__c) this.controller.getRecord()).id; //'a0Hj0000002sPDp';//
        //String message = ApexPages.CurrentPage().GetParameters().Get('message');
        system.debug('~~~~~'+ApexPages.CurrentPage().GetParameters().size());
        if(ApexPages.CurrentPage().GetParameters().containskey('message'))
        {
            succmsg = ApexPages.CurrentPage().GetParameters().Get('message');
        }
        showPageMessage  = false;
        string psId = ApexPages.CurrentPage().getParameters().get('id');
        ps = [SELECT Id, Name, Project__c,Project__r.ProjectTypeName__c, ProjectNumber__c, Project__r.Retailer__c, Service__r.Name,   Service__c, ServiceTitle__c, Title__c, TargetType__c, Status__c, ResponsibleForExecution__c, PurchaseAmount__c, JobManual__c, JobManualURL__c,   VariantLanguage__c,EstimatedMinutes__c, PopulateTargetQuestions__c, NumberOfWorkers__c, Service__r.IsNumberOfWorkersRequired__c, NumberOfDays__c, StartDayNumber__c, ShippingPreference__c,StartTime__c, Project__r.ProjectType__r.AllowMultidays__c,CheckDistribution__c,Service__r.AllowDistribution__c  FROM ProjectService__c where id =:psID ];
        ps.NumberOfWorkers__c = (ps.NumberOfWorkers__c==null?1:ps.NumberOfWorkers__c);
        ps.ShippingPreference__c = (ps.ShippingPreference__c==null?'Ship to Location':ps.ShippingPreference__c);
        
        initJobManualUrl();
        
        
        /*if(ps.Project__r.ProjectTypeName__c==ProjectType.IE)
url = '/apex/factcard?psId='+ps.Id;
else
url = '/apex/pdfTemplate?psId='+ps.Id;*/
        
        proj = [SELECT Id, Name, Status__c, ProjectType__c, Retailer__r.Name, ProjectCancelLeadTime__c, FulfillmentLeadTime__c, StartDate__c,EndDate__c,Retailer__r.isMaterialReqd__c, ProjectType__r.Name, IsExternalProject__c, OneHubRetailerId__c, ProjectOrigin__c FROM Project__c WHERE Id = : ps.project__c];
        
        Set<String> hiddenElemets = new Set<String>();
        hiddenElemets.add('ProjectService__c.Edit');
        hiddenMap = UIConfig.isHidden(proj.Status__c, hiddenElemets);
        
        
        hasLeadTime = false;
        if (proj.Status__c == 'Planning' || proj.Status__c == 'Rejected'  || proj.Status__c == 'Booked' && AppUtil.hasProjectLeadTimeByProjectId(proj.Id))
        {
            hasLeadTime = true;    
        }
        
        boolean hasLeadtime = AppUtil.hasProjectLeadTime(proj);       
        String attrId;
        pscas = new List<ServiceAttributeValue>();
        
        for (ProjectServiceAttribute__c psca : [Select AttributeTitle__c, AttributeValue__c , AttributeType__c from  ProjectServiceAttribute__c where ServiceAttribute__r.isvisible__c=true and  ProjectService__c = :psId Order By AttributeOrder__c ])
        {
            ServiceAttributeValue sav = new ServiceAttributeValue();
            sav.name = psca.AttributeTitle__c;
            sav.value = psca.AttributeValue__c ;
            sav.type = psca.AttributeType__c;
            
            if (psca.AttributeType__c == 'Photo')
            {
                if (String.isNotBlank(psca.AttributeValue__c)) {
                    
                    attrId = psca.AttributeValue__c.split('=')[0];
                    List<Attachment> a = [Select Id, Name, Body from Attachment where Id =: attrId  LIMIT 1];
                    if(a.size() >0)
                    {
                        sav.attachmentname = a[0].Name;
                        sav.attachmentId = attrId;
                    }
                }
            }
            
            pscas.add(sav);
        }
        
        
        /* Removed as per Bug: 53726
if (ps.Status__c == 'Booked' && proj.IsExternalProject__c == false ) {
Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'Submit For Approval is required if Primary Items are added or deleted.'));
}*/ 
        
        if (proj.Status__c == 'Planning' || (proj.Status__c == 'Booked' && hasLeadtime) || proj.Status__c == 'Rejected' ) {
            showEditProjectServiceButton = true;
        } else {
            showEditProjectServiceButton = false;
        }
        
    }
    
}