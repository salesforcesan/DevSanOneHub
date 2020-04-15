({
    doInit : function(component, event, helper) {
        helper.Init(component, event, helper);
        helper.getAILabelOptions(component, event, helper);
        //helper.getServiceQuestionRule(component, event, helper);        
    },
    
    modelChange: function (cmp, evt, helper) {
        var val = cmp.find('aiModel').get('v.value');
        cmp.set('v.selectedValue', val);
        console.log('val: ', val);
    },
    
    saveChanges : function(component, event, helper) {
        var model = component.get('v.selectedValue');
        var question = component.get('v.question');
        var questions = component.get('v.questions');
        var hasRuleError = false;
        var notifyString = [];    
        
        question.AILabelId = model;
        //console.log('question saved: ', question);
        if ((component.find("minVal")!= undefined) && (component.find("MaxVal")!= undefined))
        {
            var minValue = component.find("minVal").get("v.value");
            var maxValue = component.find("MaxVal").get("v.value");
            if (isNaN(minValue))
            {
                var message = ' Please enter Numeric Value in min Value field';
                
                helper.showError(component,message)
                return;
            }
            
            if (isNaN(maxValue))
            {
                var message = ' Please enter Numeric Value in Max Value field';
                
                helper.showError(component,message)
                return;
            }
            
            if(parseInt(minValue) > parseInt(maxValue))
            {
                var message = ' Please enter  minimum  Value less then maximum value';
                helper.showError(component,message)
                return;
            }
            if(parseInt(maxValue) < parseInt(minValue))
            {
                var message = ' Please enter  maximum  Value greater then minimum value';
                helper.showError(component,message)
                return;
            }
        }          
        
        var activeMessage = '';
        var message = 'You cannot inactivate a response for a question used in a Rule.  Please remove the Rule, then inactivate the response.';        
        var isService = ( typeof question.IsServiceQuestion !== 'undefined' ) ? question.IsServiceQuestion : false;
        
        if (question.DefinedResponses != null) {
            
            question.DefinedResponses.forEach(function(definedResponse) { 
                
                if(!definedResponse.Active){
                    
                    if (definedResponse.RuleUsedInProjectServiceQuestion != null){
                        for (var i= 0 ; i < definedResponse.RuleUsedInProjectServiceQuestion.length ; i++){
                            
                            if (definedResponse.DefinedResponseText ==  definedResponse.RuleUsedInProjectServiceQuestion[i].SqValue){
                                hasRuleError = true;
                                
                                var questionRule = question.children.find(item => ((isService) ? item.ID : item.ProjectServiceQuestionId) == definedResponse.RuleUsedInProjectServiceQuestion[i].ServiceQuestion);        
                                notifyString.push('<br \>' +  questionRule.QuestionIndentation + ' : ' + questionRule.QuestionText + ' (Defined Response :' + definedResponse.DefinedResponseText + ')');
                                
                            }                        
                        }
                    }
                }
            });
        }
        
        if (hasRuleError){
            
            activeMessage = message + '<br \>' + notifyString.sort();
            
            component.set('v.recordError',activeMessage);
            helper._notify(component, activeMessage, 'error');
            return;
        }        
        
        var editQuestionEvent = component.getEvent('editSurveyQuestion1');
        
        editQuestionEvent.setParams({ "question": question });
        
        editQuestionEvent.fire();
        
    },
    saveRule: function(component, evt, helper)
    {
        var serviceQuestionEvent = component.getEvent('SQRule');
        serviceQuestionEvent.setParams({ "squestionRule": component.get("v.ServicequestionRule"),
                                        "serviceQuestion":component.get("v.recordid")
                                       });
        
        
        serviceQuestionEvent.fire();
    },
    
    closeDialog: function(cmp, evt, helper) {
        
        var dlgEvt = cmp.getEvent('closeDialogEvent');
        dlgEvt.fire();
    }    
})