({
    onInit: function(component, event, helper) {
        helper.getTargetUseTypes(component, event);
       	helper.getTargetTypes(component, event);
       	helper.getProjectAccounts(component, event); 
        helper.getNameSpace(component);
        helper.getProjectTypeInfo(component, event); 
    },
    
    getProjectTypeInfo: function (component, event, helper) { 
        
        var projectId = component.get('v.projectId');
        console.log('~projectId~'+projectId);
        var action = component.get("c.ProjectTypeInfoDetail");
        action.setParams({            
            "projId": projectId
        });
        action.setCallback(this, function(response){    
            
            console.log('~~getState~~'+response.getState());
            var state = response.getState();
            if(state === 'SUCCESS'){  
                console.log('~~'+response.getReturnValue());
                component.set("v.isProjectAccountMandatory", response.getReturnValue()); 
            }            
        });        
        $A.enqueueAction(action);
 	},
    
    getProjectServiceTargets : function(component, event, helper) {
       	 this.showSpinner(component);
         var projectServiceId = component.get('v.recordId');
         var action = component.get("c.GetProjectServiceTargets");
     	 action.setParams({            
           "projectServiceId": projectServiceId
        });
         action.setCallback(this, function(response){
            this.hideSpinner(component);
            var state = response.getState();
            if(state === 'SUCCESS'){       
                var uniqueArray= null;
                var targets =  response.getReturnValue();
                component.set("v.targets", targets);
				console.log('targets ', component.get('v.targets'));
                
                if (!$A.util.isEmpty(targets)){
                    let plus5 = targets.map((r, i, arr) =>  r.TargetUse );
                       uniqueArray = Array.from(new Set(plus5));
                }
                if (uniqueArray == null){
                    var typeValue = ['Primary'];
                    uniqueArray = typeValue;
                }
                
                component.set("v.mapTargets", uniqueArray);
                
                var targetIds = [];
                targets.forEach(item => targetIds.push(item.TargetId));
                component.set("v.targetIds", targetIds);
                console.log('targetIds: ', targetIds);
                component.set('v.targetsLoaded', true);
                
            } else {
                var messageTitle;
                this.errorMessage(component, messageTitle, response) 
            }
        });
        //action.setStorable();
        $A.enqueueAction(action);
    
    },
 
    addTargets: function(component, event, targets, targetUse, accountId, projectId) {
        this.showSpinner(component);
        var projectServiceId = component.get('v.recordId'); 
        console.log('psId', projectServiceId);
        var action = component.get("c.AddTargets");
        action.setParams({        
           "searchIds": JSON.stringify(targets),
           "projectServiceId": projectServiceId,
           "targetUseType":targetUse,
           "projectAccountId":accountId,
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
                $A.get('e.force:refreshView').fire();
                //this.getProjectServiceTargets(component, event);
            } else {
                var messageTitle;
                this.errorMessage(component, messageTitle, response) 
            }
        });
        $A.enqueueAction(action);    
    },
    
    handleRemove: function(cmp, evt){
        this.showSpinner(cmp);
        let targetIds = cmp.get('v.selectedTargets');
        var projectServiceId = cmp.get('v.recordId'); 
        var action = cmp.get("c.RemoveProjectServiceTargets");
        action.setParams({        
           "projectServiceTargetIdList": targetIds,
        });
        action.setCallback(this, function(response){
            this.hideSpinner(cmp);
            var state = response.getState();
            if(state === 'SUCCESS'){                 
                var ret = response.getReturnValue();
                //console.log('message: ', ret.message);
                this._msgBox('success', ret.message); 
                cmp.set('v.selectedTargets', []);
                cmp.set('v.selectedAccount', '');
                this.clearChecks(cmp);
                $A.get('e.force:refreshView').fire();
                
            } else {
                var messageTitle;
                this.errorMessage(component, messageTitle, response) 
            }
        });
        
        
        $A.enqueueAction(action);

    },
    
     updateTargets: function(cmp, evt, targets){
        this.showSpinner(cmp);
        var action = cmp.get("c.UpdateTargets");
        action.setParams({        
           "projectServiceTargetWrapperList": JSON.stringify(targets)
        });
        action.setCallback(this, function(response){
            this.hideSpinner(cmp);
            var state = response.getState();
            if(state === 'SUCCESS'){             
               var ret = JSON.parse(response.getReturnValue());
               console.log('message: ', ret);
               this._msgBox('success', ret.message); 
                
                cmp.set('v.editMode', false);
                cmp.set('v.selectedTargets', []);
                cmp.set('v.selectedAccount', '');
                this.clearFields(cmp);
                this.clearChecks(cmp);
                $A.get('e.force:refreshView').fire();
            } else {
                var messageTitle;
                this.errorMessage(cmp, messageTitle, response) 
            }
        });
        $A.enqueueAction(action);

    },
    
    handleMessageBoxEvent: function(cmp, evt) {
        var targetResult = {
            id: evt.getParam('id'),
            value: evt.getParam('context')
        };
        if (evt.getParam('context') !== 1) {
            return;
        }
        if (targetResult.id === 'removeTargets' && targetResult.value == 1) {
            this.handleRemove(cmp, evt);
        }
    },

    handleRemoveConfirm: function(cmp, evt) {
        var prompt = cmp.find('messageBox');
        prompt && prompt.show({
            id: 'removeTargets',
            title: 'Remove Selected Targets',
            body: '<p>Are you sure that you want to remove the selected targets from the service?</p>',
            positiveLabel: 'Confirm',
            negativeLabel: 'No',
            severity: 'error'
        });
    },

    _msgBox: function(type, msg) {
        var notice = $A.get('e.force:showToast');

        notice.setParams({
            'mode': type === 'error' ? 'sticky' : 'dismissible',
            'type': type,
            'message': msg
        });
        notice.fire();
    },
    
     getTargetUseTypes: function(component, event, helper) { 
        var projectServiceId = component.get('v.recordId');
        var action = component.get("c.GetTargetUseTypes");
        action.setParams({        
           "projectServiceId": projectServiceId,
        });
        action.setCallback(this,function(response){   
           var targetUseTypeResults = response.getReturnValue();
           if(!$A.util.isEmpty(targetUseTypeResults)) {
          	  component.set("v.targetUseTypes", targetUseTypeResults);

            }
        });
        $A.enqueueAction(action);
    },
    
    getProjectAccounts: function (component, event, helper) {
        var projectId = component.get("v.projectId"); 
        var action = component.get("c.GetTargetAccounts");
        action.setParams({
            "projectId": projectId
        });
        action.setCallback(this,function(response){   
            var accs = JSON.parse(response.getReturnValue());
            console.log('accs: ', accs);
            component.set("v.projectAccounts", accs);
            if(!$A.util.isEmpty(accs)){
               accs.length > 1 ? component.set('v.selectedAccount', '') : component.set('v.selectedAccount', accs[0].Id);  
            } else {
               this.showToast('No Account', 'There is no account associated to this project', 'error');   
            }
           
            console.log('selected account on load: ', component.get('v.selectedAccount'));
            
        });
        $A.util.addClass(component.find("addTargetSpinner"), "slds-hide");
        $A.enqueueAction(action);
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
    
    errorMessage: function(cmp, messageTitle, result) {
        var message;
        var errors = result.getError();
        if (errors[0] && errors[0].message) // To show other type of exceptions
            message = errors[0].message;
        if (errors[0] && errors[0].pageErrors) // To show DML exceptions
            message = errors[0].pageErrors[0].message;
        
        this.showToast(messageTitle, message, 'error');  
    },
    
    clearFields: function(component, event, helper) {
        var pasted = component.find('pasteTargets');
        var search = component.find('searchText');
        var account = component.find('projectAccounts');
        if (!$A.util.isEmpty(account)){ 
            account.set('v.value', '');
        }
        search.set('v.value', '');
        pasted.set('v.value', null);
        component.set('v.pasteList', []);     
    },
    
    clearChecks: function(component, event, helper) {
       var allSelections = document.querySelectorAll(".checkboxes input");
        component.set('v.selectAll', false);
        for (var i = 0; i < allSelections.length; i++) {
           allSelections[i].setAttribute('checked', false);    
        }  
    },

    showSpinner: function(component) {
        var spinner = component.find("projectTargetSpinner");
        $A.util.removeClass(spinner, "slds-hide");
    },

    hideSpinner: function(component) {
        var spinner = component.find("projectTargetSpinner");
        $A.util.addClass(spinner, "slds-hide");
    },
    
    checkPrimaryTargets: function(component, event, type) {
    	var primaryTargs = [];
        var secondaryTargs = []; 
        var targets = component.get('v.selectedTargets');
        var data = component.get('v.targets');
        var targetUse = component.get('v.selectedUseTypeUpdate');
        var targData = data.filter(function(item) {
            targets.forEach(function(targ) {
               targ == item.ProjectServiceTargetId && item.TargetUse == 'Primary' ? primaryTargs.push(item) : 
               targ == item.ProjectServiceTargetId && item.TargetUse == 'Secondary' ? secondaryTargs.push(item) : '';
             });
        });
        var allPrimary = [];// = data.filter(item => item.TargetUse == 'Primary');
        var allSecondary = []; //= data.filter(item => item.TargetUse == 'Secondary');
        
        data.forEach(function(item) {
            if(item.TargetUse == 'Primary'){
                allPrimary.push(item);
            } else if (item.TargetUse == 'Secondary'){
                allSecondary.push(item);
            }
        });
        
        if(type == 'delete'){
            if(primaryTargs.length == allPrimary.length && (secondaryTargs.length != allSecondary.length)) {
                return true;
            } else {
                return false;
            }
        } else if (type == 'update') {
            
            if(primaryTargs.length == allPrimary.length && (targetUse != 'Primary' && targetUse != '')) {
            	return true;
            } else {
                return false;
            }
        }
        
	},
    
    showToast : function(title, message, type) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "message": message,
            "type": type
        });
        toastEvent.fire();
    },  
})