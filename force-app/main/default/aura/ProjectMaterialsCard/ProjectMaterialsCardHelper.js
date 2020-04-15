({
    removeMaterial : function(component, event, helper) { 
        var spinner = component.find("projectMaterialCardSpinner")
        $A.util.removeClass(spinner, "slds-hide");
        var projectServiceMaterial = component.get("v.projectServiceMaterial");
        var action = component.get("c.RemoveMaterialFromService");           
        console.log(projectServiceMaterial.ProjectServiceMaterialId);    
        action.setParams({            
            "projectServiceMaterialID" : projectServiceMaterial.ProjectServiceMaterialId
        });    
        
        action.setCallback(this,function(response){   
            var results = JSON.parse(response.getReturnValue());               
            console.log(results);    
            var appEvent = $A.get("e.c:ProjectMaterialChange"); 
            appEvent.setParams({ "state" : results.State });
            appEvent.setParams({ "message" : results.Message });
            console.log(appEvent);    
            appEvent.fire();
        });
        $A.enqueueAction(action);        
    },
    
    handleMessageBoxEvent: function(component, evt) {
        var result = {
            id: evt.getParam('id'),
            value: evt.getParam('context')
        };
        if (result.id === 'removeMaterial' && result.value == 1) {
            this.removeMaterial(component);
        }
    },
    
    openMessageBox : function(component, event) {
        var prompt = component.find('messageBox');
        prompt && prompt.show({
            id: 'removeMaterial',
            title: 'Remove Material',
            body: '<p>Are you sure that you want to remove the material?</p>',
            positiveLabel: 'Remove Material',
            negativeLabel: 'Cancel',
            severity: 'error'
        });
    },
})