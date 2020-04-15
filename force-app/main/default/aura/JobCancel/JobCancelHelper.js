({
	cancelSelectedJobs : function (component,jobIds,value,comment) {		
		console.log('firing cancel job event =' + jobIds);
		console.log('Ids=' + jobIds + ', selReason=' + value  + ', Comment=' + comment);
		var action = component.get("c.CancelJobs");    
        console.log('stringfy=' + JSON.stringify(jobIds));
		action.setParams({
			jobIdList : JSON.stringify(jobIds),
			selReason : value,
			selComm : comment
		});		
        this.showSpinner(component);
		action.setCallback(this, function (response) {
			var state = response.getState();
			if (state === "SUCCESS") {
                var responseWrapper = JSON.parse(response.getReturnValue());
                console.log(responseWrapper);
				//var result = response.getReturnValue();
				if (responseWrapper.State === "ERROR") {
					component.set("v.errormessage", responseWrapper.Message);
				} else {
                     //this.notifyMessage(component,responseWrapper.Message,"success"); 
                     this.notifyJobsUpdate(responseWrapper.Message);                    
					 var appEvent = $A.get("e.c:EventHideModal");                    
                     appEvent.fire();
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
   showSpinner: function(cmp){
        var spinner = cmp.find("displaySpinner");
        $A.util.removeClass(spinner, "slds-hide"); 
    },
    hideSpinner: function(cmp){
        var spinner = cmp.find("displaySpinner");
        $A.util.addClass(spinner, "slds-hide"); 
    },
    notifyMessage: function(cmp, msg, msgType) {
    	var notify = cmp.find('notification1');
    	notify.set('v.message', msg);
    	notify.set('v.type', msgType);
    	notify.set('v.visible', true);
        //notify.show(msg,msgType,true);
  },
    notifyJobsUpdate: function(msg){
    	var appEvent = $A.get("e.c:EventJobsRefresh");
        appEvent.setParam("message",msg);
		appEvent.fire();
	}    
})