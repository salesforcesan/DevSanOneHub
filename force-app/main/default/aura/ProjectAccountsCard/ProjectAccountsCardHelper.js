({
    init: function(cmp) {
        var acct = cmp.get('v.projectAccount') || {};
        cmp.set('v.cssClass', !!acct.isPrimary ? 'oh-primary-holder slds-m-bottom_small' : 'slds-m-bottom_small');
        cmp.set('v.canSetPrimary', !acct.isPrimary && acct.canSetPrimary ? true : false);
        cmp.set('v.canDelete', !acct.isPrimary && acct.canDelete ? true : false );
        this._initNameValues(cmp, acct.fieldset);
    },

    _initNameValues: function(cmp, arrList) {
        var fieldset = [];
        arrList.forEach(function(arr) {
            fieldset.push({
                "name": arr[0],
                "value": arr[1]
            });
        });
        cmp.set('v.nameValues', fieldset);
    },

    removeAccount: function(component, event, helper) {
        var spinner = component.find("projectAccountCardSpinner");
        $A.util.removeClass(spinner, "slds-hide");
        var projectAccount = component.get("v.projectAccount");
        var action = component.get("c.RemoveAccountsFromProject");
        action.setParams({
            "ProjectAccountId": projectAccount.id
        });
        var self = this;
        action.setCallback(this, function(response) {
            
            
            var state = response.getState(),
                msg = '';
			
            if (state === 'SUCCESS') {
                var result = JSON.parse(response.getReturnValue());
                msg = result.Message;
                self.showToast('Successfully removed account from project', 'success');
            }

            if (state === 'ERROR') {
                var errors = response.getError();
                if (!!errors && !!errors[0] && !!errors[0].message) {
                    msg = errors[0].message;
                } else {
                    msg = 'The system run into an unknown error.';
                }
                self.showToast('Error removing account from project: ' + msg, 'error');
            }

            var appEvent = $A.get("e.c:ProjectAccountChange");
            appEvent.setParams({ "state": state });
            appEvent.setParams({ "message": msg });
            appEvent.fire();
        });

        $A.enqueueAction(action);

    },

    handleMessageBoxEvent: function(component, evt) {
        var result = {
            id: evt.getParam('id'),
            value: evt.getParam('context')
        };
        if (result.id === 'removeAccount' && result.value == 1) {
            this.removeAccount(component);
        }

    },

    openMessageBox: function(component, event, helper) {
        var projectAccount = component.get("v.projectAccount");
        var self = this;
        //var bodyText = projectAccount.hasServiceTarget ? '<p>Warning: This account has Target(s) associated with it. <br/><br/> Are you sure that you want to remove the account?</p>' : '<p>Are you sure that you want to remove the account?</p>'; 
        var bodyText='';
        var prompt = component.find('messageBox');                
        
        if(projectAccount.hasServiceTarget){
            //alert('Warning: This account has Target(s) associated with it.Please remove the Target(s) before deleting the account.'); 
            bodyText =  'This account has Target(s) associated with it.Please remove or re-associate the Target(s)  before deleting the account.';  
            self.showToast(bodyText, 'error');
        }
        else if (projectAccount.hasAccountSpecificServiceQuestion){            
            bodyText =  'This account has Survey Question(s) associated with it.Please remove or re-associate the Survey Question(s)  before deleting the account.';  
            self.showToast(bodyText, 'error');
        }
        else{
            bodyText =  '<p>Are you sure that you want to remove the account?</p>'; 
            prompt && prompt.show({
                id: 'removeAccount',
                title: 'Remove Account',
                body: bodyText,
                positiveLabel: 'Confirm',
                negativeLabel: 'No',
                severity: 'error'
        	});

        }
                
        
    },
    gotoDetail: function(cmp, evt) {
        var plId = evt.getParam('context');
        var navEvt = $A.get("e.force:navigateToSObject");
        navEvt.setParams({
            "recordId": plId
        });
        navEvt.fire();
    },
    makePrimaryAccount: function(cmp, evt) {
        var projectAccount = cmp.get("v.projectAccount");
        var action = cmp.get("c.makeAcctPrimary");
        action.setParams({
            "ProjectAccountId": projectAccount.id
        });
        var self = this;
        action.setCallback(this, function(response) {

            var state = response.getState();
            var msg = '';

            var result = JSON.parse(response.getReturnValue());

            if (state === 'SUCCESS') {
                var result = JSON.parse(response.getReturnValue());
                msg = result.Message;
                self.showToast('Successfully set primary account', 'success');
            }


            if (state === 'ERROR') {
                var errors = response.getError();
                if (!!errors && !!errors[0] && !!errors[0].message) {
                    msg = errors[0].message;
                } else {
                    msg = 'The system run into an unknown error.';
                }
                self.showToast('Error setting primary account: ' + msg, 'error');
            }


            console.log(result);

            var appEvent = $A.get("e.c:ProjectAccountChange");
            appEvent.setParams({ "state": result.State });
            appEvent.setParams({ "message": result.Message });
            console.log(appEvent);
            appEvent.fire();
        });

        $A.enqueueAction(action);
    },
    showToast: function(message, type) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "message": message,
            "type": type
        });
        toastEvent.fire();
    },

})