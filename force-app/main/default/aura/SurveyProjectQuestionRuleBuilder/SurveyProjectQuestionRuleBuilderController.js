({
    doInit : function(component, event, helper) {
        helper.init(component, event, helper);
    },
    closeModalDialog : function(component, event, helper) {       
        helper.fireCloseEvent(component, false, null);        
    },
    AddRule: function(component, event, helper)
    {
        helper.saveRule(component, event, helper);
    }        
})