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
        'component': 'c:SurveyQuestionRuleBuilder',
        'size': 'x-small',
        'title': 'Survey Question Rule Builder'
    }, 
    
    handleDragOver: function(e) {
        if (e.preventDefault) {
            e.preventDefault(); // Necessary. Allows us to drop.
        }
        
        e.dataTransfer.dropEffect = 'move';  // See the section on the DataTransfer object.
        
        return false;
    },    
    getService: function(component) {
        var message;
        var messageTitle;
        var serviceid = component.get("v.recordId");
        
        var action = component.get("c.getServiceApex", []);
        action.setParams({
            "serviceid": serviceid
        });
        console.log(action);
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
    getServiceQuestions: function(component) {
        
        var message;
        var messageTitle;
        var serviceid =  component.get("v.recordId");
        
        var action = component.get("c.getServiceQuestionsApex", []);
        action.setParams({
            "serviceid": serviceid
        });
        console.log(action);
        var self = this;
        action.setCallback(self, function(result) {
            var state = result.getState();
            messageTitle = 'Server Message';
            message = '';
            if (state === "SUCCESS") {
                var responseWrapper = JSON.parse(result.getReturnValue());
                var questions = responseWrapper.Data;
                component.set("v.notflattenquestions", questions);
                
                //To build tree with javascript
                var tree = this.unflatten(questions);
                component.set("v.questions", tree);
                
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
    reOrderServiceQuestion: function(component, attributes){
        
        var message;
        var messageTitle;
        var serviceid =  component.get("v.recordId");
        
        var action = component.get("c.ReorderServiceQuestion", []);
        action.setParams(attributes);
        
        var self = this;
        action.setCallback(self, function(result) {
            var state = result.getState();
            messageTitle = 'Server Message';
            message = '';
            if (state === "SUCCESS") {
                var responseWrapper = JSON.parse(result.getReturnValue());
                var questions = responseWrapper.Data;
                var tree = this.unflatten(questions);  
                
                component.set("v.questions", tree);                
                
                //to refresh
                var evtFire = $A.get("e.c:ServiceQuestionSortableEvent");
                
                setTimeout(function() {
                    
                    evtFire.fire();
                    
                }, 100);
                return;
                
                
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
    
    
    addServiceQuestionrule: function(component)
    {
        var message;
        var messageTitle;
        var spinner = component.find("spinner");  
        $A.util.removeClass(spinner, "slds-hide");
        
        var serviceid = component.get("v.recordId"); 
        var serviceQuestion = component.get("v.serviceQuestionId");
        var pserviceQuestion = component.get("v.pserviceQuestionId");
        var selectedop = component.get("v.operator");
        var drl = component.get("v.definedResponses");
        var action = component.get("c.addServiceQuestionRule", []);      
        action.setParams({
            "serviceId":serviceid,
            "sqId":serviceQuestion,
            "psqId":pserviceQuestion,
            "sop":selectedop,
            "drl":drl
        });
        
        var self = this;
        action.setCallback(self, function(result) {
            
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
            else 
            {
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
    
    addServiceQuestion: function(component) {
        
        var message;
        var messageTitle;
        var spinner = component.find("spinner");  
        $A.util.removeClass(spinner, "slds-hide");
        
        
        var serviceid = component.get("v.recordId");
        var questionid = component.get("v.questionId");
        
        var action = component.get("c.addServiceQuestion", []);
        action.setParams({
            "serviceid": serviceid,
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
               this.errorMessage(component, messageTitle, message, result);
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
    removeServiceQuestion: function(component, servicequestionid) {
        
        var message;
        var messageTitle;
        var spinner = component.find("spinner");  
        $A.util.removeClass(spinner, "slds-hide");      
        
        var action = component.get("c.removeServiceQuestionApex", []);
        action.setParams({
            "servicequestionid": servicequestionid
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
                this.errorMessage(component, messageTitle, message, result);
            }
            
        });
        $A.enqueueAction(action);
    },
    updateProjectService: function(component){
        var self = this;
        window.setTimeout(
            $A.getCallback(function() {
                self.getServiceQuestions(component);
            }), 250
        );                     
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
                this.errorMessage(component, messageTitle, message, result);
                this.getServiceQuestions(component);
            }
        });
        $A.enqueueAction(action);
    },
    showServiceQuestionRuleModal:function(cmp, event, question ){
        var serviceId =  cmp.get("v.recordId");
        this._renderDialog(cmp, this.ServiceQuestionRuleDialogSetting,{
            'serviceId': serviceId,
            'squestionId': question.ProjectServiceQuestionId,
            'parentsquestionId': question.ParentID
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
    editServiceQuestion: function(component) {
        
        var message;
        var messageTitle;
        var spinner = component.find("spinner");  
        $A.util.removeClass(spinner, "slds-hide");
        
        var question = JSON.stringify(component.get("v.question"));  
        
        var action = component.get("c.saveServiceQuestion", []);      
        action.setParams({
            "questionWrapperInput": question});
        console.log(action);  
        var self = this;
        action.setCallback(self, function(result) {
            
            $A.util.addClass(spinner, "slds-hide");
            
            var state = result.getState();
            messageTitle = 'Server Message';
            message = '';
            if (state === "SUCCESS") {
                console.log('hello world+++++++++++++');
                
                message = "Sucessfully saved question changes";  	
                this.showToast(messageTitle, message, 'success');
                
                var responseWrapper = JSON.parse(result.getReturnValue());
                var questions = responseWrapper.Data;
                component.set("v.notflattenquestions", questions);
                console.log('questions resp: ', questions);
                //To build tree with javascript
                var tree = this.unflatten(questions);
                component.set("v.questions", tree);
                
            } 
            else 
            {
            	this.errorMessage(component, messageTitle, message, result);
            }
        });
        $A.enqueueAction(action);
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
        var serviceId = cmp.get('v.recordId');
        var sourceId = event.getParam('sourceId');
        var targetId = event.getParam('targetId');
        var actionType = event.getParam('actionType');
        
        console.log('Source: ' + sourceId);
        console.log('parent: ' + targetId);
        console.log('Service: ' + serviceId);
        var questions = cmp.get("v.notflattenquestions");
        var targetType = questions.find(item => item.ProjectServiceQuestionId == targetId);
        var sourceType = questions.find(item => item.ProjectServiceQuestionId == sourceId);        
        if(!sourceType.ItemQuestion  && ((targetType.QuestionType == 'Group' && actionType == 'reparent') || targetType.ItemQuestion)) {
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
                'serviceId': serviceId,
                'squestionId': sourceId,
                'parentsquestionId': targetId
            });
        } else {
            console.log('reorder'); 
            //reOrderQuestion
            var attributes = {
                "serviceId": serviceId,
                "questionId": sourceId,
                "precedingQuestionId": targetId
            }      
            
            
            this.reOrderServiceQuestion(cmp,attributes);
            
        }
        event.stopPropagation();
        
    },
    errorMessage: function(cmp, messageTitle, message, result) {
        console.log(result.getError());
        var errors = result.getError();
        if (errors[0] && errors[0].message) // To show other type of exceptions
            message = errors[0].message;
        if (errors[0] && errors[0].pageErrors) // To show DML exceptions
            message = errors[0].pageErrors[0].message;
        
        this.showToast(messageTitle, message, 'error');  
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