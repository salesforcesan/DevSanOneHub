({
   
    init: function(component) {
        var action = component.get("c.getProjectTypesApex");
        
        var self = this;
        self.getProjectTypes(component);
        self.getRecordTypes(component);
        
    },
    getProjectTypes: function(component) {
        
        var action = component.get("c.getProjectTypesApex");
        
        var self = this;
        action.setCallback(self, function(result) {
            
            console.log(result.getReturnValue());
            var projecttypes = JSON.parse(result.getReturnValue());
            
            component.set("v.projecttypes", projecttypes);
        });
        $A.enqueueAction(action);
      
    },
    getRecordTypes: function(component) {
        
        var action = component.get("c.getProjectRecordTypesApex");
        
        var self = this;
        action.setCallback(self, function(result) {
            
            console.log(result.getReturnValue());
            var recordtypes = JSON.parse(result.getReturnValue());
            
            component.set("v.recordtypes", recordtypes);
        });
        $A.enqueueAction(action);
      
    },
    getNameSpace: function(cmp) {
        var action = cmp.get("c.getNamespaceApex");
        var self = this;
        action.setCallback(self, function(result) {
            cmp.set("v.ns", result.getReturnValue());            
        });
        $A.enqueueAction(action);
    },
  	closeDialog: function(cmp) {
    	var closeEvt = cmp.getEvent('closeDialogEvent');
    	closeEvt.fire();
  	},
    
    
    
    
})