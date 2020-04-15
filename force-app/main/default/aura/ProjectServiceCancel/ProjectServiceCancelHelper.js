({
    cancel: function(cmp, evt) {
        cmp.getEvent('closeDialogEvent').fire();
    },
    submit: function(cmp, evt) {
        var values = {
            'id': cmp.get("v.projectServiceId"),
            'reason': cmp.find('serviceCancelReason').get('v.value'),
            'comment': cmp.find('comment').get('v.value')
        };
        if (!values.reason || values.reason === '--SELECT--') {
            this._notify(cmp, 'The reason is required.', 'error');
            return;
        }
        this.cancelService(cmp, evt, values);
    },
    cancelService: function(cmp, evt, values) {
        var spinner = cmp.find("displaySpinner");
        $A.util.removeClass(spinner, "slds-hide"); 
        var action = cmp.get("c.CancelProjectService");
        action.setParams({            
            "psId" : values.id,
            "reason" : values.reason,
            "comment" : values.comment
        });
        var self = this;
        action.setCallback(this,function(response){
            var responseWrapper = JSON.parse(response.getReturnValue());
            self.showToast(responseWrapper.Message, responseWrapper.State);
            if(responseWrapper.State.toLowerCase() === "success" || response.getState().toLowerCase() === "success"){
                var navEvent = $A.get("e.force:navigateToURL");
                navEvent.setParams({
                    "url": "/one/one.app#/sObject/"+ cmp.get("v.projectId") + "/view?slideDevName=services&v=" + Date.now()
                });    
                navEvent.fire();
                self.cancel(cmp,evt);
            }
            $A.util.addClass(spinner, "slds-hide"); 
        });
        $A.enqueueAction(action); 
    },
	_notify: function(cmp, msg, type) {
        cmp.find('notification').show(msg, type);
    },
    showToast : function(message, type, mode) {
        debugger;
        if(typeof mode === 'undefined'){
            mode = 'dismissible';
        }
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "message": message,
            "type":type,
            "mode": mode
        });
        toastEvent.fire();
    }
})