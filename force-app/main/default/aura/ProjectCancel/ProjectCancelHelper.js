({
    loadProjectDetails : function(cmp){                
        var action = cmp.get("c.GetProjectCancelReasons");
        var inputsel = cmp.find("projectCancelReason");      
        var opts = [];   
        this.showSpinner(cmp);
        action.setCallback(this, function(a) {
            for(var i=0;i< a.getReturnValue().length;i++){
                opts.push({"class": "optionClass", label: a.getReturnValue()[i], value: a.getReturnValue()[i]});
            }
            inputsel.set("v.options", opts);   
            this.hideSpinner(cmp);
        });
        $A.enqueueAction(action);                
    },    
	cancelSelectedProject : function (component, event, helper) {
		var project = component.get("v.project");
		var comment = component.find("cancelReasonComment").get("v.value");		
		var action = component.get("c.CancelProject");
        
		action.setParams({
			projectId : project.Id,
			selReason : project.CancelReason,
			selComm : comment
		});
        this.showSpinner(component);
		action.setCallback(this, function (response) {
			var state = response.getState();                        
			if (state === "SUCCESS") {
                var responseWrapper = JSON.parse(response.getReturnValue());                                          
				var result = response.getReturnValue();
				if (responseWrapper.State === 'ERROR') {
					component.set("v.errormessage", responseWrapper.Message);
				} else {
                    helper.notifyMessage(component,responseWrapper.Message,"success");
					var appEvent = $A.get("e.c:EventHideModal");
					appEvent.fire();
                    window.location.reload();
					//helper.gotoProjectDashboard();
				}
			} else if (state === "INCOMPLETE") {
				console.log('do something here');
			} else if (state === "ERROR") {
				var errors = response.getError();                
				if (errors) {
					if (errors[0] && error[0].message) {
						component.set("v.errormessage", errors[0].message);
					}
				} else {
					component.set("v.errormessage", "Unhandled Exception occurred:\r\nContact Administrator");
				}
			}
			this.hideSpinner(component);
		});
		$A.enqueueAction(action);
	},
	gotoProjectDashboard : function () {
		var evt = $A.get("e.force:navigateToComponent");
		evt.setParams({
			componentDef : "c:ProjectDashboardLayout",
			componentAttributes : {}
		});
		evt.fire();
	},
   showSpinner: function(cmp){
        var spinner = cmp.find("displaySpinner");
        $A.util.removeClass(spinner, "slds-hide"); 
    },
    hideSpinner: function(cmp){
        var spinner = cmp.find("displaySpinner");
        $A.util.addClass(spinner, "slds-hide"); 
    },
    notifyMessage: function(cmp, msg, msgType) {
    var e = cmp.find('notification');
    e.set('v.message', msg);
    e.set('v.type', msgType);
    e.set('v.visible', true);
  },
})