public with sharing class LightningSurveyQuestionsController {

    //Common methods to both Service and ProjectService
    @AuraEnabled
    public static List<QuestionWrapper> getAvailableSurveyQuestions(string questiontext, string questiontype, boolean targetquestion, string recordid) {

        try {
            if (String.isBlank(recordid)) {
                throw new AuraHandledException('Survey Id can not be null.');
            }

            string projectserviceid = '';
            string serviceid = '';
            ProjectService__c ps;
            Boolean fromProjectService = false;

            Id recid = Id.ValueOf(recordid);

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

            if (fromProjectService) {
                if (ps.Service__r.LimitQuestionstoFamily__c == true ) {
                    baseQuery += 'AND Id IN (Select Question__c FROM ServiceFamilyQuestions__c WHERE ServiceFamily__c  = \'' + ps.Service__r.ServiceFamily__c + '\') ';
                }
            } 

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

            SurveyState surveyStateDef = fromProjectService
                ? SurveyState.fromProjectBuilder(projectserviceid)
                : SurveyState.fromServiceBuilder(serviceid);

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
        }

        catch (Exception ex) {
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



    //ProjectService Methods

    private static void ReOrderProjectServiceQuestions(List<ProjectServiceQuestion__c> psqs) {
        Integer qno = 1;
        for (ProjectServiceQuestion__c psq : psqs) {
            psq.QuestionNumber__c = qno;
            qno++;

        }

        update psqs;

    }

    @AuraEnabled
    public static string getProjectServiceApex(string projectserviceid) {


        projectService__c ps = [Select Id, Name, SurveyComplexityScore__c, SurveyScoreThreshold__c,
                                IsSurveyScoreExceedThreshold__c, IsSurveyScoreWarning__c,
                                ServiceName__c, ServiceTitle__c, ProjectNumber__c, SurveyScoreWarning__c,
                                SurveyComplexityScoreDRPercent__c, SurveyComplexityScoreTQPercent__c,
                                SurveyComplexityScoreJumpPercent__c, SurveyComplexityScoreQPercent__c
                                FROM ProjectService__c WHERE Id = :projectserviceid];


        String psstring = JSON.serialize(ps);
        String psstringsansuuc = psstring.replace('__c', '');

        String psstringsamsns = psstringsansuuc.replace(CONSTANTS.CURRENTNAMESPACEPREFIX, '');


        system.debug(psstringsamsns);
        return psstringsamsns;

    }

    //oh3392
    static Map<Id, Boolean> getServiceQuestionOptions(String projectServiceId) {
        List<ServiceQuestion__c> questions = [SELECT Question__c, Optional__c
                                              from ServiceQuestion__c
                                              WHERE Service__c in (SELECT Service__c FROM ProjectService__c WHERE Id = :projectServiceId)];
        Map<Id, Boolean> result = new Map<Id, Boolean>();
        for (ServiceQuestion__c q : questions) {
            result.put(q.Question__c, q.Optional__c);
        }
        return result;
    }

    @AuraEnabled
    public static list<ProjectServiceTargetWrapper> GetProjectServiceTargets(String projectServiceId) {

        return LightningProjectServiceTargetsController.GetProjectServiceTargets(projectServiceId);

    }

    @AuraEnabled
    public static string getProjectServiceQuestionsApex(string projectserviceid) {

        try {

            system.debug('PS Id1: ' + projectserviceid);

            if (projectserviceid == null || projectserviceid == '') {
                return '';
            }
            List<QuestionWrapper> customquestions = new List<QuestionWrapper>();

            Map<Question__c, List<QuestionDefinedResponse__c>> mapQuestionInfo = new Map<Question__c, List<QuestionDefinedResponse__c>>();



            List<ProjectServiceQuestion__c> projectservicequestions = [SELECT Id, Question__c, Question__r.Active__c, Question__r.Description__c, QuestionHint__c, HintLock__c,
                                            Question__r.IsQuestionVisibleToClient__c, Question__r.ItemQuestion__c, Question__r.Name, AILabel__c, AILabel__r.Name,
                                            Question__r.OneHubQuestionId__c, Question__r.QuestionText__c, Question__r.QuestionType__c,
                                            Question__r.ReplaceByOneHubQuestionId__c, Question__r.TargetType__c, Question__r.DefinedResponseCount__c, MinValue__c, MaxValue__c,
                                            ServiceQuestion__c, CanRemove__c, QuestionNumber__c, Active__c, JumpToAction__c, Optional__c, Question__r.ExceptionQuestion__c
                                            FROM ProjectServiceQuestion__c WHERE ProjectService__c = :projectserviceid
                                                    ORDER BY QuestionNumber__c];



            //List<Question__c> questions = Database.query(baseQuery);
            Map<Id, Integer> mapQuestionNumber = new Map<Id, Integer>();
            Map<Id, ProjectServiceQuestion__c> mapQuestions = new Map<Id, ProjectServiceQuestion__c>();
            for (ProjectServiceQuestion__c psq : projectservicequestions ) {
                Integer qno = psq.QuestionNumber__c == null ? 0 : Integer.ValueOf(psq.QuestionNumber__c);
                mapQuestionNumber.put(psq.Question__c, qno);
                mapQuestions.put(psq.Id, psq);

            }

            Set<Id> setQuestionIds = mapQuestions.keySet();

            system.debug('questions: ' + setQuestionIds);
            system.debug('questions length: ' + setQuestionIds.size());

            List<ProjectServiceQuestionDefinedResponse__c> projectservicequestionDefinedResponses = [SELECT Id, ProjectServiceQuestion__c, QuestionDefinedResponse__c, Question__c,
                                                           QuestionDefinedResponse__r.DefinedResponseOrder__c, DefinedResponseText__c,
                                                           QuestionDefinedResponse__r.OneHubAnswerId__c, CanRemove__c, JumpToQuestion__c, EndOfQuestions__c, Active__c,
                                                           ProjectServiceQuestion__r.QuestionNumber__c, ProjectServiceQuestion__r.Question__r.ItemQuestion__c,
                                                           JumpToAction__c, QuestionDefinedResponse__r.Exception__r.ExceptionCode__c, ProjectServiceQuestion__r.Question__r.QuestionType__c
                                                           FROM ProjectServiceQuestionDefinedResponse__c
                                                           WHERE ProjectServiceQuestion__c in :setQuestionIds ORDER BY QuestionDefinedResponse__r.DefinedResponseOrder__c];

            system.debug('projectservicequestionDefinedResponses: ' + projectservicequestionDefinedResponses);
            system.debug('psqdr length: ' + projectservicequestionDefinedResponses.size());


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
                lstjtq = getAllowedJumps(psqdr, projectservicequestions);
                mapAllowedJumpToQuestions.put(psqdr.Id, lstjtq );

            }

            system.debug('MAP PSQDR: ' + mappsqdr);
            String firstItemQuestionId = '';
            String lastItemQuestionId = '';

            //oh3392
            Map<Id, Boolean> svcQuestionMap = getServiceQuestionOptions(projectserviceid);


            for (ProjectServiceQuestion__c psq : projectservicequestions ) {
                List<DefinedResponseWrapper> drList = new List<DefinedResponseWrapper>();
                if (psq.Question__r.DefinedResponseCount__c > 0) {
                    for (ProjectServiceQuestionDefinedResponse__c psqdr : mappsqdr.get(psq.Id)) {

                        DefinedResponseWrapper dr = new DefinedResponseWrapper();

                        dr.DefinedResponseId = psqdr.QuestionDefinedResponse__c;
                        dr.DefinedResponseText = psqdr.DefinedResponseText__c;
                        dr.CanRemove = psqdr.CanRemove__c;
                        dr.DefinedResponseOrder = Integer.ValueOf(psqdr.QuestionDefinedResponse__r.DefinedResponseOrder__c);
                        dr.ProjectServiceQuestionDefinedResponseId = psqdr.Id;
                        dr.CanRemove = psqdr.CanRemove__c;
                        system.debug('JTQ: ' + psqdr.JumpToQuestion__c + ' JTA: ' + psqdr.JumpToAction__c);
                        dr.JumpToQuestion = psqdr.JumpToQuestion__c == null || String.ValueOf(psqdr.JumpToQuestion__c)
                                            == '' ? psqdr.JumpToAction__c : psqdr.JumpToQuestion__c;
                        dr.EndOfQuestions = psqdr.EndOfQuestions__c;
                        dr.Active = psqdr.Active__c;

                        dr.ExceptionCode = psqdr.QuestionDefinedResponse__r.Exception__r.ExceptionCode__c;


                        dr.JumpToQuestionNumber = mapQuestionNumber.get(psqdr.JumpToQuestion__c);
                        dr.AllowedJumpToQuestions = mapAllowedJumpToQuestions.get(psqdr.Id);
                        drList.add(dr);
                    }

                }

                QuestionWrapper customquestion = new QuestionWrapper();
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



                customquestions.add(customquestion);
            }

            customquestions = SetItemQuestionFlags(firstItemQuestionId, lastItemQuestionId, customquestions);

            ResponseWrapper rw = ResponseWrapper.getInstance(CONSTANTS.RESPONSE_STATE_SUCCESS, 'Successfully retrieved the questions', customquestions);

            String returnString = JSON.serialize(rw);
            system.debug(returnString);
            return returnString;

        }

        catch (Exception ex) {
            throw new System.AuraHandledException(ex.getMessage());

        }






    }

    @AuraEnabled
    public static string addProjectServiceQuestion(string projectserviceid, string questionid) {

        try {
            system.debug('PS Id1: ' + projectserviceid);

            if (projectserviceid == null || projectserviceid == '' || questionid == null || questionid == '') {
                return '';
            }
            Question__c question;
            //oh2962 get ISQuestionVisibleToClient field in SELECT statement
            List<Question__c> questions = [Select Id, ExceptionQuestion__c, ItemQuestion__c, IsQuestionVisibleToClient__c, QuestionType__c, QuestionHint__c from Question__c WHERE Id = :questionid LIMIT 1];

            if (!questions.isEmpty())

            {
                question = questions[0];

            }
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
                //Check if there are item questions in the survey
                List<ProjectServiceQuestion__c> projectsqs = [Select Id, QuestionNumber__c FROM ProjectServiceQuestion__c WHERE
                        ProjectService__c = :projectserviceid AND Question__r.ItemQuestion__c = true order by QuestionNumber__c DESC LIMIT 1];
                if (projectsqs.size() > 0) {
                    maxqno = projectsqs[0].QuestionNumber__c;
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
            system.debug('Max QNo: ' + maxqno);

            //New question question number is maxqno + 1. Check if there are existing questions in PSQ
            //with the same question number and increase them by 1
            //We are doing this as item questions now have to be grouped together

            List<ProjectServiceQuestion__c> psqs = [Select Id, QuestionNumber__c FROM ProjectServiceQuestion__c WHERE
                                                    ProjectService__c = :projectserviceid and QuestionNumber__c >= :newqno];

            for (ProjectServiceQuestion__c psq : psqs) {
                psq.QuestionNumber__c = psq.QuestionNumber__c + 1;

            }
            update psqs;

            ProjectServiceQuestion__c sqObj = new ProjectServiceQuestion__c();
            sqObj.ProjectService__c = projectserviceid;
            sqObj.Question__c = questionid;
            sqObj.ServiceQuestion__c = false;
            sqObj.CanRemove__c = true;
            sqObj.Active__c = true;

            sqObj.QuestionNumber__c = newqno;

            sqObj.isTargetQuestion__c = isItemQuestion;


            if (question.QuestionType__c == CONSTANTS.QUESTIONTYPE_PHOTO)
                sqObj.Optional__c = true;
            else
                sqObj.Optional__c = false;


            sqObj.JumpToAction__c = CONSTANTS.QUESTIONJUMP_CONTINUE;
            //oh2962: service visibility to client
            sqObj.IsVisibleToClient__c = question.IsQuestionVisibleToClient__c;
            sqObj.QuestionHint__c = question.QuestionHint__c;
            insert sqObj;



            ProjectServiceQuestionDefinedResponse__c psqdefResp;
            List<ProjectServiceQuestionDefinedResponse__c> psqdfrList = new List<ProjectServiceQuestionDefinedResponse__c>();

            List<QuestionDefinedResponse__c> qDefResList = [ SELECT Id, Name, DefinedResponseOrder__c, DefinedResponseText__c
                    FROM QuestionDefinedResponse__c where Question__c = :questionid];
            for (QuestionDefinedResponse__c qdr : qDefResList ) {
                system.debug('~~~~~ def resp  ' + '__' + qdr.id + '__' + qdr.name + '__' + qdr.DefinedResponseOrder__c + '__' + qdr.DefinedResponseText__c  );
                psqdefResp =  new ProjectServiceQuestionDefinedResponse__c();
                psqdefResp.ProjectServiceQuestion__c = sqObj.id;
                psqdefResp.QuestionDefinedResponse__c = qdr.Id;
                psqdefResp.EndOfQuestions__c = false;
                psqdefResp.JumpToAction__c = 'CONTINUE';
                psqdefResp.CanRemove__c = true;
                psqdfrList.add(psqdefResp);
            }

            insert psqdfrList;

            return getProjectServiceQuestionsApex(projectserviceid);

        } catch (DMLException ex) {
            System.debug('Exception: ' + ex);
            throw new System.AuraHandledException(ex.getDmlMessage(0));

        } catch (Exception ex) {
            throw new System.AuraHandledException(ex.getMessage());

        }

    }


    @AuraEnabled
    public static string deleteProjectServiceQuestion(string projectservicequestionid) {

        try {

            system.debug('psqid: ' + projectservicequestionid);
            ProjectServiceQuestion__c psq = [SELECT Id, name, ProjectService__c, Question__c
                                             from ProjectServiceQuestion__c WHERE Id = :projectservicequestionid];

            Id projectserviceid = psq.ProjectService__c;
            Id question = psq.Question__c;

            //Check if this if a question that is being jumped to by any of the reposnses

            Integer jumpCount = [Select count() from ProjectServiceQuestionDefinedResponse__c WHERE
                                 ProjectServiceQuestion__r.ProjectService__c = :projectserviceid and
                                         JumpToQuestion__c = :question LIMIT 1];
            if (jumpCount == 1) {
                //Do not remove the question. Send back an error.
                throw new CustomException('Cannot remove question. This question is being skipped to by other questions.');

            } else {
                delete psq;

            }

            List<ProjectServiceQuestion__c> psqs = [SELECT Id, Question__c, QuestionNumber__c, Active__c
                                                    FROM ProjectServiceQuestion__c WHERE ProjectService__c = :projectserviceid
                                                            ORDER BY QuestionNumber__c];

            ReOrderProjectServiceQuestions(psqs);
            return getProjectServiceQuestionsApex(projectserviceid);

        } catch (Exception ex) {
            throw new System.AuraHandledException(ex.getMessage());

        }

    }

    @AuraEnabled
    public static string saveProjectServiceQuestion(string questionWrapperInput) {

        try {

            system.debug('Save Wrapper Input: ' + questionWrapperInput);
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


            ProjectServiceQuestion__c psq = [Select Id, Name, JumpToAction__c, ProjectService__c, MinValue__c, MaxValue__c, QuestionHint__c, AILabel__c
                                             from ProjectServiceQuestion__c WHERE
                                             Id = :question.ProjectServiceQuestionId LIMIT 1];


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

            if (question.QuestionType == CONSTANTS.QUESTIONTYPE_MULTI_SELECT ||
                    ((question.QuestionType == CONSTANTS.QUESTIONTYPE_SINGLE_SELECT ||
                      question.QuestionType == CONSTANTS.QUESTIONTYPE_YESNO)
                     && question.JumpToAction != CONSTANTS.QUESTIONJUMP_BRANCH)
               ) {
                system.debug('Multi Select: ');

                List<ProjectServiceQuestionDefinedResponse__c> psqdrs = [Select Id, name, JumpToQuestion__c,
                                                               EndOfQuestions__c, Active__c, JumpToAction__c, ProjectServiceQuestion__r.ProjectService__c
                                                               FROM ProjectServiceQuestionDefinedResponse__c WHERE Id in :psqdrIds];

                for (ProjectServiceQuestionDefinedResponse__c psqdr : psqdrs) {
                    psqdr.JumpToQuestion__c = null;
                    psqdr.JumpToAction__c = null;
                    psqdr.Active__c = mappsqdrwrapper.get(psqdr.Id).Active;
                    system.debug('JTA UP: ' + question.JumpToAction);
                }

                update psqdrs;

            }



            if ((question.QuestionType == CONSTANTS.QUESTIONTYPE_SINGLE_SELECT ||
                    question.QuestionType == CONSTANTS.QUESTIONTYPE_YESNO)
                    && question.JumpToAction == CONSTANTS.QUESTIONJUMP_BRANCH) {

                system.debug('NOT Multi Select: ');

                List<ProjectServiceQuestionDefinedResponse__c> psqdrs = [Select Id, name, JumpToQuestion__c,
                                                               EndOfQuestions__c, Active__c, JumpToAction__c, ProjectServiceQuestion__r.ProjectService__c
                                                               FROM ProjectServiceQuestionDefinedResponse__c WHERE Id in :psqdrIds];


                for (ProjectServiceQuestionDefinedResponse__c psqdr : psqdrs) {

                    if (mappsqdrwrapper.get(psqdr.Id).JumpToQuestion != CONSTANTS.QUESTIONJUMP_RETURN &&
                            mappsqdrwrapper.get(psqdr.Id).JumpToQuestion != CONSTANTS.QUESTIONJUMP_CONTINUE) {
                        psqdr.JumpToQuestion__c = mappsqdrwrapper.get(psqdr.Id).JumpToQuestion;
                        psqdr.JumpToAction__c = CONSTANTS.QUESTIONJUMP_QUESTION;

                    }

                    else {
                        psqdr.JumpToQuestion__c = null;
                        psqdr.JumpToAction__c = mappsqdrwrapper.get(psqdr.Id).JumpToQuestion;
                    }


                    psqdr.Active__c = mappsqdrwrapper.get(psqdr.Id).Active;

                }

                update psqdrs;
            }

            system.debug('BEFORE RETURN ');
            return getProjectServiceQuestionsApex(projectserviceid);

        } catch (DMLException ex) {
            System.debug('Exception: ' + ex);
            throw new System.AuraHandledException(ex.getDmlMessage(0));

        } catch (Exception ex) {
            throw new System.AuraHandledException(ex.getMessage());
        }

    }


    @AuraEnabled
    public static void updateOptionalQuestions(Map<String, Object> query) {
        try {
            if (query.size() == 0) {
                return;
            }

            Map<Id, Boolean> optionalMap = new Map<Id, Boolean>();
            Set<id> ids = new Set<Id>();
            Id mId;

            for (String qId : query.keySet()) {
                mId = Id.valueOf(qId);
                ids.add(mId);
                optionalMap.put(mId, Boolean.valueOf(query.get(qId)));
            }

            List<ProjectServiceQuestion__c> qList = [SELECT Id, Optional__c FROM ProjectServiceQuestion__c WHERE Id = :ids];
            if (ids.size() == 0) {
                throw new AuraHandledException('The changed questions are not found.');
            }

            for (ProjectServiceQuestion__c q : qList) {
                if (q.Optional__c != Boolean.valueOf(optionalMap.get(q.Id))) {
                    q.Optional__c = Boolean.valueOf(optionalMap.get(q.Id));
                }
            }
            update qList;
        } catch (DmlException dml) {
            throw new AuraHandledException(dml.getDmlMessage(0));
        } catch (Exception ex) {
            throw new AuraHandledException('err');
        }
    }


    @AuraEnabled
    public static string saveProjectServiceQuestionActiveFlag(string questionListWrapperInput) {
        string projectserviceid;

        try {
            system.debug('Wrapper Input: ' + questionListWrapperInput);
            List<QuestionWrapper> questions = (List<QuestionWrapper>) JSON.deserialize(questionListWrapperInput, List<QuestionWrapper>.class);

            Map<Id, Boolean> mapActiveFlags = new Map<Id, Boolean>();
            Set<Id> psqids = new Set<Id>();
            for (QuestionWrapper qw : questions) {
                mapActiveFlags.put(qw.ProjectServiceQuestionId, qw.Active);
                psqids.add(qw.ProjectServiceQuestionId);

            }

            Map<Id, Id> mapjqs = new Map<Id, Id>();

            List<ProjectServiceQuestionDefinedResponse__c> psqdrs = [Select Id, JumpToQuestion__c, Active__c, CanRemove__c  from
                    ProjectServiceQuestionDefinedResponse__c WHERE ProjectServiceQuestion__c in

                    :psqids AND JumpToQuestion__c != null ];
            for (ProjectServiceQuestionDefinedResponse__c psqdr : psqdrs) {
                mapjqs.put(psqdr.JumpToQuestion__c, psqdr.JumpToQuestion__c);
            }

            List<ProjectServiceQuestion__c> psqs = [Select Id, Name, Active__c, Question__c, ProjectService__c from ProjectServiceQuestion__c WHERE Id in :psqids];

            projectserviceid = psqs[0].ProjectService__c;

            for (ProjectServiceQuestion__c psq : psqs) {
                system.debug('PSQ: ' + psq.Id);
                if (mapActiveFlags.get(psq.Id) == false && mapjqs.get(psq.Question__c) != null) {
                    system.debug('Jump To Q: ' + mapjqs.get(psq.Question__c));
                    throw new CustomException('Cannot deactivate question. This question is being skipped to by other questions.');
                    return '';
                } else {
                    psq.Active__c = mapActiveFlags.get(psq.Id);
                }

            }

            update psqs;

            return '';


        }

        catch (DMLException ex) {
            System.debug('Exception: ' + ex);
            throw new System.AuraHandledException(ex.getDmlMessage(0));

        } catch (Exception ex) {
            throw new System.AuraHandledException(ex.getMessage());

        }
    }


    private static List<UISelectWrapper> getAllowedJumps(ProjectServiceQuestionDefinedResponse__c psqdr, List<ProjectServiceQuestion__c> projectservicequestions) {

        Boolean firstItemQuestionAdded = false;
        List<UISelectWrapper> retList = new List<UISelectWrapper>();

        if (psqdr == null || psqdr.ProjectServiceQuestion__r.Question__r.QuestionType__c == CONSTANTS.QUESTIONTYPE_MULTI_SELECT)
            return null;


        retList.add(new UISelectWrapper(CONSTANTS.QUESTIONJUMP_RETURN, CONSTANTS.QUESTIONJUMP_RETURN));


        Boolean itemQuestion = psqdr.ProjectServiceQuestion__r.Question__r.ItemQuestion__c;
        Integer questionNumber = Integer.ValueOf(psqdr.ProjectServiceQuestion__r.QuestionNumber__c);


        for (ProjectServiceQuestion__c psq : projectservicequestions) {
            if (itemQuestion == true) { //Item Question can only jump to other item questions
                if (psq.QuestionNumber__c > questionNumber && psq.Question__r.ItemQuestion__c == true && psq.Active__c) {
                    retList.add(new UISelectWrapper('Jump to: Q' + psq.QuestionNumber__c, String.ValueOf(psq.Question__c)));
                }

            } else {
                //When jumping from a non item question to an item question
                //can only jump to the first item question as they are
                //considered a group
                if (psq.QuestionNumber__c > questionNumber) {
                    if (!psq.Active__c)
                        continue;

                    if (firstItemQuestionAdded == true && psq.Question__r.ItemQuestion__c == true) {
                        continue;
                    }

                    retList.add(new UISelectWrapper('Jump to: Q' + psq.QuestionNumber__c, String.ValueOf(psq.Question__c)));

                    if (psq.Question__r.ItemQuestion__c == true) {
                        firstItemQuestionAdded = true;
                    }

                }
            }

        }


        return retList ;

    }


    //Service Template Builder methods

    private static void ReOrderServiceQuestions(List<ServiceQuestion__c> sqs) {
        Integer qno = 1;
        for (ServiceQuestion__c sq : sqs) {
            sq.QuestionNumber__c = qno;
            qno++;

        }

        update sqs;

    }


    private static List<UISelectWrapper> getAllowedJumps(ServiceQuestionDefinedResponse__c sqdr, List<ServiceQuestion__c> servicequestions) {

        Boolean firstItemQuestionAdded = false;

        if (sqdr == null || sqdr.ServiceQuestion__r.Question__r.QuestionType__c == CONSTANTS.QUESTIONTYPE_MULTI_SELECT)
            return null;


        List<UISelectWrapper> retList = new List<UISelectWrapper>();


        retList.add(new UISelectWrapper(CONSTANTS.QUESTIONJUMP_RETURN, CONSTANTS.QUESTIONJUMP_RETURN));

        Boolean itemQuestion = sqdr.ServiceQuestion__r.Question__r.ItemQuestion__c;
        Integer questionNumber = Integer.ValueOf(sqdr.ServiceQuestion__r.QuestionNumber__c);


        for (ServiceQuestion__c sq : servicequestions) {
            if (itemQuestion == true) { //Item Question can only jump to other item questions
                if (sq.QuestionNumber__c > questionNumber && sq.Question__r.ItemQuestion__c == true) {
                    retList.add(new UISelectWrapper('Jump to: Q' + sq.QuestionNumber__c, String.ValueOf(sq.Question__c)));
                }

            } else {
                //When jumping from a non item question to an item question
                //can only jump to the first item question as they are
                //considered a group
                if (sq.QuestionNumber__c > questionNumber) {

                    if (firstItemQuestionAdded == true && sq.Question__r.ItemQuestion__c == true) {
                        continue;
                    }
                    retList.add(new UISelectWrapper('Jump to: Q' + sq.QuestionNumber__c, String.ValueOf(sq.Question__c)));

                    if (sq.Question__r.ItemQuestion__c == true) {
                        firstItemQuestionAdded = true;
                    }

                }
            }

        }

        return retList ;

    }


    @AuraEnabled
    public static string getServiceApex(string serviceid) {

        service__c ps = [Select Id, Name, SurveyTemplateVersion__c FROM Service__c WHERE Id = :serviceid];

        String psstring = JSON.serialize(ps);
        String psstringsansuuc = psstring.replace('__c', '');

        String psstringsamsns = psstringsansuuc.replace(CONSTANTS.CURRENTNAMESPACEPREFIX, '');


        system.debug(psstringsamsns);
        return psstringsamsns;
    }

    @AuraEnabled
    public static string getServiceQuestionsApex(string serviceid) {

        try {

            system.debug('Service Id: ' + serviceid);

            if (serviceid == null || serviceid == '') {
                return '';
            }
            List<QuestionWrapper> customquestions = new List<QuestionWrapper>();

            Map<Question__c, List<QuestionDefinedResponse__c>> mapQuestionInfo = new Map<Question__c, List<QuestionDefinedResponse__c>>();


            List<ServiceQuestion__c> servicequestions = [SELECT Id, Question__c, QuestionHint__c, HintLock__c, Question__r.Active__c, Question__r.Description__c, Question__r.Name,
                                     Question__r.IsQuestionVisibleToClient__c, Question__r.ItemQuestion__c, MinValue__c, MaxValue__c,
                                     Question__r.OneHubQuestionId__c, Question__r.QuestionText__c, Question__r.QuestionType__c,
                                     Question__r.ReplaceByOneHubQuestionId__c, Question__r.TargetType__c, Question__r.DefinedResponseCount__c,
                                     CanRemove__c, QuestionNumber__c, JumpToAction__c, Question__r.ExceptionQuestion__c, Optional__c, isactive__c
                                     FROM ServiceQuestion__c WHERE Service__c = :serviceid
                                             ORDER BY QuestionNumber__c];



            //List<Question__c> questions = Database.query(baseQuery);
            Map<Id, Integer> mapQuestionNumber = new Map<Id, Integer>();
            Map<Id, ServiceQuestion__c> mapQuestions = new Map<Id, ServiceQuestion__c>();
            for (ServiceQuestion__c sq : servicequestions ) {
                Integer qno = sq.QuestionNumber__c == null ? 0 : Integer.ValueOf(sq.QuestionNumber__c);
                mapQuestionNumber.put(sq.Question__c, qno);
                mapQuestions.put(sq.Id, sq);

            }

            Set<Id> setQuestionIds = mapQuestions.keySet();

            system.debug('questions: ' + setQuestionIds);
            system.debug('questions length: ' + setQuestionIds.size());

            List<ServiceQuestionDefinedResponse__c> servicequestionDefinedResponses = [SELECT Id, ServiceQuestion__c, QuestionDefinedResponse__c,
                                                    QuestionDefinedResponse__r.DefinedResponseOrder__c, DefinedResponseText__c,
                                                    QuestionDefinedResponse__r.OneHubAnswerId__c, CanRemove__c, JumpToQuestion__c, EndOfQuestions__c,
                                                    ServiceQuestion__r.QuestionNumber__c, ServiceQuestion__r.Question__r.ItemQuestion__c, ServiceQuestion__r.Question__c,
                                                    JumpToAction__c, QuestionDefinedResponse__r.Exception__r.ExceptionCode__c, ServiceQuestion__r.Question__r.QuestionType__c,
                                                    IsActive__c FROM ServiceQuestionDefinedResponse__c

                                                    WHERE ServiceQuestion__c in :setQuestionIds ORDER BY QuestionDefinedResponse__r.DefinedResponseOrder__c];

            system.debug('servicequestionDefinedResponses: ' + servicequestionDefinedResponses);
            system.debug('sqdr length: ' + servicequestionDefinedResponses.size());



            Map<Id, List<ServiceQuestionDefinedResponse__c>> mappsqdr = new Map<Id, List<ServiceQuestionDefinedResponse__c>>();

            Map<Id, List<UISelectWrapper>> mapAllowedJumpToQuestions = new Map<Id, List<UISelectWrapper>>();

            for (ServiceQuestionDefinedResponse__c sqdr : servicequestionDefinedResponses ) {
                List<ServiceQuestionDefinedResponse__c> sqdrList = mappsqdr.get(sqdr.ServiceQuestion__c);
                if (sqdrList == null) {
                    sqdrList = new List<ServiceQuestionDefinedResponse__c> {sqdr};
                } else {
                    sqdrList.add(sqdr);
                }
                mappsqdr.put(sqdr.ServiceQuestion__c, sqdrList);
                List<UISelectWrapper> lstjtq = new List<UISelectWrapper>();

                lstjtq = getAllowedJumps(sqdr, servicequestions);



                mapAllowedJumpToQuestions.put(sqdr.Id, lstjtq );

            }

            system.debug('MAP SQDR: ' + mappsqdr);
            String firstItemQuestionId = '';
            String lastItemQuestionId = '';

            for (ServiceQuestion__c sq : servicequestions ) {
                List<DefinedResponseWrapper> drList = new List<DefinedResponseWrapper>();
                if (sq.Question__r.DefinedResponseCount__c > 0) {
                    for (ServiceQuestionDefinedResponse__c sqdr : mappsqdr.get(sq.Id)) {

                        DefinedResponseWrapper dr = new DefinedResponseWrapper();

                        dr.DefinedResponseId = sqdr.QuestionDefinedResponse__c;
                        dr.DefinedResponseText = sqdr.DefinedResponseText__c;
                        dr.DefinedResponseOrder = Integer.ValueOf(sqdr.QuestionDefinedResponse__r.DefinedResponseOrder__c);
                        dr.ProjectServiceQuestionDefinedResponseId = sqdr.Id;
                        dr.CanRemove = sqdr.CanRemove__c == null || sqdr.CanRemove__c == false ? false : true;
                        system.debug('JTQ: ' + sqdr.JumpToQuestion__c + ' JTA: ' + sqdr.JumpToAction__c);
                        dr.JumpToQuestion = sqdr.JumpToQuestion__c == null || String.ValueOf(sqdr.JumpToQuestion__c)
                                            == '' ? sqdr.JumpToAction__c : sqdr.JumpToQuestion__c;
                        dr.EndOfQuestions = sqdr.EndOfQuestions__c;
                        dr.ExceptionCode =  sqdr.QuestionDefinedResponse__r.Exception__r.ExceptionCode__c;
                        dr.Active = sqdr.isActive__c;

                        dr.JumpToQuestionNumber = mapQuestionNumber.get(sqdr.JumpToQuestion__c);
                        dr.AllowedJumpToQuestions = mapAllowedJumpToQuestions.get(sqdr.Id);
                        drList.add(dr);
                    }

                }

                QuestionWrapper customquestion = new QuestionWrapper();
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
                customquestions.add(customquestion);
            }

            customquestions = SetItemQuestionFlags(firstItemQuestionId, lastItemQuestionId, customquestions);

            ResponseWrapper rw = ResponseWrapper.getInstance(CONSTANTS.RESPONSE_STATE_SUCCESS, 'Successfully retrieved the questions', customquestions);

            String returnString = JSON.serialize(rw);
            system.debug(returnString);
            return returnString;

        }

        catch (Exception ex) {
            throw new System.AuraHandledException(ex.getMessage());

        }

    }

    @AuraEnabled
    public static string addServiceQuestion(string serviceid, string questionid) {

        try {
            if (serviceid == null || serviceid == '' || questionid == null || questionid == '') {
                return '';
            }
            List<Question> customquestions = new List<Question>();



            Question__c question;
            //oh2962, OH-3447
            List<Question__c> questions = [Select Id, ExceptionQuestion__c, QuestionHint__c, ItemQuestion__c, IsQuestionVisibleToClient__c, QuestionType__c from Question__c WHERE Id = :questionid LIMIT 1];
            if (!questions.isEmpty())

            {
                question = questions[0];

            }
            Boolean isItemQuestion = question.ItemQuestion__c;
            Boolean isExceptionQuestion = question.ExceptionQuestion__c;

            //Check if this is an exception question and if another exception question already exists
            if (isExceptionQuestion) {

                List<ServiceQuestion__c> sqs = [SELECT Id from ServiceQuestion__c WHERE Service__c = :serviceid and Question__r.ExceptionQuestion__c = true LIMIT 1];
                system.debug('sqs list: ' + sqs);
                if (!sqs.isEmpty()) {
                    system.debug('exception question already exists!');
                    throw new CustomException('Error adding question: Only one exception question can be added to a survey.');
                }
            }



            // Check if the question is an item question, if yes, then add the question
            // next to the previous item question if one exists

            Decimal maxqno = 0;

            if (isItemQuestion) {
                //Check if there are item questions in the survey
                List<ServiceQuestion__c> sqs = [Select Id, QuestionNumber__c FROM ServiceQuestion__c WHERE
                                                Service__c = :serviceid AND Question__r.ItemQuestion__c = true order by QuestionNumber__c DESC LIMIT 1];
                if (sqs.size() > 0) {
                    maxqno = sqs[0].QuestionNumber__c;
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
            system.debug('Max QNo: ' + maxqno);

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
            insert sqObj;



            ServiceQuestionDefinedResponse__c sqdefResp;
            List<ServiceQuestionDefinedResponse__c> sqdfrList = new List<ServiceQuestionDefinedResponse__c>();

            List<QuestionDefinedResponse__c> qDefResList = [ SELECT Id, Name, DefinedResponseOrder__c, DefinedResponseText__c
                    FROM QuestionDefinedResponse__c where Question__c = :questionid];
            for (QuestionDefinedResponse__c qdr : qDefResList ) {
                system.debug('~~~~~ def resp  ' + '__' + qdr.id + '__' + qdr.name + '__' + qdr.DefinedResponseOrder__c + '__' + qdr.DefinedResponseText__c  );
                sqdefResp =  new ServiceQuestionDefinedResponse__c();
                sqdefResp.ServiceQuestion__c = sqObj.id;
                sqdefResp.QuestionDefinedResponse__c = qdr.Id;
                sqdefResp.EndOfQuestions__c = false;
                sqdefResp.JumpToAction__c = 'CONTINUE';
                sqdfrList.add(sqdefResp);
            }

            insert sqdfrList;

            return getServiceQuestionsApex(serviceid);


        } catch (Exception ex) {
            throw new System.AuraHandledException(ex.getMessage());

        }




    }

    @AuraEnabled
    public static string deleteServiceQuestion(string servicequestionid) {

        try {

            system.debug('sqid: ' + servicequestionid);
            ServiceQuestion__c sq = [SELECT Id, name, Service__c, Question__c
                                     from ServiceQuestion__c WHERE Id = :servicequestionid];

            Id serviceid = sq.Service__c;
            Id question = sq.Question__c;

            //Check if this if a question that is being jumped to by any of the reposnses

            Integer jumpCount = [Select count() from ServiceQuestionDefinedResponse__c WHERE
                                 ServiceQuestion__r.Service__c = :serviceid and
                                         JumpToQuestion__c = :question LIMIT 1];
            if (jumpCount == 1) {
                //Do not remove the question. Send back an error.
                throw new CustomException('Cannot remove question. This question is being skipped to by other questions.');

            } else {
                delete sq;

            }

            List<ServiceQuestion__c> sqs = [SELECT Id, QuestionNumber__c
                                            FROM ServiceQuestion__c WHERE Service__c = :serviceid
                                                    ORDER BY QuestionNumber__c];

            ReOrderServiceQuestions(sqs);
            return getServiceQuestionsApex(serviceid);

        } catch (Exception ex) {
            throw new System.AuraHandledException(ex.getMessage());

        }

    }

    @AuraEnabled
    public static string saveServiceQuestion(string questionWrapperInput) {

        try {

            system.debug('Wrapper Input: ' + questionWrapperInput);
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
                                     from ServiceQuestion__c WHERE
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
                system.debug('Multi Select: ');

                List<ServiceQuestionDefinedResponse__c> sqdrs = [Select Id, name, JumpToQuestion__c, isActive__c,
                                                        EndOfQuestions__c, JumpToAction__c, CanRemove__c,
                                                        ServiceQuestion__r.Service__c
                                                        FROM ServiceQuestionDefinedResponse__c WHERE Id in :sqdrIds];

                for (ServiceQuestionDefinedResponse__c sqdr : sqdrs) {
                    sqdr.JumpToQuestion__c = null;
                    sqdr.JumpToAction__c = null;
                    sqdr.isActive__c = mappsqdrwrapper.get(sqdr.Id).Active;
                    sqdr.CanRemove__c = mappsqdrwrapper.get(sqdr.Id).CanRemove;
                    system.debug('JTA UP: ' + question.JumpToAction);
                }

                update sqdrs;

            }



            if ((question.QuestionType == CONSTANTS.QUESTIONTYPE_SINGLE_SELECT ||
                    question.QuestionType == CONSTANTS.QUESTIONTYPE_YESNO)
                    && question.JumpToAction == CONSTANTS.QUESTIONJUMP_BRANCH) {

                system.debug('NOT Multi Select: ');

                List<ServiceQuestionDefinedResponse__c> sqdrs = [Select Id, name, JumpToQuestion__c, isActive__c,
                                                        CanRemove__c, EndOfQuestions__c, JumpToAction__c, ServiceQuestion__r.Service__c
                                                        FROM ServiceQuestionDefinedResponse__c WHERE Id in :sqdrIds];


                for (ServiceQuestionDefinedResponse__c sqdr : sqdrs) {

                    if (mappsqdrwrapper.get(sqdr.Id).JumpToQuestion != CONSTANTS.QUESTIONJUMP_RETURN &&
                            mappsqdrwrapper.get(sqdr.Id).JumpToQuestion != CONSTANTS.QUESTIONJUMP_CONTINUE) {
                        system.debug('questionWrapperInput:::' + mappsqdrwrapper.get(sqdr.Id));
                        system.debug('sqdr.Id:::' + sqdr.Id);
                        system.debug('mappsqdrwrapper.get(sqdr.Id).JumpToQuestion:::' + mappsqdrwrapper.get(sqdr.Id).JumpToQuestion);


                        sqdr.JumpToQuestion__c = mappsqdrwrapper.get(sqdr.Id).JumpToQuestion;
                        sqdr.JumpToAction__c = CONSTANTS.QUESTIONJUMP_QUESTION;

                    }

                    else {
                        sqdr.JumpToQuestion__c = null;
                        sqdr.JumpToAction__c = mappsqdrwrapper.get(sqdr.Id).JumpToQuestion;
                    }
                    sqdr.isActive__c = mappsqdrwrapper.get(sqdr.Id).Active;
                    sqdr.CanRemove__c = mappsqdrwrapper.get(sqdr.Id).CanRemove;

                }

                update sqdrs;
            }

            system.debug('BEFORE RETURN ');

            return getServiceQuestionsApex(serviceid);

        } catch (DMLException ex) {
            System.debug('Exception: ' + ex);
            throw new System.AuraHandledException(ex.getDmlMessage(0));

        } catch (Exception ex) {
            throw new System.AuraHandledException(ex.getMessage());
        }


    }
    @AuraEnabled
    public static string saveServiceQuestionsChanges(string questionListWrapperInput) {
        try {
            system.debug('Wrapper Input: ' + questionListWrapperInput);
            List<QuestionWrapper> questions = (List<QuestionWrapper>) JSON.deserialize(questionListWrapperInput, List<QuestionWrapper>.class);
            Map<Id, Boolean> mapCanRemoveFlags = new Map<Id, Boolean>();
            Map<Id, Boolean> mapOptionalFlags = new Map<Id, Boolean>();

            Set<Id> sqids = new Set<Id>();
            for (QuestionWrapper qw : questions) {
                sqids.add(qw.ProjectServiceQuestionId);
                mapCanRemoveFlags.put(qw.ProjectServiceQuestionId, qw.CanRemove);
                mapOptionalFlags.put(qw.ProjectServiceQuestionId, qw.Optional);

            }

            List<ServiceQuestion__c> sqs = [Select Id, Name, CanRemove__c, Question__c, Optional__c, IsActive__c from ServiceQuestion__c WHERE Id in :sqids];


            for (ServiceQuestion__c sq : sqs) {
                sq.CanRemove__c = mapCanRemoveFlags.get(sq.Id);
                sq.Optional__c = mapOptionalFlags.get(sq.Id);
            }

            update sqs;

            return '';



        } catch (DMLException ex) {
            System.debug('Exception: ' + ex);
            throw new System.AuraHandledException(ex.getDmlMessage(0));

        } catch (Exception ex) {
            throw new System.AuraHandledException(ex.getMessage());

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



}