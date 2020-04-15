({
    loadProjectCancelReasons : function(cmp){                
        var action = cmp.get("c.GetProjectCancelReasons");
        var opts = [];   
        this.showSpinner(cmp);
        action.setCallback(this, function(response) {
            console.log('Cancel Reasons: ' + response.getReturnValue());
            for(var i=0;i< response.getReturnValue().length;i++){
                opts.push({"class": "optionClass", label: response.getReturnValue()[i], value: response.getReturnValue()[i]});
            }
            cmp.set("v.cancelreasons", opts);
            this.hideSpinner(cmp);
        });
        $A.enqueueAction(action);                
    },    
    getProjectDetails : function(cmp){                
        var action = cmp.get("c.GetProject");
        console.log('Project Id: ' + cmp.get("v.recordId"));
        
        action.setParams({
            recordId : cmp.get("v.recordId"),
        });
        
        this.showSpinner(cmp);
        action.setCallback(this, function(response) {
            console.log('Project Data: ' + response.getReturnValue());
            cmp.set("v.project", response.getReturnValue());
            this.hideSpinner(cmp);
        });
        $A.enqueueAction(action);                
    },    
    
    CancelClicked : function(component, event, helper) {
        var dismissActionPanel = $A.get("e.force:closeQuickAction");
        dismissActionPanel.fire();        
        
    },
    
    cancelSelectedProject : function (component, event, helper) {
        var self = this; 
        var project = component.get("v.project");
        var comment = component.find("cancelReasonComment").get("v.value");		
        var action = component.get("c.CancelProject");
        component.set("v.callbackresult","NONE");        
        
        action.setParams({
            projectId : project.Id,
            selReason : project.CancelReason,
            selComm : comment
        });
        this.showSpinner(component);
        
        
        action.setCallback(this, function (response) {
            var state = response.getState();                        
            component.set("v.callbackresult",state);        
            console.log('state: ' + component.get("v.callbackresult"));
            if (state === "SUCCESS") {
                var responseWrapper = JSON.parse(response.getReturnValue());                                          
                var result = response.getReturnValue();
                
                if (responseWrapper.Message != '' && responseWrapper.Message != null)
                {
                    component.set("v.callbackmessage",responseWrapper.Message);
                }                
                
                if (responseWrapper.State === 'SUCCESS') {
                    
                    var id = window.setTimeout(
                        $A.getCallback(function() {
                            window.clearTimeout(id);
                            self.CancelClicked(component);
                            var appEvent = $A.get("e.c:EventProjectRefresh");
                            appEvent.fire();
                            $A.get('e.force:refreshView').fire();
                        }), 1000
                    );
                }
            } else if (state === "INCOMPLETE") {
                console.log('do something here');
            } else if (state === "ERROR") {
                var errors = response.getError();                
                if (errors) {
                    if (errors[0] && error[0].message) {
                        component.set("v.callbackmessage", errors[0].message);
                    }
                } else {
                    component.set("v.callbackmessage", "Unhandled Exception occurred:\r\nContact Administrator");
                }
            }
            this.hideSpinner(component);
        });
        $A.enqueueAction(action);
    },
    showSpinner: function(cmp){
        var spinner = cmp.find("displaySpinner");
        $A.util.removeClass(spinner, "slds-hide"); 
    },
    hideSpinner: function(cmp){
        var spinner = cmp.find("displaySpinner");
        $A.util.addClass(spinner, "slds-hide"); 
    },
    notifyMessage: function(cmp, msg, msgType) {
        var e = cmp.find('notification');
        e.set('v.message', msg);
        e.set('v.type', msgType);
    },
})