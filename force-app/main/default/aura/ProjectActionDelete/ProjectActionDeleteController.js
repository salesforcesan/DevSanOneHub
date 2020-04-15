({
	doInit : function(component, event, helper) {        
        component.set("v.callbackresult","NONE");     

	},
    deleteButtonClicked : function(component, event, helper) { 
        helper.DeleteProject(component, event, helper);
    },
    cancelButtonClicked : function(component, event, helper) { 
        helper.CancelClicked(component, event, helper);
    },
    
})