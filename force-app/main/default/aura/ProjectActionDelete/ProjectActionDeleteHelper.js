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
    DeleteProject : function(component, event, helper) {
        var action = component.get("c.DeleteProjects");
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
    
})