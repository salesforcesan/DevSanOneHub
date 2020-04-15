({
    LoadMethod : function(component,psID) {
        var action = component.get("c.GetProjectService");
        action.setParams({
            "projServiceId": psID
        });
        
        action.setCallback(this,function(response){  
            console.log('~~~ rtn val ~~~');            
            console.log(response.getReturnValue());     
            console.log("~~response.getReturnValue().isSuccess~~",response.getReturnValue().isSuccess+"~~~~",response.getReturnValue().message);  
            component.set("v.service",response.getReturnValue());              
            console.log('~~~ done ~~~');    
        });
        $A.enqueueAction(action);                      
    
    }
})