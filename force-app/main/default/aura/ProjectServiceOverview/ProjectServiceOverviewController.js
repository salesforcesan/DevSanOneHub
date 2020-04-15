({
    doInit : function(component, event, helper) {
        /*var psID = component.get("v.serviceId");
        console.log('PSOverView   -   psid' + psID);
        var action = component.get("c.GetProjectService");
        action.setParams({
            "recordId": psID
        });
      
        action.setCallback(this,function(response){   
            console.log(response.getReturnValue());            
            component.set("v.service",response.getReturnValue());  
      	});
        $A.enqueueAction(action);*/
        
        var psID = component.get("v.serviceId");
        console.log('ps overview   -   psid -- ' + psID);
        helper.LoadMethod(component, psID);  
        
    }
})