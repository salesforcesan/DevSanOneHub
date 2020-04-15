({
	confirmModal : function(component, event, helper) {
        var project = component.get("v.project");
        var userevent = $A.get("e.c:EventConfirmModal");
        userevent.setParams({                 	                	
            "project": project
        });
        userevent.fire();
        console.log('confirm modal..');        
	}
})