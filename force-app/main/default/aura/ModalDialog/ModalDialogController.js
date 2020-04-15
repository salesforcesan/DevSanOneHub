({
	 closeModalDialog : function(component, event, helper) {
        component.set('v.showDialog', false);
        helper.fireCloseEvent(component, false, null);
        
    },
    closeModalDialogYes: function(component, event, helper){
        component.set('v.showDialog', false);
        helper.fireCloseEvent(component, true, null);
        
    },
})