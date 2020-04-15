({
    init : function(component, event, helper) {
		var searchText = component.find("searchText").get("v.value"); 
        console.log(searchText);
        console.log('iam inside++++++++++++++');
        var action = component.get("c.GetAccounts");
        
        action.setParams({            
            "searchText" : searchText,
            "projectid" : null,
            "getAll" : true
        });
        var self = this;
        action.setCallback(self, function(result) {
            console.log(result.getReturnValue(), "c.GetAccounts");
            component.set("v.accounts", result.getReturnValue());
            $A.util.addClass(component.find("addAccountSpinner"), "slds-hide"); 
        });
        $A.enqueueAction(action);
        
        
	},
    getNameSpace: function(cmp) {
        var action = cmp.get("c.getNamespaceApex");
        var self = this;
        action.setCallback(self, function(result) {
            cmp.set("v.ns", result.getReturnValue());            
        });
        $A.enqueueAction(action);
    },
    projectHandleSearch: function(component, event, helper)
    {
          var searchText = component.find("searchText").get("v.value"); 
        if (searchText == null || searchText == '') {
            this._showToast(component,event);
            return;
        }
        
        var replacedSearchText = searchText.indexOf('\'') >= 0 ? searchText.replace("'","\\'"):searchText;
        console.log(replacedSearchText);
        var action = component.get("c.GetAccounts");
        var button = event.getSource();
		var projectId = component.get("v.projectId");
        
        action.setParams({            
            "searchText" : replacedSearchText,
            "projectid" : projectId
        });
        
        button.set("v.disabled",true); // Disable the button while we execute the search
        
        action.setCallback(this,function(response){   
            var accounts = response.getReturnValue();
            if(accounts.length == 0)
            {                
                component.set("v.showNoResultsMessage",true);               
            }
            else
            {
                component.set("v.showNoResultsMessage",false);
            }
            component.set("v.accounts",accounts); 
            
            button.set("v.disabled",false); // Enable the button when search returns
            
        });
        
        $A.enqueueAction(action);
    },
    _showToast : function(component, event) {
    var toastEvent = $A.get("e.force:showToast");
    toastEvent.setParams({
        "title": "Account Search",
        "type": "warning",
        "message": "Please enter Account name"
    });
    toastEvent.fire();
 }

    
	
})