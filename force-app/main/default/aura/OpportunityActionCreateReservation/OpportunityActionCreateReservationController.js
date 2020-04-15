({
    
	doInit : function(component, event, helper) {
       // sankar commented
      // component.set("v.callbackresult","NONE");
       helper.onInit(component, event, helper); 
        
	},
    
    createReservationButtonClicked: function(component, event, helper) {        
		helper.CreateReservation(component, event, helper);
    },
    cancel: function(component, event, helper) {
        $A.get("e.force:closeQuickAction").fire();
    }
    
})