({
	getProjects: function(component) {
        // Get existing filters & transforms
        var spinner = component.find("projectCardsSpinner");
        $A.util.removeClass(spinner, "slds-hide");
        var formFilters = component.get("v.formFilters"),
            statusFilters = component.get("v.statusFilters"),
            action = component.get("c.getDashboardProjects"),
            self = this;
        
        if (!statusFilters) {
            statusFilters = {
            	projectStatusFilters: {
            		"My Projects": true   
            	}    
            }
        }
        
        if (formFilters) {
            formFilters = formFilters.projectFormFilters;
        }
        if (statusFilters) {
            statusFilters = JSON.stringify(statusFilters.projectStatusFilters);
        }
        
        action.setParams({
            "formFilters":formFilters,
            "statusFilters":statusFilters
        });
        action.setCallback(self, function(response) {            
            $A.util.addClass(spinner, "slds-hide");
            component.set("v.projects", response.getReturnValue()); 

            console.log("v.projects", response.getReturnValue());     
        });
        $A.enqueueAction(action);
     
	}    
})