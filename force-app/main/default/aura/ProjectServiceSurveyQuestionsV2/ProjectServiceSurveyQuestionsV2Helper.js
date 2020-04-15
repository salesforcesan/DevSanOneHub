({
    
    'AddQuestionDialogSetting': {
        'id': 'dlgAddQuestion',
        'component': 'c:AddSurveyQuestionModalv2',
        'size': 'x-medium',
        
        'title': 'Add Survey Question',      
    },
    'EditQuestionDialogSetting': {
        'id': 'dlgEditQuestion',
        'component': 'c:EditSurveyQuestionModalv2',
        'size': 'medium',
        'title': 'Edit Survey Question'
    },
    'ServiceQuestionRuleDialogSetting': {
        'id': 'dlgsquestionRule',
        'component': 'c:SurveyProjectQuestionRuleBuilder',
        'size': 'x-small',
        'title': 'Survey Question Rule Builder'
    },
    'UploadTargetDialogSetting': {
        'id': 'dlgUploadTargetn',
        'component': 'c:UploadTarget',
        'size': 'medium',
        'title': 'Upload Target'
    },
    
    handleDragOver: function(e) {
        if (e.preventDefault) {
            e.preventDefault(); // Necessary. Allows us to drop.
        }
        
        e.dataTransfer.dropEffect = 'move';  // See the section on the DataTransfer object.
        
        return false;
    },    
    buildNonFlatSurvey: function(questions, component, helper) {
        
        var nonflatSurvey = '',
            questionNumber = '',
            counter = 0,
            i = 0,
            k = 0,
            targets = component.get('v.targets');
       console.log(JSON.stringify(questions));
       
        for (i = 0; i < questions.length; i++) { 
            // flatSurvey += questions[i].QuestionIndentation;
            //flatSurvey += helper.buildFlatQuestion(questions[i], questions[i].QuestionIndentation, helper, null); 
            if (questions[i].Active) {
                
                nonflatSurvey += helper.buildNonFlatQuestion(questions[i], questions[i].QuestionIndentation); 
                
            }
            
        }
        
        return nonflatSurvey;
    },
    
    buildNonFlatQuestion: function(question, questionNumber ){
        
        
        var nonflatQuestion = '',
             rules='',
            JumpToQuestionNumberPostfix = '',
            m=0,
            j =0;
        
         if(question.ServiceQuestionRuleList!=null)
        {
           
            for (m = 0; m < question.ServiceQuestionRuleList.length; m++) {
                
                if(!$A.util.isEmpty(question.ServiceQuestionRuleList[m].RuleText))
                {
                    var str = question.ServiceQuestionRuleList[m].RuleText.toString();
                    var search = 'null';
                    var newvalue =this.replaceAll(search,' ', str);
                    rules += ' - ' + newvalue;
                }
            }
        }
        
      if(question.ServiceQuestionRuleList!=null)
      {
        nonflatQuestion = 'Rules: [ ' + question.ParentQuestionIndentation + ' ]'  +  rules;
        nonflatQuestion += '\r\n';
      }

        nonflatQuestion += questionNumber + ' ';
        nonflatQuestion += question.QuestionText ;
        if(question.Optional)
       {
           nonflatQuestion += ' OPTIONAL ' ;
       }
       if(question.HintQuestion!=null && !$A.util.isEmpty(question.HintQuestion))
       {
           nonflatQuestion += ' ( ' +  question.HintQuestion + ' ) ' ;
       }
        
        nonflatQuestion += ' \r\n';
        
        
        if (question.QuestionType == 'Number') {
            nonflatQuestion += ' Question Type: ' +  question.QuestionType;
           nonflatQuestion += ' \r\n';
            
            
            if(!$A.util.isEmpty(question.MinValue))
            {
                nonflatQuestion +=  ' - ' +  'Min value: ' + question.MinValue +  '\r\n';
                
            }
            if(!$A.util.isEmpty(question.MaxValue))
            {
                nonflatQuestion +=  ' - ' + 'Max value: ' +  question.MaxValue + '\r\n';
                
            }
          
            
            
        } else {
            if(!$A.util.isEmpty(question.QuestionType))
            {
                 nonflatQuestion += 'Question Type: ' +  question.QuestionType;
                
            }
        }
        
         nonflatQuestion += ' \r\n';
        
        for (j = 0; j < question.DefinedResponses.length; j++) {
            if (question.DefinedResponses[j].Active) {
                if(!$A.util.isEmpty(question.DefinedResponses[j].DefinedResponseText))
                {
                    var str = question.DefinedResponses[j].DefinedResponseText.toString();
                    //console.log('str++' + str);
                    var search = 'null';
                    var newstr = this.replaceAll(search,' ',str);
                    
                    nonflatQuestion += ' - ' + newstr +'\r\n';
                }
            }
            
        }
        nonflatQuestion += '\r\n';
        
               
        return nonflatQuestion;
    },
    
    buildFlatQuestion_Old: function(question, questionNumber, helper, targetName, targetNumber){
        
        var flatQuestion = '',
            JumpToQuestionNumberPostfix = '',
            j =0;
        flatQuestion += questionNumber + ' ';
        flatQuestion += helper.replaceTitle(question.QuestionText, targetName) + '\r\n';
        
        if (question.QuestionType == 'Number') {
            flatQuestion += question.QuestionType + ' ' + question.MinValue + ' - ' + question.MaxValue +'\r\n';
        } else {
            flatQuestion += question.QuestionType + ' \r\n';    
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
    replaceAll: function(find, replace, str) 
    {
        
        while( str.indexOf(find) > -1)
        {
            str = str.replace(find, replace);
        }
        
        return str;
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
                component.set("v.projectId", projectservice.Project);
                
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
    getService: function(component) {
        var message;
        var messageTitle;
        var serviceid = component.get("v.recordId");
        
        var action = component.get("c.getServiceApex", []);
        action.setParams({
            "serviceid": serviceid
        });        
        var self = this;
        action.setCallback(self, function(result) {
            var state = result.getState();
            messageTitle = 'Server Message';
            message = '';
            if (state === "SUCCESS") {
                
                var service = JSON.parse(result.getReturnValue());
                
                component.set("v.service", service);
                component.set("v.servicename", service.ServiceName);
                component.set("v.servicetitle", service.ServiceTitle);
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
    getServiceQuestions: function(component) {
        
        var message;
        var messageTitle;
        var projectserviceid =  component.get("v.recordId");
        
        var action = component.get("c.getProjectServiceQuestionsApex", []);
        action.setParams({
            "projectserviceid": projectserviceid
        }); 
        
        action.setCallback(this, function(result) {
            var state = result.getState();
            messageTitle = 'Server Message';
            message = '';
            if (state === "SUCCESS") {
                var responseWrapper = JSON.parse(result.getReturnValue());
                
                var questions = responseWrapper.Data;
                component.set("v.notflattenquestions", questions); 
                console.log('questions resp: ', questions);
                //To build tree with javascript
                var tree = this.unflatten( responseWrapper.Data);  
                
                component.set("v.questions", tree);
                
            } else {
                
                this.errorMessage(component, messageTitle, message, result) 
            }
            
        });
        $A.enqueueAction(action);
    },
    reOrderProjectServiceQuestion: function(component, attributes){
        
        var message;
        var messageTitle;
        
        var action = component.get("c.ReorderProjectServiceQuestion", []);
        action.setParams(attributes);
        action.setCallback(this, function(result) {
            
            var state = result.getState();
            
            messageTitle = 'Server Message';
            message = '';
            if (state === "SUCCESS") {
                var responseWrapper = JSON.parse(result.getReturnValue());
                var questions = responseWrapper.Data;
                component.set("v.notflattenquestions", questions);
                
                var tree = this.unflatten(questions);                 
                
                component.set("v.questions", tree);                
                
                //to refresh
                var evtFire = $A.get("e.c:ServiceQuestionSortableEvent");
                
                setTimeout(function() {
                    
                    evtFire.fire();
                    
                }, 100);
                return;
                
                
            } else {
                
                this.errorMessage(component, messageTitle, message, result) 
            }
            
        });
        $A.enqueueAction(action);
    },
    unflatten : function( array, parent, tree ){
        var self = this;
        tree = typeof tree !== 'undefined' ? tree : [];
        parent = typeof parent !== 'undefined' ? parent : { ID: 0 };
        
        const children = array.filter(child =>  child.ParentID == parent.ID );
        
        if(children != null && children.length > 0) {
            if( parent.ID == 0 ){
                tree = children;   
            }else{
                parent['children'] = children
            }
            children.forEach(child => self.unflatten(array, child) );   
            
        }
        
        return tree;
    },
    
    editServiceQuestion: function(component) {
        var message = "";
        var messageTitle = "Server Message";
        var spinner = component.find("spinner");  
        $A.util.removeClass(spinner, "slds-hide");
        
        var question = JSON.stringify(component.get("v.question"));  
        
        var action = component.get("c.saveProjectServiceQuestion", []);      
        action.setParams({
            "questionWrapperInput": question});        
        var self = this;
        action.setCallback(self, function(result) {            
            
            $A.util.addClass(spinner, "slds-hide");
            
            var state = result.getState();
            if (state === "SUCCESS") {
                message = "Sucessfully saved question changes";  	
                self.showToast(messageTitle, message, 'success');
                
                var responseWrapper = JSON.parse(result.getReturnValue());
                var questions = responseWrapper.Data;
                component.set("v.notflattenquestions", questions);
                var tree = self.unflatten(questions);                   
                component.set("v.questions", tree);
            } 
            else 
            {    
                message = "Failed to save question changes";         
                self.errorMessage(component, messageTitle, message, result);
            }
        });
        $A.enqueueAction(action);
    },    
    addServiceQuestionrule: function(component)
    {
        var message;
        var messageTitle;
        var spinner = component.find("spinner");  
        $A.util.removeClass(spinner, "slds-hide");
        
        var projectServiceId = component.get("v.recordId"); 
        var serviceQuestion = component.get("v.serviceQuestionId");
        var pserviceQuestion = component.get("v.pserviceQuestionId");
        var selectedop = component.get("v.operator");
        var drl = component.get("v.definedResponses");
        var action = component.get("c.addProjectServiceQuestionRule", []);      
        action.setParams({
            "projectServiceId":projectServiceId,
            "sqId":serviceQuestion,
            "psqId":pserviceQuestion,
            "sop":selectedop,
            "drl":drl
        });
        
        action.setCallback(this, function(result) {
            
            $A.util.addClass(spinner, "slds-hide");
            
            var state = result.getState();
            
            messageTitle = 'Server Message';
            message = '';
            if (state === "SUCCESS") {              
                message = "Sucessfully added service  question rule";  	
                this.showToast(messageTitle, message, 'success');               
                this.getServiceQuestions(component);                            
                return;
            } 
            else {                
                this.errorMessage(component, messageTitle, message, result) 
            }
        });
        $A.enqueueAction(action);
        
        
        
    },
    reOrderQuestion: function(component){
        
        var action = component.get("c.RearrangeOrder", []);
        action.setParams({
            "serviceid": serviceid,
            "question": questionid,
            "parentQuestion":  parentQuestionId
        });
        
        action.setCallback(self, function(result) {
            var state = result.getState();
            messageTitle = 'Server Message';
            message = '';
            $A.util.addClass(spinner, "slds-hide");
            if (state === "SUCCESS") {
                
                message = "Sucessfully reordered the questions";  	
                this.showToast(messageTitle, message, 'success');
                
                var responseWrapper = JSON.parse(result.getReturnValue());
                var questions = responseWrapper.Data;
                component.set("v.questions", questions);
            } 
            else 
            {                
                this.errorMessage(component, messageTitle, message, result) 
            }
        });
        $A.enqueueAction(action);        
    },    
    addServiceQuestion: function(component) {
        
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
        
        action.setCallback(this, function(result) {
            var state = result.getState();
            messageTitle = 'Server Message';
            message = '';
            $A.util.addClass(spinner, "slds-hide");
            if (state === "SUCCESS") {
                
                message = "Sucessfully added the question";  	
                this.showToast(messageTitle, message, 'success');
                
                var responseWrapper = JSON.parse(result.getReturnValue());
                var questions = responseWrapper.Data;
                this.getServiceQuestions(component);
                //component.set("v.questions", questions);
            } 
            else 
            {
                this.errorMessage(component, messageTitle, message, result) 
            }
        });
        $A.enqueueAction(action);
    },
    removeSurveyQuestionConfirm : function(component, event, helper) {
        var prompt = component.find('messageBox');
        prompt && prompt.show({
            id: 'removeOneQuestion',
            title: 'Remove Question',
            body: '<p>Are you sure that you want to remove the question?<br/>If the question has children those will be deleted as well</p>',
            positiveLabel: 'Confirm',
            negativeLabel: 'No',
            severity: 'error'
        });
    },
    handleMessageBoxEvent: function(component, evt) {
        var result = {
            id: evt.getParam('id'),
            value: evt.getParam('context')
        };
        if (result.id === 'removeOneQuestion' && result.value == 1) {
            this.removeServiceQuestion(component, component.get("v.pserviceQuestionId"));
        }
    },
    getUISecurityInformation: function(component) {
        var message, messageTitle = 'Server Message';
        var projectId = component.get('v.recordId');
        var action = component.get("c.getUISecurityInformationApexSurvey", []);
        action.setParams({
            "recordid": projectId
        });
        action.setCallback(this, function(result) {
            var state = result.getState();       
            if (state === "SUCCESS") {
                var rw = JSON.parse(result.getReturnValue());
                
                console.log('rw :::' + result.getReturnValue());
                
                if(!$A.util.isEmpty(rw.Data)) { 
                    if(!$A.util.isEmpty(rw.Data["HiddenElements"])) {
                    	component.set("v.hiddenEls", rw.Data["HiddenElements"]);
                    }
				if(!$A.util.isEmpty(rw.Data["EditableElements"])) {
                    	component.set("v.editableEls", rw.Data["EditableElements"]);
                    }
                }
                var hiddenEls = component.get('v.hiddenEls');
                var editableEls = component.get('v.editableEls');
                
                if(!$A.util.isEmpty(hiddenEls) && hiddenEls != null && hiddenEls != undefined ){
                    var keys = Object.keys(hiddenEls);
                    if(!$A.util.isEmpty(keys)){
                        keys.forEach(function(item){ 
                            item == 'ProjectServiceQuestions__c.Remove' ? component.set('v.draggable', false) : '';
                            item == 'ProjectServiceQuestions__c.Edit' ? component.set('v.editable', false) : '';
                        });   
                    }
                }
                
                if(!$A.util.isEmpty(editableEls) && editableEls != null && editableEls != undefined ){
                    var keys = Object.keys(editableEls);
                    if(!$A.util.isEmpty(keys)){
                        keys.forEach(function(item){                                                                                        
                            item == 'ProjectServiceQuestions__c.Active' ? component.set('v.disable', false) : '';                            
                        });   
                    }
                }
                
                
                component.set('v.isLoaded', true);
                console.log('loaded');
            } else {
                component.set('v.isLoaded', true);
                this.errorMessage(component, messageTitle, message, result) 
            } 
        });
        $A.enqueueAction(action);
    },
    
    removeServiceQuestion: function(component, projectservicequestionid) {
        
        var message;
        var messageTitle;
        var spinner = component.find("spinner");  
        $A.util.removeClass(spinner, "slds-hide");      
        console.log('psqID delete: ', projectservicequestionid);
        var action = component.get("c.removeProjectServiceQuestionApex", []);
        action.setParams({
            "projectservicequestionid": projectservicequestionid
        });
        
        action.setCallback(this, function(result) {
            
            var state = result.getState();
            $A.util.addClass(spinner, "slds-hide");        
            
            messageTitle = 'Server Message';
            
            if (state === "SUCCESS") 
            {
                message = "Sucessfully removed the question";  	
                this.showToast(messageTitle, message, 'success');
                this.updateProjectService(component); 
            } 
            else {
                this.errorMessage(component, messageTitle, message, result) 
            }
            
        });
        $A.enqueueAction(action);
    },
    saveQuestionChanges: function(component) {
        
        var message;
        var messageTitle;
        var spinner = component.find("spinner");  
        $A.util.removeClass(spinner, "slds-hide");
        
        var questions = JSON.stringify(component.get("v.questions"));
        
        var action = component.get("c.saveServiceQuestionsChanges", []);
        
        action.setParams({
            "questionListWrapperInput": questions
        });
        
        action.setCallback(this, function(result) {
            
            $A.util.addClass(spinner, "slds-hide");              
            var state = result.getState();
            messageTitle = 'Server Message';
            
            if (state === "SUCCESS") {
                message = 'Changes saved successfully.';
                this.showToast(messageTitle, message, 'success');
            } else {              
                this.errorMessage(component, messageTitle, message, result) 
            }
        });
        $A.enqueueAction(action);
    },
    showServiceQuestionRuleModal:function(cmp, event, question ){
        var serviceId =  cmp.get("v.recordId");
        this._renderDialog(cmp, this.ServiceQuestionRuleDialogSetting,{
            'serviceId': serviceId,
            'squestionId': question.ProjectServiceQuestionId,
            'parentsquestionId': question.ParentID,
            'editable':cmp.get('v.draggable')
        });
        
    },
    showEditQuestionModal: function(cmp, event, question){
        var questions = [];
        questions.push(question);
        this._renderDialog(cmp, this.EditQuestionDialogSetting,{
            'recordid': question.ProjectServiceQuestionId,
            'questions': questions
        });
    },
     showUploadTargetModal: function(cmp, event, question){
        var questions = [];
        questions.push(question);
        this._renderDialog(cmp, this.UploadTargetDialogSetting,{
            'recordid': question.ProjectServiceQuestionId,
            'questions': questions
        });
    },   
    
    showAddQuestionModal: function(cmp) {
        this._renderDialog(cmp, this.AddQuestionDialogSetting, {'recordId': cmp.get('v.recordId')});
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
    
    dragChangedEvent: function(cmp, event, helper) {
        
        var projectServiceId = cmp.get('v.recordId');
        
        var sourceId = event.getParam('sourceId');
        var targetId = event.getParam('targetId');
        var actionType = event.getParam('actionType');
        var questions = cmp.get("v.notflattenquestions");
        var targetType = questions.find(item => item.ProjectServiceQuestionId == targetId);
        var sourceType = questions.find(item => item.ProjectServiceQuestionId == sourceId);
        if(!sourceType.ItemQuestion  && ((targetType.QuestionType == 'Group' && actionType == 'reparent') || targetType.ItemQuestion)) {
            console.log('true not item');
            this.showToast('Error', 'You cannot drop a non-target question into a target group', 'warning');
            return;
        }
        
        if(sourceType.ItemQuestion && (targetType.QuestionType != 'Group' && !targetType.ItemQuestion))  {
            this.showToast('Error', 'You cannot drop a target question outside a target group', 'warning');
            return; 
        }
        if (actionType == 'reparent' && targetType.QuestionType != 'Group') {
            console.log('reparent');
            this._renderDialog(cmp, this.ServiceQuestionRuleDialogSetting,{
                'serviceId': projectServiceId,
                'squestionId': sourceId,
                'parentsquestionId': targetId,
                'editable':cmp.get('v.draggable')
            });
            
            
        } else {
            console.log('reorder ', targetId);
            //reOrderQuestion
            var attributes = {
                "projectServiceId": projectServiceId,
                "questionId": sourceId,
                "precedingQuestionId": targetId
            }       
            
            this.reOrderProjectServiceQuestion(cmp,attributes);
            
        }
        event.stopPropagation();
        
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
    
    
    handleDefinedResponses: function(cmp, event, helper) { 
        var responses = event.getParam('responses');
        cmp.set('v.responses', responses);
        cmp.set('v.showResponses', true);
        cmp.set('v.questionTitle', event.getParam('questionTitle'));
    },
    
    reSort: function(){
        var evtFire = component.getEvent("callSortable");
        evtFire.fire();
    },
  
    createComponent: function(component, componentType, componentAttributes, targetElement){
        
        var questions = component.get('v.questions');        
        
        $A.getCallback(function(){
            $A.createComponent(
                "c:wrapper",
                {
                    componentType: componentType,
                    componentAttributes:  { context: "GLOBAL", question: questions }, 
                    targetElement: targetElement,
                },
                function(wrapperComponent, status, errorMessage){
                    if (status === "INCOMPLETE") {
                        return;
                    }
                    else if (status === "ERROR") {
                        return;
                    }
                    
                    var renderBox = component.find("renderBox");
                    var body = renderBox.get("v.body") || [];
                    body.push(wrapperComponent);
                    renderBox.set("v.body", body);
                }
            );
        })();
        
    },
    errorMessage: function(cmp, messageTitle, message, result) {
        var errors = result.getError();
        if (errors[0] && errors[0].message) // To show other type of exceptions
            message = message + ". " + errors[0].message;
        if (errors[0] && errors[0].pageErrors) // To show DML exceptions
            message = message + ". " + errors[0].pageErrors[0].message;
        
        this.showToast(messageTitle, message, 'error');  
    },
    updateProjectService: function(component){
        var self = this;
        window.setTimeout(
            $A.getCallback(function() {
                self.getServiceQuestions(component);
            }), 250
        );                     
    },
    showSpinner: function(cmp){
        var spinner = cmp.find("displaySpinner");
        $A.util.removeClass(spinner, "slds-hide"); 
    },
    hideSpinner: function(cmp){
        var spinner = cmp.find("displaySpinner");
        $A.util.addClass(spinner, "slds-hide"); 
    },

    onAddTarget: function(component,event){
        this.showSpinner(component);
        
        var projservQnId = component.get("v.pserviceQuestionId");
        console.log('~~projservQnId~~', projservQnId);
        
        var targets = event.getParam("targetId");
        console.log('~~targets~~', targets);
        
        var action = component.get("c.AddTargets_SurveyResponse");
        action.setParams({        
           "searchIds": JSON.stringify(targets),
           "projservQnId":projservQnId
        });
        action.setCallback(this, function(response){
            this.hideSpinner(component);
            var state = response.getState();
            if(state === 'SUCCESS'){             
                //var togglePaste = component.find("togglePaste");
        		//$A.util.toggleClass(togglePaste, "togglePaste"); 
                $A.get('e.force:refreshView').fire();     
                //window.location.reload();
                this.showToast("Add Target",'Successfully added Target as response.' ,'success');
            } else {
				var errors = response.getError();
                if (!!errors && !!errors[0] && !!errors[0].message) {
                    msg = errors[0].message;
                } else {
                    msg = 'The system run into an unknown error.';
                }
                this.showToast("Add Target",'Error adding Target as response: ' + msg, 'error');
            }
        });
        $A.enqueueAction(action);
    },
    getMultiListCheck: function(component) {        
        var message;
        var messageTitle;
        var action = component.get("c.getMultiListCheckApex");
        console.log(action);
        var self = this;
        action.setCallback(self, function(result) {
            var state = result.getState();            
            message = '';
            if (state === "SUCCESS") {
                console.log('~~'+result.getReturnValue());
                var rtnVal = JSON.stringify(result.getReturnValue());                
                component.set("v.enableMultiSelect", rtnVal);                
                
            } else {
                console.log(result.getError());
                
                var errors = result.getError();
                if (errors[0] && errors[0].message) // To show other type of exceptions
                    message = errors[0].message;
                if (errors[0] && errors[0].pageErrors) // To show DML exceptions
                    message = errors[0].pageErrors[0].message;
                
                this.showToast(messageTitle, message, 'error');
            }
            
        });
        $A.enqueueAction(action);
    },
})