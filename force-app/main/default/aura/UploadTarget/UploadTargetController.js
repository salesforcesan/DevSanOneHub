({
    doInit: function(component, event, helper) {        
        component.set('v.targets', []);
        var projectServiceId = component.get("v.recordId");
        helper.onInit(component, event, helper);        
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
	   		//search.set('v.value', '');
        }
  	},
    clearFields: function(component, event, helper) {
       helper.clearFields(component, event, helper);
    },
    
    addTargetsHandler: function(component, event, helper) {
        debugger;
        let projservQnId =(!$A.util.isEmpty(component.find('ProjectSurveyQuestionCard'))) ? 
            component.find('ProjectSurveyQuestionCard').get('v.value') : 'a0l19000001pIM1AAM';
        
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
        helper.addTargets(component, event, targets);        
    }
})