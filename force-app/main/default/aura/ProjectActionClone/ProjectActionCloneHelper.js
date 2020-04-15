({
    NOTIFICATION_TYPES: {
        'ERROR': 'error',
        'INFO': 'info',
        'WARNING': 'warning',
        'SUCCESS': 'success'
    },    
    CancelClicked : function(component, event, helper) {
		var dismissActionPanel = $A.get("e.force:closeQuickAction");
        dismissActionPanel.fire();        
        
    },
    CloneProject : function(component, event, helper) {
        var action = component.get("c.InitCloneProject");
        var projectId = component.get("v.recordId");
        action.setParams({
            "projectId": projectId
        });    
       
        helper.callServerAction(component,event,helper,action);
        
    },
    callServerAction:  function(component,event,helper,action)    
    { 
      var self = this;  
      helper.showSpinner(component);
      component.set("v.callbackresult","NONE");        
      action.setCallback(this, function(response) {
            var state = response.getState();
          	if (!component.isValid())
                return;

            component.set("v.callbackresult",state);          
            if (state === "SUCCESS") {                
                helper.hideSpinner(component);
                console.log('Success returned: ' + response.getReturnValue());
                var responseWrapper = JSON.parse(response.getReturnValue());                

                if(responseWrapper.State==="SUCCESS"){
                    if (responseWrapper.Message != '' && responseWrapper.Message != null)
                    {
                        component.set("v.callbackmessage",responseWrapper.Message);
                    }
                }
                else{
                        component.set("v.callbackresult","ERROR");          
                }                
            }
            else if (state === "INCOMPLETE") {
               helper.hideSpinner(component);
				//console.log('do something here');
			} else if (state === "ERROR") {
                helper.hideSpinner(component);
				var errors = response.getError();                
				if (errors) {
					if (errors[0] && error[0].message) {    
                        component.set("v.callbackmessage",errors[0].message);
					}
				} else {
                    component.set("v.callbackmessage",'Unhandled Exception occurred:\r\nContact Administrator');
				}
			}
			self.closeActionDialog();
        });
        
        $A.enqueueAction(action);  
    },
 	showSpinner: function(cmp){
        var spinner = cmp.find("spinner");
        $A.util.removeClass(spinner, "slds-hide"); 
    },
    hideSpinner: function(cmp){
        var spinner = cmp.find("spinner");
        $A.util.addClass(spinner, "slds-hide"); 
    },
    closeActionDialog: function(component){
        var self = this;
        window.setTimeout(
            $A.getCallback(function() {
                self.CancelClicked(component);
                self.gotoDashboard();
            }), 2000
        );                     
    },
    gotoDashboard : function () {
        var evt = $A.get("e.force:navigateToComponent");
        evt.setParams({
            componentDef: "c:ProjectDashboardLayout",
            componentAttributes: {}
        });
        evt.fire();    
    },
    ApexQueueSize : function(component) {
        var action = component.get("c.CheckApexQueueSize");
        var self = this;
        
        action.setCallback(self, function(result) {
            console.log('~~');
            console.log('~g~'+ result.getState());
            console.log('~rtn~'+result.getReturnValue());
            
            
            var state = result.getState();
            if (!component.isValid())
                return;
            component.set("v.callbackresult",state); 
            
            if (state === "SUCCESS") { 
                component.set("v.isClonable", result.getReturnValue());
                
                if(!result.getReturnValue()){
                    component.set("v.callbackmessage",'The max queue limit has been reached for cloning. Please try this function again later.');
                    component.set("v.callbackresult",'ERROR');
                }
                else{
                    component.set("v.callbackresult",state);
                    component.set("v.callbackresult",'NONE');
                }
            }else if (state === "ERROR") {                
                var errors = response.getError();                
                if (errors) {
                    if (errors[0] && error[0].message) {    
                        component.set("v.callbackmessage",errors[0].message);
                    }
                } else {
                    component.set("v.callbackmessage",'Unhandled Exception occurred:\r\nContact Administrator');
                }
            }
        });        
        
        $A.enqueueAction(action);
    }
    
})