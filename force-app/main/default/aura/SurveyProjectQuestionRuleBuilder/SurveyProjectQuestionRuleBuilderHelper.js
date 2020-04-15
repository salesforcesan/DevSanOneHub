({
    init:function(component, event, helper){
        var opts = [    
            { value: "EQ", label: "Equals" }
        ];
        var parentQuestionId = component.get("v.parentsquestionId");
        
        component.set("v.operators", opts);
        
        
        var serviceQuestionRuleID = component.get("v.serviceQuestionRuleID");
        component.set("v.serviceQuestionRuleID", serviceQuestionRuleID);
               
        if (serviceQuestionRuleID == undefined){
            this._getDefinedResponsesforPSquestion(component, event, helper);
        }
        else{                       
            this._getServiceQuestionRule(component, event, helper);
        }
    },
    fireCloseEvent : function(component, confirmResult, inputResult, context) {
        
        component.getEvent("closeDialogEvent").fire();               		     
        
    },
    _getServiceQuestionRule: function(component, event, helper){
        var serviceQuestionRuleID = component.get("v.serviceQuestionRuleID");
        
        var action = component.get("c.GetProjectServiceQuestionRule");
        
        action.setParams({
            "serviceProjectQuestionRuleId": serviceQuestionRuleID
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
                    if(!$A.util.isEmpty(definedResponses.ServiceQuestionRule) && !$A.util.isEmpty(definedResponses.ServiceQuestionRule.SqOperator) && !$A.util.isUndefined(definedResponses.ServiceQuestionRule.SqOperator))
                        
                    {
                        component.set("v.selectedValue", definedResponses.ServiceQuestionRule.SqOperator);
                    }
                    else
                    {
                        component.set("v.selectedValue", 'EQ');
                    }
                    //  console.log('hello+++'+ definedResponses.ServiceQuestionRule.SqValue);  
                    if(!$A.util.isEmpty(definedResponses.ServiceQuestionRule) &&  !$A.util.isEmpty(definedResponses.ServiceQuestionRule.SqValue) && !$A.util.isUndefined(definedResponses.ServiceQuestionRule.SqValue))   
                        var sqvalue = definedResponses.ServiceQuestionRule.SqValue;
                    var array=[];
                    if(!$A.util.isEmpty(sqvalue))
                    {
                        if (sqvalue.indexOf(',') > -1)
                        { 
                            array = sqvalue.split(',');
                        }
                        else
                        {
                            array  = sqvalue.split();
                        }
                        
                        for (var i in array) {
                            //console.log( [arrayi]);
                            // 
                            definedResponses.DefinedResponses.forEach(function(element) {

                                if(element.ProjectServiceQuestionDefinedResponseId == array[i])
                                {
                                    element.IsDefinedResponseSelected = true;
                                }
                            });
                        }
                    }
                    
                    
                    component.set("v.squestionId", definedResponses.ServiceQuestionRule.ServiceQuestion);
        			component.set("v.parentsquestionId", definedResponses.ServiceQuestionRule.ParentServiceQuestion);                    
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
        
        
        var action = component.get("c.GetProjectSqDefinedResponses");
        action.setParams({
            "parentsqId": parentQuestionId,
            "sqId":serviceQuestionId
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
                    console.log('definedResponses: ', definedResponses);
                    if( !$A.util.isEmpty(definedResponses.ServiceQuestionRule) && !$A.util.isEmpty(definedResponses.ServiceQuestionRule.SqOperator) && !$A.util.isUndefined(definedResponses.ServiceQuestionRule.SqOperator))                        
                    {
                        component.set("v.selectedValue", definedResponses.ServiceQuestionRule.SqOperator);
                    }
                    else
                    {
                        component.set("v.selectedValue", 'EQ');
                    }
                    console.log('sq list: ', definedResponses.ServiceQuestionRuleList);
                    if(!$A.util.isEmpty(definedResponses.ServiceQuestionRuleList))  { 
                          
                        var sqvalues =[];
                        definedResponses.ServiceQuestionRuleList.forEach(item => sqvalues.push(item.SqValue));
                        if(!$A.util.isEmpty(sqvalues))
                        {                        
                            for (var i in sqvalues) {
                                //console.log( [arrayi]);
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
        
        if(selectedRec.length == 0)
        {
            message ="please select at least one defined response.";
            this._notify(component, message, 'error');
            return;
        }
        
        
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