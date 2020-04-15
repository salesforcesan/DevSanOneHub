({
	doInit : function(component, event, helper) {

        window.setTimeout(
            $A.getCallback(function() {
                if (component.get("v.uisecuritymessage") && component.get("v.uisecuritymessage").length > 0)                
                {
                    helper.handleUISecurityMessageChanges(component, event, helper);    
                }
                else if(component.get("v.oocfchanges") === true && component.get("v.oocfchangesrequest") === false)
                {
                    helper.checkforOOCFChanges(component, event, helper);       
                }
                else if(component.get("v.pendingchanges") === true && component.get("v.releasependingchangesrequest") === false)
                {
                    helper.checkforPendingChanges(component, event, helper);
                }
            }), 3000
        );                     
        
        
	},
    
    handlePendingProjectChanges : function(component, event, helper) { 
        component.set("v.openPendingChanges", true);
        component.set("v.projectId", event.getParam("projectId"));
    },
    handlePendingOOCFChanges : function(component, event, helper) { 
        component.set("v.openOOCFChanges", true);
        component.set("v.projectId", event.getParam("projectId"));
    },
    handlependingchangesValueChange : function(component, event, helper) { 
        helper.checkforPendingChanges(component, event, helper);        
        
    },
    handleoocfchangesValueChange : function(component, event, helper) { 
        helper.checkforOOCFChanges(component, event, helper);        
        
    },
    handleuisecuritymessageChange : function(component, event, helper) { 
        helper.handleUISecurityMessageChanges(component, event, helper);        
        
    },
    refreshProject: function(component,event,helper){
        window.location.reload();
    },
    
})