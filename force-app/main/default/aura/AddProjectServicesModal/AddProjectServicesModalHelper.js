({
  init: function(component) {
    var projectId = component.get('v.projectId');
    var action = component.get("c.getAvailableServicesApex");
    //component.find("addServiceSpinner").show();
    action.setParams({
      "projectId": projectId
    });
    var self = this;
    action.setCallback(self, function(result) {
      debugger;
      console.log(result.getReturnValue());
      component.set("v.services", result.getReturnValue());
      //component.find("addServiceSpinner").hide();
      //$A.util.addClass(component.find("addProjectServicesSpinner"), "slds-hide");

    });
    $A.enqueueAction(action);

  },
  addService: function(component, event, helper) {
    var projectId = component.get("v.projectId");
    var serviceId = component.get("v.selectedServiceId");
    var action = component.get("c.addProjectService");
    var self = this;
    if (!serviceId) {
      return;
    }
    self.showSpinner(component);
    action.setParams({
      "projectId": projectId,
      "serviceId": serviceId
    });

    action.setCallback(this, function(response) {
      var result = JSON.parse(response.getReturnValue());
      if (result.State === "SUCCESS") {
          self.closeDialog(component);
          var navEvent = $A.get("e.force:navigateToURL");
          
          if(result.Data =='ERROR')  {
              navEvent.setParams({
                  "url": "/one/one.app#/sObject/" + projectId 
              }); 
              self.showToast(result.Message, 'error', 'sticky');
          }
          else{
              navEvent.setParams({
                  "url": "/one/one.app#/sObject/" + result.Data + "/view?slideDevName=instructions&v=" + Date.now()
              });
              self.showToast(result.Message, 'success');
          }
          navEvent.fire();
          
      } else {
        self.showToast(result.Message, 'error', 'sticky');
        var navEvent = $A.get("e.force:navigateToURL");
        navEvent.setParams({
          "url": "/one/one.app#/sObject/" + projectId 
        });
        navEvent.fire();          
      }
      self.hideSpinner(component);
    });
    $A.enqueueAction(action);
  },
  showToast: function(message, type, mode) {
    if (typeof mode === 'undefined') {
      mode = 'dismissible';
    }
    var toastEvent = $A.get("e.force:showToast");
    toastEvent.setParams({
      "message": message,
      "type": type,
      "mode": mode
    });
    toastEvent.fire();
  },
  hideSpinner: function(cmp) {
    cmp.find('addProjectServicesSpinner').hide();
  },

  showSpinner: function(cmp) {
    cmp.find('addProjectServicesSpinner').show();
  },

  closeDialog: function(cmp) {
    var closeEvt = cmp.getEvent('closeDialogEvent');
    closeEvt.fire();
  }
})