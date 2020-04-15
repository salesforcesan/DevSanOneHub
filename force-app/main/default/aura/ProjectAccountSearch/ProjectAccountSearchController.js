({
    
    doInit: function(component, event, helper) {
        helper.init(component, event, helper);
        helper.getNameSpace(component, event, helper);
        
    },
    close: function(component, event, helper) {
        var userevent = component.getEvent('closeDialogEvent')
        userevent.fire();
    },
    
    handleClick: function(component, event, helper) {
        var checkbox = event.toElement;
        var checked = checkbox.checked;
        var AccountId = checkbox.id.substring(7);
        component.set("v.AccountId", AccountId);
        debugger;
    },
    
    
    addAccount: function(component, event, helper) {
        
        var selectedItemId = component.find("searchText");
        var accounts = component.get("v.accounts");
        var AccountId = component.get("v.AccountId");
        var projectId = component.get("v.projectId");
        var action = component.get("c.AddAccount");
        console.log("projectId", projectId);
        console.log(accounts, "accounts");
        console.log(selectedItemId.get("v.value"), "searchText");
        
        var accountStrings = [];
        
        if (selectedItemId.get("v.value")) {
        	accountStrings.push(selectedItemId.get("v.value"));
        }
        /*
        accounts.forEach(function(element) {
            if (element.Id === selectedItemId.get("v.value"))  {
                accountStrings.push(element.Id); 
            }
            //if (element.Selected) { accountStrings.push(element.Id); }
        });
        */
        
        action.setParams({
            "accounts": accountStrings,
            "projectId": projectId
        });
        //alert(accountStrings);
        if (accountStrings == null || accountStrings == '') {
            return;
        }
        
        action.setCallback(this, function(response) {
            var result = JSON.parse(response.getReturnValue());
            var userevent = component.getEvent('closeDialogEvent')
            userevent.fire();
            
            var appEvent = $A.get("e.c:ProjectAccountChange");
            appEvent.setParams({ "state": result.State });
            appEvent.setParams({ "message": result.Message });
            console.log(appEvent);
            // appEvent.fire();
            $A.util.addClass(component.find("addAccountSpinner"), "slds-hide");
        });
        
        $A.enqueueAction(action);
        
    },
    
    
    handleSearch: function(component, event, helper) {
        helper.projectHandleSearch(component, event, helper);
    }
})