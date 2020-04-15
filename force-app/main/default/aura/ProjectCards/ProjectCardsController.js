({
	doInit: function(cmp, event, helper) { 
        helper.getProjects(cmp);
	},
    update: function (component, event, helper) {
        // Get the new location token from the event if needed
        //var loc = event.getParam("token");
        if (component) {
            helper.getProjects(component);
        	//$A.get('e.force:refreshView').fire(); 
        }
	},
    handleProjectFormFiltersChanged: function(cmp, event, helper) { 
        var filters = cmp.get("v.formFilters");
        if (!filters) { filters = {}; }
        filters.projectFormFilters = event.getParam("projectFormFilters");
        cmp.set("v.formFilters", filters); 
        helper.getProjects(cmp);		        
    },
    handleProjectStatusFiltersChanged: function(cmp, event, helper) {
		var filters = cmp.get("v.statusFilters");
        if (!filters) { filters = {}; }
        filters.projectStatusFilters = event.getParam("projectStatusFilters");
        cmp.set("v.statusFilters", filters);
        helper.getProjects(cmp);     
    }   
})