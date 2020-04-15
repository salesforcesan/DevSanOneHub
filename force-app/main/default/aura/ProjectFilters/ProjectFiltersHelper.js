({
    // Get filtered projects from Apex controller
    getProjects: function(component) {
        var action = component.get("c.getDashboardProjects", []);
        var self = this;
        action.setCallback(self, function(result) {
            //console.log(result.getReturnValue());
            component.set("v.projects", result.getReturnValue());            
        });
        $A.enqueueAction(action);
        var filter = {Name:"",OwnerName__c:"",ProjectNumber__c:"",StartDate:"",EndDate:""};
        component.set("v.filters",filter);
    },
    
     clearFilters : function(cmp, event, helper) {
		var filters = cmp.get("v.filters");
        filters = {
           StartDate: "",
           EndDate: "",
           Name: "",
           ProjectNumber__c: "",
           OwnerName__c: ""
       }
       	cmp.set("v.filters", filters);
         console.log(cmp.get("v.filters"));
       var appEvent = $A.get("e.c:ProjectFormFiltersChanged");
       appEvent.setParams({ "projectFormFilters" : JSON.stringify(filters) });
       appEvent.fire();
        
        
    }
    /*,   
  filterTheProjects: function(component) {
 
    var action = component.get("c.filterTheProjects", []);      
    var pname = component.find("pName").get("v.value");
    var pNumber = component.find("pNumber").get("v.value");  
      
    var mapParam= {};
    mapParam['Title']=pname;    
    //mapParam['Number']=pNumber;
      
    action.setParams({
            "filterMap":mapParam
        });

    var self = this;
    action.setCallback(self, function(result) {
        //console.log(result.getReturnValue());
        component.set("v.projects", result.getReturnValue());            
    });
    $A.enqueueAction(action);  
  }  */ 
})