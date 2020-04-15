({
    
  'CONTEXT': {
    'overview': 'c:ProjectServiceOverview',
    'instructions': 'c:ProjectServiceInstructions',
    'tools': 'c:ProjectServiceTools',
    'targets': 'c:ProjectServiceTargets',
    'certifications': 'c:ProjectServiceCertifications',
    'survey': 'c:ProjectServiceSurvey'
  },

  destroyContents: function(cmp) {
    //cmp.set('v.body', []);
  },

  gobackToProject: function(cmp, evt) {
    this.destroyContents(cmp);
    var navEvent = $A.get("e.force:navigateToURL");
    navEvent.setParams({
      "url": "/one/one.app#/sObject/" + cmp.get("v.projectId") + "/view?slideDevName=services&v=" + Date.now()
    });
    navEvent.fire();
  },

  renderComponent: function(cmp) {

    
    var id = cmp.get('v.recordId'),
      pId = cmp.get('v.projectId'),
      project = cmp.get('v.project') || {},
      contextKey = cmp.get('v.projectServiceContext');

    if (!this.CONTEXT[contextKey]) {
      console.log('The context (' + contextKey + ') is invalid');
      return;
    }
    this.destroyContents(cmp);
    console.log('-- before load component:' + contextKey );
    $A.createComponent(this.CONTEXT[contextKey], {
      recordId: id,
      projectId: pId,
      bundledProject: project.BundleServices__c || false
    }, function(child, status, msgList) {
      if (status === 'SUCCESS') {

      
        
        cmp.set('v.body', [child]);
        //console.log('-- load component:' + contextKey );
      } else if (status === 'ERROR'){
        console.log('Error:' + msgList,'error');
      }
    });
    
  },

  cGetProject: function(component) {

    var self = this,
        projectServiceId = component.get("v.recordId"),
        action = component.get("c.getProjectByServiceId"),
        project;
    
    action.setParams({ 
      "projectServiceId": projectServiceId 
    });
    
    action.setCallback(self, function(result) {

      project = result.getReturnValue() || {};
      component.set('v.projectId', project.Id)
      component.set("v.project", project);
      self.renderComponent(component);
    //isSuccess

    });
    $A.enqueueAction(action);
  },

  setProjectServiceContext: function(component) {

    //component.set("v.projectServiceContext", 'instructions');
  }
})