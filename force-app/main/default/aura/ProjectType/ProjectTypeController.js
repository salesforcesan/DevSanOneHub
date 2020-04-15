({	
    setSelected: function(component, event, helper){                 
        console.log('getting selected value');
        helper.pSelected(component);
    },
    fireSelectedEvent : function(component, event) {        
        console.log('event fired');
        var projectType = component.get("v.ptype");
        console.log('fireSelectedEvent method=' + projectType.Name);
        var cmpEvent = component.getEvent('cmpEvent');
        
        cmpEvent.setParams({
            "selectedProjectTypeId":projectType.Name
        });
        cmpEvent.fire();
    },
})