({
    cEditProject: function(component, event, helper) {
        // Good
        var project = component.get("v.project");
        var projectId = component.get("v.project.Id");
        if(project.Status == 'Planning'){
            var urlEvent = $A.get("e.force:editRecord");
            urlEvent.setParams({
                "recordId": projectId
            });
            urlEvent.fire();    
        }
        else{
            var userevent = $A.get("e.c:EventDisplayModal");
            userevent.setParams({
                "modalProperties": {
                    "title": "Edit Project",
                    "size": "small"
                },
                "modalComponentName": "c:ProjectEdit",
                "modalComponentProperties": {
                    "projectId": projectId,
                    "recordId": projectId
                }
            });
            userevent.fire();
        }
    },
    cCloneProject : function(component, event, helper) {
        var action = component.get("c.InitCloneProject");
        var projectId = component.get("v.project.Id");
        action.setParams({
            "projectId": projectId
        });    
        helper.callServerAction(component,event,helper,action,true);
    },
    cReleaseProjectChanges : function(component, event, helper) {
        // Good
        var action = component.get("c.ReleaseProjectChanges");
        var projectId = component.get("v.project.Id");
        var notify = component.find("notify");
        var self = this;
        action.setParams({
            "projectId": projectId
        });
        action.setCallback(this, function(response) {
            
            var state = response.getState();
            if (state === "SUCCESS") {
				
                self.showToast('Successfully released changes', 'success');
                window.location.reload();
            }
            else
            {
                self.showToast('Error releasing changes', 'error');
            }
        
        });
        $A.enqueueAction(action);
        
    },
    cReleaseOOCF : function(component, event, helper) {
        // Good
        var action = component.get("c.ReleaseOOCFChanges");
        var projectId = component.get("v.project.Id");

        var self = this;
        action.setParams({
            "projectId": projectId
        });
        action.setCallback(this, function(response) {
            
            var state = response.getState();
            if (state === "SUCCESS") {
				
                self.showToast('Successfully released changes', 'success');
                window.location.reload();
            }
            else
            {
                self.showToast('Error releasing changes', 'error');
            }
        
        });
        $A.enqueueAction(action);
        
    },
    cDeleteProject: function(component, event, helper) {
        // Good
        var action = component.get("c.DeleteProjects");
        var projectId = component.get("v.project.Id");        
        action.setParams({
            "projectId": projectId
        });
        console.log('delete project request received for project number:' + component.get("v.project.ProjectNumber"));    
        helper.callServerAction(component,event,helper,action,true);        
    },
    
    gotoComponent : function () {
        var evt = $A.get("e.force:navigateToComponent");
        evt.setParams({
            componentDef: "c:ProjectDashboardLayout",
            componentAttributes: {}
        });
        evt.fire();    
    },
    openCancelModal : function(component, event, helper) {
        var userevent = $A.get("e.c:EventDisplayModal"); 		
        var project = component.get("v.project");
        
        userevent.setParams({                  
            "modalComponentName": "c:ProjectCancel",
             "modalProperties": {
                "title": "Cancel Project",                     
                "height": "400px",
                "width": "600px",
                "offsetFromHeader": "false"                
            },
            "modalComponentProperties": {
                "project": project
            }
        });       
        userevent.fire();
	},  
     openDeleteModal : function(component, event, helper) {
        var delProject = component.find("messageBox");
         delProject.show({
             id:'deleteProjects',
             title:'Delete Project',
             body:'<p>Are you sure you want to delete this project?</p>',
             positiveLabel:'Yes',
             negativeLabel:'No',
             severity:'error'
         });
         
	},
    openReleaseChangesModal : function(component, event, helper) {
        var relProject = component.find("messageBox");
         relProject.show({
             id:'releaseChanges',
             title:'Release Changes',
             body:'<p>Are you sure you want to release changes to this project?</p>',
             positiveLabel:'Yes',
             negativeLabel:'No',
             severity:'error'
         });
	},
    openOOCFModal : function(component, event, helper) {
        var relProject = component.find("messageBox");
         relProject.show({
             id:'oocf',
             title:'Out Of Cycle Fulfillment',
             body:'<p>Are you sure you want to release out of cycle fulfillment for this project?</p>',
             positiveLabel:'Yes',
             negativeLabel:'No',
             severity:'error'
         });
	},
    openCloneModal : function(component, event, helper) {
        var userevent = $A.get("e.c:EventDisplayModal");
        userevent.setParams({
            "modalProperties": {
                "title": "Clone Project"
            },
            "modalComponentName": "c:ModalAlert",
            "modalComponentProperties": {
                "message": "The project has been cloned. You will receive an email shortly."
            }
        });
        userevent.fire();
	},   
	openSubmitModalforVF : function(component) {
        var userevent = $A.get("e.c:EventDisplayModal");
        userevent.setParams({                  
            "modalComponentName": "c:SubmitProject",
             "modalProperties": {
                "title": "Submit Project",                     
                "size":"small",
                "offsetFromHeader": "false"
            },
            "modalComponentProperties": {
                "recordId": component.get("v.recordId"),
                "project" : component.get("v.project")
            }});
        userevent.fire();
	},
  	_notify: function(cmp, msg, type, autoHide, duration) {
    	cmp.find('notification').show(msg, type, autoHide, duration);
  	},
    callServerAction:  function(component,event,helper,action,isRedirectPage)    
    { 
      var self = this;  
      helper.showSpinner(component);
      action.setCallback(this, function(response) {
            var state = response.getState();
          	if (!component.isValid())
                return;
          
            if (state === "SUCCESS") {                
                helper.hideSpinner(component);
                var responseWrapper = JSON.parse(response.getReturnValue());                
                if(responseWrapper.State==="SUCCESS"){

                    if(isRedirectPage)
                    {
                    	helper.gotoComponent();
                    }

                    if (responseWrapper.Message != '' && responseWrapper.Message != null)
                    {
                    	self.showToast(responseWrapper.Message, 'success');    
                    }

                  
                }
                else{
                    self.showToast(responseWrapper.Message, 'error');                                  
                }                
            }
           else if (state === "INCOMPLETE") {
               helper.hideSpinner(component);
				//console.log('do something here');
			} else if (state === "ERROR") {
                helper.hideSpinner(component);
				var errors = response.getError();                
				if (errors) {
					if (errors[0] && error[0].message) {                         
                         self.showToast(errors[0].message, 'error');
					}
				} else {
					 self.showToast('Unhandled Exception occurred:\r\nContact Administrator', 'error');                                         
				}
			}
        });
        $A.enqueueAction(action);  
    },
    refreshProject: function(component,event,helper){
        var p = event.getParam('project');
        console.log(p);
        component.set("v.project",p);
        //window.location.reload(true);
        /*
    	var action = component.get("c.GetProject");
        var projectId = component.get("v.project.Id");
                
        action.setParams({
            "recordId": projectId
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var updatedProject = response.getReturnValue();
                component.set("v.project",updatedProject);                                                  
            }
        });
        $A.enqueueAction(action);*/
	},
  	showToast : function(message, type) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "message": message,
            "type": type
        });
    	toastEvent.fire();
  	},
 	showSpinner: function(cmp){
        var spinner = cmp.find("displaySpinner");
        $A.util.removeClass(spinner, "slds-hide"); 
    },
    hideSpinner: function(cmp){
        var spinner = cmp.find("displaySpinner");
        $A.util.addClass(spinner, "slds-hide"); 
    },
    GenerateJobManualHandler: function(cmp){
		var action = component.get("c.GenerateJobManual");
        var projectId = component.get("v.project.Id");

        var self = this;
        action.setParams({
            "projectId": projectId
        });
        action.setCallback(this, function(response) {
            
            var state = response.getState();
            if (state === "SUCCESS") {				
                self.showToast('Successfully generated Job manuals!', 'success');
                window.location.reload();
            }
            else{
                self.showToast('Error releasing changes', 'error');
            }
        
        });
        $A.enqueueAction(action);
    }
    
})