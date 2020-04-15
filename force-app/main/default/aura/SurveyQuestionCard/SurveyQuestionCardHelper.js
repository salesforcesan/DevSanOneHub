({       
    showEditServiceQuestionModalHandler: function(cmp, event, context){
        var question = cmp.get("v.question");        
        var cmpEvent = cmp.getEvent('EventSurveyQuestionCard');
        cmpEvent.setParams({
            'question':question,
            'context':context
        });
		cmpEvent.fire();
    },
  
    updateOptionalChange: function(component, event, serviceQuestionId, optionValue) {
         
        this.showSpinner(component); 
        var message;
        var messageTitle;
        
        var action = component.get("c.UpdateServiceQuestionOption", []);
        action.setParams({
            "serviceQuestionId": serviceQuestionId,
            "optionValue": optionValue
        });
        
        var self = this;
        action.setCallback(self, function(result) {

            var state = result.getState();
            self.hideSpinner(component);     
            if (state === "SUCCESS") 
            {
                message = "Sucessfully saved the question";  	
                this.showToast(messageTitle, message, 'success');
                self.notifyQuestionsUpdate(component);
            } 
            else {
                
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
    
    updateCanRemoveChange: function(component, event, serviceQuestionId, canRemoveQuestionValue) {               
		this.showSpinner(component); 
        var message;
        var messageTitle;
            
        var action = component.get("c.UpdateServiceQuestionCanRemove", []);
        action.setParams({
            "serviceQuestionId": serviceQuestionId,
            "canRemoveValue": canRemoveQuestionValue
        });
        
        var self = this;
        action.setCallback(self, function(result) {

            var state = result.getState();
			self.hideSpinner(component);                 
            if (state === "SUCCESS") 
            {
                message = "Sucessfully saved the question";  	
                this.showToast(messageTitle, message, 'success');
                self.notifyQuestionsUpdate(component);
            } 
            else {
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
      
    showToast : function(title, message, type) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "message": message,
            "type": type
        });
        toastEvent.fire();
    },     
    notifyQuestionsUpdate: function(component){
    	var nqEvent = component.getEvent("refreshQuestionsEvent");
		nqEvent.fire();
	},
 
    showSpinner: function(component) {
        var spinner = component.find("spinner");  
        $A.util.removeClass(spinner, "slds-hide");
    },
    hideSpinner: function(component) {
        var spinner = component.find("spinner");  
        $A.util.addClass(spinner, "slds-hide");
    },
    toggleToolTip: function(cmp, e, field) {
		var style;
        var fieldVal = cmp.get('v.show' + field);
        fieldVal ? style = '' : style = 'position: absolute; width: 100px; right:27px; top:-5px;';
        cmp.set('v.show' + field, !fieldVal);
        cmp.set('v.tooltipStyle', style);
    },
    
     slideInCard: function(cmp, e, h) {
        var surveyCard = cmp.find("surveyCard");
        $A.util.addClass(surveyCard, 'flip');
        $A.util.removeClass(surveyCard, 'flip-out');
    },
    slideOutCard: function(cmp, e, h) {
        var surveyCard = cmp.find("surveyCard");
        $A.util.addClass(surveyCard, 'flip-out');
        $A.util.removeClass(surveyCard, 'flip');
    }, 
   
    
})