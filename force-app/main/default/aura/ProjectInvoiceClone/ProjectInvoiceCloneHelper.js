({
    NOTIFICATION_TYPES: {
        'ERROR': 'error',
        'INFO': 'info',
        'WARNING': 'warning',
        'SUCCESS': 'success'
    },    
    loadProjectInvoiceCloneReasons : function(cmp){                
        
       var action = cmp.get("c.GetProjectInvoiceCancelReasons");
        var opts = [];   
        this.showSpinner(cmp);
        action.setCallback(this, function(response) {
           
            for(var i=0;i< response.getReturnValue().length;i++){
                opts.push({"class": "optionClass", label: response.getReturnValue()[i], value: response.getReturnValue()[i]});
            }
                        
            cmp.set("v.clonereasons", opts);
            this.hideSpinner(cmp);
        });
        $A.enqueueAction(action);                
    },    
    getProjectInvoiceDetails : function(cmp){                
        var action = cmp.get("c.GetProjectInvoice");
        console.log('Project Id: ' + cmp.get("v.recordId"));
        
        action.setParams({
            Id :cmp.get("v.recordId"),
        });
        
        this.showSpinner(cmp);
        action.setCallback(this, function(response) {

            cmp.set("v.projectInvoice", response.getReturnValue());
            this.hideSpinner(cmp);
        });
        $A.enqueueAction(action);                
    },    
    CancelClicked : function(component, event, helper) {
        var dismissActionPanel = $A.get("e.force:closeQuickAction");
        dismissActionPanel.fire();        
        
    },
    CloneProjectInvoice : function(component, event, helper) {
        
        var projectInvoice = component.get("v.projectInvoice");
        var reasonCode = component.find("projectInvoiceCloneReasonCode").get("v.value");
                
        var action = component.get("c.CloneProjectInvoice");
        var Id = component.get("v.recordId");
        action.setParams({
            "Id": Id,
            "reasonCode" : reasonCode,
            "comments" : projectInvoice.CloneReasonComment
        });    
        
        helper.callServerAction(component,event,helper,action);
        
    },
    callServerAction:  function(component,event,helper,action)    
    { 
        var self = this;  
        helper.showSpinner(component);
        component.set("v.callbackresult","NONE");    
        var cloneId;
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (!component.isValid())
                return;
            
            component.set("v.callbackresult",state);    
            
            if (state === "SUCCESS") {                
                helper.hideSpinner(component);
                cloneId = response.getReturnValue();
                               
                //var responseWrapper = JSON.parse(response.getReturnValue());                
                
                //if(responseWrapper.State==="SUCCESS"){
                //if (responseWrapper.Message != '' && responseWrapper.Message != null)
                //{
                component.set("v.callbackmessage","SUCCESS");
                //}
                //}
                //else{
                //        component.set("v.callbackresult","ERROR");          
                //}                
            }
            else if (state === "INCOMPLETE") {
                helper.hideSpinner(component);
                //console.log('do something here');
            } else if (state === "ERROR") {
                helper.hideSpinner(component);
                var errors = response.getError();                
                if (errors) {
                    if (errors[0] && error[0].message) {    
                        component.set("v.callbackmessage",errors[0].message);
                    }
                } else {
                    component.set("v.callbackmessage",'Unhandled Exception occurred:\r\nContact Administrator');
                }
            }
            self.closeActionDialog(component,cloneId);
        });
        
        $A.enqueueAction(action);  
    },
    showSpinner: function(cmp){
        var spinner = cmp.find("spinner");
        $A.util.removeClass(spinner, "slds-hide"); 
    },
    hideSpinner: function(cmp){
        var spinner = cmp.find("spinner");
        $A.util.addClass(spinner, "slds-hide"); 
    },
    closeActionDialog: function(component,cloneId){
        var self = this;
        window.setTimeout(
            $A.getCallback(function() {
                self.CancelClicked(component);                
                self.navigateToRecord(component,cloneId);
                //self.gotoDashboard();
            }), 2000
        );                     
    },
    navigateToRecord : function(component, cloneId) {        
         var navEvent = $A.get("e.force:navigateToSObject");
         navEvent.setParams({
              recordId: cloneId,
              slideDevName: "detail"
         });
         navEvent.fire(); 
    },
    gotoDashboard : function () {
        var evt = $A.get("e.force:navigateToComponent");
        evt.setParams({
            componentDef: "c:ProjectDashboardLayout",
            componentAttributes: {}
        });
        evt.fire();    
    },
    ApexQueueSize : function(component) {
        var action = component.get("c.CheckApexQueueSize");
        var self = this;
        
        action.setCallback(self, function(result) {
            console.log('~~');
            console.log('~g~'+ result.getState());
            console.log('~rtn~'+result.getReturnValue());
            
            
            var state = result.getState();
            if (!component.isValid())
                return;
            component.set("v.callbackresult",state); 
            
            if (state === "SUCCESS") { 
                component.set("v.isClonable", result.getReturnValue());
                
                if(!result.getReturnValue()){
                    component.set("v.callbackmessage",'The max queue limit has been reached for cloning. Please try this function again later.');
                    component.set("v.callbackresult",'ERROR');
                }
                else{
                    component.set("v.callbackresult",state);
                    component.set("v.callbackresult",'NONE');
                }
            }else if (state === "ERROR") {                
                var errors = response.getError();                
                if (errors) {
                    if (errors[0] && error[0].message) {    
                        component.set("v.callbackmessage",errors[0].message);
                    }
                } else {
                    component.set("v.callbackmessage",'Unhandled Exception occurred:\r\nContact Administrator');
                }
            }
        });        
        
        $A.enqueueAction(action);
    }
    
})