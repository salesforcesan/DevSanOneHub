({
  doInit: function(component, event, helper) {
    helper.init(component);
    var serviceSelector = component.find("serviceSelector");
    var projectId = component.get("v.projectId");
    console.log(projectId);
    var action = component.get("c.GetProjectServiceOptions");
    action.setParams({
      "projectId": projectId
    });

    action.setCallback(this, function(response) {
      var servicesResults = response.getReturnValue();
      var opts = [];
      console.log("material:results" + servicesResults);
      servicesResults.forEach(function(element) {
        console.log("material" + element);
        opts.push({ class: "optionClass", label: element.split('\:')[1], value: element.split('\:')[0] });
      });
      serviceSelector.set("v.options", opts);

    });
    $A.enqueueAction(action);
  },

  close: function(component, event, helper) {
    helper.closeDialog(component);
  },

  addMaterials: function(component, event, helper) {

    if (!component.find("quantity").get("v.value")) {

      var toastEvent = $A.get("e.force:showToast");
      toastEvent.setParams({
        "message": 'Please Add A Quantity to Continue',
        "type": 'error'
      });
      toastEvent.fire();
      return;
    }

    var selectedMaterialId = component.get("v.selectedMaterialId");
    var projectserviceId = component.find("serviceSelector").get("v.value");
    var quantity = component.find("quantity").get("v.value");
    var shipTo = component.find("shipTo").get("v.value");
    var useType = component.find("useType").get("v.value");
    var action = component.get("c.AddMaterials");
    action.setParams({
      "materialId": selectedMaterialId,
      "projectserviceId": projectserviceId,
      "quantity": quantity,
      "useType": useType,
      "shipTo": shipTo,
    });

    action.setCallback(this, function(response) {
      var result = JSON.parse(response.getReturnValue());
      helper.closeDialog(component);

      var appEvent = $A.get("e.c:ProjectMaterialChange");
      appEvent.setParams({ "state": result.State });
      appEvent.setParams({ "message": result.Message });
      console.log(appEvent);
      appEvent.fire();
      $A.util.addClass(component.find("addMaterialSpinner"), "slds-hide");

    });

    $A.enqueueAction(action);
  },

  handleSearch: function(component, event, helper) {
    var searchText = component.find("searchText").get("v.value");
    var action = component.get("c.GetMaterials");
    action.setParams({
      "searchText": searchText
    });

    action.setCallback(this, function(response) {
      var materials = response.getReturnValue();

      if (materials.length == 0) {
        component.set("v.showNoResultsMessage", true);
      } else {
        component.set("v.showNoResultsMessage", false);
      }
      component.set("v.materials", materials);
      component.set("v.disableAddButton", "true");


    });

    $A.enqueueAction(action);
  },
  onCheck: function(component, event, helper) {
    var checkbox = event.srcElement;
    if (checkbox.checked) {
      component.set("v.selectedMaterialId", checkbox.id.substring(0, 18));
      component.set("v.disableAddButton", "false");
    } else {
      component.set("v.selectedMaterialId", "");
      component.set("v.disableAddButton", "true");
    }
  },

})