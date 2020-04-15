({
	getCerts: function(component,psID) {

        var spinner = component.find("Spinner"),
            action = component.get("c.GetPSCertifications");

        $A.util.removeClass(spinner, "slds-hide");
        
        action.setParams({
            "projectServiceId": psID
        });
        action.setCallback(this,function(response){              
            component.set("v.returnData",response.getReturnValue());
            $A.util.addClass(spinner, "slds-hide");  
      	});
        $A.enqueueAction(action);
	},
    getNameSpace: function(component) {

        var action = component.get("c.getNamespaceApex"),
            self = this;

        action.setCallback(self, function(result) {
            component.set("v.ns", result.getReturnValue());            
        });
        $A.enqueueAction(action);
    },
    deleteCert: function(component, event, helper) {
        
        var certID = component.get("v.certId"),
            psID = component.get("v.serviceId"),
            spinner = component.find("Spinner"),
            action = component.get("c.DeletePSCertifications"),
            state,
            errors,
            message;

        $A.util.removeClass(spinner, "slds-hide");

        action.setParams({
            "pscID" : certID,
            "psID" : psID           
        });
        action.setCallback(this, function(response) {
            state = response.getState();
            if (state === "SUCCESS") {
                component.set("v.returnData",response.getReturnValue());
                message = 'Successfully removed the certification from the project';
                this.showToast(message, 'success');
            }
            else if (state === "ERROR") {
                errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        // console.log("Error message: " + errors[0].message);
                    }
                } else {
                    // console.log("Unknown error");
                }
            }
            $A.util.addClass(spinner, "slds-hide");
        });
         
        $A.enqueueAction(action); 
    },
    openMessageBoxDeleteCert : function(component) {

        var prompt = component.find("messageBox");
        prompt && prompt.show({
            id: "deleteCert",
            title: "Delete Certification",
            body: "<p>Are you sure that you want to remove the certification?</p>",
            positiveLabel: "Remove Certification",
            negativeLabel: "Cancel",
            severity: "error"
        });
    },
    AddCert : function(component, psID, SelectedVal) {

        var spinner = component.find("Spinner"),
            action = component.get("c.SavePSCertifications"),
            state,
            message,
            errors; 

        $A.util.removeClass(spinner, "slds-hide");

        action.setParams({
            "projectServiceId": psID,
            "cert": SelectedVal
        });
        action.setCallback(this, function(response) {
            state = response.getState();
            if (state === "SUCCESS") {
                component.set("v.returnData",response.getReturnValue());
                message = 'Successfully added a certification to the project';
                this.showToast(message, 'success');
            }
            else if (state === "ERROR") {
                errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        // console.log("Error message: " + errors[0].message);
                    }
                } else {
                    // console.log("Unknown error");
                }
            }
            $A.util.addClass(spinner, "slds-hide");
        });
        $A.enqueueAction(action);
    },
    showToast: function(message, type) {

        var toastEvent = $A.get("e.force:showToast");

        toastEvent.setParams({
            "message": message,
            "type": type
        });
        toastEvent.fire();
    }
})