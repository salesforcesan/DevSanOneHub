({
    doInit: function(component,event,helper){
        
    },
	
    togglePreview : function(component, event, helper) {
        
        $A.util.toggleClass(component.find("panel"), "drawer-hide");   
        helper.updatePreview(component, event, helper);
    }
})