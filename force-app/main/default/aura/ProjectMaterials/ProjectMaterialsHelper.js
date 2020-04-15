({
  _DIALOG_DEF: {
    'id': 'dlgAddMaterial',
    'component': 'c:MaterialSearch',
    'size': 'medium',
    'title': 'Add a Material'
  },

  refreshMaterialsList: function(component, event, projectId) {
    this.showSpinner(component);
    var action = component.get("c.GetProjectServiceMaterials");
    action.setParams({
      "projectId": projectId
    });

    var self = this;
    action.setCallback(self, function(response) {
      var materials = response.getReturnValue();
      component.set("v.materials", materials);
      this.hideSpinner(component);
      if (event) {
        var state = event.getParam("state");
        var message = event.getParam("message");
        var notification = component.find("projectMaterialNotification");
        if (state) {
          self.showToast(message, state.toLowerCase(), true, 5000);
        }
      }
      console.log(materials);
    });
    $A.enqueueAction(action);
  },

  showSpinner: function(component) {
    var spinner = component.find("projectMaterialSpinner");
    $A.util.removeClass(spinner, "slds-hide");
  },

  hideSpinner: function(component) {
    var spinner = component.find("projectMaterialSpinner");
    $A.util.addClass(spinner, "slds-hide");
  },

  showToast: function(message, type) {
    var toastEvent = $A.get("e.force:showToast");
    toastEvent.setParams({
      "message": message,
      "type": type
    });
    toastEvent.fire();
  },
  showModalDialog: function(cmp) {
    var dlg = cmp.find('modalDialog'),
      self = this,
      dialogDefinition = this._DIALOG_DEF;
    var args = {
      'dialogId': dialogDefinition.id,
      'projectId': cmp.get("v.projectId")
    }
    args['dialogId'] = dialogDefinition.id;

    $A.createComponent(dialogDefinition.component, args,
      function(child, status, errMsg) {
        if ('SUCCESS' === status) {
          dlg.set('v.title', dialogDefinition.title);
          dlg.set('v.size', dialogDefinition.size);
          dlg.set('v.brand', dialogDefinition.brand || '');
          dlg.set('v.body', child);
          dlg.show();
        } else if ('ERROR' === status) {
          self.showToast("Add a Service", errMsg, 'error');
        }
      });

  }
})