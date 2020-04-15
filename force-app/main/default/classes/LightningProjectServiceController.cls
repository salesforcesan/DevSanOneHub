public with sharing class LightningProjectServiceController {
    
    @AuraEnabled
    public static list<Object> GetProjectServiceDetails(String projectServiceId) {
        String query = 'SELECT Service__r.AllowDistribution__c, CheckDistribution__c, Name,ServiceTitle__c, Title__c,NumberOfWorkers__c,ServiceName__c,EstimatedMinutes__c,ServiceObjective__c, PurchaseAmount__c FROM ProjectService__c and ProjectService__c = \'' + projectServiceId + '\'';
        list<ProjectService__c> returnValue = Database.query(query);
        return returnValue;
    }
    
    @AuraEnabled
    public static string GetProjectServiceSurveyTemplateVersion(String projectServiceId) {
        
        string version ='';
        
        List<ProjectService__c> projectServices = [Select Id,Name, Service__r.SurveyTemplateVersion__c from ProjectService__c  where id=:projectServiceId LIMIT 1];		
        
        
        if (projectServices != null && projectServices.size() > 0){            
            version = projectServices[0].Service__r.SurveyTemplateVersion__c;
        }
        
        return version;
        
    }
    
    
    @AuraEnabled
    public static ProjServiceWrapper GetProjectService(String projServiceId) {
        ProjServiceWrapper psw = new ProjServiceWrapper();
        try{
            string ps = QueryUtil.FetchQuery('ProjectService__c'); //add extra fields inside queryutil
            //ps = ps.replace('Select', 'Select service__r.AllowDistribution__c,Project__r.ProjectType__r.AllowMultidays__c,service__r.IsNumberOfWorkersRequired__c, ');
            ps += ' WHERE Id = \'' + projServiceId + '\' order by Name';
            system.debug('~~1~~'+ ps);
            ProjectService__c psData = Database.query(ps);
            
            ps = QueryUtil.FetchQuery('ProjectServiceAttribute__c');
            ps+= '  WHERE ProjectService__c = \'' + projServiceId + '\' order by AttributeOrder__c ';
            system.debug('~~2~~'+ ps);
            list<ProjectServiceAttribute__c> psaList = Database.query(ps);
            
            psw = new ProjServiceWrapper(psData,psaList);
            psw.isSuccess=true;
            psw.Message = 'Data loaded successfully !!!';
            return psw;            
        }
        catch(System.DmlException e) {
            throw new AuraHandledException(e.getDmlMessage(0));
            
        }
        catch(exception ex){
            throw new AuraHandledException(ex.getMessage());
        }
    }
    
    @AuraEnabled
    public static List<ProjServiceWrapper> GetProjectServices(String projectId) {
        List<ProjServiceWrapper> pswLsit = new List<ProjServiceWrapper>();
        ProjServiceWrapper psw = new ProjServiceWrapper();
        string psQuery = QueryUtil.FetchQuery('ProjectService__c');  //add extra fields inside queryutil
        //psQuery = psQuery.replace('Select', 'Select service__r.AllowDistribution__c, Project__r.ProjectType__r.AllowMultidays__c,service__r.IsNumberOfWorkersRequired__c, ');
        psQuery += ' WHERE Project__c = \'' + projectId + '\' order by ServiceRank__c';
        system.debug('psQuery:: '+psQuery);
        List<ProjectService__c> psList = Database.query(psQuery);
        system.debug('psList:: '+psList);
        Boolean firstservice = false;
        Integer count = 0;
        for(ProjectService__c ps:psList){
            psw = new ProjServiceWrapper(ps,null);
            count ++;
            
            if (!firstservice)
            {
                firstservice = true;
                psw.IsFirstService = true;
                
            }
            else
            {
                psw.IsFirstService = false;
            }
            
            
            if (count == psList.size())
            {
                psw.IsLastService = true;
            }
            else
            {
                psw.IsLastService = false;
            }
            
            pswLsit.add(psw);
        }
        system.debug('pswLsit:: '+pswLsit);
        return pswLsit;
    }
    
    @AuraEnabled
    public static List<ServiceWrapper> getAvailableServicesApex(String projectId){
        
        List<ServiceWrapper> services = new list<ServiceWrapper>();
        if (AppUtil.getAppSetting('ServiceSelector').toLowerCase() == 'onehub')
        {
            for(ProjectTypeService__c pts:getProjectTypeServices(projectId)) {
                ServiceWrapper service = new ServiceWrapper();
                service.Id = pts.Service__r.id;
                service.Name = pts.Service__r.Name;
                service.ServiceDescription = pts.Service__r.ServiceDescription__c;
                services.add(service);
            }
        }
        system.debug('services.si::: ' + services.size());
        return services;
        
    }    
    
    //oh-2961: account specific services visibility when adding service
    static List<ProjectTypeService__c> getProjectTypeServices(string projectId){
        Project__c p = [SELECT Id, ProjectType__c, Retailer__c FROM Project__c WHERE Id = :projectId Limit 1];
        List<ProjectAccount__c> projectAccounts = [SELECT Account__c from ProjectAccount__c WHERE Project__c=:p.Id];
        if (projectAccounts.size() ==0){
            return [SELECT Service__r.id,  Service__r.name,  Service__r.ServiceDescription__c 
                    FROM ProjectTypeService__c 
                    where ProjectType__c =: p.ProjectType__c 
                    and  Service__c  in (
                        SELECT Service__c 
                        FROM RetailerService__c 
                        where retailer__c =: p.Retailer__c 
                        and Service__r.Account__c = null) 
                    order by Service__r.name];
        }
        
        List<Id> accounts = new List<Id>();
        for(ProjectAccount__c pa: projectAccounts){
            accounts.add(pa.Account__c);
        }
        
        return [SELECT Service__r.id,  Service__r.name,  Service__r.ServiceDescription__c 
                FROM ProjectTypeService__c 
                where ProjectType__c =: p.ProjectType__c 
                and  Service__c  in (
                    SELECT Service__c 
                    FROM RetailerService__c 
                    where retailer__c =: p.Retailer__c 
                    and (Service__r.Account__c = null or Service__r.Account__c in :accounts)
                ) 
                order by Service__r.name];
    }
    
    @AuraEnabled
    public static String addProjectService(String projectId, String serviceId){
        ResponseWrapper rw;
        try{
            
            ProjectService__c ps = createService(projectId, serviceId);
            rw = ResponseWrapper.getInstance(CONSTANTS.RESPONSE_STATE_SUCCESS, 'Service has been added to the project', ps.Id);
        }
        /*catch(Exception ex){
system.debug('ERROR - addProjectService: ' + ex.getMessage());
rw = ResponseWrapper.getInstance(CONSTANTS.RESPONSE_STATE_SUCCESS, 'Error adding service to the project' , CONSTANTS.RESPONSE_STATE_ERROR);
}*/
        catch(Exception ex){
            system.debug('ERROR - addProjectService: ' + ex.getMessage());
            if(ex.getDmlMessage(0)!='')
                rw = ResponseWrapper.getInstance(CONSTANTS.RESPONSE_STATE_SUCCESS, 'Error adding service to the project - ' + ex.getDmlMessage(0), CONSTANTS.RESPONSE_STATE_ERROR);
            else
                rw = ResponseWrapper.getInstance(CONSTANTS.RESPONSE_STATE_SUCCESS, 'Error adding service to the project' , CONSTANTS.RESPONSE_STATE_ERROR);
        }
        return JSON.serialize(rw);
    }
    
    public static ProjectService__c createService(String projectId, String serviceId){
        Map<String,Decimal> mapOLI = new Map<String,Decimal>();
        
        List<Opportunity> lstOpportunity = [SELECT Id,Project__c 
                                            FROM Opportunity WHERE Project__c =:projectId LIMIT 1];
        
        if(lstOpportunity.size()>0)
        {
            Opportunity o = lstOpportunity[0];
            if(o != null)
            {
                List<OpportunityLineItem> olList = [Select Id, Service__c, Service__r.Name,Minutes__c,Product2.AssetsRequired__c 
                                                    FROM OpportunityLineItem 
                                                    WHERE OpportunityId =:o.Id and Service__c =:serviceId];
                
                if(olList.size()>0)
                {
                    for(OpportunityLineItem oli:olList)
                    {
                        mapOLI.put(oli.Service__c,oli.Minutes__c);
                    }
                    
                }
                
            }
        }
        
        
        Project__c project = [SELECT Id, OneHubRetailerId__c, RetailerAccount__c, ProjectType__r.AllowMultiDays__c, NumberOfDays__c FROM Project__c WHERE Id = :projectId];
        //oh2962: service visibility to supplier
        
        Service__c service = [SELECT Id, Name, IsExcludedForSuccessRate__c, isVisibleToClient__c,JobManualTemplate__c, AllowDistribution__c,AllowedTargetUse__c,Minutes__c FROM Service__c  WHERE Id = :serviceId];
        ProjectService__c ps = new ProjectService__c();
        ps.Service__c = serviceId;
        ps.Project__c = projectId;
        ps.TargetUse__c = service.AllowedTargetUse__c;
        //oh4493
        ps.IsExcludedForSuccessRate__c = service.IsExcludedForSuccessRate__c;
        //oh2962: service visibility to supplier
        ps.isVisibleToClient__c = service.isVisibleToClient__c;
        
        /////////////////////////////
        
        ps.ResponsibleForExecution__c = CONSTANTS.RESPONSIBLE_FOR_EXECUTION_EXECUTIONCOMPANY;
        
        ps.Project__c = projectId;
        ps.PopulateTargetQuestions__c = true;
        ps.NumberOfDays__c = 1;
        ps.NumberOfWorkers__c = 1;
        ps.StartDayNumber__c = 1;
        ps.JobManualFileName__c = '';
        ps.JobManualURL__c = '';
        ps.OneHubRetailerId__c = project.OneHubRetailerId__c;
        ps.ProjectNumberOfDays__c = String.ValueOf(project.NumberOfDays__c);
        if (project.NumberOfDays__c >= 1)
        {
            ps.DayNumbers__c = '1';
            
        }
        // ps.JobManualTemplate__c =
        //default values
        // ps.JobManualTemplate__c  = CONSTANTS.JOB_MANUAL_STANDARD_TEMPLATE;
        
        ps.JobManual__c = (service.JobManualTemplate__c!=null)?service.JobManualTemplate__c:CONSTANTS.JOB_MANUAL_STANDARD_TEMPLATE;
        if( ps.JobManual__c  == 'Standard')
        {
            ps.IncludeAutoGenManual__c = true;
        }
        else
        {
            ps.IncludeAutoGenManual__c = false;
        }
        ps.ServiceTitle__c = service.Name;
        //ps.TargetUse__c = service.AllowedTargetUse__c;
        
        if(mapOLI!=null && mapOLI.size() > 0)
        {
            if(mapOLI.containsKey(serviceId))
            {
                ps.EstimatedMinutes__c = mapOLI.get(serviceId)!= null?(Decimal)mapOLI.get(serviceId):service.Minutes__c;
                
            }
            
            
        }
        else
        {
            ps.EstimatedMinutes__c = (Decimal)service.Minutes__c;
        }
        
        
        //ps.EstimatedMinutes__c=5;
        
        
        ps.isManualGenInProgress__c=false;
        ps.RetailerAccount__c = project.RetailerAccount__c;
        
        AggregateResult[] result = [Select MAX(ServiceRank__c) MaxRank FROM ProjectService__c where Project__c =:projectId];
        Integer maxRank = Integer.valueOf(result[0].get('MaxRank'));
        if (maxRank != null){
            ps.ServiceRank__c = Decimal.valueOf(maxRank + 1);
        }
        else
        {
            ps.ServiceRank__c = 1;
        }
        string urlData;
        insert ps;
        
        system.debug('PS AfterInsert Status: ' + ps.Project__r.Status__c);
        
        Map<Id, Id> mqv = new Map<Id, Id>();
        Map<Id, Id> mqdrv = new Map<Id, Id>();
        //remove in-active filter per OH-2489 -- Question__r.Active__c = true
        list<ServiceQuestion__c> tempQnsList = [SELECT Id, Name,IsActive__c, Question__r.ItemQuestion__c, Question__c, QuestionNumber__c, QuestionText__c, 
                                                QuestionType__c,CanRemove__c, Optional__c, 
                                                JumpToAction__c,service__r.name,MinValue__c,MaxValue__c,IsVisibleToClient__c,QuestionHint__c,HintLock__c,
                                                ParentServiceQuestion__c,QuestionIndentation__c,QuestionIndentationLevel__c 
                                                FROM ServiceQuestion__c WHERE service__c = : serviceId 
                                                ORDER BY QuestionNumber__c]; 
        list<ProjectServiceQuestionDefinedResponse__c> definedResponses = new list<ProjectServiceQuestionDefinedResponse__c>();
        
        Map<ID,ProjectServiceQuestion__c> SQProjectServiceQuesMap = new Map<ID,ProjectServiceQuestion__c>();
        Map<ID,ProjectServiceQuestionDefinedResponse__c> SQProjectServiceQuestionDefinedResponseMap = new Map<ID,ProjectServiceQuestionDefinedResponse__c>();
        
        
        for(integer j=0;j<tempQnsList.size();j++)
        {
            ProjectServiceQuestion__c surveyQn = new ProjectServiceQuestion__c();
            surveyQn.QuestionNumber__c = tempQnsList[j].QuestionNumber__c;
            
            surveyQn.IsTargetQuestion__c = tempQnsList[j].Question__r.ItemQuestion__c; 
            surveyQn.ServiceQuestion__c = true;
            surveyQn.ProjectService__c = ps.id;  
            //oh2962 client visibility
            surveyQn.IsVisibleToClient__c = tempQnsList[j].IsVisibleToClient__c;
            ////////////////////////////////////
            
            surveyQn.Question__c = tempQnsList[j].Question__c;
            surveyQn.QuestionVariant__c = mqv.get(tempQnsList[j].Question__c);
            surveyQn.CanRemove__c = tempQnsList[j].CanRemove__c;
            surveyQn.QuestionHint__c = string.ValueOf(tempQnsList[j].QuestionHint__c);
            surveyQn.HintLock__c = Boolean.ValueOf(tempQnsList[j].HintLock__c);
            surveyQn.Optional__c = tempQnsList[j].Optional__c;
            surveyQn.JumpToAction__c = tempQnsList[j].JumpToAction__c;
            if(!(String.isBlank(String.ValueOf(tempQnsList[j].MinValue__c))))  
            {                
                surveyQn.MinValue__c = integer.ValueOf(tempQnsList[j].MinValue__c);
            }
            if(!(String.isBlank(String.ValueOf(tempQnsList[j].MaxValue__c))))  
            {
                surveyQn.MaxValue__c = integer.ValueOf(tempQnsList[j].MaxValue__c);
            }
            
            ServiceQuestion__c serviceQuestion = tempQnsList[j];
            surveyQn.QuestionIndentation__c = serviceQuestion.QuestionIndentation__c;
            
            // To Create Rules
            SQProjectServiceQuesMap.put(serviceQuestion.Id, surveyQn);
            
            ProjectServiceQuestion__c parentProjectServiceQues = SQProjectServiceQuesMap.get(serviceQuestion.ParentServiceQuestion__c);
            
            system.debug('parentProjectServiceQues::' + parentProjectServiceQues);
            system.debug('QuestionText__c::' + serviceQuestion.QuestionText__c);
            
            if (parentProjectServiceQues !=null) {
                surveyQn.ParentProjectServiceQuestion__c = parentProjectServiceQues.Id;
            }                              
            
            // End of add rule code 
            
            
            //surveyQn.Active__c  = tempQnsList[j].IsActive__c;
            insert surveyQn;
            
            if (tempQnsList[j].QuestionType__c != CONSTANTS.QUESTIONTYPE_YESNO &&
                tempQnsList[j].QuestionType__c != CONSTANTS.QUESTIONTYPE_SINGLE_SELECT &&
                tempQnsList[j].QuestionType__c != CONSTANTS.QUESTIONTYPE_MULTI_SELECT)
            {
                continue;
            }
            
            ProjectServiceQuestionDefinedResponse__c defResp;
            List<ServiceQuestionDefinedResponse__c> sqDefResList = [ SELECT Id, Name,IsActive__c, QuestionDefinedResponse__c, JumpToQuestion__c, EndOfQuestions__c, CanRemove__c, JumpToAction__c  FROM ServiceQuestionDefinedResponse__c where ServiceQuestion__c = :tempQnsList[j].Id]  ;
            
            
            
            for(integer i=0;i<sqDefResList.size();i++)
            {
                //RN - If canRemove is false and not active, do not show it to the
                //project builder - OH-3899
                if (!sqDefResList[i].CanRemove__c && !sqDefResList[i].IsActive__c)
                    continue;
                
                
                defResp =  new ProjectServiceQuestionDefinedResponse__c();
                defResp.ProjectServiceQuestion__c = surveyQn.id;
                defResp.QuestionDefinedResponse__c = sqDefResList[i].QuestionDefinedResponse__c;
                defResp.JumpToQuestion__c = sqDefResList[i].JumpToQuestion__c;
                defResp.EndOfQuestions__c = sqDefResList[i].EndOfQuestions__c;
                defResp.CanRemove__c = sqDefResList[i].CanRemove__c;
                defResp.QuestionDefinedResponseVariant__c = mqdrv.get(sqDefResList[i].QuestionDefinedResponse__c);
                defResp.JumpToAction__c = sqDefResList[i].JumpToAction__c;
                defResp.Active__c  = sqDefResList[i].IsActive__c;   
                definedResponses.add(defResp);
                
                SQProjectServiceQuestionDefinedResponseMap.put(sqDefResList[i].Id,defResp);
            }
        }
        if(definedResponses.size() > 0){
            insert definedResponses;
        }
        
        
        List<ServiceQuestionRule__c> serviceQuestionRules = [SELECT ServiceQuestion__c, ParentServiceQuestion__c, Operator__c, Value__c, ServiceQuestionText__c, ParentServiceQuestionText__c, DefinedResponseValue__c, DefinedResponseValueText__c, ParentServiceQuestionType__c, Id 
                                                             FROM ServiceQuestionRule__c 
                                                             WHERE ServiceQuestion__r.Service__c =:serviceId];
        
        List<ProjectServiceQuestionRule__c> projectServiceQuestionRules = new List<ProjectServiceQuestionRule__c>();
        
        for(ServiceQuestionRule__c serviceQuestionRule :serviceQuestionRules){
            
            ProjectServiceQuestion__c projectServiceQues = SQProjectServiceQuesMap.get(serviceQuestionRule.ServiceQuestion__c);
            ProjectServiceQuestion__c parentProjectServiceQues = SQProjectServiceQuesMap.get(serviceQuestionRule.ParentServiceQuestion__c);
            
            ProjectServiceQuestionRule__c projectServiceQuestionRule = new ProjectServiceQuestionRule__c();
            
            projectServiceQuestionRule.ProjectServiceQuestion__c = projectServiceQues.Id; 
            projectServiceQuestionRule.ParentProjectServiceQuestion__c = parentProjectServiceQues.Id;
            projectServiceQuestionRule.Operator__c= serviceQuestionRule.Operator__c;
            ProjectServiceQuestionDefinedResponse__c projServiceQuestionDefinedResponse = SQProjectServiceQuestionDefinedResponseMap.get(serviceQuestionRule.DefinedResponseValue__c);
            if (projServiceQuestionDefinedResponse != null){
                projectServiceQuestionRule.DefinedResponseValue__c = projServiceQuestionDefinedResponse.Id;
            }
            
            projectServiceQuestionRule.Value__c = serviceQuestionRule.Value__c;
            
            projectServiceQuestionRules.add(projectServiceQuestionRule);
        }
        
        insert projectServiceQuestionRules;
        
        
        List<ProjectServiceAttribute__c> pscaList = new List<ProjectServiceAttribute__c>();
        
        for(ServiceAttribute__c sa : [Select Id, Attribute__c, Service__c, DefaultAttributeValue__c 
                                      from ServiceAttribute__c where Service__c = :serviceId]){
                                          ProjectServiceAttribute__c psca = new ProjectServiceAttribute__c();
                                          psca.Attribute__c = sa.Attribute__c;            
                                          psca.AttributeValue__c   = sa.DefaultAttributeValue__c;
                                          
                                          psca.ProjectService__c = ps.id;
                                          psca.Service__c= sa.Service__c;
                                          psca.ServiceAttribute__c = sa.Id;
                                          pscaList.add(psca);
                                      }
        insert pscaList;
        
        //service target 
        TriggerUtil.skipProjectServiceTargetTrigger = true;
        List<ProjectServiceTarget__c> pstList = new List<ProjectServiceTarget__c>();
        for(ServiceTarget__c st : [Select Id, Target__c, Service__c from ServiceTarget__c where Service__c = :serviceId]){
            ProjectServiceTarget__c pst = new ProjectServiceTarget__c();
            pst.Target__c = st.Target__c;
            pst.ProjectService__c =ps.id;
            pstList.add(pst);
        }
        insert pstList;
        
        
        
        //save project location
        list<projectlocation__c> plList = [select id from projectlocation__c where project__c=: project.id];
        for(projectlocation__c pl : plList){
            pl.status__c = null;
        }
        update plList;
        return ps;
    }
    
    @AuraEnabled
    public static List<ProjServiceWrapper> setProjectServiceRankApex(string projectserviceid, string projectid, string direction){
        map<String, Integer> maprbyid = new Map<String, Integer>();
        map<Integer, String> maprbyrank = new Map<Integer, String>();
        
        List<ProjectService__c> pss = [Select Id, name, ServiceRank__c from ProjectService__c
                                       WHERE Project__c = :projectid];
        
        for (ProjectService__c ps : pss)
        {
            maprbyrank.put(Integer.valueOf(ps.ServiceRank__c), ps.Id);
            maprbyid.put(ps.Id, Integer.valueOf(ps.ServiceRank__c));
        }
        
        Integer currentRank = maprbyid.get(projectserviceid);
        Integer newRank = 0;
        
        try{
            
            if (direction.compareTo('up') == 0)
            {
                //reduce the rank
                newRank = currentRank - 1;
            }
            else if (direction.compareTo('down') == 0)
            {
                //reduce the rank
                newRank = currentRank + 1;
            }
            
            //Get the other ps that needs to increase the rank
            String otherps = maprbyrank.get(newRank);
            maprbyid.put(otherps,currentRank);
            maprbyid.put(projectserviceid,newRank);
            
            for (ProjectService__c ps : pss)
            {
                ps.ServiceRank__c = maprbyid.get(ps.Id);
            }
            
            update pss;
            
            
            
            return GetProjectServices(projectId);
            
        }
        catch(Exception ex){
            throw new System.AuraHandledException('Error changing service rank: ' + ex.getMessage());
        }
    }
    
    
    @AuraEnabled
    public static ProjServiceWrapper DeleteAttachmentHandlerEvt(string psaRecordID) {
        ProjServiceWrapper psw = new ProjServiceWrapper();
        try{
            System.debug('   psaID: '+psaRecordID);
            ProjectServiceAttribute__c pscaList = [SELECT Id,AttributeValue__c,projectservice__c,AttachmentExt__c, AttachmentURL__c, AttchFileName__c FROM ProjectServiceAttribute__c where id=:psaRecordID LIMIT 1];
            Set<String> s1 = new Set<String>();
            s1.add(string.valueof(pscaList.AttributeValue__c).substringBefore('='));
            
            
            List<Attachment> a = [select id from attachment where id =:string.valueof(pscaList.AttributeValue__c).substringBefore('=')];
            if(a.size() > 0){
                delete a;
            }
            
            pscaList.AttributeValue__c = null;
            pscaList.AttachmentExt__c = null;
            pscaList.AttachmentURL__c = null;
            pscaList.AttchFileName__c = null;
            update pscaList;
            
            psw= GetProjectService(pscaList.projectservice__c);
            psw.isSuccess=true;
            psw.Message = 'Attachment deleted successfully !!!';
        }
        catch(exception ex){
            psw = new ProjServiceWrapper();
            psw.isSuccess=false;
            psw.Message = ex.getMessage();
        }
        return psw;
        
    }
    
    
    @AuraEnabled
    public static String deleteProjectServiceApex(string projectServiceId) {
        ResponseWrapper rw;
        try{
            TriggerUtil.SkipAllTriggers();
            List<Id> psIds = new List<Id>();
            psIds.add(projectServiceId);
            List<ActionResponse> ar = ProjectServiceActionsHelper.DeleteProjectServices(psIds);
            rw = ResponseWrapper.getInstance(CONSTANTS.RESPONSE_STATE_SUCCESS, ar[0].ResponseMessage, 'SUCCESS');
        }
        catch(Exception e){
            rw = ResponseWrapper.getInstance(CONSTANTS.RESPONSE_STATE_ERROR, 'Unable to delete project service', 'ERROR');
        }
        return JSON.serialize(rw);
    }
    
    @AuraEnabled
    public static List<String> GetServiceCancelReasons()
    {
        List<String> options = new List<String>();
        Schema.DescribeFieldResult fieldResult = ProjectService__c.CancelReason__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for(Schema.PicklistEntry f : ple)
        {
            options.add(f.getLabel());
        }
        return options;
    }
    
    @AuraEnabled
    public static void CancelProjectService(String psId, String reason, String comment)
    {
        Id[] psIds = new List<Id>{ psId };
            List<ActionResponse> responses  = ProjectServiceActionsHelper.CancelProjectService(psIds, reason, comment);
        
        if(!responses[0].IsSuccessful){
            throw new AuraHandledException(responses[0].ResponseMessage);
        }
    }
    
    @AuraEnabled
    public static Id SaveAttachments(String psId, String PhotoAttributes,String attachmentID,string base64Data)
    {
        system.debug('SaveAttachments~~~attachmentID~~~'+attachmentID);
        if (attachmentID == '' || attachmentID == null ) {
            attachmentID = saveTheFile(psId, PhotoAttributes,attachmentID,base64Data);
        } else {
            appendToFile(attachmentID, PhotoAttributes,base64Data);
        }
        
        return Id.valueOf(attachmentID);
    }
    
    private static void appendToFile(Id fileId, String PhotoAttributes,string base64Data) {
        String[] PhotoAttributeVals = (String[])System.JSON.deserialize(PhotoAttributes,String[].class);
        base64Data = EncodingUtil.urlDecode(base64Data, 'UTF-8');
        Attachment a = [
            SELECT Id, Body
            FROM Attachment
            WHERE Id = :fileId
        ];
        
        String existingBody = EncodingUtil.base64Encode(a.Body);
        a.Body = EncodingUtil.base64Decode(existingBody + base64Data);
        
        update a;
    }
    
    @AuraEnabled
    public static Id saveTheFile(String psId, String PhotoAttributes,String attachmentID,string base64Data) {
        String[] PhotoAttributeVals = (String[])System.JSON.deserialize(PhotoAttributes,String[].class);
        system.debug('~~~~~'+PhotoAttributeVals[0]+'~~~~~'+PhotoAttributeVals[1]+'~~~~~'+PhotoAttributeVals[3]+'~~~~~'+PhotoAttributeVals[4]);
        Attachment myAttachment  = new Attachment();
        base64Data = EncodingUtil.urlDecode(base64Data, 'UTF-8');
        myAttachment.Name = PhotoAttributeVals[0];
        myAttachment.ContentType = PhotoAttributeVals[1];
        myAttachment.Body = EncodingUtil.base64Decode(base64Data);
        myAttachment.ParentId = PhotoAttributeVals[4];
        insert myAttachment;
        system.debug('saveTheFile::~~~~~'+myAttachment.id);
        return string.valueOf(myAttachment.id);
    }
    
    @AuraEnabled
    public static ProjServiceWrapper SaveProjServiceDetails(String projectServiceId,String ProjServValues,string attmntIDval,string DelAttmntIDval) {
        TriggerUtil.SkipAllTriggers();
        ProjServiceWrapper psw;
        
        
        try{
            ProjServiceWrapper ProjServ = (ProjServiceWrapper)System.JSON.deserialize(ProjServValues,ProjServiceWrapper.class);
            DeleteAttachmentsOnSave(DelAttmntIDval);
            
            string psQuery = QueryUtil.FetchQuery('ProjectService__c');
            psQuery += ' WHERE Id = \'' + projectServiceId + '\' order by Name';
            ProjectService__c ps = Database.query(psQuery);
            system.debug(projectServiceId+'~~'+ProjServValues);
            
            system.debug('~~ title '+ProjServ.ServiceTitle+'~worker~'+ProjServ.NumberOfWorkers+'~estMin~'+ProjServ.EstimatedMinutes);
            system.debug('~~ NumberOfDays~~ '+ProjServ.NumberOfDays+'~ResponsibleForExecution~'+ProjServ.ResponsibleForExecution+'~JobManualTemplate~'+ProjServ.JobManualTemplate);
            
            // ps.JobManualTemplate__C = ProjServ.JobManualTemplate;
            ps.JobManual__C = ProjServ.JobManualTemplate;
            
            //ps.JobManualURL__c = ProjServ.JobManualUrl;
            
            
            if(ProjServ.JobManualTemplate==CONSTANTS.JOB_MANUAL_STANDARD_TEMPLATE ){
                if(ps.JobManualURL__c==null){
                    ps.JobManualURL__c ='';
                }
                ps.JobManualFileName__c ='';
                ps.IncludeAutoGenManual__c = true;
                ps.isManualGenInProgress__c  = false;
            }
            else{
                ps.IncludeAutoGenManual__c = false;
            }
            
            if(ProjServ.JobManualTemplate==CONSTANTS.JOB_NOMANUAL_TEMPLATE)
            {
                ps.JobManualFileName__c ='';
                ps.isManualGenInProgress__c  = false;
            }
            
            psQuery = QueryUtil.FetchQuery('ProjectServiceAttribute__c');
            psQuery+= ' WHERE ProjectService__c = \'' + projectServiceId + '\' order by Name';
            list<ProjectServiceAttribute__c> psaL = Database.query(psQuery);
            ProjectServiceAttribute__c  objPSA;
            Map<Id, ProjectServiceAttribute__c> PSAMap = new Map<Id, ProjectServiceAttribute__c>(psaL);
            list<ProjectServiceAttribute__c> objPSAList = new list<ProjectServiceAttribute__c>();
            if(attmntIDval.trim()!=''){
                List<string> attrList = attmntIDval.split(',');
                system.debug('attrList++++++++++++++++++++'+ attrList);
                Set<String> attrSet = new Set<String>(attrList);
                list<Attachment> ObjList = [SELECT Id, Name, Description, OwnerId, ContentType, ParentId FROM Attachment where id in:attrSet];
                
                for(Attachment obj:ObjList){
                    delete [select id from attachment where parentid=:obj.ParentId and id !=: obj.id];
                    //Id psaID = PSANameMap.get(obj.ParentId);
                    objPSA = PSAMap.get(obj.ParentId);
                    objPSA.AttributeValue__c = string.valueOf(obj.Id) ;
                    objPSA.AttchFileName__c = obj.Name;
                    
                    GenerateURL.GenerateNewURL(obj.ParentId ,Obj.id);
                    objPSAList.add(objPSA);
                    
                    if(objPSA.Description__c ==CONSTANTS.MANUAL){
                        ps.isManualGenInProgress__c=true;
                    }
                }
            }
            
            
            list<PSAttributeWrapper> psaList = ProjServ.AvlPSA;
            for(PSAttributeWrapper psa: psaList){
                system.debug('  !!!!  ' +psa.Attributename + '~~ ' + psa.AttributeValue + '~~ ' + psa.AttributeType+ '~~ ' + psa.RecordID);
                //system.debug('  !!!!objPSA  ' +objPSA+ '~~ ' + temp);
                
                if(psa.AttributeType!='Photo'){
                    objPSA = PSAMap.get(psa.RecordID);
                    objPSA.AttributeValue__c =  psa.AttributeValue;
                    objPSAList.add(objPSA);
                }
                if(psa.Attributename==CONSTANTS.MANUAL && ProjServ.JobManualTemplate==CONSTANTS.JOB_NOMANUAL_TEMPLATE)
                {
                    objPSA = PSAMap.get(psa.RecordID);
                    objPSA.AttributeValue__c =null;
                    objPSA.AttachmentExt__c =null;
                    objPSA.AttachmentURL__c =null;
                    objPSA.AttchFileName__c =null;               
                    objPSAList.add(objPSA);
                }
                
                if(psa.Attributename==CONSTANTS.MANUAL && (ProjServ.JobManualTemplate==CONSTANTS.JOB_MANUAL_STANDARD_TEMPLATE || ProjServ.JobManualTemplate==CONSTANTS.JOB_NOMANUAL_TEMPLATE)){
                    //delete delete attribute
                    DeleteAttachmentHandlerEvt(psa.RecordID);
                    
                }
            }
            
            
            update objPSAList;
            update ps;
            
            
            psw= GetProjectService(projectServiceId);
            psw.isSuccess=true;
            psw.Message = 'Service details successfully saved. ';
        }
        catch(System.DmlException e) {
            psw = new ProjServiceWrapper();
            psw.isSuccess=false;
            psw.Message = e.getDmlMessage(0);
        }
        catch(exception ex){
            psw = new ProjServiceWrapper();
            psw.isSuccess=false;
            psw.Message = ex.getMessage();
        }
        
        return psw;
    }
    
    public static boolean DeleteAttachmentsOnSave(string RecordIDs) {
        try{
            System.debug('RecordIDs: '+RecordIDs);
            
            set<string> psaIDset = new set<string>();
            psaIDset.addAll(RecordIDs.split(','));
            
            list<ProjectServiceAttribute__c> pscaList = [SELECT Id,AttributeValue__c,projectservice__c,AttachmentExt__c, AttachmentURL__c, AttchFileName__c FROM ProjectServiceAttribute__c where id IN :psaIDset];
            
            for(ProjectServiceAttribute__c  obj: pscaList){
                Set<String> s1 = new Set<String>();
                s1.add(string.valueof(obj.AttributeValue__c).substringBefore('='));
                
                List<Attachment> a = [select id from attachment where id =:string.valueof(obj.AttributeValue__c).substringBefore('=')];
                if(a.size() > 0){
                    delete a;
                }
                
                obj.AttributeValue__c = null;
                obj.AttachmentExt__c = null;
                obj.AttachmentURL__c = null;
                obj.AttchFileName__c = null;
            }
            update pscaList;
            return true;
        }
        catch(exception ex){
            throw ex;
        }
    }
    
    @AuraEnabled
    public static Map<String,Object> GetCancelServiceDataset(String projectServiceId){
        if(String.isBlank(projectServiceId)){
            throw new AuraHandledException('The project service identifier is required.');
        }
        
        Map<String,Object> ds = new Map<String, Object>();
        ProjectService__c  svc = [SELECT Title__c, Project__c, Status__c FROM ProjectService__c WHERE Id=:projectServiceId];
        if(svc == null){
            throw new AuraHandledException('The project service not found.');
        }
        ds.put('projectId', svc.Project__c);
        ds.put('title', svc.Title__c);
        ds.put('status', svc.Status__c);
        ds.put('reasons', GetServiceCancelReasons());
        
        return ds;
    }
    
}