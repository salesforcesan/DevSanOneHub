({
  doInit: function(component, event, helper) {
    helper.init(component);
  },
  close: function(component, event, helper) {
    helper.closeDialog(component);
  },
  handleClick: function(component, event, helper) {

    var checkbox = event.target;

    var checked = checkbox.checked;
    var serviceId = checkbox.id.substring(7);
    component.set("v.selectedServiceId", serviceId);
  },
  addService: function(component, event, helper) {
    helper.addService(component, event, helper);
  }
})