({
  doInit: function(component, event, helper) {
    component.set("v.securityelements", "ProjectService__c.Add,ProjectService__c.Edit,ProjectService__c.Rank");
    helper.cGetProjectServices(component, event, helper);
  },
  upRank: function(component, event, helper) {
    helper.changeRank(component, event, helper, "up");
  },
  downRank: function(component, event, helper) {
    helper.changeRank(component, event, helper, "down");
  },
  openAddServicesModal: function(component, event, helper) {
    helper.showDialog(component, {
      "projectId": component.get("v.projectId")
    });
  },

  refreshServices: function(component, event, helper) {
    helper.refreshServices(component, event, helper);
  }
})