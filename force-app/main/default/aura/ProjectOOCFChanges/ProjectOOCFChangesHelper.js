({
    ReleaseOOCFChanges : function(component, event, helper) {
        // Good
        var action = component.get("c.ReleaseOOCFChangesApex");
        var projectId = component.get("v.projectId");
        var self = this;
        //self.showSpinner(component);
        action.setParams({
            "projectId": projectId
        });
        action.setCallback(this, function(response) {
            
            var state = response.getState();
            component.set("v.callbackresult",state);
            if (state === "SUCCESS") {
				self.hideSpinner(component);
                component.set("v.callbackmessage","Successfully submitted request to send fulfillment changes");

                var id = window.setTimeout(
                    $A.getCallback(function() {
                        window.clearTimeout(id);
                        var appEvent = $A.get("e.c:EventProjectRefresh");
                        appEvent.fire();
                        $A.get('e.force:refreshView').fire();
                    }), 1000
                );
                
            }
            else
            {
                self.hideSpinner(component);
                component.set("v.callbackmessage","Error submitting fulfillment changes");
            }
        
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
    
})