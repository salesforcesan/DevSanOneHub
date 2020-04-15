({
    refreshAccountList: function(component, event, projectId) {
        this.showSpinner(component);
        var action = component.get("c.GetProjectAccount");
        action.setParams({
            "projectId": projectId
        });
        
        var self = this;
        action.setCallback(self, function(response) {
            var ProjectAccounts = response.getReturnValue();
            component.set("v.ProjectAccounts", ProjectAccounts);
            this.hideSpinner(component);
            if (event) {
                var state = event.getParam("state");
                var message = event.getParam("message");
                var notification = component.find("projectAccountNotification");
                if (state) {
                    //Toasts are now shown in the card itself.
                    //self.showToast(message, state.toLowerCase());
                }
            }
        });
        $A.enqueueAction(action);
    },
    addAccount: function(component) {
        
        this.showSpinner(component);
        var selectedItemId = component.find("searchText");
        var projectId = component.get("v.projectId");
        var action = component.get("c.AddAccount");
        console.log("projectId", projectId);
        console.log(selectedItemId.get("v.value"), "searchText");
        
        var accountStrings = [];
        
        if (selectedItemId.get("v.value")) {
            accountStrings.push(selectedItemId.get("v.value"));
        }
        else
        {
            
            this.hideSpinner(component);
            return;
        }
        
        action.setParams({
            "accounts": accountStrings,
            "projectId": projectId
        });
        //alert(accountStrings);
        if (accountStrings == null || accountStrings == '') {
            return;
        }
        var self = this;
        action.setCallback(this, function(response) {
            var message;
            var state = response.getState();
            var result = JSON.parse(response.getReturnValue());
            this.hideSpinner(component);            
            
            if (state === "SUCCESS") {
                //NEED TO REVISIT 
                //Just calling the refreshAccountList method is not refreshing
                //the cards list. In fact it is rendering before the
                //value is being set and is clearing out the cards
                //list
                component.find("searchText").set("v.value",'');
                message = 'Successfully added account to project';
                self.showToast(message, 'success');
                
                var appEvent = $A.get("e.c:ProjectAccountChange");
                appEvent.setParams({ "state": state.toLowerCase() });
                appEvent.setParams({ "message": message });
                appEvent.fire();
            }
            else
            {
                var errors = response.getError();
                if (errors[0] && errors[0].message) // To show other type of exceptions
                    message = errors[0].message;
                if (errors[0] && errors[0].pageErrors) // To show DML exceptions
                    message = errors[0].pageErrors[0].message;                
                if (message.includes('duplicate'))
                {
                    self.showToast('Error adding account: Account already exists ', 'error');
                }
                else
                {
                    self.showToast('Error adding account: ' + message, 'error');
                }
                
            }
            
        });
        $A.enqueueAction(action);
    },
    showSpinner: function(component) {
        
        var spinner = component.find("projectAccountSpinner");
        $A.util.removeClass(spinner, "slds-hide");
        
    },
    hideSpinner: function(component) {
        var spinner = component.find("projectAccountSpinner");
        $A.util.addClass(spinner, "slds-hide");
    },
    showToast: function(message, type) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "message": message,
            "type": type
        });
        toastEvent.fire();
    },
    getNameSpace: function(cmp) {
        var action = cmp.get("c.getNamespaceApex");
        var self = this;
        action.setCallback(self, function(result) {
            cmp.set("v.ns", result.getReturnValue());  
            cmp.set("v.lawsonAccountField", result.getReturnValue() + 'CMKOneHubAccountID__c');  
        });
        $A.enqueueAction(action);
    },
})