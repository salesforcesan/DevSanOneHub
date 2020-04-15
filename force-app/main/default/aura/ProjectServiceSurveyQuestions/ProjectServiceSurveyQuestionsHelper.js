({
    'AddQuestionDialogSetting': {
        'id': 'dlgAddQuestion',
        'component': 'c:AddSurveyQuestionModal',
        'size': 'x-medium',
        'title': 'Add Survey Question'
    },
    
    'EditQuestionDialogSetting': {
        'id': 'dlgEditQuestion',
        'component': 'c:EditSurveyQuestionModal',
        'size': 'medium',
        'title': 'Edit Survey Question ~~~~1'
    },
    buildFlatSurvey: function(questions, component, helper) {

        var flatSurvey = '',
            questionNumber = '',
            counter = 0,
            targets = component.get('v.targets');
        debugger;
        for (i = 0; i < questions.length; i++) { 
            
            if (questions[i].Active) {
                if (questions[i].ItemQuestion && targets.length) {
                    for (k = 0; k < targets.length; k++) {
                        
                        counter = 0;
                        while (questions[i+counter] && questions[i+counter].Active && questions[i+counter].ItemQuestion) {
                            
                            questionNumber = '' + questions[i+counter].QuestionNumber + '.' + (k+1) + ' ';
                        	flatSurvey += helper.buildFlatQuestion(questions[i+counter], questionNumber, helper, targets[k].TargetName, (k+1));
                            
                            counter++;
                        }
                    }
                    i += counter-1;
                } else {
                	flatSurvey += helper.buildFlatQuestion(questions[i], questions[i].QuestionNumber, helper, null);    
                }
                
            }
        }
        
        return flatSurvey;
    },
    getTargets: function(component, event, projectServiceId) {

        var action,
        message,
        messageTitle,
        serviceTargets,
        projectServiceId = component.get("v.recordId");
        action = component.get("c.GetProjectServiceTargets", []);
		if (!action) return;
        
        action.setParams({
            "projectServiceId": projectServiceId
        });
        
        var self = this;
        action.setCallback(self, function(result) {
            
            if (!component.isValid()) return;            
            
            var state = result.getState();
            messageTitle = 'Server Message';
            message = '';
            if (state === "SUCCESS") {
                
                serviceTargets = result.getReturnValue();
                component.set('v.targets', serviceTargets || []);
            } else {

                var errors = result.getError();
                if (errors[0] && errors[0].message) // To show other type of exceptions
                    message = errors[0].message;
                if (errors[0] && errors[0].pageErrors) // To show DML exceptions
                    message = errors[0].pageErrors[0].message;
                this._notify(component, message, 'error');
            }
        });
        $A.enqueueAction(action);
    },
    buildFlatQuestion: function(question, questionNumber, helper, targetName, targetNumber){
        
        var flatQuestion = '',
            JumpToQuestionNumberPostfix = '';
        flatQuestion += questionNumber + ' ';
        flatQuestion += helper.replaceTitle(question.QuestionText, targetName) + '\r\n';
        
        if (question.QuestionType == 'Number') {
            flatQuestion += question.QuestionType + ' ' + question.MinValue + ' - ' + question.MaxValue + ' (' + question.JumpToAction + ')\r\n';
        } else {
        	flatQuestion += question.QuestionType + ' (' + question.JumpToAction + ')\r\n';    
        }
        
        if (question.JumpToAction == 'BRANCH' || question.JumpToAction == 'CONTINUE' || question.JumpToAction == 'RETURN') {
            for (j = 0; j < question.DefinedResponses.length; j++) {

                if (question.DefinedResponses[j].Active) {
                    flatQuestion += ' - ' + question.DefinedResponses[j].DefinedResponseText;
                    if (question.DefinedResponses[j].JumpToQuestionNumber) {
                        if (targetNumber) {
                            JumpToQuestionNumberPostfix = '.'+targetNumber;
                        }
                        flatQuestion += ' (Jump to: ' + question.DefinedResponses[j].JumpToQuestionNumber + JumpToQuestionNumberPostfix  + ')\r\n'; 
                    } else {
                        flatQuestion += ' (' + question.DefinedResponses[j].JumpToQuestion + ')\r\n';     
                    }
                }

            }
        } 
        
        flatQuestion += '\r\n';
        
        return flatQuestion;
    },
    replaceTitle: function(questionText, targetName){
        return questionText.replace('{title}', targetName);	    
    },
    exportFile: function(filenamePrefix, fileContent) {
        var filename = filenamePrefix + '_Survey_Export.txt',
            element = document.createElement('a');
        
        element.setAttribute('href', 'data:text/plain;charset=utf-8,' + encodeURIComponent(fileContent));
        element.setAttribute('download', filename);
        element.style.display = 'none';
        document.body.appendChild(element);
        element.click();
        document.body.removeChild(element);
    },
    getProjectService: function(component) {
        var message;
        var messageTitle;
        var projectserviceid = component.get("v.recordId");
        
        var action = component.get("c.getProjectServiceApex", []);
        
        if (!action) return;
        
        action.setParams({
            "projectserviceid": projectserviceid
        });
        console.log(action);
        var self = this;
        action.setCallback(self, function(result) {
            
            if (!component.isValid()) return;
            
            
            var state = result.getState();
            messageTitle = 'Server Message';
            message = '';
            if (state === "SUCCESS") {
                
        
                var projectservice = JSON.parse(result.getReturnValue());
                
                component.set("v.projectservice", projectservice);
                component.set("v.servicename", projectservice.ServiceName);
                component.set("v.servicetitle", projectservice.ServiceTitle);
                component.set("v.surveyscore", projectservice.SurveyComplexityScore);  
                component.set("v.issurveyscoreerror", projectservice.IsSurveyScoreExceedThreshold);  
                component.set("v.issurveyscorewarning", projectservice.IsSurveyScoreWarning);            
                component.set("v.surveyscorethreshold", projectservice.SurveyScoreThreshold);            
                component.set("v.surveyscorewarning", projectservice.SurveyScoreWarning);     
                
                component.set("v.surveyscoredrpercent", projectservice.SurveyComplexityScoreDRPercent);  
                component.set("v.surveyscoretqpercent", projectservice.SurveyComplexityScoreTQPercent);            
                component.set("v.surveyscoreqpercent", projectservice.SurveyComplexityScoreQPercent);            
                component.set("v.surveyscorejumppercent", projectservice.SurveyComplexityScoreJumpPercent);     
                
                //var scoredataarray = ["{",""minvalue"",":",0,",",""lowSegmentMax"",":",projectservice.SurveyScoreWarning,",",""medSegmentMax"",":",projectservice.SurveyScoreThreshold,",",""highSegmentMax"",":",projectservice.SurveyScoreThreshold + 100,",",""guageValue"",":",projectservice.SurveyComplexityScore + 100,",","}"];
                //component.set("v.surveyscoredata", scoredataarray.join());     
                //console.log('score data: ' + component.get("v.surveyscoredata"));  
                var gaugeValue = component.get('v.surveyscore');
                var lowSegmentMax = component.get('v.surveyscorewarning');
                var medSegmentMax = component.get('v.surveyscorethreshold');
                var highSegmentMax = (medSegmentMax * .20) + medSegmentMax;
                
                if (gaugeValue > highSegmentMax) {
                    gaugeValue = highSegmentMax;  
                };
                
                var surveyMap = {
                    "minValue":0,
                    "lowSegmentMax":lowSegmentMax,
                    "medSegmentMax":medSegmentMax,
                    "highSegmentMax":highSegmentMax,
                    "gaugeValue":gaugeValue};
                
                component.set("v.surveyscoredata", surveyMap); 
                
            } else {
                
                console.log(result.getError());
                
                var errors = result.getError();
                if (errors[0] && errors[0].message) // To show other type of exceptions
                    message = errors[0].message;
                if (errors[0] && errors[0].pageErrors) // To show DML exceptions
                    message = errors[0].pageErrors[0].message;
                
                this._notify(component, message, 'error');
                
                
            }
            
        });
        $A.enqueueAction(action);
    },
    getProjectServiceQuestions: function(component) {
        
        var message;
        var messageTitle;
        var projectserviceid =  component.get("v.recordId");
        
        var action = component.get("c.getProjectServiceQuestionsApex", []);
        if (!action) return;
        
        action.setParams({
            "projectserviceid": projectserviceid
        });
        console.log(action);
        var self = this;
        action.setCallback(self, function(result) {
            
            if (!component.isValid()) return;
            
            var state = result.getState();
            messageTitle = 'Server Message';
            message = '';
            if (state === "SUCCESS") {
                var responseWrapper = JSON.parse(result.getReturnValue());
                var questions = responseWrapper.Data;
                 component.set('v.questions', questions);
                console.log('surv questions init: ', questions);
                self.updateProjectService(component);
                
                
            } else {
                console.log(result.getError());
                
                var errors = result.getError();
                if (errors[0] && errors[0].message) // To show other type of exceptions
                    message = errors[0].message;
                if (errors[0] && errors[0].pageErrors) // To show DML exceptions
                    message = errors[0].pageErrors[0].message;
                
                this._notify(component, message, 'error');
                
                
            }
            
        });
        $A.enqueueAction(action);
    },
    editProjectServiceQuestion: function(component) {
        var message;
        var messageTitle;
        var spinner = component.find("spinner");  
        $A.util.removeClass(spinner, "slds-hide");
        
        var question = JSON.stringify(component.get("v.question"));  
        
        var action = component.get("c.saveProjectServiceQuestion", []);      
        action.setParams({
            "questionWrapperInput": question});
        console.log(action);  
        var self = this;
        action.setCallback(self, function(result) {
            
            if (!component.isValid()) return;
            
            $A.util.addClass(spinner, "slds-hide");
            
            var state = result.getState();
            messageTitle = 'Server Message';
            message = '';
            if (state === "SUCCESS") {
                
                message = "Sucessfully saved question changes";  	
                self.showToast('Server message',message,'success');
                
                var responseWrapper = JSON.parse(result.getReturnValue());
                var questions = responseWrapper.Data;
                 component.set('v.questions', questions);
                self.updateProjectService(component);          
                
            } 
            else 
            {
                console.log(result.getError());
                var errors = result.getError();
                if (errors[0] && errors[0].message) // To show other type of exceptions
                    message = errors[0].message;
                if (errors[0] && errors[0].pageErrors) // To show DML exceptions
                    message = errors[0].pageErrors[0].message;
                
                self.showToast(messageTitle, message, 'error');
                self.updateProjectServiceQuestions(component);                  
                
            }
        });
        $A.enqueueAction(action);
    },   
    addCustomQuestion: function(component) {
        
        var message;
        var messageTitle;
        var spinner = component.find("spinner");  
        $A.util.removeClass(spinner, "slds-hide");
        
        
        var projectserviceid = component.get("v.recordId");
        var questionid = component.get("v.questionId");
        
        var action = component.get("c.addProjectServiceQuestion", []);
        action.setParams({
            "projectserviceid": projectserviceid,
            "questionid": questionid
        });
        console.log(action);
        var self = this;
        action.setCallback(self, function(result) {
            
            if (!component.isValid()) return;
            
            var state = result.getState();
            messageTitle = 'Server Message';
            message = '';
            $A.util.addClass(spinner, "slds-hide");
            if (state === "SUCCESS") {
                
                message = "Sucessfully added the question";  	
                self.showToast('Server message',message,'success');
                
                var responseWrapper = JSON.parse(result.getReturnValue());
                var questions = responseWrapper.Data;
                component.set('v.questions', questions);

                self.updateProjectService(component);          
                
            } 
            else 
            {
                console.log(result.getError());
                var errors = result.getError();
                if (errors[0] && errors[0].message) // To show other type of exceptions
                    message = errors[0].message;
                if (errors[0] && errors[0].pageErrors) // To show DML exceptions
                    message = errors[0].pageErrors[0].message;
                
                self.showToast('Server message', message, 'error');
            }
        });
        $A.enqueueAction(action);
    },
    removeCustomQuestion: function(component) {
        
        var message;
        var messageTitle;
        var spinner = component.find("spinner");  
        $A.util.removeClass(spinner, "slds-hide");      
        
        var action = component.get("c.deleteProjectServiceQuestion", []);
        action.setParams({
            "projectservicequestionid": component.get("v.removepsqid")
        });
        console.log(action);
        var self = this;
        action.setCallback(self, function(result) {

            if (!component.isValid()) return;
            
            var state = result.getState();
            $A.util.addClass(spinner, "slds-hide");        
            
            messageTitle = 'Server Message';
            
            if (state === "SUCCESS") 
            {
                message = "Sucessfully removed the question";  	
                self.showToast('Server message',message,'success');
                var responseWrapper = JSON.parse(result.getReturnValue());
                var questions = responseWrapper.Data;
                component.set('v.questions', questions)
                component.set("v.removepsqid", ''); 
                
                self.updateProjectService(component);
            } 
            else {
                console.log(result.getError());
                var errors = result.getError();
                if (errors[0] && errors[0].message) // To show other type of exceptions
                    message = errors[0].message;
                if (errors[0] && errors[0].pageErrors) // To show DML exceptions
                    message = errors[0].pageErrors[0].message;
                self.showToast('Server message',message,'error');
                
            }
            
        });
        $A.enqueueAction(action);
    },
    saveQuestionActiveChange: function(component) {
        
        var message;
        var messageTitle;
        var spinner = component.find("spinner");  
        $A.util.removeClass(spinner, "slds-hide");      
        
        
        var questions = JSON.stringify(component.get("v.questions"));
        
        var action = component.get("c.saveProjectServiceQuestionActiveFlag", []);
        
        action.setParams({
            "questionListWrapperInput": questions
        });
        console.log(action);
        var self = this;
        
        action.setCallback(self, function(result) {
            
            if (!component.isValid()) return;
            
            $A.util.addClass(spinner, "slds-hide");              
            var state = result.getState();
            messageTitle = 'Server Message';
            
            if (state === "SUCCESS") {
                message = 'Changes saved successfully.';
                self.showToast('Server message',message,'success');
                
            } else {
                console.log(result.getError());
                var errors = result.getError();
                if (errors[0] && errors[0].message) // To show other type of exceptions
                    message = errors[0].message;
                if (errors[0] && errors[0].pageErrors) // To show DML exceptions
                    message = errors[0].pageErrors[0].message;
                self.showToast('Error occured',message,'error');
            }
            
            self.updateProjectServiceQuestions(component);        
            
        });
        $A.enqueueAction(action);
    },
    showEditQuestionModal: function(cmp, questions, recordId){
		questions[0].isProjectService = true;
        this._renderDialog(cmp, this.EditQuestionDialogSetting,{
            'recordid': recordId,
            'questions': questions,
            'hiddenElement':cmp.get("v.hiddenelements")
        });
    },
    showAddQuestionModal: function(cmp) {
        var questions = (cmp.get('v.questions') || []).map(function(q){
            return q.QuestionId;
        });
        
        this._renderDialog(cmp, this.AddQuestionDialogSetting, 
                           {'recordId': cmp.get('v.recordId'), 
                            'fromProjectBuilder': true,
                            'addedQuestions': questions});
    },
    handleMessageBoxEvent: function(component, evt) {
        var result = {
            id: evt.getParam('id'),
            value: evt.getParam('context')
        };
        if (result.id === 'removeOneQuestion' && result.value == 1) {
            this.removeCustomQuestion(component);
        }
    },
    openMessageBox : function(component, event, helper) {
        
        var prompt = component.find('messageBox');
        prompt && prompt.show({
            id: 'removeOneQuestion',
            title: 'Remove Question',
            body: '<p>Are you sure that you want to remove the question?</p>',
            positiveLabel: 'Confirm',
            negativeLabel: 'No',
            severity: 'error'
        });
    },
    showToast : function(title, message, type) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "message": message,
            "type": type
        });
        toastEvent.fire();
    },    
    _notify: function(cmp, msg, type, autoHide, duration) {
        cmp.find('notification').show(msg, type, autoHide, duration);
    },
    _renderDialog: function(root, dialogDefinition, params) {
        var dlg = root.find('modalDialog'),
            self = this,
            args = (!!params) ? this._cloneObject(params) : {};
        args['dialogId'] = dialogDefinition.id;
        
        $A.createComponent(dialogDefinition.component, args,
                           function(cmp, status, errMsg) {
                               if ('SUCCESS' === status) {
                                   dlg.set('v.title', dialogDefinition.title);
                                   dlg.set('v.size', dialogDefinition.size);
                                   dlg.set('v.brand', dialogDefinition.brand || '');
                                   dlg.set('v.body', cmp);
                                   dlg.show();
                               } else if ('ERROR' === status) {
                                   self._notify(root, errMsg, self.NOTIFICATION_TYPES.ERROR);
                               }
                           });
    },
    _cloneObject: function(obj) {
        var t = {};
        for (var nm in obj) {
            t[nm] = obj[nm];
        }
        return t;
    },
    async: function(cmp, callback, duration) {
        if (!callback) {
            return;
        }
        duration = duration || 250;
        var id = window.setTimeout($A.getCallback(function() {
            window.clearTimeout(id);
            if (cmp.isValid()) {
                callback(cmp);
            }
        }), duration);
    },
    updateProjectService: function(component){
        var self = this;
        window.setTimeout(
            $A.getCallback(function() {
                self.getProjectService(component);
            }), 250
        );                     
    },

    updateProjectServiceQuestions: function(component){
        var self = this;
        window.setTimeout(
            $A.getCallback(function() {
                self.getProjectServiceQuestions(component);
            }), 250
        );                     
    },

    _getOptional:function(evt) {
        var query = {},
        checkbox = evt.getSource();
        query[checkbox.get('v.name')] = checkbox.get('v.value');
        return query;
    },

    handleOptionChangeEvent: function(cmp,evt){
        var self=this, payload;

        function doResponse(cmp){
            self._msgBox('success','The questions are saved successfully.');
        }
        
        function doErrorResponse(cmp){
            self.updateProjectServiceQuestions(cmp);        
        }

        payload= {
            'query': {
                'query': self._getOptional(evt)
            },
            'action': 'updateOptionalQuestions',
            'callback': doResponse,
            'callbackError': doErrorResponse
        };

        self.dispatch(cmp, payload);
    },

   dispatch: function(cmp, payload) {
        var request, errors, state, self = this;

        function handleResponse(response) {
            state = response.getState();
            if (!cmp.isValid()) {
                self._msgBox('error', 'The component is out of scope.');
                return;
            }
            self._hideSpinner(cmp);
            switch (state) {
                case 'SUCCESS':
                    if (!!payload.callback) {
                        payload.callback(cmp, response.getReturnValue());
                        return;
                    }
                    break;
                case 'ERROR':
                    errors = response.getError();
                    if (!!errors && !!errors[0] && !!errors[0].message) {
                        self._msgBox('error', errors[0].message);
                    } else {
                        self._msgBox('error', 'The system run into an unknown error.');
                    }

                    if (!!payload.callbackError) {
                        payload.callbackError(cmp, response.getReturnValue());
                        return;
                    }

                    
                    break;
                case 'INCOMPLETE':
                    self._msgBox('error', 'The system run into an incomplete state.');
                    break;
                default:
                    self._msgBox('error', 'The system run into an unknown state.');
                    break;
            }
        }

        try {
            self._showSpinner(cmp);
            request = cmp.get('c.' + payload.action);
            request.setParams(payload.query);
            request.setCallback(this, handleResponse);
            $A.enqueueAction(request);
        } catch (ex) {
            self._msgBox('error', ex.message);
            self._hideSpinner(cmp);
        }
    },

    _msgBox: function(type, msg) {
        var notice = $A.get('e.force:showToast');

        notice.setParams({
            'mode': type === 'error' ? 'sticky' : 'dismissible',
            'type': type,
            'message': msg
        });
        notice.fire();
    },

    _showSpinner: function(cmp){
         var spinner = cmp.find("spinner");  
        $A.util.removeClass(spinner, "slds-hide");
    },

    _hideSpinner: function(cmp){
         var spinner = cmp.find("spinner");
        $A.util.addClass(spinner, "slds-hide");
    }
})