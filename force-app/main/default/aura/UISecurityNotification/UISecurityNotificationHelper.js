({
    showPendingNotification: function (component)
    {
        component.find("warningNotification").show('There are pending changes to be released','info');
        component.set("v.isPendingchanges",true);
     },
    showOOCFNotification: function (component)
    {
        component.find("warningNotification").show('There are pending out of cycle Fulfillment changes','info');
        component.set("v.isOOCFChanges",true);
     },
  
    showSecurityMessageNotification: function (component)
    {
        var message = component.get("v.uisecuritymessage");
        component.find("warningNotification").show(message,'warning');
    },    
    checkforPendingChanges : function (component, event, helper)
    {
      if (component.get("v.pendingchanges") === true && component.get("v.releasependingchangesrequest") === false)
      {
            window.setTimeout(
                $A.getCallback(function() {
                    helper.showPendingNotification(component);
                }), 1000
            );                     
      }
    },
    checkforOOCFChanges : function (component, event, helper)
    {
        
       if (component.get("v.oocfchanges") === true && component.get("v.oocfchangesrequest") === false)
       {
            window.setTimeout(
                $A.getCallback(function() {
                    helper.showOOCFNotification(component);
                }), 1000
            );                     
       }
        
    },
    handleUISecurityMessageChanges : function (component, event, helper)
    {
        
        if (component.get("v.uisecuritymessage") && 
            component.get("v.uisecuritymessage").length > 0)
        {
            window.setTimeout(
                $A.getCallback(function() {
                    helper.showSecurityMessageNotification(component);
                }), 500
            );                     
        }
        
    },
    
    
    
})