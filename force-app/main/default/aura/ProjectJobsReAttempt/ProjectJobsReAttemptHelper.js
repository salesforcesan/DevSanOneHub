({
	createAttempts : function (component, event, helper) {
		var jobIds = component.get("v.selectedJobIds");
        var selectedDate = component.get('v.day');        
        console.log(`firing event .. with JobIds=${jobIds},  SelectedDate=${selectedDate}`);
		var action = component.get("c.CreateJobAttempts");
		action.setParams({
			jobIdList : JSON.stringify(jobIds),			
			scheduledDate : JSON.stringify(selectedDate)
		});
        
		action.setCallback(this, function (response) {
			var state = response.getState();
            console.log('state=' + state);
			if (state === "SUCCESS") {
            var responseWrapper = response.getReturnValue();	
            console.log(responseWrapper);
            if (responseWrapper.State === "ERROR") {
					component.set("v.errormessage", responseWrapper.Message);
				} else {
                    this.notifyMessage(component,responseWrapper.Message,"success");
                    this.notifyJobsUpdate();                    
					var appEvent = $A.get("e.c:EventHideModal");
					appEvent.fire();
				}
			} else if (state === "INCOMPLETE") {
				console.log('do something here');
			} else if (state === "ERROR") {
				var errors = response.getError();                
                console.log('errors=' + errors[0]);
				if (errors) {
					if (errors[0] && errors[0].message) {
						component.set("v.errormessage", errors[0].message);
					}
				} else {
					component.set("v.errormessage", "Unhandled Exception occurred:\r\nContact Administrator");
				}
			}
		});
		$A.enqueueAction(action);                        
	},	
     notifyMessage: function(cmp, msg, msgType) {
    	var e = cmp.find('notification');
    	e.set('v.message', msg);
    	e.set('v.type', msgType);
    	e.set('v.visible', true);
  },
  notifyJobsUpdate: function(){
    	var appEvent = $A.get("e.c:EventJobsRefresh");                
		appEvent.fire();
	}   
})