({
    CancelClicked : function(component, event, helper) {
        var dismissActionPanel = $A.get("e.force:closeQuickAction");
        dismissActionPanel.fire();
    },    
    isOverridable: function(component,event){
        
        var projectId = component.get("v.recordId");
        var action = component.get("c.checkIfProjectDataAccessOveride");
        action.setParams({
            "projectId": projectId
        });
        var self = this;
        
        action.setCallback(self, function(response) {
            var overrideAccess = response.getReturnValue();
            component.set("v.overrideAccess", overrideAccess);
            
            this.hideSpinner(component);

        });
        $A.enqueueAction(action);
    },
    getProjectAccountServiceAccessList: function(component, event, projectId){    
        
        this.showSpinner(component);
        
        var action = component.get("c.GetProjectAccountServiceAccessList");
        action.setParams({
            "projectId": projectId
        });
        
        var self = this;
        action.setCallback(self, function(response) {
            var projectAccoutServiceAcesses = response.getReturnValue();
            
            component.set("v.ProjectAccoutServiceAcesses", projectAccoutServiceAcesses.PASDataAccess);
            component.set("v.ProjectServices", projectAccoutServiceAcesses.ServiceList);
            
            this.hideSpinner(component);          
			
        });
        $A.enqueueAction(action);
    },
    refreshDataAccessList: function(component, event){
        
        var ProjectAccoutServiceAcesses = component.get('v.ProjectAccoutServiceAcesses');
		var ProjectServices = component.get('v.ProjectServices');        
        
        if (ProjectAccoutServiceAcesses == undefined || ProjectServices == undefined) {return;}
        
        var rowLength = ProjectAccoutServiceAcesses.length;
        var horizontalLength = ProjectServices.length;        

        for(var i = 0; i < rowLength; i++) {           
            
            var selected = true;
                        
            for(var j = 0; j < horizontalLength; j++) {  
                
                if (ProjectAccoutServiceAcesses[i] != null && ProjectAccoutServiceAcesses[i].ProjectAccountService[j] != null)
                {
                    if (ProjectAccoutServiceAcesses[i].ProjectAccountService[j].Access == false)
                    {
                        selected = false;
                    }
                }
            }
            
            //To set checkbox value of Row check box
            if (component.find("checkboxR") != undefined)
            {                
                if (Array.isArray(component.find("checkboxR"))) {
                    var myLabel = component.find("checkboxR")[i];
                    myLabel.set("v.value", selected);
                }else
                {
                    component.find("checkboxR").set("v.value", selected);
                }
            }
        }        
        
        for(var i = 0; i < horizontalLength; i++) {           

            var selectedC = true;            
            for(var j = 0; j < rowLength ; j++) {                  
                
                if (ProjectAccoutServiceAcesses[j] != null && ProjectAccoutServiceAcesses[j].ProjectAccountService[i] != null)
                {
                    if (ProjectAccoutServiceAcesses[j].ProjectAccountService[i].Access == false)
                    {
                        selectedC = false;
                    }
                }                
            }
            
            //To set checkbox value of Row check box
            if (component.find("checkboxC") != undefined)
            {  
                if (Array.isArray(component.find("checkboxC"))) {
                    myLabel = component.find("checkboxC")[i];
                    myLabel.set("v.value", selectedC);
                }else
                {
                    component.find("checkboxC").set("v.value", selectedC);
                }
            }
        }
    },
    save: function(component, event){
        
        var self = this;
        var dataAccessList = component.get("v.ProjectAccoutServiceAcesses");
        var action = component.get('c.saveDataAccess');                
        var projectId = component.get('v.recordId');
        
        self.showSpinner(component);       
        
         action.setParams({
            "projectId": projectId,
             "dataAccessList": JSON.stringify(component.get("v.ProjectAccoutServiceAcesses")),
             "overrideAccess": component.get('v.overrideAccess')
        });
            
        action.setCallback(this, function(response) {
            
            var result = JSON.parse(response.getReturnValue());

            var state = response.getState();     
            
            // To show the error on failure.
            component.set('v.callbackmessage',result.Message);
            component.set('v.callbackresult',result.Data);   
            
            if (result.Data === 'SUCCESS') {
                
                // To close the model dailog on successful save.                    
                self.closeActionDialog();                    
            }
            
            self.hideSpinner(component);
        });
        
        $A.enqueueAction(action);
    },
    closeActionDialog: function(component){
        var self = this;
        window.setTimeout(
            $A.getCallback(function() {
                self.CancelClicked(component);                
            }), 2000
        );                     
    },
    saveDataAccess: function(component, event, helper){

        this.showSpinner(component);
        var action = component.get("c.SaveDataAccess");        
        
        var self = this;
        action.setCallback(self, function(response) {            
            this.hideSpinner(component);
        });
        $A.enqueueAction(action);
        
    },
    showToast: function(message, type, mode) {
        if (typeof mode === 'undefined') {
            mode = 'dismissible';
        }
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "message": message,
            "type": type,
            "mode": mode
        });
        toastEvent.fire();
    },    
    showSpinner: function(component) {
        var spinner = component.find("projectAccountSpinner");
        $A.util.removeClass(spinner, "slds-hide");
    },
    hideSpinner: function(component) {
        var spinner = component.find("projectAccountSpinner");
        $A.util.addClass(spinner, "slds-hide");
    },
    
})