({
    doInit: function(component, event, helper) {
        component.set("v.securityelements", "ProjectTarget__c.Add");
        component.set('v.targets', []);
        var projectServiceId = component.get("v.recordId");
        helper.onInit(component, event, helper);
        helper.getProjectServiceTargets(component, event);
    },
    
    refreshComponent: function (cmp, event, h) {                
        h.getProjectServiceTargets(cmp, event, h);
    },    
    
    addTargetsHandler: function(component, event, helper) {
        
        let accountId =(!$A.util.isEmpty(component.find('projectAccounts'))) ? 
            component.find('projectAccounts').get('v.value') : '';
        let projectId = component.get('v.projectId');
        console.log('pId:', projectId);
        let searchText = component.find('searchText').get('v.value');
        let targetUse = component.get('v.selectedUseType');
        let existingTargets = component.get('v.targets');
        let targets = [];
        if(existingTargets.length == 0 && targetUse != 'Primary' ) {
            helper._msgBox('warning', 'You need to first add primary target types');
            return;
        };
        
        let isProjectAccountMandatory = component.get('v.isProjectAccountMandatory');
        if(isProjectAccountMandatory && accountId=='' && (targetUse == 'Primary'|| targetUse == 'Secondary') ){
            helper._msgBox('warning', 'Account is Mandatory to add a Target. Please select an Account.');
            return;
        }
        
        targets = helper.handlePasteList(component, event, helper);
        if($A.util.isEmpty(targets) && $A.util.isEmpty(searchText)) {return;}
        $A.util.isEmpty(targets) ? targets = [] : targets;

        if(!$A.util.isEmpty(searchText)) {
            var search = searchText.split(';');
            component.set('v.searchIds', search);
            targets = [...targets, ...search];
            console.log('targets pushed: ', targets);
        }
        helper.addTargets(component, event, targets, targetUse, accountId, projectId);
    },
    
    handleSectionToggle: function (cmp, event) {
        var openSections = event.getParam('openSections');
        if (openSections.length === 0) {
            cmp.set('v.activeSectionsMessage', "All sections are closed");
        } else {
            cmp.set('v.activeSectionsMessage', "Open sections: " + openSections.join(', '));
        }
        
        var message = cmp.get('v.activeSectionsMessage');
        console.log('message active: ', message);
    },

    onMessageBoxEvent: function(cmp, evt, helper) {
        helper.handleMessageBoxEvent(cmp, evt);
    },

    removeSelectedHandler: function(cmp, evt, helper) {
        let targetIds = cmp.get('v.selectedTargets');
        if($A.util.isEmpty(targetIds)) {return;}
        console.log('targetIds: ', targetIds);
        if(helper.checkPrimaryTargets(cmp, evt, 'delete')){
        	helper._msgBox('warning', 'You cannot delete all primary targets when you have secondary targets');
            return;
       };
        helper.handleRemoveConfirm(cmp, evt);
    },
    
    clearFields: function(component, event, helper) {
       helper.clearFields(component, event, helper);
    },
    
    togglePaste : function(cmp, evt, helper) {
        var togglePaste = cmp.find("togglePaste");
        $A.util.toggleClass(togglePaste, "togglePaste");
        if(!$A.util.hasClass(togglePaste, "togglePaste")) {
            helper.clearFields(cmp, event, helper);
        }
  	},
    toggleSearch : function(cmp, evt, helper) {
        let toggleSearch = cmp.find("searchContainer");
		let toggleWidth = cmp.find("searchWidth");
        $A.util.toggleClass(toggleSearch, "slds-hide");
        $A.util.toggleClass(toggleWidth, "oh-flex");
        if(!$A.util.hasClass(toggleSearch, "slds-hide")) {
            let search = cmp.find('searchText');
	   		search.set('v.value', '');
        }
  	},
    
    onMessageBoxEvent: function(cmp, evt, helper) {
        helper.handleMessageBoxEvent(cmp, evt);
    },
    
    onChangeTargetType:function(component, event, helper) {
        var targetType = event.getSource().get("v.value");
        component.set("v.selectedTargetType", targetType);
    },
    onChangeTargetUseType:function(component, event, helper) {
        var targetUseType = event.getSource().get("v.value");
        component.set("v.selectedUseType", targetUseType);
    },
    
    onChangeTargetUseTypeUpdate:function(component, event, helper) {
        var targetUseType = event.getSource().get("v.value");
        component.set("v.selectedUseTypeUpdate", targetUseType);
    },
    
    onChangeAccount:function(component, event, helper) {
        var account = event.getSource().get("v.value");
        component.set("v.selectedAccount", account);
    },
    
    onChangeAccountUpdate:function(component, event, helper) {
        var account = event.getSource().get("v.value");
        component.set("v.selectedAccountUpdate", account);
    },
    
    updateChecked: function(cmp, e, h) {
        var selectedTargets = cmp.get('v.selectedTargets');
        var target = e.getSource().get('v.value');
        if(!target) return;
        if(e.getSource().get('v.checked')) {
            if(target == 'selectAll') {
                cmp.set('v.selectAll', true);
                selectedTargets = cmp.get('v.targets').map(item => item.ProjectServiceTargetId);
            } else {
                console.log('item: ', target); 
            	selectedTargets.push(target); 
            }
            cmp.set('v.selectedTargets', selectedTargets);
            console.log('selected targets: ', selectedTargets);
        } else {
           var newTargets = selectedTargets.filter(item => item != target) ;
           if(target == 'selectAll') {
               cmp.set('v.selectAll', false);
               newTargets = [];
               cmp.set('v.selectedTargets', newTargets)
           } else { 
               var elem = document.querySelector('#selectAll');
               cmp.set('v.selectedTargets', newTargets);
           }

           console.log('new selected targets: ', newTargets);
        }
    },
    
    cancelEdit: function(component, event, helper) {
		component.set('v.editMode', false);
        //component.set('v.selectedTargets', []);
        component.set('v.selectedAccountUpdate', '');
    },
    
    showEditMode: function(component, event, helper) {
      	component.set('v.editMode', true);
    },

    saveTargetsUpdate: function(component, event, helper) {
      	var targets = component.get('v.selectedTargets');
        var account = component.get('v.selectedAccountUpdate');
        var targetUse = component.get('v.selectedUseTypeUpdate');
        if((!account && !targetUse) && !targets) return;
        if(helper.checkPrimaryTargets(component, event, 'update')){
        	helper._msgBox('warning', 'You cannot assign all primary targets to a different target type');
            return;
        };
        var targetsMap = [];
        for (var i= 0; i < targets.length; i++) {
            targetsMap[i] = { 
               'ProjectServiceTargetId': targets[i].trim(),
               'ProjectAccountId': account,
               'TargetUse':targetUse
            };
        }

        helper.updateTargets(component, event, targetsMap);
        
    },

})