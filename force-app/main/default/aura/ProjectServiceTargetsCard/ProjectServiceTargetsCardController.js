({	
    doInit : function(component, event, helper) {
       // component.set("v.securityelements", "ProjectTarget__c.Delete");
        helper.initSecurity(component,event,helper);
    },
    
    onMessageBoxEvent: function(component, evt, helper) {
	    helper.handleMessageBoxEvent(component, evt);
    },
        
   removeTargetClick : function(component, event, helper) { 
		event.stopPropagation();       
        helper.openMessageBox(component, event);
        var projectServiceTarget = component.get("v.projectServiceTarget"); 
       
       
    },
    
    navToTarget: function(cmp, e, h) {
        var recId = e.currentTarget.id;
        var navEvt = $A.get("e.force:navigateToSObject");
        navEvt.setParams({
          "recordId": recId,
          "slideDevName": "details"
        });
        navEvt.fire();
    }
    
    
})