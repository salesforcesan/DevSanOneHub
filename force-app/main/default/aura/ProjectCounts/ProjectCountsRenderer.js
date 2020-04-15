({
     rerender: function (component, helper) {
        this.superRerender();
        var showButtonNow = component.find('newProject');
        $A.util.addClass(showButtonNow, 'slds-show');
     }
})