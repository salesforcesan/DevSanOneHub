({
	doInit : function(component, event, helper) {        
        component.set("v.callbackresult","NONE");     
        helper.init(component);

	},
    deleteButtonClicked : function(component, event, helper) { 
        helper.DeleteService(component, event, helper);
    }
    
})