({
    init:function(component, event, helper){
        var parentQuestionId = component.get("v.parentsquestionId");    
        var serviceQuestionRuleID;// = component.get("v.serviceQuestionRuleID");
                
        
        if (serviceQuestionRuleID == undefined || serviceQuestionRuleID == null){
            this._getDefinedResponsesforPSquestion(component, event, helper);
        }
        else{                       
            this._getServiceQuestionRule(component, event, helper);
        }
        
        console.log('question type check: ', component.get('v.parentSqObject'));
    },
    fireCloseEvent : function(component, confirmResult, inputResult, context) {
        
        component.getEvent("closeDialogEvent").fire();               		     
        
    },
    _getServiceQuestionRule: function(component, event, helper){
        var serviceQuestionRuleID = component.get("v.serviceQuestionRuleID");
       
        var action = component.get("c.GetServiceQuestionRule");
        
        action.setParams({
            "serviceQuestionRuleId": serviceQuestionRuleID
        });        
        action.setCallback(this, function(response) {
            
            var state = response.getState();
            
            if (!component.isValid()) {
                console.log('not sucess');
                // self._msgBox('error', 'The component is out of scope.');
                return;
            }
            //self.hideSpinner(component);
            if (state === 'SUCCESS') {
                if(!($A.util.isEmpty(response.getReturnValue()))){
                    var responseWrapper = JSON.parse(response.getReturnValue());
                    var definedResponses = responseWrapper.Data;
                    console.log('definedResponses' + definedResponses);
                    
                    if(!$A.util.isEmpty(definedResponses.ServiceQuestionRule.SqOperator) && !$A.util.isUndefined(definedResponses.ServiceQuestionRule.SqOperator))
                        
                    {
                        component.set("v.selectedValue", definedResponses.ServiceQuestionRule.SqOperator);
                    }
                    else
                    {
                        component.set("v.selectedValue", 'EQ');
                    }
                    //console.log('hello+++'+ definedResponses.ServiceQuestionRule.SqValue);  
                    if(!$A.util.isEmpty(definedResponses.ServiceQuestionRuleList))  { 
                          
                        var sqvalues =[];
                        definedResponses.ServiceQuestionRuleList.forEach(item => sqvalues.push(item.SqValue));
                        if(!$A.util.isEmpty(sqvalues))
                        {                        
                            for (var i in sqvalues) {
                                //console.log( [arrayi]);
                                definedResponses.DefinedResponses.forEach(function(element) {
                                    
                                    console.log('response Id'+ element.DefinedResponseId);
                                    // console.log('array value'+ array[i]);
                                    if(element.DefinedResponseText == sqvalues[i])
                                    {
                                        element.IsDefinedResponseSelected = true;
                                    }
                                });
                            }
                        }
                    }
                    
                    component.set("v.parentSqObject",definedResponses);
                    
                }
                return;
                
            }
            
            if (state === 'ERROR') {
                console.log('error');
                var errors = response.getError();
                if (!!errors && !!errors[0] && !!errors[0].message) {
                    // self._msgBox('error', errors[0].message);
                } else {
                    //  self._msgBox('error', 'The system runs into an error.');
                }
                return;
            }
            //  self._msgBox('error', 'The system runs into an error. Please refresh the component.');
            
        });
        $A.enqueueAction(action);
        
    },
    _getDefinedResponsesforPSquestion: function(component, event, helper)
    {
        
        var self = this;
        // self.showSpinner(component);
        var serviceQuestionId = component.get("v.squestionId");
        var parentQuestionId = component.get("v.parentsquestionId");
       
        //alert(parentQuestionId + ' ' + serviceQuestionId);
        
        var action = component.get("c.GetSqDefinedResponses");
        action.setParams({
            "parentsqId": parentQuestionId,
            "sqId":serviceQuestionId
        });
        
        console.log('parentQuestionId:::' + parentQuestionId)
        console.log('serviceQuestionId:::' + serviceQuestionId)
        
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (!component.isValid()) {
                console.log('not sucess');
                // self._msgBox('error', 'The component is out of scope.');
                return;
            }
            //self.hideSpinner(component);
            if (state === 'SUCCESS') {
                if(!($A.util.isEmpty(response.getReturnValue()))){
                    var responseWrapper = JSON.parse(response.getReturnValue());
                    var definedResponses = responseWrapper.Data;
                    console.log('definedResponses: ', definedResponses);
                    
                    if(!$A.util.isEmpty(definedResponses.ServiceQuestionRule.SqOperator) && !$A.util.isUndefined(definedResponses.ServiceQuestionRule.SqOperator))
                        
                    {
                        component.set("v.selectedValue", definedResponses.ServiceQuestionRule.SqOperator);
                    }
                    else
                    {
                        component.set("v.selectedValue", 'EQ');
                    }
                      console.log('rule list', definedResponses.ServiceQuestionRuleList);  
                    if(!$A.util.isEmpty(definedResponses.ServiceQuestionRuleList)) {                      
                        
                        var sqvalues =[];
                        definedResponses.ServiceQuestionRuleList.forEach(item => sqvalues.push(item.SqValue));
                        if(!$A.util.isEmpty(sqvalues)) {                        
                            for (var i in sqvalues) {
                                definedResponses.DefinedResponses.forEach(function(element) {
                                    if(element.DefinedResponseText == sqvalues[i]) {
                                        element.IsDefinedResponseSelected = true;
                                    }
                                });
                            }
                        }
                    }
                    
                    component.set("v.parentSqObject",definedResponses);
                    
                }
                return;
                
            }
            
            if (state === 'ERROR') {
                console.log('error');
                var errors = response.getError();
                if (!!errors && !!errors[0] && !!errors[0].message) {
                    // self._msgBox('error', errors[0].message);
                } else {
                    //  self._msgBox('error', 'The system runs into an error.');
                }
                return;
            }
            //  self._msgBox('error', 'The system runs into an error. Please refresh the component.');
            
        });
        $A.enqueueAction(action);
        
    },
    saveRule:function(component, event, helper)
    {
        
        var serviceQuestionId = component.get("v.squestionId");
        var parentQuestionId = component.get("v.parentsquestionId");
        var selectedval = component.get("v.selectedValue");
        var getCheckAllId = component.find("cboxRow");
        var selectedRec = [];
        var message='';
        for (var i = 0; i < getCheckAllId.length; i++) {
            
            if(getCheckAllId[i].get("v.value") == true )
            {
                selectedRec.push(getCheckAllId[i].get("v.text")); 
            }
        }
        console.log('selected rec: ', selectedRec);
        if(selectedRec.length == 0)
        {
            message ="please select at least one defined response.";
            this._notify(component, message, 'error');
            return;
        }
        
        /*if(selectedRec.length > 1 && selectedval == 'EQ')
        {
            message ="please select only one defined response";
            this._notify(component, message, 'error');
            return;
        }*/

        
        var surveyQuestionruleEvent = component.getEvent("SurveyQuestionrule");
        surveyQuestionruleEvent.setParams({ "ServiceQuestionId": serviceQuestionId,
                                           "parentServiceQuestionId":parentQuestionId,
                                           "operator":selectedval,
                                           "definedReponses":JSON.stringify(selectedRec)
                                          });
        surveyQuestionruleEvent.fire();
        
    },
    
    _notify: function(cmp, msg, type, autoHide, duration) {
        cmp.find('nt').show(msg, type, autoHide, duration);
    },
    
})