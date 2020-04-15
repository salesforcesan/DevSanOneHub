({
    removeMaterialClick : function(component, event, helper) {        
        var projectServiceMaterial = component.get("v.projectServiceMaterial"); 
       	helper.openMessageBox(component, event);
      }, 

	onMessageBoxEvent: function(component, evt, helper) {
	    helper.handleMessageBoxEvent(component, evt);
    },    
    
})