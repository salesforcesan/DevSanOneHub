({
   doInit: function(component, event, helper) {   
       // Get filtered projects
       helper.getProjects(component);
   },
    
   applyFilter: function(cmp, event, helper) {
       // Get the current filters
       // Publish the changed filters  
       var appEvent = $A.get("e.c:ProjectFormFiltersChanged");
       var filter = cmp.get("v.filters");
       console.log(cmp.get("v.filters"));
       appEvent.setParams({ "projectFormFilters" : JSON.stringify(filter) });           
       appEvent.fire();
    },
   changeFilter: function(cmp, event, helper) {
       // Get the current filters
       var filters = cmp.get("v.filters");
       if (!filters) { filters = {}; }
       
       // Change this filter property in the filter object
       if (event.target.type == "checkbox") {
           // Handle checkboxes
          filters[event.target.id] = event.target.checked; 
       } else {
          filters[event.target.id] = event.target.value;
       }
       
       // Save the changed filters 
       cmp.set("v.filters", filters);
      
       // Publish the changed filters  
	   var appEvent = $A.get("e.c:ProjectFormFiltersChanged");
       appEvent.setParams({ "projectFormFilters" : JSON.stringify(filters) });
       appEvent.fire();
    }, 
    clearFilters : function(cmp, event, helper) {
        helper.clearFilters(cmp, event, helper);
    },
  	handleClick : function(component, event, helper) {
        // todo: delete this test code
        helper.filterTheProjects(component);
    }
})