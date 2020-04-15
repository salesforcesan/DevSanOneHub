({
    onInit: function(component, evt, h){
        h.init(component);
      
    },

    onMessageBoxEvent: function(component, evt, helper) {
        helper.handleMessageBoxEvent(component, evt);

    },

    goToProjectAccountOverview: function(component, event, helper) {
        helper.goToProjectAccount(component, event, helper, "tools");
    },

    removeAccountClick: function(component, event, helper) {
        helper.openMessageBox(component, event, helper);
    },
    gotoDetail: function(cmp, evt, helper) {
        helper.gotoDetail(cmp, evt);
    },

    makePrimaryClick: function(cmp, evt, helper) {
        helper.makePrimaryAccount(cmp, evt);
    }
})