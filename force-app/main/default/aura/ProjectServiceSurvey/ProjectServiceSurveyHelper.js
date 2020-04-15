({
    getProjectService: function(component) {
        
        var message;
        var messageTitle;
        var projectServiceId =  component.get("v.recordId");
        
        var action = component.get("c.GetProjectServiceSurveyTemplateVersion", []);
        action.setParams({
            "projectServiceId": projectServiceId
        });
        
        
        var self = this;
        action.setCallback(self, function(result) {
            var state = result.getState();
            messageTitle = 'Server Message';
            message = '';
            if (state === "SUCCESS") {
                var SurveyTemplateVersion = result.getReturnValue();             
                console.log(SurveyTemplateVersion);
                component.set("v.surveyTemplateVersion", SurveyTemplateVersion);   
                component.set('v.isLoaded',true);
            } else {
                console.log(result.getError());
                
                var errors = result.getError();
                if (errors[0] && errors[0].message) // To show other type of exceptions
                    message = errors[0].message;
                if (errors[0] && errors[0].pageErrors) // To show DML exceptions
                    message = errors[0].pageErrors[0].message;
                
                this.showToast(messageTitle, message, 'error');
                component.set('v.isLoaded',true);
            }
            
        });
        $A.enqueueAction(action);
    },
})