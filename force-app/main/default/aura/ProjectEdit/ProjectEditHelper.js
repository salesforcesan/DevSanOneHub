({
	init : function(component) {
        component.set("v.securityelements", "Project__c.Name,Project__c.StartDate__c,Project__c.EndDate__c,Project__c.ProjectLaunchDate__c,Project__c.ProjectInstructions__c");
        var projectId = component.get("v.projectId");
		var action = component.get("c.GetProject");
  		action.setParams({"recordId":projectId});
        var self = this;
        action.setCallback(self, function(result) {
            var state = result.getState();    
            debugger;
            if(state==="SUCCESS"){            
            	var project = result.getReturnValue();
            	component.set("v.project", project);
                $A.util.addClass(component.find("editProjectSpinner"), "slds-hide");
            }
        });
        $A.enqueueAction(action);

	},
    saveProject : function(component, event, helper) {
        $A.util.removeClass(component.find("editProjectSpinner"), "slds-hide");
		var project = JSON.stringify(component.get("v.project"));  
        var action = component.get("c.saveNonPlanningProject");
        action.setParams({"serilizedProject": project});
        var self = this;
        //alert(project);
        action.setCallback(self, function(result) {
            var responseWrapper = JSON.parse(result.getReturnValue());
            this.showToast(responseWrapper.Message, responseWrapper.State);
            if (responseWrapper.State === "SUCCESS") {
                if(responseWrapper.Data.ApexJobName != ""){
                    window.location.reload();
                }
                var userevent = $A.get("e.c:EventHideModal");
                userevent.fire();
                var appEvent = $A.get("e.c:EventProjectRefresh");
                appEvent.setParams({"project":responseWrapper.Data});
                appEvent.setParams({"origin":"edit_project_modal"});
                
                appEvent.fire();
            }
            $A.util.addClass(component.find("editProjectSpinner"), "slds-hide");
        });
        $A.enqueueAction(action);
	},
    showToast : function(message, type) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "message": message,
            "type":type
        });
    	toastEvent.fire();
	}
})