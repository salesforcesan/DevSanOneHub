({
    /*To get TimelineWrapper custom object from apex controller*/
	getTimeline: function(component) {
        var spinner = component.find("projectAuditSpinner");
        $A.util.removeClass(spinner, "slds-hide");
        
        var action = component.get("c.GetTimelineObject");
        action.setParams({ "projectId": component.get("v.projectId") });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                component.set("v.timeline", response.getReturnValue());
                component.set("v.isLoaded", true);
                console.log("timeline loaded");
                console.log(response.getReturnValue(), "timeline response.getReturnValue()");
            }
            $A.util.addClass(spinner, "slds-hide");
        });
        $A.enqueueAction(action);
    }
})