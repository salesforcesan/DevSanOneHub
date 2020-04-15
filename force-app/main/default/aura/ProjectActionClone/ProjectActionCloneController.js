({
	doInit : function(component, event, helper) {        
        component.set("v.callbackresult","NONE");     
		//helper.ApexQueueSize(component);
	},
    cloneButtonClicked : function(component, event, helper) { 
        helper.CloneProject(component, event, helper);
    },
    cancelButtonClicked : function(component, event, helper) { 
        helper.CancelClicked(component, event, helper);
    },
    
})