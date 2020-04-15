({
	 doInit: function(component, event, helper) {
		var opportunityId = component.get("v.recordId");
        if(!opportunityId){
            return;
        }
		var action = component.get("c.getOpportunityProjectConfirmationInfo");
        $A.util.removeClass(component.find("spinner"), "slds-hide");
        action.setParams({ 
            "opportunityId": opportunityId
        });
        var self = this;
        action.setCallback(this,function(response){   
            var result = JSON.parse(response.getReturnValue());
            if(result.State  === "SUCCESS"){
                if(result.Message != ''){
                	component.find('notificationInfo').show(result.Message, 'warning', false);    
                }
                component.set('v.modalBody', result.Data);
                component.set('v.disabled', false);
            }
            else{
                component.find('notificationError').show(result.Message, 'error', false);
                //self.showToast(result.Message, 'error');
            }
            	
            $A.util.addClass(component.find("spinner"), "slds-hide");
        });
        $A.enqueueAction(action);

	},
    createProject : function(component, event, helper) {
		var opportunityId = component.get("v.recordId");
        if(!opportunityId){
            return;
        }
		var action = component.get("c.createProjectFromOpportunity");
        $A.util.removeClass(component.find("spinner"), "slds-hide");
        action.setParams({ 
            "opportunityId": opportunityId
        });
        var self = this;
        action.setCallback(this,function(response){   
            var result = JSON.parse(response.getReturnValue());
            if(result.State  === "SUCCESS"){
                self.showToast(result.Message, 'success');
                var navEvt = $A.get("e.force:navigateToSObject");
                navEvt.setParams({
                  "recordId": result.Data
                });
                navEvt.fire();
            }
            else {
                //self.showToast(result.Message,'error', 'sticky');
                component.find('notificationError').show(result.Message, 'error', false);
            }
            $A.util.addClass(component.find("spinner"), "slds-hide");
        });
        $A.enqueueAction(action);

	},
    showToast : function(message, type, mode) {
        debugger;
        if(typeof mode === 'undefined'){
            mode = 'dismissible';
        }
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "message": message,
            "type":type,
            "mode": mode
        });
    	toastEvent.fire();
	}
})