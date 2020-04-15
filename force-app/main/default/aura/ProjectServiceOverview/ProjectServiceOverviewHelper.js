({
	LoadMethod : function(component,psID) {
        var spinner = component.find("Spinner"); 
        $A.util.removeClass(spinner, "slds-hide");
		var psID = component.get("v.serviceId");
        console.log('PSOverView   -   psid' + psID);
        var action = component.get("c.GetProjectService");
        action.setParams({
            "projServiceId": psID
        });
      
        action.setCallback(this,function(response){   
            console.log(response.getReturnValue());            
            component.set("v.service",response.getReturnValue());  
            //this._notify(component, response.getReturnValue().message, response.getReturnValue().isSuccess==true ?'success':'error',true);
            $A.util.addClass(spinner, "slds-hide");
      	});
        $A.enqueueAction(action);
	},
    _notify: function(cmp, msg, type, autoHide, duration) {
        cmp.find('notification').show(msg, type, autoHide, duration);
    }
})