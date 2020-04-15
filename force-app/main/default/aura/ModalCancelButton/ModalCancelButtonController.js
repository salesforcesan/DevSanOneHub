({
	hideModal : function(component, event, helper) {
		var appEvent = $A.get("e.c:EventHideModal");
    	appEvent.fire();
	}
})