({
    doInit: function(component, event, helper) {
        helper.init(component);
        helper.getNameSpace(component);      
        
    },
    close: function(component, event, helper) {
        helper.closeDialog(component);
    },    
    handleClick: function(component, event, helper) {
        
        var checkbox = event.target;
        
        var checked = checkbox.checked;
        var projectTypeData = checkbox.id.substring(11);
        var parray = projectTypeData.split('-');
        
        var navEvent = $A.get("e.force:createRecord");
        var ns = component.get("v.ns");
        var projectTypeField = ns + "ProjectType__c";
        
        console.log(projectTypeData);
        
        
        navEvent.setParams({ 
            "entityApiName": ns + "Project__c",
            'defaultFieldValues': {
      			"ProjectType__c": parray[0]
   			},
            'recordTypeId':component.get("v.recordtypes")[parray[1] + 'Planning']
        });
        navEvent.fire();
        helper.closeDialog(component);
        
        
        
        
        
    },
    
    
})