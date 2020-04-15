({
    
    onCheck : function(component, event, helper) {
        console.log('onCheck');
        var status = component.get("v.material.Selected");
        console.log('status', status);
        if(status === "true")
        {
            component.set("v.material.Selected", "false");            
        }
        else
        {
            component.set("v.material.Selected", "true");            
        }
    }
})