({
    doInit: function(component, event, helper) {
        var projectId = component.get("v.projectId");
        component.set("v.securityelements", "ProjectAccount__c.Add,ProjectAccount__c.Delete");
        
        helper.refreshAccountList(component, event, projectId);
        helper.getNameSpace(component, event, helper);
      
        
    },
    refreshProjectAccounts: function(component, event, helper) {
        var projectId = component.get("v.projectId");
        component.set("v.securityelements", "ProjectAccount__c.Add,ProjectAccount__c.Delete");
        helper.refreshAccountList(component, event, projectId);
        
    },
    addAccount: function(component, event, helper) {
        
        helper.addAccount(component);
        
    }
})