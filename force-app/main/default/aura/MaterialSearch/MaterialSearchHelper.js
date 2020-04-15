({
  init: function(component) {
    var searchText = component.find("searchText").get("v.value");
    var action = component.get("c.GetMaterials");
    action.setParams({
      "searchText": searchText
    });
    var self = this;
    action.setCallback(self, function(result) {
      console.log(result.getReturnValue());
      component.set("v.materials", result.getReturnValue());
      $A.util.addClass(component.find("addMaterialSpinner"), "slds-hide");
    });
    $A.enqueueAction(action);
  },

  closeDialog: function(cmp) {
    var closeEvt = cmp.getEvent('closeDialogEvent');
    closeEvt.fire();
  }

})