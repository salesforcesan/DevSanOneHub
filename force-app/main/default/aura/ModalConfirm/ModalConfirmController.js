({
	fireConfirmEvent : function(component, event, helper) {
		var appEvent = $A.get("e.c:EventConfirm"),
            confirmEventKey = component.get("v.confirmEventKey");
    	appEvent.setParams({ 
        	"confirmEventKey" : confirmEventKey
    	});
    	appEvent.fire();
        var appEvent = $A.get("e.c:EventHideModal");
    	appEvent.fire();
	}
})