({
  doInit: function(component, event, helper) {
    var projectId = component.get("v.projectId");
    console.log(projectId);
    component.set("v.securityelements", "ProjectMaterial__Add");
    helper.refreshMaterialsList(component, event, projectId);
  },

  openAddMaterialModal: function(component, event, helper) {
    helper.showModalDialog(component);
  },

})