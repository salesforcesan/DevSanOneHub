public with sharing class LightningSurveyQuestionsControllerv2 {
    
    @AuraEnabled
    public static List<QuestionWrapper> getAvailableSurveyQuestions(string questiontext, string questiontype, boolean targetquestion, string recordid) {
        try {
            string projectserviceid = '';
            string serviceid = '';
            ProjectService__c ps;
            Id recid = Id.ValueOf(recordid);
            Boolean fromProjectService = false;
            
            system.debug('~~~~~recid~~~~' + String.Valueof(recid.getSObjectType()));
            
            if (String.Valueof(recid.getSObjectType()).containsignorecase('projectservice__c')) {
                fromProjectService = true;
                projectserviceid = recordid;
            } else if (String.Valueof(recid.getSObjectType()).containsignorecase('service__c')) {
                serviceid = recordid;
            }
            
            if (fromProjectService) {
                ps = [Select Service__r.LimitQuestionstoFamily__c, Service__r.ServiceFamily__c from ProjectService__c  where id = :projectserviceid LIMIT 1];
            }
            
            List<QuestionWrapper> customquestions = new List<QuestionWrapper>();
            
            Map<Question__c, List<QuestionDefinedResponse__c>> mapQuestionInfo = new Map<Question__c, List<QuestionDefinedResponse__c>>();
            
            
            String baseQuery = 'SELECT Id, Name, Active__c, Description__c, IsQuestionVisibleToClient__c, ItemQuestion__c, OneHubQuestionId__c, QuestionText__c, ' ;
            baseQuery += ' QuestionType__c, ReplaceByOneHubQuestionId__c, TargetType__c, DefinedResponseCount__c, ExceptionQuestion__c ';
            baseQuery += ' FROM Question__c WHERE Active__c = true ';
            
            system.debug('~~~' + baseQuery);
            
            //OH2-1866
            if (fromProjectService) {
                
                Set<ID> accountIds = new Set<ID>();
                List<ProjectAccount__c> projectAccountList = [SELECT Id, Account__c from ProjectAccount__c where Project__c in (select Project__c from ProjectService__c where id = :projectserviceid)];
                for (ProjectAccount__c pa : projectAccountList) {
                    accountIds.add(pa.Account__c);
                }
                
                if (accountIds.size() > 0 ) {
                    baseQuery += 'AND (Account__c = null OR Account__c IN: accountIds ) ';
                    //baseQuery += 'AND (Account__c = null OR Account__c in (\'0011100001KmoDbAAJ\')) ';
                }
                
                system.debug('~~accountIds~~' + accountIds);
            }
            
            
            if (fromProjectService) {
                if (ps.Service__r.LimitQuestionstoFamily__c == true ) {
                    baseQuery += 'AND Id IN (Select Question__c FROM ServiceFamilyQuestions__c WHERE ServiceFamily__c  = \'' + ps.Service__r.ServiceFamily__c + '\') ';
                }
            }
            SurveyState surveyStateDef =  fromProjectService 
                ? SurveyState.fromProjectBuilder(projectserviceid)
                : SurveyState.fromServiceBuilder(serviceid);
            
            if (questiontext != null && questiontext != '') {
                baseQuery += ' AND QuestionText__c like \'%' + questiontext + '%\' ';
                baseQuery += ' AND (QuestionText__c like \'%' + questiontext + '%\'  OR Name like \'%' + questiontext + '%\') ';
            }
            
            if (questiontype != null && questiontype != '' && questiontype.toLowerCase() != 'none') {
                baseQuery += ' AND QuestionType__c = \'' + questiontype + '\'';
            }
            
            baseQuery += ' AND ItemQuestion__c =  ' + targetquestion ;
            
            List<Question__c> questions = Database.query(baseQuery);
            
            Map<Id, Question__c> mapQuestions = new Map<Id, Question__c>(questions);
            Set<Id> setQuestionIds = mapQuestions.keySet();
            
            system.debug('~~2~~' + baseQuery); 
            system.debug('~~setQuestionIds~~' + setQuestionIds);
            
            List<QuestionDefinedResponse__c> questionDefinedResponses = [SELECT Id, Question__c, DefinedResponseOrder__c,
                                                                         DefinedResponseText__c, OneHubAnswerId__c, Exception__r.ExceptionCode__c, Exception__r.ExceptionCodeDesc__c  FROM QuestionDefinedResponse__c
                                                                         WHERE Question__c in :setQuestionIds];
            
            Map<Id, List<QuestionDefinedResponse__c>> mapqdr = new Map<Id, List<QuestionDefinedResponse__c>>();
            
            for (QuestionDefinedResponse__c qdr : questionDefinedResponses ) {
                List<QuestionDefinedResponse__c> qdrList = mapqdr.get(qdr.Question__c);
                if (qdrList == null) {
                    qdrList = new List<QuestionDefinedResponse__c> {qdr};
                        } else {
                            qdrList.add(qdr);
                        }
                mapqdr.put(qdr.Question__c, qdrList);
                
            }
            
            for (Question__c question : questions) {
                List<DefinedResponseWrapper> drList = new List<DefinedResponseWrapper>();
                if (question.DefinedResponseCount__c > 0) {
                    for (QuestionDefinedResponse__c qdr : mapqdr.get(question.Id)) {
                        DefinedResponseWrapper dr = new DefinedResponseWrapper();
                        
                        dr.DefinedResponseId = qdr.Id;
                        if (qdr.Exception__c != null) {
                            dr.DefinedResponseText = qdr.Exception__r.ExceptionCodeDesc__c;
                        } else {
                            dr.DefinedResponseText = qdr.DefinedResponseText__c;
                        }
                        dr.ExceptionCode = qdr.Exception__r.ExceptionCode__c;
                        dr.DefinedResponseOrder = Integer.ValueOf(qdr.DefinedResponseOrder__c);
                        dr.ProjectServiceQuestionDefinedResponseId = null;
                        drList.add(dr);
                    }
                }
                
                QuestionWrapper customquestion = new QuestionWrapper();
                customquestion.Active = surveyStateDef.isQuestionValidToAdd(question.Id, question.ExceptionQuestion__c);
                customquestion.QuestionId = question.Id;
                customquestion.QuestionText = question.QuestionText__c;
                customquestion.ItemQuestion = question.ItemQuestion__c;
                customquestion.QuestionTitle = question.Name;
                customquestion.QuestionType = question.QuestionType__c;
                customquestion.IsExceptionQuestion = question.ExceptionQuestion__c;
                customquestion.DefinedResponseCount = Integer.ValueOf(question.DefinedResponseCount__c);
                customquestion.IsQuestion = true;
                customquestion.DefinedResponses = drList;
                
                
                customquestions.add(customquestion);
            }
            
            return customquestions;
        } catch (Exception ex) {
            throw new System.AuraHandledException(ex.getMessage());
        }
    }
    
    private static List<QuestionWrapper> SetItemQuestionFlags(string firstItemQuestionId, string lastItemQuestionId, List<QuestionWrapper> customquestions) {
        
        for (QuestionWrapper qw : customquestions) {
            if (qw.QuestionId == firstItemQuestionId) {
                qw.IsFirstItemQuestion = true;
            }
            
            if (qw.QuestionId == lastItemQuestionId) {
                qw.IsLastItemQuestion = true;
            }
        }
        
        return customquestions;
    }
    
    @AuraEnabled
    public static string getServiceApex(string serviceid) {
        
        service__c ps = [Select Id, Name FROM Service__c WHERE Id = :serviceid];
        
        String psstring = JSON.serialize(ps);
        String psstringsansuuc = psstring.replace('__c', '');
        
        String psstringsamsns = psstringsansuuc.replace(CONSTANTS.CURRENTNAMESPACEPREFIX, '');
        
        return psstringsamsns;
    }
    
    @AuraEnabled
    public static string getServiceQuestionsApex(string serviceid) {
        
        try {
            
            if (serviceid == null || serviceid == '') {
                return '';
            }
            List<QuestionWrapper> customquestions = new List<QuestionWrapper>();
            
            Map<Question__c, List<QuestionDefinedResponse__c>> mapQuestionInfo = new Map<Question__c, List<QuestionDefinedResponse__c>>();
            
            
            List<ServiceQuestion__c> servicequestions = [SELECT Id, Question__c, QuestionHint__c, HintLock__c, Question__r.Active__c, Question__r.Description__c, Question__r.Name,
                                                         Question__r.IsQuestionVisibleToClient__c, Question__r.ItemQuestion__c, MinValue__c, MaxValue__c,
                                                         Question__r.OneHubQuestionId__c, Question__r.QuestionText__c, Question__r.QuestionType__c,
                                                         Question__r.ReplaceByOneHubQuestionId__c, Question__r.TargetType__c, Question__r.DefinedResponseCount__c,
                                                         CanRemove__c, QuestionNumber__c, JumpToAction__c, Question__r.ExceptionQuestion__c, Optional__c, isactive__c,
                                                         QuestionIndentation__c, ParentServiceQuestion__c, QuestionIndentationLevel__c
                                                         FROM ServiceQuestion__c WHERE Service__c = :serviceid
                                                         ORDER BY QuestionNumber__c
                                                        ];
            
            Map<ID, ServiceQuestionRule__c> sqrsMap = new Map<ID, ServiceQuestionRule__c>();
            Set<ID> ParentIds = new Set<ID>();
            
            List<ServiceQuestionRule__c> sqrs = new List<ServiceQuestionRule__c>([Select ServiceQuestion__c, Id, Name, ParentServiceQuestion__c, Operator__c, ServiceQuestionText__c,
                                                                                  ParentServiceQuestionText__c, DefinedResponseValue__c, value__c, DefinedResponseValueText__c, ParentServiceQuestionType__c
                                                                                  FROM ServiceQuestionRule__c
                                                                                  WHERE ServiceQuestion__r.Service__c = : serviceid]);
            
            Map<String, List<ServiceQuestionRule__c>> sqRuleMap = new Map<String, List<ServiceQuestionRule__c>>();
            
            for (ServiceQuestionRule__c sqr : sqrs) {
                
                List<ServiceQuestionRule__c> lstServiceQuestionRule = new List<ServiceQuestionRule__c>();
                if (sqRuleMap.containsKey(sqr.ServiceQuestion__c)) {
                    lstServiceQuestionRule.addAll(sqRuleMap.get(sqr.ServiceQuestion__c));
                }
                
                lstServiceQuestionRule.add(sqr);
                sqRuleMap.put(sqr.ServiceQuestion__c, lstServiceQuestionRule);
                
                
                //sqrsMap.put(sqr.ServiceQuestion__c,idKey);
                ParentIds.add(sqr.ParentServiceQuestion__c);
            }
            
            Map<Id, Integer> mapQuestionNumber = new Map<Id, Integer>();
            Map<Id, ServiceQuestion__c> mapQuestions = new Map<Id, ServiceQuestion__c>();
            for (ServiceQuestion__c sq : servicequestions ) {
                Integer qno = sq.QuestionNumber__c == null ? 0 : Integer.ValueOf(sq.QuestionNumber__c);
                mapQuestionNumber.put(sq.Question__c, qno);
                mapQuestions.put(sq.Id, sq);
            }
            
            Set<Id> setQuestionIds = mapQuestions.keySet();
            
            
            List<ServiceQuestionDefinedResponse__c> servicequestionDefinedResponses = [SELECT Id, ServiceQuestion__c, QuestionDefinedResponse__c,
                                                                                       QuestionDefinedResponse__r.DefinedResponseOrder__c, DefinedResponseText__c,
                                                                                       QuestionDefinedResponse__r.OneHubAnswerId__c, CanRemove__c, JumpToQuestion__c, EndOfQuestions__c,
                                                                                       ServiceQuestion__r.QuestionNumber__c, ServiceQuestion__r.Question__r.ItemQuestion__c, ServiceQuestion__r.Question__c,
                                                                                       JumpToAction__c, QuestionDefinedResponse__r.Exception__r.ExceptionCode__c, ServiceQuestion__r.Question__r.QuestionType__c,
                                                                                       IsActive__c FROM ServiceQuestionDefinedResponse__c
                                                                                       WHERE ServiceQuestion__c in :setQuestionIds ORDER BY QuestionDefinedResponse__r.DefinedResponseOrder__c];
            
            
            Map<Id, List<ServiceQuestionDefinedResponse__c>> mappsqdr = new Map<Id, List<ServiceQuestionDefinedResponse__c>>();
            
            
            for (ServiceQuestionDefinedResponse__c sqdr : servicequestionDefinedResponses ) {
                List<ServiceQuestionDefinedResponse__c> sqdrList = mappsqdr.get(sqdr.ServiceQuestion__c);
                if (sqdrList == null) {
                    sqdrList = new List<ServiceQuestionDefinedResponse__c> {sqdr};
                        } else {
                            sqdrList.add(sqdr);
                        }
                mappsqdr.put(sqdr.ServiceQuestion__c, sqdrList);
            }
            
            String firstItemQuestionId = '';
            String lastItemQuestionId = '';
            
            integer sqIndex = 0;
            
            
            List<ServiceQuestionRule__c> sqRuleList = [select ServiceQuestion__c, Id, Name, ParentServiceQuestion__c,
                                                       Operator__c, ServiceQuestionText__c,
                                                       ParentServiceQuestionText__c, DefinedResponseValue__c, value__c,
                                                       DefinedResponseValueText__c,
                                                       ParentServiceQuestionType__c
                                                       from ServiceQuestionRule__c
                                                       where ParentServiceQuestion__c in: setQuestionIds];
            
            Map<Id, Set<String>> serviceQuestionRuleMap = new Map<Id, Set<String>>();
            
            Map<string, List<ServiceQuestionRuleWrapper>> serviceQuestionRuleMapList = new Map<string, List<ServiceQuestionRuleWrapper>>();
            
            for (ServiceQuestionRule__c rule : sqRuleList) {
                
                Set<String> ruleList = serviceQuestionRuleMap.get(rule.ParentServiceQuestion__c);
                
                
                
                List<ServiceQuestionRuleWrapper> psqRuleList = serviceQuestionRuleMapList.get(rule.ParentServiceQuestion__c + rule.Value__c);
                
                if (ruleList == null) {
                    ruleList = new Set<String> {rule.Value__c};
                        } else {
                            ruleList.add(rule.Value__c);
                        }
                
                ServiceQuestionRuleWrapper sqrWrapper = new ServiceQuestionRuleWrapper(rule);
                if (psqRuleList == null) {
                    psqRuleList = new List<ServiceQuestionRuleWrapper> {sqrWrapper};
                        } else {
                            psqRuleList.add(sqrWrapper);
                        }
                
                serviceQuestionRuleMap.put(rule.ParentServiceQuestion__c, ruleList);
                serviceQuestionRuleMapList.put(rule.ParentServiceQuestion__c + rule.Value__c, psqRuleList);
            }
            
            for (ServiceQuestion__c sq : servicequestions ) {
                
                List<DefinedResponseWrapper> drList = new List<DefinedResponseWrapper>();
                Set<String> ruleList = serviceQuestionRuleMap.get(sq.ID);
                
                if (sq.Question__r.DefinedResponseCount__c > 0) {
                    for (ServiceQuestionDefinedResponse__c sqdr : mappsqdr.get(sq.Id)) {
                        
                        DefinedResponseWrapper dr = new DefinedResponseWrapper();
                        
                        dr.DefinedResponseId = sqdr.QuestionDefinedResponse__c;
                        dr.DefinedResponseText = sqdr.DefinedResponseText__c;
                        dr.DefinedResponseOrder = Integer.ValueOf(sqdr.QuestionDefinedResponse__r.DefinedResponseOrder__c);
                        dr.ProjectServiceQuestionDefinedResponseId = sqdr.Id;
                        dr.CanRemove = sqdr.CanRemove__c == null || sqdr.CanRemove__c == false ? false : true;
                        
                        dr.JumpToQuestion = sqdr.JumpToQuestion__c == null || String.ValueOf(sqdr.JumpToQuestion__c)
                            == '' ? sqdr.JumpToAction__c : sqdr.JumpToQuestion__c;
                        dr.EndOfQuestions = sqdr.EndOfQuestions__c;
                        dr.ExceptionCode =  sqdr.QuestionDefinedResponse__r.Exception__r.ExceptionCode__c;
                        dr.Active = sqdr.isActive__c;
                        
                        dr.RuleUsedInProjectServiceQuestion = serviceQuestionRuleMapList.get(sq.Id + sqdr.DefinedResponseText__c);
                        dr.UsedForRule = (sqdr.isActive__c == true && (ruleList != null && ruleList.contains(sqdr.DefinedResponseText__c))) ? true : false;
                        
                        
                        dr.JumpToQuestionNumber = mapQuestionNumber.get(sqdr.JumpToQuestion__c);
                        //dr.AllowedJumpToQuestions = mapAllowedJumpToQuestions.get(sqdr.Id);
                        drList.add(dr);
                    }
                    
                }
                
                QuestionWrapper customquestion = new QuestionWrapper();
                
                
                customquestion.ID = sq.Id;
                customquestion.ParentID = sq.ParentServiceQuestion__c;
                
                customquestion.QuestionId = sq.Question__c;
                customquestion.QuestionTitle = sq.Question__r.Name;
                customquestion.MinValue = string.ValueOf(sq.MinValue__c);
                customquestion.MaxValue = string.ValueOf(sq.MaxValue__c);
                customquestion.HintQuestion = string.ValueOf(sq.QuestionHint__c);
                customquestion.HintLock = Boolean.ValueOf(sq.HintLock__c);
                customquestion.QuestionText = sq.Question__r.QuestionText__c;
                customquestion.ItemQuestion = sq.Question__r.ItemQuestion__c;
                customquestion.JumpToAction = sq.JumpToAction__c;
                customquestion.QuestionType = sq.Question__r.QuestionType__c;
                customquestion.DefinedResponseCount = Integer.ValueOf(sq.Question__r.DefinedResponseCount__c);
                customquestion.DefinedResponses = drList;
                customquestion.ProjectServiceQuestionId = sq.Id;
                customquestion.ServiceQuestion = true;
                customquestion.CanRemove = sq.CanRemove__c;
                customquestion.QuestionNumber = Integer.ValueOf(sq.QuestionNumber__c);
                customquestion.IsServiceQuestion = true;
                customquestion.IsExceptionQuestion = sq.Question__r.ExceptionQuestion__c;
                
                customquestion.QuestionIndentation = sq.QuestionIndentation__c;
                
                customquestion.QuestionIndentationSize = String.isBlank(sq.QuestionIndentation__c) ? 1 : sq.QuestionIndentation__c.split('\\.').size();
                customquestion.Optional = sq.Optional__c;
                
                customquestion.AllowedJumpToActions = new List<UISelectWrapper>();
                customquestion.AllowedJumpToActions.add(new UISelectWrapper (CONSTANTS.QUESTIONJUMP_CONTINUE, CONSTANTS.QUESTIONJUMP_CONTINUE));
                customquestion.AllowedJumpToActions.add(new UISelectWrapper (CONSTANTS.QUESTIONJUMP_RETURN, CONSTANTS.QUESTIONJUMP_RETURN));
                
                if (customquestion.QuestionType == CONSTANTS.QUESTIONTYPE_SINGLE_SELECT ||
                    customquestion.QuestionType == CONSTANTS.QUESTIONTYPE_YESNO) {
                        customquestion.AllowedJumpToActions.add(new UISelectWrapper (CONSTANTS.QUESTIONJUMP_BRANCH, CONSTANTS.QUESTIONJUMP_BRANCH));
                    }
                
                
                if (customquestion.ItemQuestion) {
                    if (firstItemQuestionId == null || firstItemQuestionId == '') {
                        firstItemQuestionId = customquestion.QuestionId;
                    }
                    lastItemQuestionId = customquestion.QuestionId;
                }
                
                customquestion.QuestionIndentationLevel = Integer.valueOf(sq.QuestionIndentationLevel__c);
                customquestion.HasChild = ParentIds.contains(customquestion.ID);
                
                if (sqRuleMap.containsKey(sq.Id)) {
                    
                    //To get parent id from service question
                    List<ServiceQuestionRule__c> serviceQuestionRuleList = sqRuleMap.get(sq.Id);
                    if (serviceQuestionRuleList != null && serviceQuestionRuleList.size() > 0) {
                        
                        List<ServiceQuestionRuleWrapper> serviceQuestionRuleWrapperList = new List<ServiceQuestionRuleWrapper>();
                        List<String> ruleValueTest = new List<String>();
                        
                        for (ServiceQuestionRule__c serviceQuestionRule : serviceQuestionRuleList) {
                            
                            ServiceQuestionRuleWrapper sqr = new ServiceQuestionRuleWrapper(serviceQuestionRule);
                            
                            serviceQuestionRuleWrapperList.add(sqr);
                            ruleValueTest.add(sqr.RuleText);
                        }
                        
                        if (serviceQuestionRuleWrapperList.size() > 0) {
                            customquestion.ServiceQuestionRule = serviceQuestionRuleWrapperList[0];
                            customquestion.ServiceQuestionRule.RuleValueText = ruleValueTest;
                            customquestion.ServiceQuestionRuleList = serviceQuestionRuleWrapperList;
                            customquestion.ParentID = serviceQuestionRuleWrapperList[0].ParentServiceQuestion;
                        }
                        
                    }
                }
                
                
                
                /*
if (serviceQuestionRule != null){
customquestion.ServiceQuestionRule = new ServiceQuestionRuleWrapper(serviceQuestionRule);
customquestion.ParentID = customquestion.ServiceQuestionRule.ParentServiceQuestion;
}
*/
                
                customquestion.ParentID = customquestion.ParentID == null ? '' : customquestion.ParentID;
                
                customquestions.add(customquestion);
                sqIndex++;
            }
            
            customquestions = SetItemQuestionFlags(firstItemQuestionId, lastItemQuestionId, customquestions);
            
            ResponseWrapper rw = ResponseWrapper.getInstance(CONSTANTS.RESPONSE_STATE_SUCCESS, 'Successfully retrieved the questions', customquestions);
            
            String returnString = JSON.serialize(rw);
            
            return returnString;
            
        }
        
        catch (Exception ex) {
            throw new System.AuraHandledException(ex.getMessage());
            
        }
        
    }
    
    
    @AuraEnabled
    public static string addServiceQuestion(string serviceid, string questionid) {
        
        try {
            String targetGroupQuestionId = '';
            if (serviceid == null || serviceid == '' || questionid == null || questionid == '') {
                return '';
            }
            List<Question> customquestions = new List<Question>();
            
            Question__c question;
            //oh2962, OH-3447
            List<Question__c> questions = [Select Id, ExceptionQuestion__c, QuestionHint__c, ItemQuestion__c, IsQuestionVisibleToClient__c, QuestionType__c
                                           from Question__c
                                           WHERE Id = :questionid LIMIT 1];
            if (!questions.isEmpty()) {
                question = questions[0];
                
            }
            Boolean isItemQuestion = question.ItemQuestion__c;
            Boolean isExceptionQuestion = question.ExceptionQuestion__c;
            
            //Check if this is an exception question and if another exception question already exists
            if (isExceptionQuestion) {
                
                List<ServiceQuestion__c> sqs = [SELECT Id from ServiceQuestion__c WHERE Service__c = :serviceid
                                                and Question__r.ExceptionQuestion__c = true LIMIT 1];
                
                if (!sqs.isEmpty()) {
                    throw new CustomException('Error adding question: Only one exception question can be added to a survey.');
                }
            }
            
            // Check if the question is an item question, if yes, then add the question
            // next to the previous item question if one exists
            
            Decimal maxqno = 0;
            
            if (isItemQuestion) {
                List<ServiceQuestion__c> tgqs = [Select Id, name from ServiceQuestion__c
                                                 where Service__c = :serviceid AND
                                                 Question__r.Name = :CONSTANTS.QUESTIONTYPE_TARGET_GROUP Limit 1];
                if (!tgqs.isEmpty()) {
                    targetGroupQuestionId = tgqs[0].Id;
                }
                
                //Check if there are item questions in the survey
                List<ServiceQuestion__c> sqs = [Select Id, QuestionNumber__c FROM ServiceQuestion__c WHERE
                                                Service__c = :serviceid AND Question__r.ItemQuestion__c = true order by QuestionNumber__c DESC LIMIT 1];
                if (sqs.size() > 0) {
                    maxqno = sqs[0].QuestionNumber__c;
                } else {
                    //First Item Question. Add Target Group also
                    maxqno = GetLastServiceQuestionNumber(serviceid);
                    List<Question__c> tgs = [Select Id, Name from Question__c WHERE Name = : CONSTANTS.QUESTIONTYPE_TARGET_GROUP];
                    if (tgs.isEmpty()) {
                        throw new System.AuraHandledException('Target Group Question missing. Contact Administrator');
                    }
                    
                    //Insert Target group question here
                    ServiceQuestion__c sqObj = new ServiceQuestion__c();
                    sqObj.Service__c = serviceid;
                    sqObj.Question__c = tgs[0].Id;
                    sqObj.CanRemove__c = false;
                    sqObj.QuestionHint__c = question.QuestionHint__c;
                    sqObj.QuestionNumber__c = maxqno + 1;
                    sqObj.Optional__c = false;
                    //oh2962: service visibility to client
                    sqObj.IsVisibleToClient__c = question.IsQuestionVisibleToClient__c;
                    insert sqObj;
                    targetGroupQuestionId = sqObj.Id;
                    maxqno = maxqno + 1;
                }
                
            }
            
            if (maxqno == 0) {
                List<ServiceQuestion__c> sqnos = [Select Id, QuestionNumber__c FROM ServiceQuestion__c WHERE
                                                  Service__c = :serviceid order by QuestionNumber__c DESC LIMIT 1];
                
                if (sqnos != null && sqnos.size() > 0) {
                    maxqno = sqnos[0].QuestionNumber__c;
                }
                
            }
            
            Decimal newqno = maxqno + 1;
            
            //New question question number is maxqno + 1. Check if there are existing questions in PSQ
            //with the same question number and increase them by 1
            //We are doing this as item questions now have to be grouped together
            
            List<ServiceQuestion__c> sqs = [Select Id, QuestionNumber__c FROM ServiceQuestion__c WHERE
                                            Service__c = :serviceid and QuestionNumber__c >= :newqno];
            
            for (ServiceQuestion__c sq : sqs) {
                sq.QuestionNumber__c = sq.QuestionNumber__c + 1;
                
            }
            update sqs;
            
            ServiceQuestion__c sqObj = new ServiceQuestion__c();
            sqObj.Service__c = serviceid;
            sqObj.Question__c = questionid;
            sqObj.CanRemove__c = false;
            sqObj.QuestionHint__c = question.QuestionHint__c;
            sqObj.QuestionNumber__c = newqno;
            sqObj.Optional__c = false;
            sqObj.JumpToAction__c = CONSTANTS.QUESTIONJUMP_CONTINUE;
            //oh2962: service visibility to client
            sqObj.IsVisibleToClient__c = question.IsQuestionVisibleToClient__c;
            if (isItemQuestion) {
                sqObj.ParentServiceQuestion__c = targetGroupQuestionId;
            }
            insert sqObj;
            
            ServiceQuestionDefinedResponse__c sqdefResp;
            List<ServiceQuestionDefinedResponse__c> sqdfrList = new List<ServiceQuestionDefinedResponse__c>();
            
            List<QuestionDefinedResponse__c> qDefResList = [ SELECT Id, Name, DefinedResponseOrder__c, DefinedResponseText__c
                                                            FROM QuestionDefinedResponse__c where Question__c = :questionid];
            for (QuestionDefinedResponse__c qdr : qDefResList ) {
                sqdefResp =  new ServiceQuestionDefinedResponse__c();
                sqdefResp.ServiceQuestion__c = sqObj.id;
                sqdefResp.QuestionDefinedResponse__c = qdr.Id;
                sqdefResp.EndOfQuestions__c = false;
                sqdefResp.JumpToAction__c = 'CONTINUE';
                sqdfrList.add(sqdefResp);
            }
            
            insert sqdfrList;
            setQuestionIndentation(serviceid);
            
            return  getServiceQuestionsApex(serviceid);
            
        } catch (Exception ex) {
            throw new System.AuraHandledException(ex.getMessage());
        }
    }
    
    
    private static Integer GetLastServiceQuestionNumber(string serviceid) {
        
        Integer maxqno = 0;
        
        List<ServiceQuestion__c> sqnos = [Select Id, QuestionNumber__c FROM ServiceQuestion__c WHERE
                                          Service__c = :serviceid order by QuestionNumber__c DESC LIMIT 1];
        
        if (sqnos != null && sqnos.size() > 0) {
            maxqno = Integer.valueof(sqnos[0].QuestionNumber__c);
        }
        return maxqno;
        
    }
    
    @AuraEnabled
    public static string removeServiceQuestionApex(string servicequestionid) {
        
        try {
            //Need to change the below method to remove serviceid
            //serviceid can be retrieved by questionid
            List<ID> allsqs = GetAllChildren('', servicequestionid);
            
            Set<Id> sqids = new Set<Id>(allsqs);
            sqids.add(servicequestionid);
            
            List<ServiceQuestion__c> sqs = [SELECT Id, name, Service__c, Question__c, ItemQuestion__c
                                            from ServiceQuestion__c WHERE Id IN :sqids];
            
            string serviceid;
            
            if (!sqs.isEmpty()) {
                serviceid = sqs[0].Service__c;
                String sqId = sqs[0].Id;
                
                //Check if there are any question rules
                List<ServiceQuestionRule__c> sqrules = [Select Id, Name from ServiceQuestionRule__c WHERE ParentServiceQuestion__c in :sqids];
                if (!sqrules.isEmpty()) {
                    delete sqrules;
                }
                
                delete sqs;
                
                
                //Query to check if there is any target group
                List<ServiceQuestion__c> sqGroupQuestionList = [Select Id, QuestionNumber__c, QuestionText__c, ItemQuestion__c
                                                                FROM ServiceQuestion__c
                                                                WHERE Service__c = :serviceid
                                                                AND Question__r.ItemQuestion__c = true];
                
                if (sqGroupQuestionList == null || sqGroupQuestionList.size() == 0) {
                    List<ServiceQuestion__c> sqParentTargetGroupList = [Select Id, QuestionNumber__c, QuestionText__c, ItemQuestion__c
                                                                        FROM ServiceQuestion__c
                                                                        WHERE Service__c = :serviceid
                                                                        AND Question__r.QuestionText__c = : CONSTANTS.QUESTIONTYPE_TARGET_GROUP
                                                                        Limit 1];
                    
                    if (sqParentTargetGroupList != null) {
                        delete sqParentTargetGroupList;
                    }
                }
                
                ResetServiceQuestionNumber(serviceid);
                setQuestionIndentation(serviceid);
                
            }
            
            
            return '';
            
        } catch (Exception ex) {
            throw new System.AuraHandledException(ex.getMessage());
        }
        
    }
    
    
    @AuraEnabled
    public static void deleteServiceQuestionRule(string serviceId , string sqId) {
        List<ServiceQuestionRule__c> lstsqr = [select Id, name, Operator__c, ParentServiceQuestion__c, ServiceQuestion__c, value__c
                                               FROM ServiceQuestionRule__c
                                               WHERE  ServiceQuestion__c = :sqId];
        if (lstsqr.size() > 0) {
            delete lstsqr;
        }
    }
    
    private static void ResetServiceQuestionNumber(String serviceId) {
        List<ServiceQuestion__c> sqs = [SELECT Id, QuestionNumber__c, QuestionIndentation__c , ParentServiceQuestion__c
                                        FROM ServiceQuestion__c WHERE Service__c = :serviceid
                                        ORDER BY QuestionNumber__c];
        
        ResetServiceQuestionNumber(sqs);
        
    }
    
    private static void ResetServiceQuestionNumber(List<ServiceQuestion__c> sqs) {
        Integer qno = 1;
        for (ServiceQuestion__c sq : sqs) {
            sq.QuestionNumber__c = qno;
            qno++;
            
        }
        update sqs;
    }
    
    @AuraEnabled
    public static void addServiceQuestionRule(string serviceId , string sqId, string psqId, string sop, string drl) {
        try {
            boolean isUpdate = false;
            
            //SObject row was retrieved via SOQL without querying the requested field: ServiceQuestionRule__c.DefinedResponseValue__c
            
            List<ServiceQuestionRule__c> sqrList = new List<ServiceQuestionRule__c>();
            List<String> parsedDrl = (List<String>) JSON.deserialize(drl, List<String>.class);
            List<ServiceQuestionRule__c> lstsqr = [SELECT Id, name, Operator__c, ParentServiceQuestion__c, ServiceQuestion__c , DefinedResponseValue__c, DefinedResponseValueText__c
                                                   FROM ServiceQuestionRule__c
                                                   WHERE  ServiceQuestion__c = :sqId ]; //Limit 1];
            
            if (lstsqr != null && lstsqr.size() > 0) {
                delete lstsqr;
            }
            
            for (String drls : parsedDrl ) {
                
                ServiceQuestionRule__c sqr = new ServiceQuestionRule__c();
                sqr.ServiceQuestion__c = string.valueOf(sqId);
                sqr.ParentServiceQuestion__c = string.valueOf(psqId);
                sqr.Operator__c = string.valueOf(sop);
                //sqr.DefinedResponseValue__c = string.valueOf(drls);
                sqr.Value__c = string.valueOf(drls);
                sqrList.add(sqr);
                
            }
            
            insert sqrList;
            
            // To update parent question id in Service Question Object
            ServiceQuestion__c ServiceQuestion = [SELECT Id, ParentServiceQuestion__c, QuestionIndentation__c, QuestionNumber__c, Service__c
                                                  FROM ServiceQuestion__c
                                                  where  Id = :sqId];
            
            if ((ServiceQuestion != null) && (ServiceQuestion.ParentServiceQuestion__c == psqId)) {
                isUpdate = true;
            }
            
            if (!isUpdate) {
                ServiceQuestion.ParentServiceQuestion__c = psqId;
                update ServiceQuestion;
                
                // To set auto number and indentation
                RearrangeOrder(serviceId, string.valueOf(sqId), string.valueOf(psqId), false);
            }
        } catch (DMLException ex) {
            throw new System.AuraHandledException(ex.getDmlMessage(0));
        } catch (Exception ex) {
            throw new System.AuraHandledException(ex.getMessage());
        }
    }
    
    @AuraEnabled
    public static string saveServiceQuestion(string questionWrapperInput) {
        try {
            string serviceid;
            QuestionWrapper question = (QuestionWrapper ) JSON.deserialize(questionWrapperInput, QuestionWrapper.class);
            
            set<Id> sqdrIds = new Set<Id>();
            map<Id, DefinedResponseWrapper> mappsqdrwrapper = new map<Id, DefinedResponseWrapper>();
            
            for (DefinedResponseWrapper dr : question.DefinedResponses) {
                if (dr.ProjectServiceQuestionDefinedResponseId != '-1') {
                    sqdrIds.add(dr.ProjectServiceQuestionDefinedResponseId);
                    mappsqdrwrapper.put(dr.ProjectServiceQuestionDefinedResponseId, dr);
                }
            }
            
            ServiceQuestion__c sq = [Select Id, Name, JumpToAction__c, Service__c, MinValue__c, MaxValue__c, QuestionHint__c, HintLock__c
                                     from ServiceQuestion__c
                                     WHERE
                                     Id = :question.ProjectServiceQuestionId LIMIT 1];
            
            if (sq != null) {
                sq.QuestionHint__c = string.ValueOf(question.HintQuestion);
                sq.HintLock__c = Boolean.ValueOf(question.HintLock);
            }
            
            
            if (question.QuestionType == CONSTANTS.QUESTIONTYPE_NUMBER) {
                
                sq.MinValue__c = String.isBlank(question.MinValue) ? null : Integer.ValueOf(question.MinValue);
                sq.MaxValue__c = String.isBlank(question.MaxValue) ? null : Integer.ValueOf(question.MaxValue);
            }
            
            
            sq.JumpToAction__c = question.JumpToAction;
            
            update sq;
            serviceid = sq.Service__c;
            
            //Check if the question is a single select or a yes/no question
            //only then update the defined response else update question jumptoaction
            
            if (question.QuestionType == CONSTANTS.QUESTIONTYPE_MULTI_SELECT ||
                ((question.QuestionType == CONSTANTS.QUESTIONTYPE_SINGLE_SELECT ||
                  question.QuestionType == CONSTANTS.QUESTIONTYPE_YESNO)
                 && question.JumpToAction != CONSTANTS.QUESTIONJUMP_BRANCH)
               ) {
                   List<ServiceQuestionDefinedResponse__c> sqdrs = [Select Id, name, JumpToQuestion__c, isActive__c,
                                                                    EndOfQuestions__c, JumpToAction__c, CanRemove__c,
                                                                    ServiceQuestion__r.Service__c
                                                                    FROM ServiceQuestionDefinedResponse__c
                                                                    WHERE Id in :sqdrIds];
                   
                   for (ServiceQuestionDefinedResponse__c sqdr : sqdrs) {
                       sqdr.JumpToQuestion__c = null;
                       sqdr.JumpToAction__c = null;
                       sqdr.isActive__c = mappsqdrwrapper.get(sqdr.Id).Active;
                       sqdr.CanRemove__c = mappsqdrwrapper.get(sqdr.Id).CanRemove;
                   }
                   update sqdrs;
               }
            
            if ((question.QuestionType == CONSTANTS.QUESTIONTYPE_SINGLE_SELECT ||
                 question.QuestionType == CONSTANTS.QUESTIONTYPE_YESNO)
                && question.JumpToAction == CONSTANTS.QUESTIONJUMP_BRANCH) {
                    List<ServiceQuestionDefinedResponse__c> sqdrs = [Select Id, name, JumpToQuestion__c, isActive__c,
                                                                     CanRemove__c, EndOfQuestions__c, JumpToAction__c, ServiceQuestion__r.Service__c
                                                                     FROM ServiceQuestionDefinedResponse__c WHERE Id in :sqdrIds];
                    
                    for (ServiceQuestionDefinedResponse__c sqdr : sqdrs) {
                        //sqdr.JumpToQuestion__c = null;
                        //sqdr.JumpToAction__c = CONSTANTS.QUESTIONJUMP_CONTINUE;
                        
                        /*
if (mappsqdrwrapper.get(sqdr.Id).JumpToQuestion != CONSTANTS.QUESTIONJUMP_RETURN &&
mappsqdrwrapper.get(sqdr.Id).JumpToQuestion != CONSTANTS.QUESTIONJUMP_CONTINUE) {
sqdr.JumpToQuestion__c = mappsqdrwrapper.get(sqdr.Id).JumpToQuestion;
sqdr.JumpToAction__c = CONSTANTS.QUESTIONJUMP_QUESTION;
} else {
sqdr.JumpToQuestion__c = null;
sqdr.JumpToAction__c = mappsqdrwrapper.get(sqdr.Id).JumpToQuestion;
}
*/
                        
                        sqdr.isActive__c = mappsqdrwrapper.get(sqdr.Id).Active;
                        sqdr.CanRemove__c = mappsqdrwrapper.get(sqdr.Id).CanRemove;
                    }
                    update sqdrs;
                }
            
            return getServiceQuestionsApex(serviceid);
        } catch (DMLException ex) {
            throw new System.AuraHandledException(ex.getDmlMessage(0));
        } catch (Exception ex) {
            throw new System.AuraHandledException(ex.getMessage());
        }
    }
    
    @AuraEnabled
    public static string saveServiceQuestionsChanges(string questionListWrapperInput) {
        try {
            List<QuestionWrapper> questions = (List<QuestionWrapper>) JSON.deserialize(questionListWrapperInput, List<QuestionWrapper>.class);
            Map<Id, Boolean> mapCanRemoveFlags = new Map<Id, Boolean>();
            Map<Id, Boolean> mapOptionalFlags = new Map<Id, Boolean>();
            
            Set<Id> sqids = new Set<Id>();
            for (QuestionWrapper qw : questions) {
                sqids.add(qw.ProjectServiceQuestionId);
                mapCanRemoveFlags.put(qw.ProjectServiceQuestionId, qw.CanRemove);
                mapOptionalFlags.put(qw.ProjectServiceQuestionId, qw.Optional);
            }
            
            List<ServiceQuestion__c> sqs = [Select Id, Name, CanRemove__c, Question__c, Optional__c, IsActive__c
                                            from ServiceQuestion__c WHERE Id in :sqids];
            
            for (ServiceQuestion__c sq : sqs) {
                sq.CanRemove__c = mapCanRemoveFlags.get(sq.Id);
                sq.Optional__c = mapOptionalFlags.get(sq.Id);
            }
            
            update sqs;
            return '';
            
        } catch (DMLException ex) {
            throw new System.AuraHandledException(ex.getDmlMessage(0));
        } catch (Exception ex) {
            throw new System.AuraHandledException(ex.getMessage());
        }
    }
    
    
    public static void setQuestionIndentation(ID serviceid) {
        
        List<ServiceQuestion__c> sqs = [SELECT Id, QuestionNumber__c, QuestionIndentation__c
                                        FROM ServiceQuestion__c WHERE Service__c = :serviceid
                                        ORDER BY QuestionNumber__c];
        Integer qno = 1;
        Map<ID, ServiceQuestion__c> sqMap = new Map<ID, ServiceQuestion__c>();
        
        for (ServiceQuestion__c sq : sqs) {
            sq.QuestionIndentation__c = '';
            sqMap.put(sq.ID, sq);
        }
        
        Map<Id, List<ServiceQuestionWrapper>> childServiceQuestionList = new Map<Id, List<ServiceQuestionWrapper>>();//userRoleToUsers
        Map<Id, ID> parentIdMap = new Map<Id, ID>();
        
        for (ServiceQuestion__c serviceQuestion : [SELECT Id, ParentServiceQuestion__c FROM ServiceQuestion__c WHERE Service__c = :serviceid Order By QuestionNumber__c]) {
            if (childServiceQuestionList.containsKey(serviceQuestion.ParentServiceQuestion__c)) {
                List<ServiceQuestionWrapper> childId = childServiceQuestionList.get(serviceQuestion.ParentServiceQuestion__c);
                childId.add(new ServiceQuestionWrapper(sqMap.get(serviceQuestion.Id)));
                
                childServiceQuestionList.put(serviceQuestion.ParentServiceQuestion__c, childId);
            } else {
                List<ServiceQuestionWrapper> tl =  new List<ServiceQuestionWrapper>();
                ServiceQuestionWrapper sqw = new ServiceQuestionWrapper(sqMap.get(serviceQuestion.Id));
                tl.add(sqw);
                childServiceQuestionList.put(serviceQuestion.ParentServiceQuestion__c, tl);
            }
            
            parentIdMap.put(serviceQuestion.Id, serviceQuestion.ParentServiceQuestion__c);
        }
        
        Map<ID, ServiceQuestion__c> sqob = new Map<ID, ServiceQuestion__c>();
        
        integer ind = 1;
        sqs = new List<ServiceQuestion__c>();
        
        for (ServiceQuestion__c sq : sqMap.values()) {
            if (sqob.get(sq.id) == null) {
                sq.QuestionIndentation__c = string.valueOf(ind);
                ind++;
            }
            List<ServiceQuestionWrapper> sqwList = childServiceQuestionList.get(sq.id);
            
            if (sqwList != null) {
                
                integer i = 1;
                for (ServiceQuestionWrapper sqw : sqwList) {
                    ServiceQuestion__c parent = sqMap.get(parentIdMap.get(sqw.ServiceQuestion.id));
                    
                    sqw.ServiceQuestion.QuestionIndentation__c = parent.QuestionIndentation__c + string.valueOf('.' + i);
                    
                    sqob.put(sqw.ServiceQuestion.ID, sqw.ServiceQuestion);
                    i++;
                }
            }
            
            sqs.add(sq);
        }
        
        update sqs;
    }
    
    @AuraEnabled
    public static string ReorderServiceQuestion(String serviceId, String questionId, String precedingQuestionId) {
        
        Integer qIndex = -1;
        Integer precedingIndex = -1;
        Integer qChildCount = 0;
        Integer questionNumber = 1;
        Integer count = 0;
        
        Map<String, ServiceQuestion__c> sqMap = new Map<String, ServiceQuestion__c>();
        ServiceQuestion__c precedingSqObj = new ServiceQuestion__c();
        ServiceQuestion__c sqObj = new ServiceQuestion__c();
        List<ServiceQuestion__c> lstOfQuestionNode = new List<ServiceQuestion__c>();
        List<ServiceQuestion__c> reversed = new List<ServiceQuestion__c>();
        
        List<ServiceQuestion__c> lst = [SELECT Id, QuestionText__c, ItemQuestion__c, QuestionNumber__c, QuestionIndentation__c , ParentServiceQuestion__c
                                        FROM ServiceQuestion__c
                                        WHERE Service__c = :serviceid
                                        ORDER BY QuestionNumber__c];
        
        //To make sure even if question number goes out of sync it is reset to continous number
        for (ServiceQuestion__c sq : lst) {
            
            sq.QuestionNumber__c = questionNumber++;
            sqMap.put(sq.Id, sq);
        }
        
        if (sqMap.containsKey(questionId)) {
            qIndex =  sqMap.get(questionId).QuestionNumber__c.intValue() - 1;
            sqObj = sqMap.get(questionId);
            List<ID> childs = GetAllChildren(serviceid, questionId);
            if (childs != null) {
                qChildCount = childs.size();
            }
        }
        
        Integer parentsChildCount = 0;
        
        if (sqMap.containsKey(precedingQuestionId)) {
            precedingSqObj = sqMap.get(precedingQuestionId);
            precedingIndex = sqMap.get(precedingQuestionId).QuestionNumber__c.intValue() - 1;
            
            List<ID> parentsChilds = GetAllChildren(serviceid, precedingQuestionId);
            if (parentsChilds != null) {
                precedingIndex = precedingIndex + parentsChilds.size();
            }
            
        }
        
        if ((precedingSqObj.ParentServiceQuestion__c == null || String.isEmpty(String.valueOf(precedingSqObj.ParentServiceQuestion__c))) ||
            precedingSqObj.QuestionText__c == constants.QUESTIONTYPE_TARGET_GROUP)  {
                deleteServiceQuestionRule(serviceId, questionid);
                sqObj.ParentServiceQuestion__c = (precedingSqObj.QuestionText__c == constants.QUESTIONTYPE_TARGET_GROUP && sqObj.ItemQuestion__c) ? precedingSqObj.Id : NULL;
            }
        
        
        for (Integer i = qIndex; i <= qIndex + qChildCount; i++) {
            lstOfQuestionNode.add(lst[qIndex]);
            lst.remove(qIndex);
            count++;
        }
        
        if (precedingIndex >= qIndex) { precedingIndex = (precedingIndex - count); }
        
        if (precedingIndex < (lst.size() - 1)) {
            
            integer val = precedingIndex + 1;
            integer serviceQuestionListSize = lst.size();
            
            for (Integer i = precedingIndex + 1 ; i < serviceQuestionListSize; i++) {
                lstOfQuestionNode.add(lst[i]);
            }
            
            for (Integer i = precedingIndex + 1 ; i < serviceQuestionListSize; i++) {
                lst.remove(val);
            }
        }
        
        lst.addAll(lstOfQuestionNode);
        
        questionNumber = 1;
        
        for (ServiceQuestion__c sq : lst) {
            sq.QuestionNumber__c = questionNumber++;
        }
        
        UPDATE lst;
        
        setQuestionIndentation(serviceid);
        
        return getServiceQuestionsApex(serviceId);
    }
    
    public static void RearrangeOrder(String serviceid, string question, string precedingQuestion, boolean reOrder) {
        
        Integer qIndex = -1;
        Integer parentIndex = -1;
        
        if (precedingQuestion == null) { precedingQuestion = ''; }
        
        List<ServiceQuestion__c> sqs = [SELECT Id, QuestionNumber__c, QuestionIndentation__c , ParentServiceQuestion__c
                                        FROM ServiceQuestion__c WHERE Service__c = :serviceid
                                        ORDER BY QuestionNumber__c];
        
        Integer index = 0;
        for (ServiceQuestion__c sq : sqs) {
            if (sq.ID == question) {qIndex = index;}
            if (sq.ID == precedingQuestion) {parentIndex = index;}
            
            //To break when question id and parent id are fetched
            if (qIndex > -1 && parentIndex > -1) {
                break;
            }
            
            index++;
        }
        
        ServiceQuestion__c sq = sqs.get(qIndex);
        ServiceQuestion__c sqParentObj = sqs.get(parentIndex);
        
        
        List<ID> childs = GetAllChildren(serviceid, question);
        
        List<ID> parentsChilds = GetAllChildren(serviceid, precedingQuestion);
        
        List<ServiceQuestion__c> toBeRemovedSQ = new List<ServiceQuestion__c>();
        
        for (Integer i = qIndex; i <= (qIndex + childs.size()); i++) {
            toBeRemovedSQ.add(sqs.get(i));
        }
        
        for (Integer i = qIndex, j = qIndex; i <= (qIndex + childs.size()); i++) {
            sqs.remove(j);
        }
        
        integer parentsExsitingChilds = parentsChilds.size() - (childs.size() + 1);
        
        if (qIndex > parentIndex) {
            
            //parentIndex = parentIndex + parentsExsitingChilds;
            parentIndex = parentIndex + parentsExsitingChilds + 1;
            
        } else {
            parentIndex = parentIndex + (parentsExsitingChilds - childs.size());
            //parentIndex = parentIndex + parentsExsitingChilds;
        }
        
        boolean addToBottom = (sqs.size() <= parentIndex);
        
        for (ServiceQuestion__c rsq : toBeRemovedSQ) {
            
            if (addToBottom) {
                sqs.add(rsq);
            } else {
                sqs.add(parentIndex, rsq);
            }
            parentIndex++;
        }
        
        
        
        Integer qno = 1;
        
        for (ServiceQuestion__c sqobj : sqs) {
            sqobj.QuestionNumber__c = qno;
            qno++;
        }
        
        update sqs;
        
        setQuestionIndentation(serviceid);
    }
    
    public static void RearrangeOrder_Working(String serviceid, string question, string precedingQuestion, boolean reOrder) {
        
        Integer qIndex = -1;
        Integer parentIndex = -1;
        
        if (precedingQuestion == null) { precedingQuestion = ''; }
        
        List<ServiceQuestion__c> sqs = [SELECT Id, QuestionNumber__c, QuestionIndentation__c , ParentServiceQuestion__c
                                        FROM ServiceQuestion__c WHERE Service__c = :serviceid
                                        ORDER BY QuestionNumber__c];
        
        Integer index = 0;
        for (ServiceQuestion__c sq : sqs) {
            if (sq.ID == question) {qIndex = index;}
            if (sq.ID == precedingQuestion) {parentIndex = index;}
            
            //To break when question id and parent id are fetched
            if (qIndex > -1 && parentIndex > -1) {
                break;
            }
            
            index++;
        }
        
        ServiceQuestion__c sq = sqs.get(qIndex);
        ServiceQuestion__c sqParentObj = sqs.get(parentIndex);
        
        if (reOrder) {
            
            if (sqParentObj.ParentServiceQuestion__c == null || String.isEmpty(String.valueOf(sqParentObj.ParentServiceQuestion__c)))  {
                deleteServiceQuestionRule(serviceId, question);
                sq.ParentServiceQuestion__c = NULL;
            }
            
            sqs.remove(qIndex);
            
            if (precedingQuestion == '') {
                sqs.add(0, sq);
            } else {
                if (sqs.size() <= parentIndex) {
                    sqs.add(sq);
                } else {
                    sqs.add(parentIndex + (parentIndex > qIndex ? 0 : 1), sq);
                }
            }
        } else {
            List<ID> childs = GetAllChildren(serviceid, question);
            
            List<ID> parentsChilds = GetAllChildren(serviceid, precedingQuestion);
            
            List<ServiceQuestion__c> toBeRemovedSQ = new List<ServiceQuestion__c>();
            
            for (Integer i = qIndex; i <= (qIndex + childs.size()); i++) {
                toBeRemovedSQ.add(sqs.get(i));
            }
            
            for (Integer i = qIndex, j = qIndex; i <= (qIndex + childs.size()); i++) {
                sqs.remove(j);
            }
            
            integer parentsExsitingChilds = parentsChilds.size() - (childs.size() + 1);
            
            if (qIndex > parentIndex) {
                
                //parentIndex = parentIndex + parentsExsitingChilds;
                parentIndex = parentIndex + parentsExsitingChilds + 1;
                
            } else {
                parentIndex = parentIndex + (parentsExsitingChilds - childs.size());
                //parentIndex = parentIndex + parentsExsitingChilds;
            }
            
            boolean addToBottom = (sqs.size() <= parentIndex);
            
            for (ServiceQuestion__c rsq : toBeRemovedSQ) {
                
                if (addToBottom) {
                    sqs.add(rsq);
                } else {
                    sqs.add(parentIndex, rsq);
                }
                parentIndex++;
            }
            
        }
        
        Integer qno = 1;
        
        for (ServiceQuestion__c sqobj : sqs) {
            sqobj.QuestionNumber__c = qno;
            qno++;
        }
        
        update sqs;
        
        setQuestionIndentation(serviceid);
    }
    
    
    public static List<ID> GetAllChildren(String serviceid, ID sqID) {
        if (String.isEmpty(serviceid)) {
            serviceid = [Select Id, Service__c from ServiceQuestion__c WHERE Id = : sqID].Service__c;
        }
        
        Map<Id, List<ID>> childServiceQuestionList = new Map<Id, List<ID>>();
        
        for (ServiceQuestion__c serviceQuestion : [SELECT Id, ParentServiceQuestion__c FROM ServiceQuestion__c where Service__c = :serviceid Order By QuestionNumber__c]) {
            
            if (childServiceQuestionList.containsKey(serviceQuestion.ParentServiceQuestion__c)) {
                
                List<ID> childServiceQuestionId = childServiceQuestionList.get(serviceQuestion.ParentServiceQuestion__c);
                childServiceQuestionId.add(serviceQuestion.Id);
                childServiceQuestionList.put(serviceQuestion.ParentServiceQuestion__c, childServiceQuestionId);
            } else {
                
                List<ID> childServiceQuestionId = new List<ID>();
                childServiceQuestionId.add(serviceQuestion.Id);
                childServiceQuestionList.put(serviceQuestion.ParentServiceQuestion__c, childServiceQuestionId);
            }
        }
        
        List<ID> sqIds = new List<ID>();
        List<ID> resultList = new List<ID>();
        List<ID> childIds = new List<ID>();
        childIds.add(sqID);
        
        integer i = 0;
        boolean hasChild = true;
        
        while (hasChild) {
            childIds = GetChildren(childServiceQuestionList, childIds);
            
            if (childIds.size() == 0) {
                hasChild = false;
            } else {
                resultList.addAll(childIds);
            }
        }
        
        return resultList;
    }
    
    public static List<ID> GetChildren(Map<ID, List<ID>> sqrList, List<ID> sqIds) {
        List<ID> childList = new List<ID>();
        for (ID parentId : sqIds) {
            List<ID> result = sqrList.get(parentId);
            if (result != null) {
                childList.addAll(result);
            }
        }
        return childList;
    }
    
    
    @AuraEnabled
    public static string GetSqDefinedResponses(string parentsqId, string sqId) {
        
        if (string.isEmpty(parentsqId ) ) {
            throw new System.AuraHandledException('Parent Service Question Id  not blank');
        }
        if (string.isEmpty(sqId) ) {
            throw new System.AuraHandledException(' Service Question Id not blank');
        }
        
        List<ServiceQuestionRule__c> servicequestions = [Select ServiceQuestion__c, Id, Name, ParentServiceQuestion__c, Operator__c, ServiceQuestionText__c, value__c,
                                                         ParentServiceQuestionText__c, DefinedResponseValue__c, DefinedResponseValueText__c, ParentServiceQuestionType__c
                                                         FROM ServiceQuestionRule__c
                                                         WHERE ParentServiceQuestion__c = :parentsqId AND ServiceQuestion__c = :sqId];
        
        List<ServiceQuestionRuleWrapper> serviceQuestionRuleWrapperList = new List<ServiceQuestionRuleWrapper>();
        
        List<String> ruleValueTest = new List<String>();
        
        for (ServiceQuestionRule__c serviceQuestionRule : servicequestions) {
            
            ServiceQuestionRuleWrapper sqr = new ServiceQuestionRuleWrapper(serviceQuestionRule);
            
            serviceQuestionRuleWrapperList.add(sqr);
            ruleValueTest.add(sqr.RuleText);
        }
        
        List<ServiceQuestionDefinedResponse__c> servicequestionDefinedResponses = [SELECT Id, ServiceQuestion__c, QuestionDefinedResponse__c,
                                                                                   QuestionDefinedResponse__r.DefinedResponseOrder__c,
                                                                                   DefinedResponseText__c,
                                                                                   QuestionDefinedResponse__r.OneHubAnswerId__c,
                                                                                   CanRemove__c, JumpToQuestion__c,
                                                                                   EndOfQuestions__c,
                                                                                   ServiceQuestion__r.QuestionNumber__c,
                                                                                   ServiceQuestion__r.Question__r.ItemQuestion__c,
                                                                                   ServiceQuestion__r.Question__c,
                                                                                   JumpToAction__c, QuestionDefinedResponse__r.Exception__r.ExceptionCode__c,
                                                                                   ServiceQuestion__r.Question__r.QuestionType__c,
                                                                                   IsActive__c FROM ServiceQuestionDefinedResponse__c
                                                                                   WHERE ServiceQuestion__c = :parentsqId
                                                                                   AND IsActive__c = true ORDER BY QuestionDefinedResponse__r.DefinedResponseOrder__c];
        
        if (servicequestionDefinedResponses.size() == 0) {
            throw new System.AuraHandledException('Parent Service Defined Response Count shows zero');
        }
        
        List<DefinedResponseWrapper> drList = new  List<DefinedResponseWrapper>();
        for ( ServiceQuestionDefinedResponse__c sqdr : servicequestionDefinedResponses) {
            DefinedResponseWrapper dr = new DefinedResponseWrapper();
            dr.DefinedResponseId = sqdr.QuestionDefinedResponse__c;
            dr.DefinedResponseText = sqdr.DefinedResponseText__c;
            dr.DefinedResponseOrder = Integer.ValueOf(sqdr.QuestionDefinedResponse__r.DefinedResponseOrder__c);
            dr.ProjectServiceQuestionDefinedResponseId = sqdr.Id;
            dr.CanRemove = sqdr.CanRemove__c == null || sqdr.CanRemove__c == false ? false : true;
            dr.EndOfQuestions = sqdr.EndOfQuestions__c;
            dr.ExceptionCode =  sqdr.QuestionDefinedResponse__r.Exception__r.ExceptionCode__c;
            dr.Active = sqdr.isActive__c;
            drList.add(dr);
        }
        
        
        List<ServiceQuestion__c> servicequestion = [SELECT Id, Question__c, Question__r.QuestionType__c, Question__r.Description__c, Question__r.Name, Question__r.QuestionText__c FROM ServiceQuestion__c WHERE Id = :parentsqId];
        QuestionWrapper customquestion = new QuestionWrapper();
        if (servicequestion.size() > 0) {
            ServiceQuestion__c sq  = servicequestion[0];
            customquestion.QuestionId = sq.Question__c;
            customquestion.QuestionTitle = sq.Question__r.Name;
            customquestion.QuestionText = sq.Question__r.QuestionText__c;
            customquestion.QuestionType = sq.Question__r.QuestionType__c;
            customquestion.DefinedResponses = drList;
            customquestion.ServiceQuestionRule = new ServiceQuestionRuleWrapper();
            
            if (serviceQuestionRuleWrapperList.size() > 0) {
                customquestion.ServiceQuestionRule = serviceQuestionRuleWrapperList[0];
                customquestion.ServiceQuestionRule.RuleValueText = ruleValueTest;
                customquestion.ServiceQuestionRuleList = serviceQuestionRuleWrapperList;
            }
            
        }
        
        ResponseWrapper rw = ResponseWrapper.getInstance(CONSTANTS.RESPONSE_STATE_SUCCESS, 'Successfully retrieved the DefinedResponses', customquestion);
        String returnString = JSON.serialize(rw);
        return returnString;
        
    }
    
    @AuraEnabled
    public static void UpdateServiceQuestionOption(string serviceQuestionId, Boolean optionValue) {
        List<ServiceQuestion__c> servicequestions = [SELECT Id, CanRemove__c, Optional__c FROM ServiceQuestion__c
                                                     WHERE Id = :serviceQuestionId Limit 1];
        
        if (servicequestions != null && servicequestions.size() > 0) {
            
            servicequestions[0].Optional__c = optionValue;
            
            update servicequestions;
        }
        
    }
    
    @AuraEnabled
    public static void UpdateServiceQuestionCanRemove(string serviceQuestionId, Boolean canRemoveValue) {
        
        List<ServiceQuestion__c> servicequestions = [SELECT Id, CanRemove__c, Optional__c FROM ServiceQuestion__c
                                                     WHERE Id = :serviceQuestionId Limit 1];
        
        if (servicequestions != null && servicequestions.size() > 0) {
            servicequestions[0].CanRemove__c = canRemoveValue;
            update servicequestions;
        }
        
        update servicequestions;
    }
    
    @AuraEnabled
    public static string GetServiceQuestionRule(string serviceQuestionRuleId) {
        
        string returnValue = '';
        
        List<ServiceQuestionRule__c> servicequestions = [select Id, name, Operator__c, ParentServiceQuestion__c,
                                                         ServiceQuestion__c , value__c, DefinedResponseValue__c, ServiceQuestionText__c,
                                                         ParentServiceQuestionText__c
                                                         FROM ServiceQuestionRule__c
                                                         WHERE ID = : serviceQuestionRuleId];
        
        List<ServiceQuestionRuleWrapper> serviceQuestionRuleWrapperList = new List<ServiceQuestionRuleWrapper>();
        List<String> ruleValueTest = new List<String>();
        
        if (servicequestions != null && servicequestions.size() > 0) {
            //ServiceQuestionRuleWrapper sqrule = new ServiceQuestionRuleWrapper(servicequestions[0]);
            
            
            for (ServiceQuestionRule__c serviceQuestionRule : servicequestions) {
                
                ServiceQuestionRuleWrapper sqr = new ServiceQuestionRuleWrapper(serviceQuestionRule);
                
                serviceQuestionRuleWrapperList.add(sqr);
                ruleValueTest.add(sqr.RuleText);
            }
            
            QuestionWrapper customquestion = GetServiceQuestionWithDefinedResponses(servicequestions[0].ParentServiceQuestion__c, servicequestions);
            
            if (serviceQuestionRuleWrapperList.size() > 0) {
                customquestion.ServiceQuestionRule = serviceQuestionRuleWrapperList[0];
                customquestion.ServiceQuestionRule.RuleValueText = ruleValueTest;
                customquestion.ServiceQuestionRuleList = serviceQuestionRuleWrapperList;
            }
            
            ResponseWrapper rw = ResponseWrapper.getInstance(CONSTANTS.RESPONSE_STATE_SUCCESS, 'Successfully retrieved the DefinedResponses', customquestion);
            
            returnValue = JSON.serialize(rw);
        }
        
        
        return returnValue;
    }
    
    @AuraEnabled
    public static QuestionWrapper GetServiceQuestionWithDefinedResponses(string parentsqId, List<ServiceQuestionRule__c> servicequestions) {
        
        
        List<ServiceQuestionRuleWrapper> sqrw = new List<ServiceQuestionRuleWrapper>();
        for (ServiceQuestionRule__c  sqr : servicequestions) {
            sqrw.add(new ServiceQuestionRuleWrapper(sqr));
        }
        
        List<ServiceQuestionDefinedResponse__c> servicequestionDefinedResponses = [SELECT Id, ServiceQuestion__c, QuestionDefinedResponse__c,
                                                                                   QuestionDefinedResponse__r.DefinedResponseOrder__c, DefinedResponseText__c,
                                                                                   QuestionDefinedResponse__r.OneHubAnswerId__c, CanRemove__c, JumpToQuestion__c, EndOfQuestions__c,
                                                                                   ServiceQuestion__r.QuestionNumber__c, ServiceQuestion__r.Question__r.ItemQuestion__c, ServiceQuestion__r.Question__c,
                                                                                   JumpToAction__c, QuestionDefinedResponse__r.Exception__r.ExceptionCode__c, ServiceQuestion__r.Question__r.QuestionType__c,
                                                                                   IsActive__c FROM ServiceQuestionDefinedResponse__c
                                                                                   WHERE ServiceQuestion__c = :parentsqId ORDER BY QuestionDefinedResponse__r.DefinedResponseOrder__c];
        
        if (servicequestionDefinedResponses.size() == 0) {
            throw new System.AuraHandledException('Parent Service Defined Response Count shows zero');
        }
        
        List<DefinedResponseWrapper> drList = new  List<DefinedResponseWrapper>();
        for ( ServiceQuestionDefinedResponse__c sqdr : servicequestionDefinedResponses) {
            DefinedResponseWrapper dr = new DefinedResponseWrapper();
            dr.DefinedResponseId = sqdr.QuestionDefinedResponse__c;
            dr.DefinedResponseText = sqdr.DefinedResponseText__c;
            dr.DefinedResponseOrder = Integer.ValueOf(sqdr.QuestionDefinedResponse__r.DefinedResponseOrder__c);
            dr.ProjectServiceQuestionDefinedResponseId = sqdr.Id;
            dr.CanRemove = sqdr.CanRemove__c == null || sqdr.CanRemove__c == false ? false : true;
            dr.EndOfQuestions = sqdr.EndOfQuestions__c;
            dr.ExceptionCode =  sqdr.QuestionDefinedResponse__r.Exception__r.ExceptionCode__c;
            dr.Active = sqdr.isActive__c;
            drList.add(dr);
        }
        
        List<ServiceQuestion__c> servicequestion = [SELECT Id, Question__c, Question__r.Description__c, Question__r.Name, Question__r.QuestionText__c FROM ServiceQuestion__c WHERE Id = :parentsqId ];
        QuestionWrapper customquestion = new QuestionWrapper();
        if (servicequestion.size() > 0) {
            ServiceQuestion__c sq  = servicequestion[0];
            customquestion.QuestionId = sq.Question__c;
            customquestion.QuestionTitle = sq.Question__r.Name;
            customquestion.QuestionText = sq.Question__r.QuestionText__c;
            customquestion.DefinedResponses = drList;
            
            if (sqrw.size() > 0) {
                customquestion.ServiceQuestionRule = sqrw[0];
                customquestion.ServiceQuestionRuleList = sqrw;
            }
        }
        
        return customquestion;
        
    }
        
    ////////Project Service Question
    @AuraEnabled
    public static string getProjectServiceQuestionsApex(string projectserviceid) {
        
        try {
            if (projectserviceid == null || projectserviceid == '') {
                return '';
            }
            List<QuestionWrapper> customquestions = new List<QuestionWrapper>();
            
            Map<Question__c, List<QuestionDefinedResponse__c>> mapQuestionInfo = new Map<Question__c, List<QuestionDefinedResponse__c>>();
            
            List<ProjectServiceQuestion__c> projectservicequestions = [SELECT Id, Question__c, Question__r.Active__c, Question__r.Description__c, QuestionHint__c, HintLock__c,
                                                                       Question__r.IsQuestionVisibleToClient__c, Question__r.ItemQuestion__c, Question__r.Name,
                                                                       Question__r.OneHubQuestionId__c, Question__r.QuestionText__c, Question__r.QuestionType__c,
                                                                       Question__r.ReplaceByOneHubQuestionId__c, Question__r.TargetType__c, Question__r.DefinedResponseCount__c, MinValue__c, MaxValue__c,
                                                                       ServiceQuestion__c, CanRemove__c, QuestionNumber__c, Active__c, JumpToAction__c, Optional__c, Question__r.ExceptionQuestion__c,
                                                                       QuestionIndentation__c, ParentProjectServiceQuestion__c, AILabel__c, AILabel__r.Name,
                                                                       ParentProjectServiceQuestion__r.QuestionIndentation__c, QuestionIndentationLevel__c
                                                                       FROM ProjectServiceQuestion__c WHERE ProjectService__c = :projectserviceid
                                                                       ORDER BY QuestionNumber__c];
            
            //Map<ID, ProjectServiceQuestionRule__c> sqrsMap = new Map<ID, ProjectServiceQuestionRule__c>();
            
            Set<ID> ParentIds = new Set<ID>();
            List<ProjectServiceQuestionRule__c> sqrs = new List<ProjectServiceQuestionRule__c>([SELECT Id, Name, DefinedResponseValue__c, DefinedResponseValueText__c, Operator__c, ParentProjectServiceQuestion__c, ParentProjectServiceQuestionText__c,
                                                                                                ParentProjectServiceQuestionType__c, ProjectServiceQuestion__c, ProjectServiceQuestionText__c, Value__c
                                                                                                FROM ProjectServiceQuestionRule__c
                                                                                                WHERE ProjectServiceQuestion__r.ProjectService__c = : projectserviceid]);
            
            //for (ProjectServiceQuestionRule__c idKey : sqrs) {
            //sqrsMap.put(idKey.ProjectServiceQuestion__c,idKey);
            //ParentIds.add(idKey.ParentProjectServiceQuestion__c);
            //}
            
            
            Map<String, List<ProjectServiceQuestionRule__c>> sqRuleMap = new Map<String, List<ProjectServiceQuestionRule__c>>();
            for (ProjectServiceQuestionRule__c sqr : sqrs) {
                
                List<ProjectServiceQuestionRule__c> lstServiceQuestionRule = new List<ProjectServiceQuestionRule__c>();
                if (sqRuleMap.containsKey(sqr.ProjectServiceQuestion__c)) {
                    lstServiceQuestionRule.addAll(sqRuleMap.get(sqr.ProjectServiceQuestion__c));
                }
                
                lstServiceQuestionRule.add(sqr);
                sqRuleMap.put(sqr.ProjectServiceQuestion__c, lstServiceQuestionRule);
                
                ParentIds.add(sqr.ParentProjectServiceQuestion__c);
            }
            
            
            Map<Id, Integer> mapQuestionNumber = new Map<Id, Integer>();
            Map<Id, ProjectServiceQuestion__c> mapQuestions = new Map<Id, ProjectServiceQuestion__c>();
            for (ProjectServiceQuestion__c psq : projectservicequestions ) {
                Integer qno = psq.QuestionNumber__c == null ? 0 : Integer.ValueOf(psq.QuestionNumber__c);
                mapQuestionNumber.put(psq.Question__c, qno);
                mapQuestions.put(psq.Id, psq);
            }
            
            Set<Id> setQuestionIds = mapQuestions.keySet();
            List<ProjectServiceQuestionDefinedResponse__c> projectservicequestionDefinedResponses = [SELECT Id, ProjectServiceQuestion__c, QuestionDefinedResponse__c, Question__c,
                                                                                                     QuestionDefinedResponse__r.DefinedResponseOrder__c, DefinedResponseText__c,
                                                                                                     QuestionDefinedResponse__r.OneHubAnswerId__c, CanRemove__c, JumpToQuestion__c, EndOfQuestions__c, Active__c,
                                                                                                     ProjectServiceQuestion__r.QuestionNumber__c, ProjectServiceQuestion__r.Question__r.ItemQuestion__c,
                                                                                                     JumpToAction__c, QuestionDefinedResponse__r.Exception__r.ExceptionCode__c, ProjectServiceQuestion__r.Question__r.QuestionType__c
                                                                                                     FROM ProjectServiceQuestionDefinedResponse__c
                                                                                                     WHERE ProjectServiceQuestion__c in :setQuestionIds ORDER BY QuestionDefinedResponse__r.DefinedResponseOrder__c];
            
            Map<Id, List<ProjectServiceQuestionDefinedResponse__c>> mappsqdr = new Map<Id, List<ProjectServiceQuestionDefinedResponse__c>>();
            
            Map<Id, List<UISelectWrapper>> mapAllowedJumpToQuestions = new Map<Id, List<UISelectWrapper>>();
            
            for (ProjectServiceQuestionDefinedResponse__c psqdr : projectservicequestionDefinedResponses ) {
                List<ProjectServiceQuestionDefinedResponse__c> psqdrList = mappsqdr.get(psqdr.ProjectServiceQuestion__c);
                if (psqdrList == null) {
                    psqdrList = new List<ProjectServiceQuestionDefinedResponse__c> {psqdr};
                        } else {
                            psqdrList.add(psqdr);
                        }
                mappsqdr.put(psqdr.ProjectServiceQuestion__c, psqdrList);
                List<UISelectWrapper> lstjtq = new List<UISelectWrapper>();
                //lstjtq = getAllowedJumps(psqdr, projectservicequestions);
                mapAllowedJumpToQuestions.put(psqdr.Id, lstjtq );
                
            }
            
            String firstItemQuestionId = '';
            String lastItemQuestionId = '';
            
            //oh3392
            Map<Id, Boolean> svcQuestionMap = getServiceQuestionOptions(projectserviceid);
            
            List<ProjectServiceQuestionRule__c> projectServiceQuestionRuleList = [Select Id, Name, DefinedResponseValue__c,
                                                                                  DefinedResponseValueText__c, Operator__c,
                                                                                  ParentProjectServiceQuestion__c, ParentProjectServiceQuestionText__c,
                                                                                  ParentProjectServiceQuestionType__c, ProjectServiceQuestion__c,
                                                                                  ProjectServiceQuestionText__c, Value__c
                                                                                  From ProjectServiceQuestionRule__c
                                                                                  Where ParentProjectServiceQuestion__c in: setQuestionIds];
            
            Map<Id, Set<String>> projectServiceQuestionRuleMap = new Map<Id, Set<String>>();
            
            Map<string, List<ServiceQuestionRuleWrapper>> projectServiceQuestionRuleMapList = new Map<string, List<ServiceQuestionRuleWrapper>>();
            
            for (ProjectServiceQuestionRule__c rule : projectServiceQuestionRuleList ) {
                
                Set<String> ruleList = projectServiceQuestionRuleMap.get(rule.ParentProjectServiceQuestion__c);
                List<ServiceQuestionRuleWrapper> psqRuleList = projectServiceQuestionRuleMapList.get(rule.ParentProjectServiceQuestion__c + rule.Value__c);
                
                if (ruleList == null) {
                    ruleList = new Set<String> {rule.Value__c};
                        } else {
                            ruleList.add(rule.Value__c);
                        }
                
                if (psqRuleList == null) {
                    psqRuleList = new List<ServiceQuestionRuleWrapper> {new ServiceQuestionRuleWrapper(rule)};
                        } else {
                            psqRuleList.add(new ServiceQuestionRuleWrapper(rule));
                        }
                
                projectServiceQuestionRuleMap.put(rule.ParentProjectServiceQuestion__c, ruleList);
                projectServiceQuestionRuleMapList.put(rule.ParentProjectServiceQuestion__c + rule.Value__c, psqRuleList);
            }
            
            for (ProjectServiceQuestion__c psq : projectservicequestions ) {
                List<DefinedResponseWrapper> drList = new List<DefinedResponseWrapper>();
                
                Set<String> ruleList = projectServiceQuestionRuleMap.get(psq.ID);
                
                
                
                if (psq.Question__r.DefinedResponseCount__c > 0 && mappsqdr.containsKey(psq.Id)) {
                    for (ProjectServiceQuestionDefinedResponse__c psqdr : mappsqdr.get(psq.Id)) {
                        
                        DefinedResponseWrapper dr = new DefinedResponseWrapper();
                        
                        dr.DefinedResponseId = psqdr.QuestionDefinedResponse__c;
                        dr.DefinedResponseText = psqdr.DefinedResponseText__c;
                        dr.CanRemove = psqdr.CanRemove__c;
                        dr.DefinedResponseOrder = Integer.ValueOf(psqdr.QuestionDefinedResponse__r.DefinedResponseOrder__c);
                        dr.ProjectServiceQuestionDefinedResponseId = psqdr.Id;
                        dr.CanRemove = psqdr.CanRemove__c;
                        dr.JumpToQuestion = psqdr.JumpToQuestion__c == null || String.ValueOf(psqdr.JumpToQuestion__c)
                            == '' ? psqdr.JumpToAction__c : psqdr.JumpToQuestion__c;
                        dr.EndOfQuestions = psqdr.EndOfQuestions__c;
                        dr.Active = psqdr.Active__c;
                        
                        dr.ExceptionCode = psqdr.QuestionDefinedResponse__r.Exception__r.ExceptionCode__c;
                        dr.JumpToQuestionNumber = mapQuestionNumber.get(psqdr.JumpToQuestion__c);
                        dr.AllowedJumpToQuestions = mapAllowedJumpToQuestions.get(psqdr.Id);
                        
                        dr.RuleUsedInProjectServiceQuestion = projectServiceQuestionRuleMapList.get(psq.Id + psqdr.DefinedResponseText__c);
                        dr.UsedForRule = (psqdr.Active__c == true && (ruleList != null && ruleList.contains(psqdr.DefinedResponseText__c))) ? true : false;
                        
                        drList.add(dr);
                    }
                }
                
                QuestionWrapper customquestion = new QuestionWrapper();
                
                customquestion.ID = psq.Id;
                customquestion.ParentID = psq.ParentProjectServiceQuestion__c;
                customquestion.ParentQuestionIndentation = psq.ParentProjectServiceQuestion__r.QuestionIndentation__c;
                customquestion.QuestionId = psq.Question__c;
                customquestion.QuestionText = psq.Question__r.QuestionText__c;
                customquestion.QuestionTitle =  psq.Question__r.Name;
                customquestion.QuestionType = psq.Question__r.QuestionType__c;
                customquestion.ItemQuestion = psq.Question__r.ItemQuestion__c;
                customquestion.JumpToAction = psq.JumpToAction__c;
                customquestion.DefinedResponseCount = Integer.ValueOf(psq.Question__r.DefinedResponseCount__c);
                customquestion.DefinedResponses = drList;
                customquestion.ProjectServiceQuestionId = psq.Id;
                customquestion.ServiceQuestion = psq.ServiceQuestion__c;
                customquestion.CanRemove = psq.CanRemove__c;
                customquestion.QuestionNumber = Integer.ValueOf(psq.QuestionNumber__c);
                customquestion.Active = psq.Active__c;
                customquestion.AILabelId = psq.AILabel__c;
                customquestion.AILabelName = psq.AILabel__r.Name;
                customquestion.IsProjectServiceQuestion = true;
                customquestion.IsExceptionQuestion = psq.Question__r.ExceptionQuestion__c;
                customquestion.Optional = psq.Optional__c;
                
                //oh3392
                customquestion.IsOptionEditable = svcQuestionMap.get(psq.Question__c) != null ? svcQuestionMap.get(psq.Question__c) : true;
                customquestion.MinValue = string.valueOf(psq.MinValue__c);
                customquestion.MaxValue = string.valueOf(psq.MaxValue__c);
                customquestion.HintQuestion = string.valueOf(psq.QuestionHint__c);
                customquestion.HintLock = psq.HintLock__c != null ? Boolean.valueOf(psq.HintLock__c) : false;
                
                customquestion.AllowedJumpToActions = new List<UISelectWrapper>();
                customquestion.AllowedJumpToActions.add(new UISelectWrapper (CONSTANTS.QUESTIONJUMP_CONTINUE, CONSTANTS.QUESTIONJUMP_CONTINUE));
                customquestion.AllowedJumpToActions.add(new UISelectWrapper (CONSTANTS.QUESTIONJUMP_RETURN, CONSTANTS.QUESTIONJUMP_RETURN));
                
                if (customquestion.QuestionType == CONSTANTS.QUESTIONTYPE_SINGLE_SELECT ||
                    customquestion.QuestionType == CONSTANTS.QUESTIONTYPE_YESNO) {
                        customquestion.AllowedJumpToActions.add(new UISelectWrapper (CONSTANTS.QUESTIONJUMP_BRANCH, CONSTANTS.QUESTIONJUMP_BRANCH));
                    }
                
                if (customquestion.ItemQuestion) {
                    if (firstItemQuestionId == null || firstItemQuestionId == '') {
                        firstItemQuestionId = customquestion.QuestionId;
                    }
                    lastItemQuestionId = customquestion.QuestionId;
                }
                
                // new code
                customquestion.QuestionIndentation = psq.QuestionIndentation__c;
                customquestion.QuestionIndentationSize = String.isBlank(psq.QuestionIndentation__c) ? 1 : psq.QuestionIndentation__c.split('\\.').size();
                customquestion.QuestionIndentationLevel = Integer.valueOf(psq.QuestionIndentationLevel__c);
                customquestion.HasChild = ParentIds.contains(customquestion.ID);
                
                //To get parent id from service question
                //ProjectServiceQuestionRule__c projectServiceQuestionRule = sqrsMap.get(customquestion.ProjectServiceQuestionId);
                //if (projectServiceQuestionRule != null){
                //    customquestion.ProjectServiceQuestionRule = new ProjectServiceQuestionRuleWrapper(projectServiceQuestionRule);
                //    customquestion.ParentID = customquestion.ProjectServiceQuestionRule.ParentProjectServiceQuestion;
                //}
                
                if (sqRuleMap.containsKey(psq.Id)) {
                    List<ProjectServiceQuestionRule__c> serviceQuestionRuleList = sqRuleMap.get(psq.Id);
                    if (serviceQuestionRuleList != null && serviceQuestionRuleList.size() > 0) {
                        List<ServiceQuestionRuleWrapper> serviceQuestionRuleWrapperList = new List<ServiceQuestionRuleWrapper>();
                        List<String> ruleValueTest = new List<String>();
                        
                        for (ProjectServiceQuestionRule__c serviceQuestionRule : serviceQuestionRuleList) {
                            
                            ServiceQuestionRuleWrapper sqr = new ServiceQuestionRuleWrapper(serviceQuestionRule);
                            
                            serviceQuestionRuleWrapperList.add(sqr);
                            ruleValueTest.add(sqr.RuleText);
                        }
                        
                        if (serviceQuestionRuleWrapperList.size() > 0) {
                            customquestion.ServiceQuestionRule = serviceQuestionRuleWrapperList[0];
                            customquestion.ServiceQuestionRule.RuleValueText = ruleValueTest;
                            customquestion.ServiceQuestionRuleList = serviceQuestionRuleWrapperList;
                            customquestion.ParentID = serviceQuestionRuleWrapperList[0].ParentServiceQuestion;
                        }
                        
                    }
                }
                
                
                customquestion.ParentID = customquestion.ParentID == null ? '' : customquestion.ParentID;
                
                customquestions.add(customquestion);
            }
            
            customquestions = SetItemQuestionFlags(firstItemQuestionId, lastItemQuestionId, customquestions);
            
            ResponseWrapper rw = ResponseWrapper.getInstance(CONSTANTS.RESPONSE_STATE_SUCCESS, 'Successfully retrieved the questions', customquestions);
            
            String returnString = JSON.serialize(rw);
            return returnString;
            
        }
        
        catch (Exception ex) {
            throw new System.AuraHandledException(ex.getStackTraceString());
            
        }
    }
    
    static Map<Id, Boolean> getServiceQuestionOptions(String projectServiceId) {
        List<ServiceQuestion__c> questions = [SELECT Question__c, Optional__c
                                              from ServiceQuestion__c
                                              WHERE Service__c in (SELECT Service__c
                                                                   FROM ProjectService__c
                                                                   WHERE Id = :projectServiceId)];
        Map<Id, Boolean> result = new Map<Id, Boolean>();
        for (ServiceQuestion__c q : questions) {
            result.put(q.Question__c, q.Optional__c);
        }
        return result;
    }
    
    @AuraEnabled
    public static void UpdateProjectServiceQuestionOption(string projectServiceQuestionId, Boolean optionValue) {
        List<ProjectServiceQuestion__c> projectServiceQuestions = [SELECT Id, CanRemove__c, Optional__c FROM ProjectServiceQuestion__c
                                                                   WHERE Id = :projectServiceQuestionId Limit 1];
        
        if (projectServiceQuestions != null && projectServiceQuestions.size() > 0) {
            
            projectServiceQuestions[0].Optional__c = optionValue;
            
            update projectServiceQuestions;
        }
        
    }
    
    @AuraEnabled
    public static void saveProjectServiceQuestionActiveFlag(string projectServiceQuestionId, Boolean optionValue) {
        
        List<ProjectServiceQuestion__c> projectServiceQuestions = [SELECT Id, CanRemove__c, Active__c FROM ProjectServiceQuestion__c
                                                                   WHERE Id = :projectServiceQuestionId Limit 1];
        
        if (projectServiceQuestions != null && projectServiceQuestions.size() > 0) {
            
            projectServiceQuestions[0].Active__c = optionValue;
            
            update projectServiceQuestions;
        }
        
    }
    
    @AuraEnabled
    public static void saveProjectServiceQuestionActiveFlag(string projectServiceId, string projectServiceQuestionId, Boolean optionValue) {
        
        List<ID> resultList = new List<ID>();
        if (!optionValue) {
            resultList = LightningSurveyQuestionsControllerv2.GetProjectServiceAllChildren(projectServiceId, projectServiceQuestionId);
        }
        resultList.add(projectServiceQuestionId);
        
        List<ProjectServiceQuestion__c> projectServiceQuestions = [SELECT Id, CanRemove__c, Active__c FROM ProjectServiceQuestion__c
                                                                   WHERE Id in :resultList];
        
        if (projectServiceQuestions != null && projectServiceQuestions.size() > 0) {
            for (ProjectServiceQuestion__c psq  : projectServiceQuestions) {
                psq.Active__c = optionValue;
            }
            update projectServiceQuestions;
        }
    }
    
    @AuraEnabled
    public static string addProjectServiceQuestion(string projectserviceid, string questionid) {
        String targetGroupQuestionId = '';
        SavePoint savePoint = Database.setSavePoint();
        
        try {
            if (projectserviceid == null || projectserviceid == '' || questionid == null || questionid == '') {
                return '';
            }
            Question__c question;
            //oh2962 get ISQuestionVisibleToClient field in SELECT statement
            List<Question__c> questions = [Select Id, ExceptionQuestion__c, ItemQuestion__c, IsQuestionVisibleToClient__c, QuestionType__c, QuestionHint__c from Question__c WHERE Id = :questionid LIMIT 1];
            
            if (questions.isEmpty()) {
                throw new AuraHandledException('Question Not Found:' + questionid);
            }
            
            question = questions[0];
            
            Boolean isItemQuestion = question.ItemQuestion__c;
            Boolean isExceptionQuestion = question.ExceptionQuestion__c;
            
            //Check if this is an exception question and if another exception question already exists
            if (isExceptionQuestion) {
                List<ProjectServiceQuestion__c> psqs = [SELECT Id from ProjectServiceQuestion__c WHERE ProjectService__c = :projectserviceid and Question__r.ExceptionQuestion__c = true LIMIT 1];
                if (!psqs.isEmpty()) {
                    
                    throw new CustomException('Error adding question: Only one exception question can be added to a survey.');
                    
                }
            }
            
            List<Question> customquestions = new List<Question>();
            
            // Check if the question is an item question, if yes, then add the question
            // next to the previous item question if one exists
            Decimal maxqno = 0;
            
            
            if (isItemQuestion) {
                
                List<ProjectServiceQuestion__c> tgqs = [Select Id, name from ProjectServiceQuestion__c
                                                        where ProjectService__c = :projectserviceid AND
                                                        Question__r.Name = :CONSTANTS.QUESTIONTYPE_TARGET_GROUP Limit 1];
                if (!tgqs.isEmpty()) {
                    targetGroupQuestionId = tgqs[0].Id;
                }
                
                
                //Check if there are item questions in the survey
                List<ProjectServiceQuestion__c> projectsqs = [Select Id, QuestionNumber__c FROM ProjectServiceQuestion__c WHERE
                                                              ProjectService__c = :projectserviceid AND Question__r.ItemQuestion__c = true order by QuestionNumber__c DESC LIMIT 1];
                if (projectsqs.size() > 0) {
                    maxqno = projectsqs[0].QuestionNumber__c;
                }
                
                else {
                    //First Item Question. Add Target Group also
                    
                    maxqno = GetLastProjectServiceQuestionNumber(projectserviceid);
                    List<Question__c> tgs = [Select Id, Name from Question__c WHERE Name = : CONSTANTS.QUESTIONTYPE_TARGET_GROUP];
                    if (tgs.isEmpty()) {
                        throw new System.AuraHandledException('Target Group Question missing. Contact Administrator');
                    }
                    //Insert Target group question here
                    ProjectServiceQuestion__c psqObj = new ProjectServiceQuestion__c();
                    psqObj.ProjectService__c = projectserviceid;
                    psqObj.Question__c = tgs[0].Id;
                    psqObj.CanRemove__c = false;
                    psqObj.QuestionHint__c = question.QuestionHint__c;
                    psqObj.QuestionNumber__c = maxqno + 1;
                    psqObj.Optional__c = false;
                    //oh2962: service visibility to client
                    psqObj.IsVisibleToClient__c = question.IsQuestionVisibleToClient__c;
                    insert psqObj;
                    targetGroupQuestionId = psqObj.Id;
                    maxqno = maxqno + 1;
                }
            }
            
            if (maxqno == 0) {
                
                list<ProjectServiceQuestion__c> psQuestionList = [Select Id, QuestionNumber__c FROM ProjectServiceQuestion__c WHERE
                                                                  ProjectService__c = :projectserviceid order by QuestionNumber__c DESC LIMIT 1];
                
                if (psQuestionList != null && psQuestionList.size() > 0) {
                    maxqno = psQuestionList[0].QuestionNumber__c;
                }
                
                
            }
            
            Decimal newqno = maxqno + 1;
            
            //New question question number is maxqno + 1. Check if there are existing questions in PSQ
            //with the same question number and increase them by 1
            //We are doing this as item questions now have to be grouped together
            
            List<ProjectServiceQuestion__c> psqs = [Select Id, QuestionNumber__c FROM ProjectServiceQuestion__c WHERE
                                                    ProjectService__c = :projectserviceid and QuestionNumber__c >= :newqno];
            
            for (ProjectServiceQuestion__c psq : psqs) {
                psq.QuestionNumber__c = psq.QuestionNumber__c + 1;
                
            }
            update psqs;
            
            ProjectServiceQuestion__c psqObj = new ProjectServiceQuestion__c();
            psqObj.ProjectService__c = projectserviceid;
            psqObj.Question__c = questionid;
            psqObj.ServiceQuestion__c = false;
            psqObj.CanRemove__c = true;
            psqObj.Active__c = true;
            
            psqObj.QuestionNumber__c = newqno;
            
            psqObj.isTargetQuestion__c = isItemQuestion;
            
            
            if (question.QuestionType__c == CONSTANTS.QUESTIONTYPE_PHOTO)
                psqObj.Optional__c = true;
            else
                psqObj.Optional__c = false;
            
            
            psqObj.JumpToAction__c = CONSTANTS.QUESTIONJUMP_CONTINUE;
            //oh2962: service visibility to client
            psqObj.IsVisibleToClient__c = question.IsQuestionVisibleToClient__c;
            psqObj.QuestionHint__c = question.QuestionHint__c;
            
            if (isItemQuestion) {
                psqObj.ParentProjectServiceQuestion__c = targetGroupQuestionId;
            }
            insert psqObj;
            
            ProjectServiceQuestionDefinedResponse__c psqdefResp;
            List<ProjectServiceQuestionDefinedResponse__c> psqdfrList = new List<ProjectServiceQuestionDefinedResponse__c>();
            
            List<QuestionDefinedResponse__c> qDefResList = [ SELECT Id, Name, DefinedResponseOrder__c, DefinedResponseText__c
                                                            FROM QuestionDefinedResponse__c where Question__c = :questionid];
            for (QuestionDefinedResponse__c qdr : qDefResList ) {
                
                psqdefResp =  new ProjectServiceQuestionDefinedResponse__c();
                psqdefResp.ProjectServiceQuestion__c = psqObj.id;
                psqdefResp.QuestionDefinedResponse__c = qdr.Id;
                psqdefResp.EndOfQuestions__c = false;
                psqdefResp.JumpToAction__c = 'CONTINUE';
                psqdefResp.CanRemove__c = true;
                psqdefResp.Active__c = true;
                psqdfrList.add(psqdefResp);
            }
            
            if(question.QuestionType__c != CONSTANTS.QUESTIONTYPE_TARGET_MULTI_SELECT){
                insert psqdfrList;    
            }
            
            
            setProjectQuestionIndentation(projectserviceid);
            
            return getProjectServiceQuestionsApex(projectserviceid);
            
        } catch (DMLException ex) {
            Database.rollback(savePoint);
            throw new System.AuraHandledException(ex.getDmlMessage(0));
            
        } catch (Exception ex) {
            Database.rollback(savePoint);
            throw new System.AuraHandledException(ex.getMessage());
            
        }
        
    }
    
    private static Integer GetLastProjectServiceQuestionNumber(string projectServiceId) {
        
        Integer maxqno;
        
        List<ProjectServiceQuestion__c> psqnos = [Select Id, QuestionNumber__c FROM ProjectServiceQuestion__c WHERE
                                                  ProjectService__c = :projectServiceId order by QuestionNumber__c DESC LIMIT 1];
        
        if (psqnos != null && psqnos.size() > 0) {
            maxqno = Integer.valueof(psqnos[0].QuestionNumber__c);
        }
        return maxqno;
        
    }
        
    public static void setProjectQuestionIndentation(ID projectserviceid) {
        
        List<ProjectServiceQuestion__c> sqs = [SELECT Id, QuestionNumber__c, QuestionIndentation__c
                                               FROM ProjectServiceQuestion__c WHERE ProjectService__c = :projectserviceid
                                               ORDER BY QuestionNumber__c];
        Integer qno = 1;
        Map<ID, ProjectServiceQuestion__c> sqMap = new Map<ID, ProjectServiceQuestion__c>();
        
        for (ProjectServiceQuestion__c sq : sqs) {
            sq.QuestionIndentation__c = '';
            sqMap.put(sq.ID, sq);
        }
        
        
        Map<Id, List<ProjectServiceQuestionWrapper>> childProjectServiceQuestionList = new Map<Id, List<ProjectServiceQuestionWrapper>>();//userRoleToUsers
        Map<Id, ID> parentIdMap = new Map<Id, ID>();
        
        for (ProjectServiceQuestion__c projectServiceQuestion : [SELECT Id, ParentProjectServiceQuestion__c FROM ProjectServiceQuestion__c
                                                                 WHERE ProjectService__c = :projectserviceid
                                                                 Order By QuestionNumber__c]) {
                                                                     if (childProjectServiceQuestionList.containsKey(projectServiceQuestion.ParentProjectServiceQuestion__c)) {
                                                                         List<ProjectServiceQuestionWrapper> childId = childProjectServiceQuestionList.get(projectServiceQuestion.ParentProjectServiceQuestion__c);
                                                                         childId.add(new ProjectServiceQuestionWrapper(sqMap.get(projectServiceQuestion.Id)));
                                                                         
                                                                         //usersId.sort();
                                                                         childProjectServiceQuestionList.put(projectServiceQuestion.ParentProjectServiceQuestion__c, childId);
                                                                     } else {
                                                                         List<ProjectServiceQuestionWrapper> tl =  new List<ProjectServiceQuestionWrapper>();
                                                                         ProjectServiceQuestionWrapper sqw = new ProjectServiceQuestionWrapper(sqMap.get(projectServiceQuestion.Id));
                                                                         tl.add(sqw);
                                                                         childProjectServiceQuestionList.put(projectServiceQuestion.ParentProjectServiceQuestion__c, tl);
                                                                     }
                                                                     
                                                                     parentIdMap.put(projectServiceQuestion.Id, projectServiceQuestion.ParentProjectServiceQuestion__c);
                                                                 }
        
        Map<ID, ProjectServiceQuestion__c> sqob = new Map<ID, ProjectServiceQuestion__c>();
        
        integer ind = 1;
        sqs = new List<ProjectServiceQuestion__c>();
        
        for (ProjectServiceQuestion__c sq : sqMap.values()) {
            if (sqob.get(sq.id) == null) {
                sq.QuestionIndentation__c = string.valueOf(ind);
                ind++;
            }
            List<ProjectServiceQuestionWrapper> sqwList = childProjectServiceQuestionList.get(sq.id);
            
            if (sqwList != null) {
                
                integer i = 1;
                for (ProjectServiceQuestionWrapper sqw : sqwList) {
                    ProjectServiceQuestion__c parent = sqMap.get(parentIdMap.get(sqw.ProjectServiceQuestion.id));
                    
                    sqw.ProjectServiceQuestion.QuestionIndentation__c = parent.QuestionIndentation__c + string.valueOf('.' + i);
                    
                    sqob.put(sqw.ProjectServiceQuestion.ID, sqw.ProjectServiceQuestion);
                    i++;
                }
            }
            
            sqs.add(sq);
        }
        
        update sqs;
    }
        
    @AuraEnabled
    public static string saveProjectServiceQuestion(string questionWrapperInput) {
        
        try {
            string projectserviceid;
            QuestionWrapper question = (QuestionWrapper) JSON.deserialize(questionWrapperInput.replace('\n', ' '), QuestionWrapper.class);
            
            set<Id> psqdrIds = new Set<Id>();
            map<Id, DefinedResponseWrapper> mappsqdrwrapper = new map<Id, DefinedResponseWrapper>();
            
            for (DefinedResponseWrapper dr : question.DefinedResponses) {
                if (dr.ProjectServiceQuestionDefinedResponseId != '-1') {
                    psqdrIds.add(dr.ProjectServiceQuestionDefinedResponseId);
                    mappsqdrwrapper.put(dr.ProjectServiceQuestionDefinedResponseId, dr);
                }
                
            }
            
            
            ProjectServiceQuestion__c psq = [Select Id, Name, JumpToAction__c, ProjectService__c,
                                             MinValue__c, MaxValue__c,
                                             QuestionHint__c, AILabel__c
                                             from ProjectServiceQuestion__c
                                             WHERE Id = :question.ProjectServiceQuestionId LIMIT 1];
            
            
            psq.JumpToAction__c = question.JumpToAction;
            if (string.isEmpty(question.AILabelId)) {
                psq.AILabel__c = null;
            } else {
                psq.AILabel__c = question.AILabelId;
            }
            
            if (psq != null) {
                psq.QuestionHint__c = string.ValueOf(question.HintQuestion);
            }
            
            if (question.QuestionType == CONSTANTS.QUESTIONTYPE_NUMBER) {
                psq.MinValue__c = String.isBlank(question.MinValue) ? null : Integer.ValueOf(question.MinValue);
                psq.MaxValue__c = String.isBlank(question.MaxValue) ? null : Integer.ValueOf(question.MaxValue);
            }
            
            
            update psq;
            projectserviceid = psq.ProjectService__c;
            
            
            //Check if the question is a single select or a yes/no question
            //only then update the defined response else update question jumptoaction
            
            if (question.QuestionType == CONSTANTS.QUESTIONTYPE_MULTI_SELECT || question.QuestionType == CONSTANTS.QUESTIONTYPE_TARGET_MULTI_SELECT ||
                ((question.QuestionType == CONSTANTS.QUESTIONTYPE_SINGLE_SELECT ||
                  question.QuestionType == CONSTANTS.QUESTIONTYPE_YESNO)
                 && question.JumpToAction != CONSTANTS.QUESTIONJUMP_BRANCH)
               ) {
                   
                   List<ProjectServiceQuestionDefinedResponse__c> psqdrs = [Select Id, name, JumpToQuestion__c,
                                                                            EndOfQuestions__c, Active__c, JumpToAction__c, ProjectServiceQuestion__r.ProjectService__c
                                                                            FROM ProjectServiceQuestionDefinedResponse__c WHERE Id in :psqdrIds];
                   
                   for (ProjectServiceQuestionDefinedResponse__c psqdr : psqdrs) {
                       psqdr.JumpToQuestion__c = null;
                       psqdr.JumpToAction__c = null;
                       psqdr.Active__c = mappsqdrwrapper.get(psqdr.Id).Active;
                   }
                   
                   update psqdrs;
                   
               }
            
            
            
            if ((question.QuestionType == CONSTANTS.QUESTIONTYPE_SINGLE_SELECT ||
                 question.QuestionType == CONSTANTS.QUESTIONTYPE_YESNO)
                && question.JumpToAction == CONSTANTS.QUESTIONJUMP_BRANCH) {
                    
                    List<ProjectServiceQuestionDefinedResponse__c> psqdrs = [Select Id, name, JumpToQuestion__c,
                                                                             EndOfQuestions__c, Active__c, JumpToAction__c, ProjectServiceQuestion__r.ProjectService__c
                                                                             FROM ProjectServiceQuestionDefinedResponse__c WHERE Id in :psqdrIds];
                    
                    
                    for (ProjectServiceQuestionDefinedResponse__c psqdr : psqdrs) {
                        //Issue is here
                        //psqdr.JumpToQuestion__c = null;
                        //psqdr.JumpToAction__c = CONSTANTS.QUESTIONJUMP_CONTINUE;
                        
                        /*
if (mappsqdrwrapper.get(psqdr.Id).JumpToQuestion != CONSTANTS.QUESTIONJUMP_RETURN &&
mappsqdrwrapper.get(psqdr.Id).JumpToQuestion != CONSTANTS.QUESTIONJUMP_CONTINUE) {
psqdr.JumpToQuestion__c = mappsqdrwrapper.get(psqdr.Id).JumpToQuestion;
psqdr.JumpToAction__c = CONSTANTS.QUESTIONJUMP_QUESTION;

}

else {
psqdr.JumpToQuestion__c = null;
psqdr.JumpToAction__c = mappsqdrwrapper.get(psqdr.Id).JumpToQuestion;
}
*/
                        
                        psqdr.Active__c = mappsqdrwrapper.get(psqdr.Id).Active;
                        
                    }
                    
                    update psqdrs;
                }
            
            return getProjectServiceQuestionsApex(projectserviceid);
            
        } catch (DMLException ex) {
            throw new System.AuraHandledException(ex.getDmlMessage(0));
        } catch (Exception ex) {
            throw new System.AuraHandledException(ex.getMessage());
        }
        
    }
    
    @AuraEnabled
    public static string removeProjectServiceQuestionApex(string projectservicequestionid) {
        
        try {
            //Need to change the below method to remove serviceid
            //serviceid can be retrieved by questionid
            List<ID> allsqs = GetProjectServiceAllChildren('', projectservicequestionid);
            
            Set<Id> sqids = new Set<Id>(allsqs);
            sqids.add(projectservicequestionid);
            
            List<ProjectServiceQuestion__c> sqs = [SELECT Id, name, ProjectService__c, Question__c
                                                   from ProjectServiceQuestion__c WHERE Id IN :sqids];
            
            string projectServiceId;
            
            if (!sqs.isEmpty()) {
                projectServiceId = sqs[0].ProjectService__c;
                
                //Check if there are any question rules
                List<ProjectServiceQuestionRule__c> sqrules = [Select Id, Name from ProjectServiceQuestionRule__c
                                                               WHERE ParentProjectServiceQuestion__c in :sqids];
                if (!sqrules.isEmpty()) {
                    delete sqrules;
                }
                
                delete sqs;
                
                
                //Query to check if there is any target group
                List<ProjectServiceQuestion__c> sqGroupQuestionList = [Select Id
                                                                       FROM ProjectServiceQuestion__c
                                                                       WHERE ProjectService__c = :projectServiceId
                                                                       AND Question__r.ItemQuestion__c = true];
                
                if (sqGroupQuestionList == null || sqGroupQuestionList.size() == 0) {
                    List<ProjectServiceQuestion__c> sqParentTargetGroupList = [Select Id
                                                                               FROM ProjectServiceQuestion__c
                                                                               WHERE ProjectService__c = :projectServiceId
                                                                               AND Question__r.QuestionText__c = : CONSTANTS.QUESTIONTYPE_TARGET_GROUP
                                                                               Limit 1];
                    
                    if (sqParentTargetGroupList != null) {
                        delete sqParentTargetGroupList;
                    }
                }
                
                ResetProjectServiceQuestionNumber(projectserviceid);
                setProjectQuestionIndentation(projectserviceid);
            }
            
            return '';
            
        } catch (Exception ex) {
            throw new System.AuraHandledException(ex.getMessage());
        }
        
    }
        
    private static void ResetProjectServiceQuestionNumber(String projectServiceId) {
        List<ProjectServiceQuestion__c> sqs = [SELECT Id, QuestionNumber__c, QuestionIndentation__c , ParentProjectServiceQuestion__c
                                               FROM ProjectServiceQuestion__c WHERE ProjectService__c = :projectServiceId
                                               ORDER BY QuestionNumber__c];
        
        ResetProjectServiceQuestionNumber(sqs);
        
    }
    
    private static void ResetProjectServiceQuestionNumber(List<ProjectServiceQuestion__c> sqs) {
        Integer qno = 1;
        for (ProjectServiceQuestion__c sq : sqs) {
            sq.QuestionNumber__c = qno;
            qno++;
            
        }
        update sqs;
    }
    
    public static List<ID> GetProjectServiceAllChildren(String projectserviceid, ID sqID) {
        if (String.isEmpty(projectserviceid)) {
            projectserviceid = [Select Id, ProjectService__c from ProjectServiceQuestion__c WHERE Id = : sqID].ProjectService__c;
        }
        
        Map<Id, List<ID>> childProjectServiceQuestionList = new Map<Id, List<ID>>();
        
        for (ProjectServiceQuestion__c projectServiceQuestion : [SELECT Id, ParentProjectServiceQuestion__c FROM ProjectServiceQuestion__c where ProjectService__c = :projectserviceid Order By QuestionNumber__c]) {
            
            if (childProjectServiceQuestionList.containsKey(projectServiceQuestion.ParentProjectServiceQuestion__c)) {
                
                List<ID> childProjectServiceQuestionId = childProjectServiceQuestionList.get(projectServiceQuestion.ParentProjectServiceQuestion__c);
                childProjectServiceQuestionId.add(projectServiceQuestion.Id);
                childProjectServiceQuestionList.put(projectServiceQuestion.ParentProjectServiceQuestion__c, childProjectServiceQuestionId);
            } else {
                
                List<ID> childProjectServiceQuestionId = new List<ID>();
                childProjectServiceQuestionId.add(projectServiceQuestion.Id);
                childProjectServiceQuestionList.put(projectServiceQuestion.ParentProjectServiceQuestion__c, childProjectServiceQuestionId);
            }
        }
        
        List<ID> sqIds = new List<ID>();
        List<ID> resultList = new List<ID>();
        List<ID> childIds = new List<ID>();
        childIds.add(sqID);
        
        integer i = 0;
        boolean hasChild = true;
        
        while (hasChild) {
            childIds = GetChildren(childProjectServiceQuestionList, childIds);
            
            if (childIds.size() == 0) {
                hasChild = false;
            } else {
                resultList.addAll(childIds);
            }
        }
        
        return resultList;
    }
    
    @AuraEnabled
    public static string GetProjectServiceQuestionRule(string serviceProjectQuestionRuleId) {
        
        string returnValue = '';
        
        List<ProjectServiceQuestionRule__c> projectServiceQuestions = [select Id, name, Operator__c, ParentProjectServiceQuestion__c,
                                                                       ProjectServiceQuestion__c , DefinedResponseValue__c, ProjectServiceQuestionText__c, value__c,
                                                                       ParentProjectServiceQuestionText__c
                                                                       FROM ProjectServiceQuestionRule__c
                                                                       WHERE ID = : serviceProjectQuestionRuleId limit 1];
        
        if (projectServiceQuestions != null && projectServiceQuestions.size() > 0) {
            //ProjectServiceQuestionRuleWrapper sqrule = new ProjectServiceQuestionRuleWrapper(projectServiceQuestions[0]);
            
            QuestionWrapper customquestion = GetProjectServiceQuestionWithDefinedResponses(projectServiceQuestions[0].ParentProjectServiceQuestion__c, projectServiceQuestions);
            
            ResponseWrapper rw = ResponseWrapper.getInstance(CONSTANTS.RESPONSE_STATE_SUCCESS, 'Successfully retrieved the DefinedResponses', customquestion);
            
            returnValue = JSON.serialize(rw);
        }
        
        
        return returnValue;
    }
    
    @AuraEnabled
    public static QuestionWrapper GetProjectServiceQuestionWithDefinedResponses(string parentsqId, List<ProjectServiceQuestionRule__c> projectServiceqQestions) {
        
        ServiceQuestionRuleWrapper sqrw = new ServiceQuestionRuleWrapper();
        If(projectServiceqQestions.size() > 0) {
            ProjectServiceQuestionRule__c sqr = projectServiceqQestions[0];
            sqrw.Id = sqr.Id;
            sqrw.ParentServiceQuestion = sqr.ParentProjectServiceQuestion__c;
            sqrw.ServiceQuestion = sqr.ProjectServiceQuestion__c;
            sqrw.SqOperator = sqr.Operator__c;
            sqrw.SqValue = sqr.value__c;
        }
        
        List<ProjectServiceQuestionDefinedResponse__c> projectServicequestionDefinedResponses = [SELECT Id,
                                                                                                 ProjectServiceQuestion__c,
                                                                                                 QuestionDefinedResponse__c,
                                                                                                 QuestionDefinedResponse__r.DefinedResponseOrder__c,
                                                                                                 DefinedResponseText__c,
                                                                                                 QuestionDefinedResponse__r.OneHubAnswerId__c,
                                                                                                 CanRemove__c,
                                                                                                 JumpToQuestion__c,
                                                                                                 EndOfQuestions__c,
                                                                                                 ProjectServiceQuestion__r.QuestionNumber__c,
                                                                                                 ProjectServiceQuestion__r.Question__r.ItemQuestion__c,
                                                                                                 ProjectServiceQuestion__r.Question__c,
                                                                                                 JumpToAction__c,
                                                                                                 QuestionDefinedResponse__r.Exception__r.ExceptionCode__c,
                                                                                                 ProjectServiceQuestion__r.Question__r.QuestionType__c,
                                                                                                 Active__c
                                                                                                 FROM ProjectServiceQuestionDefinedResponse__c
                                                                                                 WHERE ProjectServiceQuestion__c = :parentsqId
                                                                                                 ORDER BY QuestionDefinedResponse__r.DefinedResponseOrder__c];
        
        
        if (projectServicequestionDefinedResponses.size() == 0) {
            throw new System.AuraHandledException('Parent Service Defined Response Count shows zero');
        }
        
        List<DefinedResponseWrapper> drList = new  List<DefinedResponseWrapper>();
        for ( ProjectServiceQuestionDefinedResponse__c sqdr : projectServicequestionDefinedResponses) {
            DefinedResponseWrapper dr = new DefinedResponseWrapper();
            dr.DefinedResponseId = sqdr.QuestionDefinedResponse__c;
            dr.DefinedResponseText = sqdr.DefinedResponseText__c;
            dr.DefinedResponseOrder = Integer.ValueOf(sqdr.QuestionDefinedResponse__r.DefinedResponseOrder__c);
            dr.ProjectServiceQuestionDefinedResponseId = sqdr.Id;
            dr.CanRemove = sqdr.CanRemove__c == null || sqdr.CanRemove__c == false ? false : true;
            dr.EndOfQuestions = sqdr.EndOfQuestions__c;
            dr.ExceptionCode =  sqdr.QuestionDefinedResponse__r.Exception__r.ExceptionCode__c;
            dr.Active = sqdr.Active__c;
            drList.add(dr);
        }
        
        
        List<ProjectServiceQuestion__c> servicequestion = [SELECT Id, Question__c, Question__r.Description__c, Question__r.Name, Question__r.QuestionText__c FROM ProjectServiceQuestion__c WHERE Id = :parentsqId ];
        QuestionWrapper customquestion = new QuestionWrapper();
        if (servicequestion.size() > 0) {
            ProjectServiceQuestion__c sq  = servicequestion[0];
            customquestion.QuestionId = sq.Question__c;
            customquestion.QuestionTitle = sq.Question__r.Name;
            customquestion.QuestionText = sq.Question__r.QuestionText__c;
            customquestion.DefinedResponses = drList;
            customquestion.ServiceQuestionRule = sqrw;
            
        }
        
        return customquestion;
        
    }
    
    @AuraEnabled
    public static string GetProjectSqDefinedResponses(string parentsqId, string sqId) {
        
        
        if (string.isEmpty(parentsqId ) ) {
            throw new System.AuraHandledException('Parent Service Question Id  not blank');
        }
        if (string.isEmpty(sqId) ) {
            throw new System.AuraHandledException(' Service Question Id not blank');
        }
        
        List<ProjectServiceQuestionRule__c> projectServicequestions = [SELECT Id, name, Operator__c, ParentProjectServiceQuestion__c, value__c,
                                                                       ProjectServiceQuestion__c , DefinedResponseValue__c,
                                                                       ProjectServiceQuestionText__c, ParentProjectServiceQuestionType__c, DefinedResponseValueText__c,
                                                                       ParentProjectServiceQuestionText__c
                                                                       FROM ProjectServiceQuestionRule__c
                                                                       WHERE ParentProjectServiceQuestion__c = :parentsqId
                                                                       AND ProjectServiceQuestion__c = :sqId];
        
        List<ServiceQuestionRuleWrapper> projectServiceQuestionRuleWrapperList = new List<ServiceQuestionRuleWrapper>();
        
        List<String> ruleValueTest = new List<String>();
        
        If(projectServicequestions.size() > 0) {
            
            for (ProjectServiceQuestionRule__c psQuestionRule : projectServicequestions) {
                ServiceQuestionRuleWrapper sqr = new ServiceQuestionRuleWrapper(psQuestionRule);
                
                projectServiceQuestionRuleWrapperList.add(sqr);
                ruleValueTest.add(sqr.RuleText);
            }
            
        }
        List<ProjectServiceQuestionDefinedResponse__c> projectServicequestionDefinedResponses = [SELECT Id, ProjectServiceQuestion__c, QuestionDefinedResponse__c,
                                                                                                 QuestionDefinedResponse__r.DefinedResponseOrder__c, DefinedResponseText__c,
                                                                                                 QuestionDefinedResponse__r.OneHubAnswerId__c, CanRemove__c, JumpToQuestion__c, EndOfQuestions__c,
                                                                                                 ProjectServiceQuestion__r.QuestionNumber__c, ProjectServiceQuestion__r.Question__r.ItemQuestion__c,
                                                                                                 ProjectServiceQuestion__r.Question__c,
                                                                                                 JumpToAction__c, QuestionDefinedResponse__r.Exception__r.ExceptionCode__c,
                                                                                                 ProjectServiceQuestion__r.Question__r.QuestionType__c,
                                                                                                 Active__c FROM ProjectServiceQuestionDefinedResponse__c
                                                                                                 WHERE ProjectServiceQuestion__c = :parentsqId
                                                                                                 AND Active__c = true
                                                                                                 ORDER BY QuestionDefinedResponse__r.DefinedResponseOrder__c];
        
        if (projectServiceQuestionDefinedResponses.size() == 0) {
            throw new System.AuraHandledException('Parent Service Defined Response Count shows zero');
        }
        
        List<DefinedResponseWrapper> drList = new  List<DefinedResponseWrapper>();
        for ( ProjectServiceQuestionDefinedResponse__c sqdr : projectServicequestionDefinedResponses) {
            DefinedResponseWrapper dr = new DefinedResponseWrapper();
            dr.DefinedResponseId = sqdr.QuestionDefinedResponse__c;
            dr.DefinedResponseText = sqdr.DefinedResponseText__c;
            dr.DefinedResponseOrder = Integer.ValueOf(sqdr.QuestionDefinedResponse__r.DefinedResponseOrder__c);
            dr.ProjectServiceQuestionDefinedResponseId = sqdr.Id;
            dr.CanRemove = sqdr.CanRemove__c == null || sqdr.CanRemove__c == false ? false : true;
            dr.EndOfQuestions = sqdr.EndOfQuestions__c;
            dr.ExceptionCode =  sqdr.QuestionDefinedResponse__r.Exception__r.ExceptionCode__c;
            dr.Active = sqdr.Active__c;
            drList.add(dr);
        }
        
        
        List<ProjectServiceQuestion__c> projectServiceQuestion = [SELECT Id, Question__c, Question__r.Description__c, Question__r.Name, Question__r.QuestionText__c, Question__r.QuestionType__c
                                                                  FROM ProjectServiceQuestion__c WHERE Id = :parentsqId ];
        QuestionWrapper customquestion = new QuestionWrapper();
        if (projectServiceQuestion.size() > 0) {
            ProjectServiceQuestion__c sq  = projectServiceQuestion[0];
            customquestion.QuestionId = sq.Question__c;
            customquestion.QuestionTitle = sq.Question__r.Name;
            customquestion.QuestionText = sq.Question__r.QuestionText__c;
            customquestion.QuestionType = sq.Question__r.QuestionType__c;
            customquestion.DefinedResponses = drList;
            customquestion.ServiceQuestionRule = new ServiceQuestionRuleWrapper();
            
            if (projectServiceQuestionRuleWrapperList.size() > 0) {
                customquestion.ServiceQuestionRule = projectServiceQuestionRuleWrapperList[0];
                customquestion.ServiceQuestionRule.RuleValueText = ruleValueTest;
                customquestion.ServiceQuestionRuleList = projectServiceQuestionRuleWrapperList;
            }
            
        }
        
        ResponseWrapper rw = ResponseWrapper.getInstance(CONSTANTS.RESPONSE_STATE_SUCCESS, 'Successfully retrieved the DefinedResponses', customquestion);
        String returnString = JSON.serialize(rw);
        
        return returnString;
        
    }
    
    
    @AuraEnabled
    public static void addProjectServiceQuestionRule(string projectServiceId , string sqId, string psqId, string sop, string drl) {
        try {
            boolean isUpdate = false;
            
            //SObject row was retrieved via SOQL without querying the requested field: ServiceQuestionRule__c.DefinedResponseValue__c
            List<ProjectServiceQuestionRule__c> sqrList = new List<ProjectServiceQuestionRule__c>();
            List<String> parsedDrl = (List<String>) JSON.deserialize(drl, List<String>.class);
            List<ProjectServiceQuestionDefinedResponse__c> sqDefinedResponse = [SELECT Id, DefinedResponseText__c FROM ProjectServiceQuestionDefinedResponse__c where id  IN :parsedDrl];
            
            
            List<ProjectServiceQuestionRule__c> lstsqr = [SELECT Id, name, Operator__c,
                                                          ParentProjectServiceQuestion__c,
                                                          ProjectServiceQuestion__c ,
                                                          DefinedResponseValue__c,
                                                          value__c,
                                                          DefinedResponseValueText__c
                                                          FROM ProjectServiceQuestionRule__c
                                                          WHERE  ProjectServiceQuestion__c = :sqId];
            
            if (lstsqr != null && lstsqr.size() > 0) {
                delete lstsqr;
            }
            
            for (String drls : parsedDrl ) {
                ProjectServiceQuestionRule__c objSqr = new ProjectServiceQuestionRule__c();
                objSqr.ProjectServiceQuestion__c = string.valueOf(sqId);
                objSqr.ParentProjectServiceQuestion__c = string.valueOf(psqId);
                objSqr.Operator__c = string.valueOf(sop);
                objSqr.value__c = string.valueOf(drls);
                sqrList.add(objSqr);
            }
            
            insert sqrList;
            
            // To update parent question id in Service Question Object
            ProjectServiceQuestion__c projectServiceQuestion = [SELECT Id, ParentProjectServiceQuestion__c,
                                                                QuestionIndentation__c,
                                                                QuestionNumber__c,
                                                                ProjectService__c
                                                                FROM ProjectServiceQuestion__c
                                                                where  Id = :sqId];
            
            if ((projectServiceQuestion != null) && (projectServiceQuestion.ParentProjectServiceQuestion__c == psqId)) {
                isUpdate = true;
            }
            
            if (!isUpdate) {
                projectServiceQuestion.ParentProjectServiceQuestion__c = psqId;
                update projectServiceQuestion;
                
                // To set auto number and indentation
                RearrangeProjectServiceQuestionOrder(projectServiceId, string.valueOf(sqId), string.valueOf(psqId), false);
            }
            
        } catch (DMLException ex) {
            throw new System.AuraHandledException(ex.getDmlMessage(0));
        } catch (Exception ex) {
            throw new System.AuraHandledException(ex.getMessage());
        }
    }
    
    
    public static void RearrangeProjectServiceQuestionOrder(String projectServiceid, string question, string parentQuestion, boolean reOrder) {
        
        Integer qIndex = -1;
        Integer parentIndex = -1;
        
        if (parentQuestion == null) { parentQuestion = ''; }
        
        List<ProjectServiceQuestion__c> sqs = [SELECT Id, QuestionNumber__c, QuestionIndentation__c , ParentProjectServiceQuestion__c
                                               FROM ProjectServiceQuestion__c WHERE ProjectService__c = : projectServiceid
                                               ORDER BY QuestionNumber__c];
        
        Integer index = 0;
        for (ProjectServiceQuestion__c sq : sqs) {
            if (sq.ID == question) {qIndex = index;}
            if (sq.ID == parentQuestion) {parentIndex = index;}
            
            //To break when question id and parent id are fetched
            if (qIndex > -1 && parentIndex > -1) {
                break;
            }
            
            index++;
        }
        
        ProjectServiceQuestion__c sq = sqs.get(qIndex);
        ProjectServiceQuestion__c sqParentObj = sqs.get(parentIndex);
        
        if (reOrder) {
            
            if (sqParentObj.ParentProjectServiceQuestion__c == null || String.isEmpty(String.valueOf(sqParentObj.ParentProjectServiceQuestion__c)))  {
                deleteProjectServiceQuestionRule(projectServiceid, question);
                sq.ParentProjectServiceQuestion__c = NULL;
            }
            
            sqs.remove(qIndex);
            
            if (parentQuestion == '') {
                sqs.add(0, sq);
            } else {
                if (sqs.size() <= parentIndex) {
                    sqs.add(sq);
                } else {
                    sqs.add(parentIndex + (parentIndex > qIndex ? 0 : 1), sq);
                }
            }
        } else {
            
            List<ID> childs = GetProjectServiceAllChildren(projectServiceid, question);
            
            List<ID> parentsChilds = GetProjectServiceAllChildren(projectServiceid, parentQuestion);
            
            List<ProjectServiceQuestion__c> toBeRemovedSQ = new List<ProjectServiceQuestion__c>();
            
            for (Integer i = qIndex; i <= (qIndex + childs.size()); i++) {
                toBeRemovedSQ.add(sqs.get(i));
            }
            
            for (Integer i = qIndex, j = qIndex; i <= (qIndex + childs.size()); i++) {
                sqs.remove(j);
            }
            
            integer parentsExsitingChilds = parentsChilds.size() - (childs.size() + 1);
            
            if (qIndex > parentIndex) {
                parentIndex = parentIndex + parentsExsitingChilds + 1;
                
            } else {
                parentIndex = parentIndex + (parentsExsitingChilds - childs.size());
            }
            
            
            boolean addToBottom = (sqs.size() <= parentIndex);
            
            for (ProjectServiceQuestion__c rsq : toBeRemovedSQ) {
                
                if (addToBottom) {
                    sqs.add(rsq);
                } else {
                    sqs.add(parentIndex, rsq);
                }
                parentIndex++;
            }
            
        }
        
        Integer qno = 1;
        
        for (ProjectServiceQuestion__c sqobj : sqs) {
            sqobj.QuestionNumber__c = qno;
            qno++;
        }
        
        update sqs;
        
        setProjectQuestionIndentation(projectserviceid);
    }
    
    
    @AuraEnabled
    public static void deleteProjectServiceQuestionRule(string serviceId , string sqId) {
        List<ProjectServiceQuestionRule__c> lstsqr = [select Id, name, Operator__c, ParentProjectServiceQuestion__c, ProjectServiceQuestion__c, value__c
                                                      FROM ProjectServiceQuestionRule__c
                                                      WHERE  ProjectServiceQuestion__c = :sqId];
        if (lstsqr.size() > 0) {
            delete lstsqr;
        }
        
    }
    
    @AuraEnabled
    public static string ReorderProjectServiceQuestion(String projectServiceId, String questionId, String precedingQuestionId) {
        
        Integer qIndex = -1;
        Integer precedingIndex = -1;
        Integer qChildCount = 0;
        Integer questionNumber = 1;
        Integer count = 0;
        
        Map<String, ProjectServiceQuestion__c> sqMap = new Map<String, ProjectServiceQuestion__c>();
        ProjectServiceQuestion__c precedingSqObj = new ProjectServiceQuestion__c();
        ProjectServiceQuestion__c sqObj = new ProjectServiceQuestion__c();
        List<ProjectServiceQuestion__c> lstOfQuestionNode = new List<ProjectServiceQuestion__c>();
        List<ProjectServiceQuestion__c> reversed = new List<ProjectServiceQuestion__c>();
        
        List<ProjectServiceQuestion__c> lst = [SELECT Id, QuestionText__c, IsItemQuestion__c, QuestionNumber__c, QuestionIndentation__c , ParentProjectServiceQuestion__c
                                               FROM ProjectServiceQuestion__c
                                               WHERE ProjectService__c = :projectServiceId
                                               ORDER BY QuestionNumber__c];
        
        //To make sure even if question number goes out of sync it is reset to continous number
        for (ProjectServiceQuestion__c sq : lst) {
            
            sq.QuestionNumber__c = questionNumber++;
            sqMap.put(sq.Id, sq);
        }
        
        if (sqMap.containsKey(questionId)) {
            qIndex =  sqMap.get(questionId).QuestionNumber__c.intValue() - 1;
            sqObj = sqMap.get(questionId);
            List<ID> childs = GetProjectServiceAllChildren(projectServiceId, questionId);
            if (childs != null) {
                qChildCount = childs.size();
            }
        }
        
        Integer parentsChildCount = 0;
        
        if (sqMap.containsKey(precedingQuestionId)) {
            precedingSqObj = sqMap.get(precedingQuestionId);
            precedingIndex = sqMap.get(precedingQuestionId).QuestionNumber__c.intValue() - 1;
            
            List<ID> parentsChilds = GetProjectServiceAllChildren(projectServiceId, precedingQuestionId);
            if (parentsChilds != null) {
                precedingIndex = precedingIndex + parentsChilds.size();
            }
            
        }
        
        if ((precedingSqObj.ParentProjectServiceQuestion__c == null || String.isEmpty(String.valueOf(precedingSqObj.ParentProjectServiceQuestion__c))) ||
            precedingSqObj.QuestionText__c == constants.QUESTIONTYPE_TARGET_GROUP)  {
                deleteProjectServiceQuestionRule(projectServiceId, questionid);
                sqObj.ParentProjectServiceQuestion__c = (precedingSqObj.QuestionText__c == constants.QUESTIONTYPE_TARGET_GROUP && sqObj.IsItemQuestion__c) ? precedingSqObj.Id : NULL;
            }
        
        
        for (Integer i = qIndex; i <= qIndex + qChildCount; i++) {
            lstOfQuestionNode.add(lst[qIndex]);
            lst.remove(qIndex);
            count++;
        }
        
        if (precedingIndex >= qIndex) { precedingIndex = (precedingIndex - count); }
        
        if (precedingIndex < (lst.size() - 1)) {
            
            integer val = precedingIndex + 1;
            integer serviceQuestionListSize = lst.size();
            
            for (Integer i = precedingIndex + 1 ; i < serviceQuestionListSize; i++) {
                lstOfQuestionNode.add(lst[i]);
            }
            
            for (Integer i = precedingIndex + 1 ; i < serviceQuestionListSize; i++) {
                lst.remove(val);
            }
        }
        
        lst.addAll(lstOfQuestionNode);
        
        questionNumber = 1;
        
        for (ProjectServiceQuestion__c sq : lst) {
            sq.QuestionNumber__c = questionNumber++;
        }
        
        UPDATE lst;
        
        setProjectQuestionIndentation(projectServiceId);
        
        return getProjectServiceQuestionsApex(projectServiceId);
    }
    
    @AuraEnabled
    public static string getProjectServiceApex(string projectserviceid) {
        
        projectService__c ps = [Select Id, Name, SurveyComplexityScore__c, SurveyScoreThreshold__c,
                                IsSurveyScoreExceedThreshold__c, IsSurveyScoreWarning__c,
                                ServiceName__c, ServiceTitle__c, ProjectNumber__c, SurveyScoreWarning__c,
                                SurveyComplexityScoreDRPercent__c, SurveyComplexityScoreTQPercent__c,
                                SurveyComplexityScoreJumpPercent__c, Project__c, SurveyComplexityScoreQPercent__c
                                FROM ProjectService__c WHERE Id = :projectserviceid];
        
        
        String psstring = JSON.serialize(ps);
        String psstringsansuuc = psstring.replace('__c', '');
        
        String psstringsamsns = psstringsansuuc.replace(CONSTANTS.CURRENTNAMESPACEPREFIX, '');
        
        return psstringsamsns;
        
    }
    @AuraEnabled
    public static string getUISecurityInformationApexSurvey(string recordid) {
        if (!String.isEmpty(recordid)) {
            string ret = null;
            ret = LightningUISecurityController.getUISecurityInformationApex(recordid);
            return ret;
        } else {
            return null;
        }
    }
    
    @AuraEnabled
    public static List<AILabel__c> getAILabelOptions() {
        List<AILabel__c> AILabels = [Select Id, Name, Description__c
                                     from AILabel__c];
        if (AILabels.size() > 0) {
            return AILabels;
        } else {
            return null;
        }
    }
    
    @AuraEnabled
    public static List<string> AddTargets_SurveyResponse(String searchIds, string projservQnId) 
    {
        List<String> idsNotFoundOrAlreadyExist = new List<String>();
        try{
            Set<String> uniqueList = (Set<String>)JSON.deserialize(searchIds, Set<String>.class);            
            list<Target__c> targetList = [SELECT Name, Id, 
                                          UPC__c, 
                                          description__c, 
                                          ImageUrl__c, 
                                          status__c,
                                          RecordType.Name,
                                          StockCode__c, 
                                          AccountInfo__c
                                          FROM Target__c
                                          WHERE (UPC__c in :uniqueList or StockCode__c in :uniqueList or Id in :uniqueList) 
                                          AND Status__c = 'Active'];
            
            ProjectServiceQuestion__c psqObj = [SELECT Id,Question__c from ProjectServiceQuestion__c where id =:projservQnId limit 1]; 		
            list<QuestionDefinedResponse__c> DefRespList = [SELECT Id,question__c from QuestionDefinedResponse__c where Question__c =: psqObj.Question__c];
            
            ProjectServiceQuestionDefinedResponse__c  psqResp;
            list<ProjectServiceQuestionDefinedResponse__c> psqRespList = new list<ProjectServiceQuestionDefinedResponse__c>();
            for(Target__c obj : targetList)
            {
                psqResp = new ProjectServiceQuestionDefinedResponse__c();
                psqResp.QuestionDefinedResponse__c= DefRespList[0].id; 
                psqResp.ProjectServiceQuestion__c = psqObj.id;
                psqResp.Target__c = obj.id;
                psqResp.Active__c = true;
                psqResp.CanRemove__c = true;
                psqRespList.add(psqResp);
            }
            insert psqRespList;            
        }
        catch (Exception e) {
            System.debug(e);
        }
        return idsNotFoundOrAlreadyExist;
    }
    
    @AuraEnabled
    public static boolean getMultiListCheckApex() {        
        OrgCustomSettings__c settings = OrgCustomSettings__c.getInstance('Setting');
        return boolean.valueOf(settings.EnableMultiListQnsDragnDrop__c);
    }
}