public class importexportdataController {

    public string jsonData {get; set;}
    public string importServiceJSON {get; set;}
    public string selectedIds {get; set;}
    public List<Service__c> services {get; set;}
    
    public importexportdataController() {
        services = [SELECT Id, Name FROM Service__c];
    }

    public PageReference processImport() {
        
        List<ServiceDataWrapper> sws = (List<ServiceDataWrapper>)System.JSON.deserialize(importServiceJSON,List<ServiceDataWrapper>.class);
        system.debug(sws);
        //validate data before import
        Set<String> importServiceNames = new Set<String>();
        Set<String> importAttributeNames = new Set<String>();
        Set<String> importQuestuionOHIds = new Set<String>();
        Set<String> importDefinedResponseOHIds = new Set<String>();
        Set<String> importJumpToQstnIds = new Set<String>();
        List<String> errorMessages = new List<String>();
        
        for(ServiceDataWrapper sw: sws){
            if(String.isBlank(sw.Service.Name)){
                errorMessages.add('Service name cannot be empty');
            }
            
            for(ServiceDataWrapper.ServiceAttributeData sad: sw.ServiceAttributes){
                if(String.isBlank(sad.AttributeTitle)){
                    errorMessages.add('Attribute Title cannot be empty');
                }   
                importAttributeNames.add(sad.AttributeTitle);
            }
            
            for(ServiceDataWrapper.ServiceQuestionData sqd: sw.ServiceQuestions){
                if(String.isBlank(sqd.OneHubQuestionId)){
                    errorMessages.add('OneHubQuestionId cannot be empty');
                }   
                importQuestuionOHIds.add(sqd.OneHubQuestionId);

                if(!String.isBlank(sqd.ParentOneHubQuestionId)){
                    importQuestuionOHIds.add(sqd.ParentOneHubQuestionId);
                }   
                
                
            }
            
            for(ServiceDataWrapper.ServiceQuestionDRData sqdr: sw.ServiceQuestionDRs){
                if(String.isBlank(sqdr.OneHubDefinedResponseId)){
                    errorMessages.add('OneHubDefinedResponseId cannot be empty');
                }   
                importDefinedResponseOHIds.add(sqdr.OneHubDefinedResponseId);
            }
            
            importServiceNames.add(sw.Service.Name);
        }
        
        Integer serviceMatchCount = [SELECT Count() FROM Service__c WHERE Name in :importServiceNames];
        Integer attributeMatchCount = [SELECT Count() FROM Attribute__c WHERE AttributeTitle__c in :importAttributeNames];
        Integer questionMatchCount = [SELECT Count() FROM Question__c WHERE OneHubQuestionId__c in :importQuestuionOHIds];
        Integer drMatchCount = [SELECT Count() FROM QuestionDefinedResponse__c WHERE OneHubAnswerId__c in :importDefinedResponseOHIds];
        Integer jQstnMatchCount = [SELECT Count() FROM Question__c WHERE OneHubQuestionId__c in :importJumpToQstnIds];
        
        if(serviceMatchCount > 0){
            errorMessages.add('One or more service already exists in destination org');
        }
        if(attributeMatchCount < importAttributeNames.size()){
            errorMessages.add('Some of the attributes are missing in destination org');
        }
        if(questionMatchCount < importQuestuionOHIds.size()){
            errorMessages.add('Some of the questions are missing in destination org');
        }
        if(importJumpToQstnIds.size() > 0 && jQstnMatchCount < importJumpToQstnIds.size()){
            errorMessages.add('Some of the jump to questions are missing in destination org');
        }
        if(drMatchCount < importDefinedResponseOHIds.size()){
            errorMessages.add('Some of the question defined responses are missing in destination org');
        }
        if(errorMessages.size() > 0){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error,String.join(errorMessages, ', ')));
            return null;
        }
        
        Map<String,Attribute__c> destAttrMap = new Map<String,Attribute__c>();
        for(Attribute__c attr :[SELECT Id,AttributeTitle__c FROM Attribute__c WHERE AttributeTitle__c in :importAttributeNames]){
            destAttrMap.put(attr.AttributeTitle__c, attr);
        }
        
        Map<String,Question__c> destQstnMap = new Map<String,Question__c>();
        for(Question__c q :[SELECT Id, OneHubQuestionId__c FROM Question__c WHERE OneHubQuestionId__c in :importQuestuionOHIds]){
            destQstnMap.put(q.OneHubQuestionId__c, q);
        }
        
        Map<String,Id> destQDRMap = new Map<String,Id>();
        for(QuestionDefinedResponse__c dr :[SELECT Id, OneHubAnswerId__c FROM QuestionDefinedResponse__c WHERE OneHubAnswerId__c in :importDefinedResponseOHIds]){
            destQDRMap.put(dr.OneHubAnswerId__c, dr.Id);
        }
        
        Map<String, Id> jToQstnMap = new Map<String,Id>();
        for(Question__c dr :[SELECT Id, OneHubQuestionId__c FROM Question__c WHERE OneHubQuestionId__c in :importJumpToQstnIds]){
            jToQstnMap.put(dr.OneHubQuestionId__c, dr.Id);
        }
        
        
        for(ServiceDataWrapper sw: sws){
            
            //create service
            Service__c s = new Service__c();
            s.Name = sw.Service.Name;
            s.AllowDistribution__c = sw.Service.AllowDistribution;
            s.NoSurvey__c = sw.Service.NoSurvey;
            s.Duration__c = sw.Service.Duration;
            s.IsNumberOfWorkersRequired__c = sw.Service.IsNumberOfWorkersRequired;
            s.ServiceDescription__c = sw.Service.ServiceDescription;
            s.TargetType__c = sw.Service.TargetType;
            s.IsBulkScan__c = sw.Service.IsBulkScan;
            s.IsSelfDirected__c = sw.Service.IsSelfDirected;
            s.IsBillable__c = sw.Service.IsBillable;
            s.Specialization__c = sw.Service.Specialization; 
            
            s.Minutes__c = sw.Service.Minutes; 
            s.SurveyTemplateVersion__c = sw.Service.SurveyTemplateVersion; 
            s.IsVisibleToClient__c = sw.Service.IsVisibleToClient; 
            s.AllowedTargetUse__c = sw.Service.AllowedTargetUse; 
            s.ServiceFamily__c = sw.Service.ServiceFamily; 
            s.ExceptionPrompt__c = sw.Service.ExceptionPrompt; 
            
            insert s;
            
            
            List<ServiceAttribute__c> sas = new List<ServiceAttribute__c>();
            for(ServiceDataWrapper.ServiceAttributeData sad: sw.ServiceAttributes){
                ServiceAttribute__c sa = new ServiceAttribute__c();
                sa.Service__c = s.Id;
                sa.Attribute__c = ((Attribute__c)destAttrMap.get(sad.AttributeTitle)).Id;
                sa.AttributeOrder__c = sad.AttributeOrder;
                sa.DefaultAttributeValue__c = sad.DefaultAttributeValue;
                sa.ExcludeFromJobManual__c = sad.ExcludeFromJobManual;
                sa.IsVisible__c = sad.IsVisible;
                sas.add(sa);
            }
            insert sas;
            
            List<ServiceQuestion__c> sqs = new List<ServiceQuestion__c>();
            Map<string,string> qtopq = new Map<string,string>();
            for(ServiceDataWrapper.ServiceQuestionData swsq: sw.ServiceQuestions){
                ServiceQuestion__c sq = new ServiceQuestion__c();
                sq.Service__c = s.Id;
                sq.Question__c = ((Question__c)destQstnMap.get(swsq.OneHubQuestionId)).Id;
                sq.CanRemove__c = swsq.CanRemove;
                sq.Optional__c = swsq.Optional;
                sq.JumpToAction__c = swsq.JumpToAction;
                sq.QuestionNumber__c = swsq.QuestionNumber;
                sq.MaxValue__c = swsq.MaxValue;
                sq.MinValue__c = swsq.MinValue;
                sq.QuestionIndentation__c = swsq.QuestionIndentation;    
                //Using this field temporarily to store Survey Hint
                sq.QuestionHint__c = swsq.ParentOneHubQuestionId;
                sqs.add(sq);
            }
            insert sqs;
            
            Map<String,String> sqMap = new Map<String,String>();
            for(ServiceQuestion__c tsq : [SELECT Id, Question__r.OneHubQuestionId__c FROM ServiceQuestion__c WHERE Service__c =: s.Id]){
                sqMap.put(s.Id + '-' + tsq.Question__r.OneHubQuestionId__c, tsq.Id);
            }

            List<ServiceQuestionDefinedResponse__c> sqdrs = new List<ServiceQuestionDefinedResponse__c>();
            
            for(ServiceDataWrapper.ServiceQuestionDRData swdr: sw.ServiceQuestionDRs){
                ServiceQuestionDefinedResponse__c dr = new ServiceQuestionDefinedResponse__c();
                dr.ServiceQuestion__c = sqMap.get(s.Id + '-' + swdr.OneHubQuestionId);
                dr.CanRemove__c = swdr.CanRemove;
                dr.Optional__c = swdr.Optional;
                dr.JumpToAction__c = swdr.JumpToAction;
                dr.IsActive__c = swdr.IsActive;
                dr.JumpToQuestion__c = jToQstnMap.get(swdr.JumpToOneHubQuestionId);
                dr.QuestionDefinedResponse__c = destQDRMap.get(swdr.OneHubDefinedResponseId);
                
                sqdrs.add(dr);
            }
            insert sqdrs;

            List<ServiceQuestionRule__c> sqrs = new List<ServiceQuestionRule__c>();
            for(ServiceDataWrapper.ServiceQuestionRuleData sqrd: sw.ServiceQuestionRules){
                ServiceQuestionRule__c sqr = new ServiceQuestionRule__c();
                sqr.Operator__c = sqrd.Operator;
                sqr.Value__c = sqrd.Value;
                sqr.ServiceQuestion__c = sqMap.get(s.Id + '-' + sqrd.OneHubQuestionId);
                sqr.ParentServiceQuestion__c = sqMap.get(s.Id + '-' + sqrd.ParentOneHubQuestionId);
                sqrs.add(sqr);
            }
            insert sqrs;            
            
        
            List<ServiceQuestion__c> tsqs = [SELECT Id, QuestionHint__c, ParentServiceQuestion__c, 
                                          Question__r.OneHubQuestionId__c FROM ServiceQuestion__c 
                                          WHERE Service__c =: s.Id]; 
            for(ServiceQuestion__c tsq : tsqs){
                
                if (!String.IsEmpty(tsq.QuestionHint__c))
                {
                    tsq.ParentServiceQuestion__c = sqMap.get(s.Id + '-' + tsq.QuestionHint__c);
                    tsq.QuestionHint__c = '';
                }
            }
            update tsqs;

            
        }
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Info,'Services created!'));
        return null;
    }

    public PageReference processSelected() {
        set<string> serviceIds = new set<string>();
        for(string item : selectedIds.split(','))
        {
            serviceIds.add(item);           
        }
        List<Service__c> ss = [SELECT Id, Name,ServiceDescription__c, TargetType__c FROM Service__c WHERE Id in :serviceIds];
        List<ServiceDataWrapper> sdas = new List<ServiceDataWrapper>();
        List<ServiceDataWrapper.ServiceAttributeData> sada = new List<ServiceDataWrapper.ServiceAttributeData>();
        for(Service__c s:ss){
            ServiceDataWrapper sda = new ServiceDataWrapper();
           
            sda.Service = GetServiceData(s.Id);
            sda.ServiceAttributes = GetServiceAttributeData(s.Id);
            sda.ServiceQuestions = GetServiceQuestionData(s.Id);
            sda.ServiceQuestionDRs = GetServiceQuestionDRData(s.Id);
            sda.ServiceQuestionRules = GetServiceQuestionRuleData(s.id);
            sdas.add(sda);
        }
        jsonData = JSON.serialize(sdas);
        return null;
    }

    private ServiceDataWrapper.ServiceData GetServiceData(string serviceId)
    {
        
        ServiceDataWrapper.ServiceData  svc = new ServiceDataWrapper.ServiceData();
        Service__c service = [SELECT Name,AllowDistribution__c,NoSurvey__c,Duration__c,
                            IsNumberOfWorkersRequired__c,ServiceDescription__c,TargetType__c,IsBulkScan__c,
                            IsSelfDirected__c,IsBillable__c,Specialization__c, Minutes__c,SurveyTemplateVersion__c,
                            IsVisibleToClient__c, AllowedTargetUse__c, ServiceFamily__c, ExceptionPrompt__c FROM Service__c WHERE Id = :serviceId];
        
        if (service == null)
            return null;

        svc.Name = service.Name;
        svc.AllowDistribution = service.AllowDistribution__c;
        svc.NoSurvey = service.NoSurvey__c;
        svc.Duration = service.Duration__c;
        svc.IsNumberOfWorkersRequired = service.IsNumberOfWorkersRequired__c;
        svc.ServiceDescription = service.ServiceDescription__c;
        svc.TargetType = service.TargetType__c;
        svc.IsBulkScan = service.IsBulkScan__c;
        svc.IsSelfDirected = service.IsSelfDirected__c;
        svc.IsBillable = service.IsBillable__c;
        svc.Specialization = service.Specialization__c;   
        
        svc.Minutes = Integer.valueof(service.Minutes__c);
        svc.SurveyTemplateVersion = service.SurveyTemplateVersion__c;
        svc.IsVisibleToClient = service.IsVisibleToClient__c;
        svc.AllowedTargetUse = service.AllowedTargetUse__c;
        svc.ServiceFamily = service.ServiceFamily__c;
        svc.ExceptionPrompt = service.ExceptionPrompt__c;
        
        return svc;    
    
    
    }
    
    private List<ServiceDataWrapper.ServiceAttributeData> GetServiceAttributeData(string serviceId)
    {
    
        List<ServiceDataWrapper.ServiceAttributeData> sada = new List<ServiceDataWrapper.ServiceAttributeData>();
        
        List<ServiceAttribute__c> sas = [SELECT Id, Name,Attribute__c, AttributeOrder__c, AttributeTitle__c,
             AttributeType__c, DefaultAttributeValue__c, ExcludeFromJobManual__c, IsVisible__c FROM ServiceAttribute__c
             WHERE Service__c = :serviceId];

        for(ServiceAttribute__c sa:sas){    
            ServiceDataWrapper.ServiceAttributeData sad = new ServiceDataWrapper.ServiceAttributeData();
            sad.AttributeOrder = sa.AttributeOrder__c;
            sad.AttributeTitle = sa.AttributeTitle__c;
            sad.AttributeType = sa.AttributeType__c;
            sad.DefaultAttributeValue = sa.DefaultAttributeValue__c;
            sad.ExcludeFromJobManual = sa.ExcludeFromJobManual__c;                                                
            sad.IsVisible = sa.IsVisible__c;                                                                
            sada.add(sad);
        }
    
        return sada;    
    
    }
    
    private List<ServiceDataWrapper.ServiceQuestionData> GetServiceQuestionData(string serviceId)
    {
    
        List<ServiceDataWrapper.ServiceQuestionData> sqda = new List<ServiceDataWrapper.ServiceQuestionData>();            
        List<ServiceQuestion__c> sqs = [SELECT Id, Name,CanRemove__c, Optional__c, JumpToAction__c,
                MaxValue__c, MinValue__c, QuestionIndentation__c, ParentServiceQuestion__c,                                        
                Question__r.OneHubQuestionId__c, QuestionNumber__c, ParentServiceQuestion__r.Question__r.OneHubQuestionId__c 
                FROM ServiceQuestion__c 
                WHERE Service__c = :serviceId];
        for(ServiceQuestion__c sq:sqs){    
            ServiceDataWrapper.ServiceQuestionData sqd = new ServiceDataWrapper.ServiceQuestionData();
            sqd.CanRemove = sq.CanRemove__c;
            sqd.Optional = sq.Optional__c;
            sqd.JumpToAction = sq.JumpToAction__c;
            sqd.OneHubQuestionId = sq.Question__r.OneHubQuestionId__c;
            sqd.QuestionNumber = sq.QuestionNumber__c;      
            
            sqd.MaxValue = Integer.ValueOf(sq.MaxValue__c);      
            sqd.MinValue = Integer.ValueOf(sq.MinValue__c);      
            sqd.QuestionIndentation = sq.QuestionIndentation__c;      
            sqd.ParentOneHubQuestionId = sq.ParentServiceQuestion__r.Question__r.OneHubQuestionId__c;      
            
            sqda.add(sqd);
        }
           
        return sqda;    
    
   }
    
    private List<ServiceDataWrapper.ServiceQuestionRuleData> GetServiceQuestionRuleData(string serviceId)
    {
    
        List<ServiceDataWrapper.ServiceQuestionRuleData> sqrds = new List<ServiceDataWrapper.ServiceQuestionRuleData>();            
        List<ServiceQuestionRule__c> sqrs = [SELECT Id, Name, Operator__c, Value__c,                                      
                ServiceQuestion__r.Question__r.OneHubQuestionId__c, ParentServiceQuestion__r.Question__r.OneHubQuestionId__c 
                FROM ServiceQuestionRule__c 
                WHERE ServiceQuestion__r.Service__c = :serviceId];
        for(ServiceQuestionRule__c sqr:sqrs){    
            ServiceDataWrapper.ServiceQuestionRuleData sqrd = new ServiceDataWrapper.ServiceQuestionRuleData();
            sqrd.Operator = sqr.Operator__c;
            sqrd.Value = sqr.Value__c;
            sqrd.OneHubQuestionId = sqr.ServiceQuestion__r.Question__r.OneHubQuestionId__c;
            sqrd.ParentOneHubQuestionId = sqr.ParentServiceQuestion__r.Question__r.OneHubQuestionId__c;
            
            sqrds.add(sqrd);
        }
           
        return sqrds;    
    
   }    
   
    private List<ServiceDataWrapper.ServiceQuestionDRData> GetServiceQuestionDRData(string serviceId)
    {
    
        List<ServiceDataWrapper.ServiceQuestionDRData> sqdra = new List<ServiceDataWrapper.ServiceQuestionDRData>();            
        List<ServiceQuestionDefinedResponse__c> sqdrs = [SELECT Id, Name,CanRemove__c, Optional__c, JumpToAction__c,
             ServiceQuestion__r.Question__r.OneHubQuestionId__c, QuestionDefinedResponse__r.OneHubAnswerId__c,
             JumpToQuestion__r.OneHubQuestionId__c, IsActive__c FROM ServiceQuestionDefinedResponse__c 
             WHERE ServiceQuestion__r.Service__c = :serviceId];
        for(ServiceQuestionDefinedResponse__c sqdr:sqdrs){    
            ServiceDataWrapper.ServiceQuestionDRData srd = new ServiceDataWrapper.ServiceQuestionDRData();
            srd.CanRemove = sqdr.CanRemove__c;
            srd.Optional = sqdr.Optional__c;
            srd.JumpToAction = sqdr.JumpToAction__c;
            srd.OneHubQuestionId = sqdr.ServiceQuestion__r.Question__r.OneHubQuestionId__c;
            srd.JumpToOneHubQuestionId = sqdr.JumpToQuestion__r.OneHubQuestionId__c;                                                
            srd.OneHubDefinedResponseId = sqdr.QuestionDefinedResponse__r.OneHubAnswerId__c; 
            srd.IsActive = sqdr.IsActive__c; 
            
            sqdra.add(srd);
        }
    
        return sqdra;
    
    }   
    
    
    public static Service__c GetService(String serviceId)
    {
        Project__c rtn;
        //begin project
        project__c newproj = new project__c(); 
        string qry = ' Select ';
        string ObjectName = 'Service__c';      
        Result objReslt = FetchFieldInfo(ObjectName);                
        qry = qry + objReslt.commaSepField + ' from ' + ObjectName + ' where id =\'' + serviceId + '\' limit 1';        
        system.debug('!!!'+qry);
        
        Service__c service = Database.query(qry);        
        return service;
    }    

    public static List<ServiceAttribute__c> GetServiceAttributes(String serviceId)
    {
        string qry = ' Select ';
        string ObjectName = 'ServiceAttribute__c';      
        Result objReslt = FetchFieldInfo(ObjectName);                
        qry = qry + objReslt.commaSepField + ' from ' + ObjectName + ' where Service__c =\'' + serviceId + '\'';        
        system.debug('!!!'+qry);
        
        List<ServiceAttribute__c> sas = Database.query(qry);        
        return sas;
        
    }    
    
    public static List<ServiceQuestion__c> GetServiceQuestions(String serviceId)
    {
        string qry = ' Select ';
        string ObjectName = 'ServiceQuestion__c';      
        Result objReslt = FetchFieldInfo(ObjectName);                
        qry = qry + objReslt.commaSepField + ', Question__r.OneHubQuestionId__c from ' + ObjectName + ' where Service__c =\'' + serviceId + '\'';        
        system.debug('!!!'+qry);
        
        List<ServiceQuestion__c> sqs = Database.query(qry);        
        return sqs;
        
    }    

    public static List<ServiceQuestionDefinedResponse__c> GetServiceQuestionDefinedResponses(String serviceId)
    {
        string qry = ' Select ';
        string ObjectName = 'ServiceQuestionDefinedResponse__c';      
        Result objReslt = FetchFieldInfo(ObjectName);                
        qry = qry + objReslt.commaSepField + ', QuestionDefinedResponse__r.OneHubAnswerId__c, JumpToQuestion__r.OneHubQuestionId__c   from ' + ObjectName + ' where ServiceQuestion__r.Service__c =\'' + serviceId + '\'';        
        system.debug('!!!'+qry);
        
        List<ServiceQuestionDefinedResponse__c> sqdrs = Database.query(qry);        
        return sqdrs;
        
    }    
    
    
    public class keyPair
    {
        public String key {get; set;}
        public String val {get; set;}
    }
    
    public class Result
    {
        public String commaSepField {get; set;}
        public list<keyPair> keyPairVal {get; set;}
    } 
    
    
    
    private static Result FetchFieldInfo(string selectedObject) 
    { 
        Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        system.debug('$$$$$' + CONSTANTS.CURRENTNAMESPACEPREFIX + selectedObject);
        keyPair field = new keyPair();
        List<keyPair> lstfieldname = new List<keyPair>();
        string commaStr = '';
        
        Map <String, Schema.SObjectField> fieldMap = schemaMap.get(CONSTANTS.CURRENTNAMESPACEPREFIX + selectedObject).getDescribe().fields.getMap();
        for(Schema.SObjectField sfield : fieldMap.Values())
        {
            schema.describefieldresult dfield = sfield.getDescribe();
            //if(!dfield.isCalculated() && dfield.isUpdateable() && !string.valueof(dfield.getname()).toLowerCase().contains('uniquekey__c') )
            //if(!dfield.isCalculated() && !dfield.isAutoNumber() && !string.valueof(dfield.getname()).toLowerCase().contains('uniquekey__c') && !string.valueof(dfield.getname()).toLowerCase().contains('axisid__c')    )
            //{
                //system.debug('#######' + dfield );
                field = new keyPair();
                field.key = dfield.getname();
                system.debug(CONSTANTS.CURRENTNAMESPACEPREFIX + selectedObject+'#######4444' + field.key + '_____' + dfield.getLabel());
                field.val = dfield.getType () + ' : ' + dfield.getLabel();
                lstfieldname.add(field);
                commaStr+= field.key+',';
                
            //}
        }
        
        Result rslt = new Result();
        rslt.commaSepField = commaStr.removeend(',');
        rslt.keyPairVal = lstfieldname;
        return rslt;
    }    
   
   
}