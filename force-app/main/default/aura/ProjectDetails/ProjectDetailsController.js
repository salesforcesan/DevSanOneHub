({
  doInit: function(component, event, helper) {
    var projID = component.get("v.ProjectId");
     component.set("v.securityelements", "Project__c.Summary,Project__c.RecordEdit,Project__c.ProjAttributesReadOnly,Project__c.ProjAttributes");      
    helper.getProjectDetails(component, projID);
  },
  save: function(component, event, helper) {
    helper.saveProject(component);
  },
  toggleField: function(component, event, helper) {
    var fields = component.find("scheduleFields");
    $A.util.toggleClass(fields, "field-show");
  },
  handleSaveSuccess: function(component, event, helper) {
    helper.handleSaveSuccess(component);
  },
  summaryClicked: function(component, event, helper) {
    var buttonId = event.target.id,
      project = component.get('v.project'),
      namespace = project.Namespace || '';

    $A.util.removeClass(component.find("projectDetailsSpinner"), "slds-hide");
    if (buttonId != null) {
      if (buttonId === "ViewProjectSummary") {
        var projectId = component.get("v.ProjectId");
        var url = '/apex/' + namespace + 'ProjectSummary?id=' + projectId;
        helper.navigate(component, url);
      }
    }
  },
  viewdetailClicked: function(component, event, helper) {
    window.open(component.get("v.project.DetailReportURL"),'_blank');  
  },
  viewExternalDetailClicked: function(component, event, helper) {
    window.open(component.get("v.project.ExternalDetailReportURL"),'_blank');  
  },
  refreshProject: function(component, event, helper) {
    var origin = event.getParam('origin');
    if (origin === 'edit_project_modal') {
      var project = event.getParam('project');
      component.set("v.project", project);
      //hack to make the recordView to refresh, set ProjectId to empty before set
      component.set("v.ProjectId", '');
      component.set("v.ProjectId", project.Id);
    }

  }
})