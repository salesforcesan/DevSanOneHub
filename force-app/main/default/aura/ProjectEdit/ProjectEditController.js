({
	doInit : function(component, event, helper) {
        helper.init(component);
	},
    close : function(component, event, helper) {  
        var userevent = $A.get("e.c:EventHideModal");
        userevent.fire();
	},
    saveProject: function(component, event, helper) {
        helper.saveProject(component, event, helper);
    }
})