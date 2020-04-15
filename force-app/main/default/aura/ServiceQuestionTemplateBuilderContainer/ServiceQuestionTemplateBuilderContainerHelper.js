({
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
                component.set("v.surveyTemplateVersion", service.SurveyTemplateVersion);
                
                
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
})