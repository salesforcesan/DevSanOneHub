({ 
    initSecurity:function(component,event,helper) {
         var pst = component.get('v.projectServiceTarget') || {};
         component.set('v.canDelete', pst.canDelete ? true : false ); 
    },
    
    removeTarget : function(component, event, helper) {        
       	var projectServiceTarget = component.get("v.projectServiceTarget");
        var elem = document.querySelector('#card' + projectServiceTarget.ProjectServiceTargetId);
        elem.className += ' delete';
        var action = component.get("c.RemoveTargetFromService");
        action.setParams({            
                "projectServiceTargetId" : projectServiceTarget.ProjectServiceTargetId
        });           

        action.setCallback(this,function(response){   
                var results = JSON.parse(response.getReturnValue());               
                console.log(results);    
                var appEvent = $A.get("e.c:ProjectServiceTargetChange"); 
                appEvent.setParams({ "state" : results.State });
       		    appEvent.setParams({ "message" : results.Message });
                console.log(appEvent);    
                appEvent.fire();
                
            });
            
            $A.enqueueAction(action);
        },

    handleMessageBoxEvent: function(component, evt) {
    var result = {
    	id: evt.getParam('id'),
    	value: evt.getParam('context')
    };
    if (result.id === 'removeTarget' && result.value == 1) {
        this.removeTarget(component);
      }
  },

  openMessageBox : function(component, event) {
        var prompt = component.find('messageBox'),
            projectServiceTarget = component.get("v.projectServiceTarget"),
            removeMessage;

        removeMessage = "<p>Are you sure that you want to remove " + projectServiceTarget.TargetName + "?</p>"

        prompt && prompt.show({
          id: 'removeTarget',
          title: 'Remove Target',
          body: removeMessage,
          positiveLabel: 'Remove',
          negativeLabel: 'Cancel',
          severity: 'error'
        });
  },    
})