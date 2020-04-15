({
    doInit : function(cmp, event, helper) {
        var spinner = cmp.find("displaySpinner");
        var action = cmp.get("c.GetServiceCancelReasons");
        var opts = [];      
        var reasonDropdown = cmp.find("serviceCancelReason");
        action.setCallback(this, function(a) {
            for(var i=0;i< a.getReturnValue().length;i++){
                opts.push({"class": "optionClass", label: a.getReturnValue()[i], value: a.getReturnValue()[i]});
            }
            reasonDropdown.set("v.options", opts);
            $A.util.addClass(spinner, "slds-hide"); 
        });
        $A.enqueueAction(action);      
    },
    onCancel: function(cmp, evt, helper) {
        helper.cancel(cmp, evt);
    },
    
    onSubmit: function(cmp, evt, helper) {
        helper.submit(cmp, evt);
    }
})