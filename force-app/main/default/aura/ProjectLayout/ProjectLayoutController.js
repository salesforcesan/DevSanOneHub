({
	doInit : function(component, event, helper) {
        component.set("v.projectId", component.get('v.recordId'));
	    helper.cGetProject(component);
	},
    saveProject : function(component, event, helper) {
    	component.find("editProject").get("e.recordSave").fire();
    },
    showSpinner : function (component, event, helper) {
        var spinner = component.find("spinnerid");
        if (spinner) {
            var evt = spinner.get("e.toggle");
            evt.setParams({ isVisible : true });
            evt.fire();
        }
    },
    hideSpinner : function (component, event, helper) {
        var spinner = component.find("spinnerid");
        if (spinner) {
            var evt = spinner.get("e.toggle");
            evt.setParams({ isVisible : false });
            evt.fire();
        }
    },

    onChangeProjectContext: function(component, event, helper){

    }
    ////// end of code //////
})