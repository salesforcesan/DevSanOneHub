({
     doInit : function(component, event, helper) {
      
        
    },
      onCheck : function(component, event, helper) {
        var status = component.get("v.account.Selected");
        if(status === true)
        {
            component.set("v.account.Selected", false);            
        }
        else
        {
            component.set("v.account.Selected", true);            
        }
    }
  
})