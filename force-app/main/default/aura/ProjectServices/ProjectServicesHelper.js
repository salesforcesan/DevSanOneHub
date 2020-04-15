({
  SERVICE_DIALOG: {
    'id': 'dlgAddServices',
    'component': 'c:AddProjectServicesModal',
    'size': 'medium',
    'title': 'Add a Service'
  },

  cGetProjectServices: function(component, event, helper) {
    this.showSpinner(component);
    var projectId = component.get("v.projectId");
    var action = component.get("c.GetProjectServices");
    action.setParams({ "projectId": projectId });

    var self = this;
    action.setCallback(self, function(result) {
      var services = result.getReturnValue();
      component.set("v.services", services);
      console.log(services, "Services");
      var maxServiceCount = component.get("v.maxServiceCount");
      if (services && services.length == maxServiceCount) {
        component.set("v.maxServicesReached", true);
      } else {
        component.set("v.maxServicesReached", false);
      }
      component.set("v.services", services);
      console.log(component.get("v.services"), "component.get('v.services')");
      //component.find('projectServicesSpinner').hide();
      this.hideSpinner(component);
      if (event) {
        var state = event.getParam("state");
        var message = event.getParam("message");
        var notification = component.find("projectServicesNotification");
        if (state) {
          self.showToast(state, message, state);
        }
      }
    });
    $A.enqueueAction(action);

  },
  changeRank: function(component, event, helper, direction) {
    this.showSpinner(component);
    var psId = event.currentTarget.id
    var projectId = component.get("v.projectId");
    var message;

    var action = component.get("c.setProjectServiceRankApex", []);
    action.setParams({
      "projectserviceid": psId,
      "projectid": projectId,
      "direction": direction

    });
    console.log(action);
    var self = this;
    action.setCallback(self, function(result) {
      this.hideSpinner(component);
      var state = result.getState();
      if (state === "SUCCESS") {
        message = "Sucessfully changed the service rank";
        var services = result.getReturnValue();
        component.set("v.services", services);
      } else {
        console.log(result.getError());
        var errors = result.getError();
        if (errors[0] && errors[0].message) // To show other type of exceptions
          message = errors[0].message;
        if (errors[0] && errors[0].pageErrors) // To show DML exceptions
          message = errors[0].pageErrors[0].message;
        self.showToast(message, 'error');
      }

    });
    $A.enqueueAction(action);



  },

  refreshServices: function(component, event, helper) {
    this.cGetProjectServices(component, event);
  },
  showSpinner: function(component) {
    var spinner = component.find("projectServicesSpinner");
    $A.util.removeClass(spinner, "slds-hide");
  },
  hideSpinner: function(component) {
    var spinner = component.find("projectServicesSpinner");
    $A.util.addClass(spinner, "slds-hide");
  },
  showToast: function(title, message, type) {
    var toastEvent = $A.get("e.force:showToast");
    toastEvent.setParams({
      "message": message,
      "type": type
    });
    toastEvent.fire();
  },

  showDialog: function(root, params) {
    var dlg = root.find('modalDialog'),
      self = this,
      args = params || {},
      dialogDefinition = this.SERVICE_DIALOG;
    args['dialogId'] = dialogDefinition.id;

    $A.createComponent(dialogDefinition.component, args,
      function(cmp, status, errMsg) {
        if ('SUCCESS' === status) {
          dlg.set('v.title', dialogDefinition.title);
          dlg.set('v.size', dialogDefinition.size);
          dlg.set('v.brand', dialogDefinition.brand || '');
          dlg.set('v.body', cmp);
          dlg.show();
        } else if ('ERROR' === status) {
          self.showToast("Add a Service", errMsg, 'error');
        }
      });
  }
})