({
  doInit: function(component, event, helper) {
    helper.setProjectServiceContext(component);
    helper.cGetProject(component, helper);
  },
  onGobackToProject: function(component, event, helper) {
    helper.gobackToProject(component, event);
  },

  handleChangeProjectServiceContext: function(component, event, helper) {
    var newProjectServiceContext = event.getParam("context");
    if (component.get('v.projectServiceContext') == newProjectServiceContext) {
      return; }
    component.set("v.projectServiceContext", newProjectServiceContext);
    helper.renderComponent(component);
  }
})