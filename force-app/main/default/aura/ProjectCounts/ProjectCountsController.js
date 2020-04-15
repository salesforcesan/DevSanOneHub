({
    doInit: function(cmp, event, helper) { 
        // Set filter default
        var filters = {};
        filters["My Projects"] = true;
        cmp.set("v.filters", filters);
        helper.getProjectStatuses(cmp);
        helper.getNameSpace(cmp);
        var statuses = cmp.get("v.statuses");  
    },
    update: function (component, event, helper) {
        // Get the new location token from the event if needed
        //var loc = event.getParam("token");
        if (component) {
            helper.getProjectStatuses(component);
        	//$A.get('e.force:refreshView').fire(); 
        }
	},
    toggleFilter: function(cmp, event, helper) {
        // Get the current filters
        var filters = {},
            thisFilter;
        
        // Set selected element
        thisFilter = event.currentTarget;
        helper.clearSelections();
        thisFilter.className += " psbar-button_on";
        
        // Toggle the filter in the filters object
        if (filters[thisFilter.id]) {
            filters[thisFilter.id] = false;
        } else {
            filters[thisFilter.id] = true;
        }
        
        cmp.set("v.filters", filters);
        
        // Publish the filters     
		var appEvent = $A.get("e.c:ProjectStatusFiltersChanged");
        appEvent.setParams({ "projectStatusFilters" : cmp.get("v.filters") });
        appEvent.fire();
    },
    createNewProject: function(cmp, event, helper) {        
        //helper.toggleClass(cmp,'projecttypedlg','slds-backdrop--');
        var navEvent = $A.get("e.force:createRecord");
        var ns = cmp.get("v.ns");
        //console.log(navEvent, 'navEvent');
        navEvent.setParams({ 
            "entityApiName": ns + "Project__c"
        });
        navEvent.fire();
    },
    showSelectProjectTypeModal: function(component, event, helper) {
        
        helper.showSelectProjectTypeModal(component);
    	return;
    },    
    
})