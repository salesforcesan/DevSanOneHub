({
    onInit: function(component, event, helper) {
       	helper.getTargetTypes(component, event); 
        helper.getNameSpace(component);        
    },
    
    getTargetTypes: function (component, event, helper) {
      var action = component.get("c.GetTargetTypes");
      action.setCallback(this,function(response){   
            var targetTypesResults = response.getReturnValue();
            component.set("v.targetTypes", targetTypesResults);
        });
        $A.util.addClass(component.find("addTargetSpinner"), "slds-hide");
        $A.enqueueAction(action);
 	},

    getNameSpace: function(cmp) {
        var action = cmp.get("c.getNamespaceApex");
        action.setCallback(this, function(result) {
            cmp.set("v.ns", result.getReturnValue()); 
            console.log('ns: ', result.getReturnValue());
        });
        $A.enqueueAction(action);
    },

    handlePasteList: function(component, event) {
        var pasted = component.find('pasteTargets').get('v.value');
        var pasteList = [];
        if(pasted) {
            pasted =  pasted.replace(/(\r\n|\n|\r)/gm,",");

            console.log('pasted: ', pasted);
            var dataNew = pasted.split(',');
            dataNew = dataNew.filter(item => item.trim() != '');
            for(var i = 0; i < dataNew.length; i++) {
             	dataNew[i] = dataNew[i].toString().trim();
            }
            component.set('v.pasteList', dataNew);  
            console.log('data New: ', dataNew);
        } 
        return dataNew;
    },
    
	addTargets: function(component, event, targets) {        
        debugger;
      
        var cmpEvent = component.getEvent('targetEvent');
        cmpEvent.setParams({
            'targetId':targets
        });
        cmpEvent.fire();
        
        
        
        /*
        this.showSpinner(component);
        var projectServiceId = component.get('v.recordId'); 
        console.log('~~psId~~', projectServiceId);
        var action = component.get("c.AddTargets_SurveyResponse");
        action.setParams({        
           "searchIds": JSON.stringify(targets),
           "projectServiceId": projectServiceId,
           "targetUseType":targetUse,
           "projservQnId":projservQnId,
            "projectId":projectId
        });
        action.setCallback(this, function(response){
            this.hideSpinner(component);
            var state = response.getState();
            if(state === 'SUCCESS'){             
                var errors =  response.getReturnValue();
                component.set("v.errors", errors);
                this.clearFields(component);
                var togglePaste = component.find("togglePaste");
        		$A.util.toggleClass(togglePaste, "togglePaste"); 
                //$A.get('e.force:refreshView').fire();                
            } else {
				var errors = response.getError();
                if (!!errors && !!errors[0] && !!errors[0].message) {
                    msg = errors[0].message;
                } else {
                    msg = 'The system run into an unknown error.';
                }
                //self.showToast('Error adding Target : ' + msg, 'error');
            }
        });
        $A.enqueueAction(action);  
        */
    },
    
    clearFields: function(component, event, helper) {
        var pasted = component.find('pasteTargets');
        var search = component.find('searchText');
        
        search.set('v.value', '');
        pasted.set('v.value', null);
        component.set('v.pasteList', []);     
    },
    
    showSpinner: function(component) {
        var spinner = component.find("projectTargetSpinner");
        $A.util.removeClass(spinner, "slds-hide");
    },

    hideSpinner: function(component) {
        var spinner = component.find("projectTargetSpinner");
        $A.util.addClass(spinner, "slds-hide");
    },
})