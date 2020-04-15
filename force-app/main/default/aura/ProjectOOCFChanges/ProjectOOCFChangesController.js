({
    doInit : function(component, event, helper) {        
        component.set("v.callbackresult","NONE");    
        
    },
    openModal: function(component, event, helper) {
        // for Display Model,set the "isOpen" attribute to "true"
        component.set("v.isOpen", true);
    },
    
    closeModal: function(component, event, helper) {
        // for Hide/Close Model,set the "isOpen" attribute to "Fasle"  
        component.set("v.isOpen", false);
    },
    
    releaseChanges: function(component, event, helper) {
		helper.ReleaseOOCFChanges(component, event, helper);    
    
    },    
    
})