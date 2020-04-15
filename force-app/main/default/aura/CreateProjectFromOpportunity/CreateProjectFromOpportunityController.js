({
	doInit : function(component, event, helper) {
        helper.doInit(component, event, helper);   
    },
    createProject: function(component, event, helper) {
        helper.createProject(component, event, helper);
    },
    cancel: function(component, event, helper) {
        $A.get("e.force:closeQuickAction").fire();
    }
})