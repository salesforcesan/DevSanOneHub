({	
    HttpRequest: {
        'className': 'ProjectSubmitRequestModel',
        'methods': {
            'get': 'get',
            'submitProject': 'modify'
        }
    },

    init: function(cmp) {
        this.getProjectValidations(cmp);
    },
            
    getProjectValidations: function(cmp) {
        this.showSpinner(cmp);
        var projectId = cmp.get("v.recordId");
        this.getDispatcher(cmp)
        .className(this.HttpRequest.className)
        .action(this.HttpRequest.methods.get)
        .body({"projectId": projectId})
        .onSuccess(this.handleValidationSuccess)
        .onError(this.handleErrors)
        .run();
    },
       
    handleValidationSuccess: function(cmp, response) { 
	// expected response info returning format
       /*response = {
            "status": 'OK',
            "errors": [],
            "warnings": [],
            "accounts": [],	
            "services": [],		
            "locations": [],
            "jobs": [],	
            "surveys": [],	
        }*/
		this.hideSpinner(cmp);
        cmp.set('v.isLoaded',true);
        if(!$A.util.isEmpty(response)) {
            cmp.set('v.status', response.status);
            if(!$A.util.isEmpty(response.errors)) {
                cmp.set('v.errors', response.errors)
            };
            if(!$A.util.isEmpty(response.warnings)) {
                cmp.set('v.warnings', response.warnings)
            };
            if(!$A.util.isEmpty(response.accounts)) {
                cmp.set('v.accountErrors', response.accounts);
            }
            if(!$A.util.isEmpty(response.services)) {
                cmp.set('v.serviceErrors', response.services);
            }
            if(!$A.util.isEmpty(response.locations)) {
                cmp.set('v.locationErrors', response.locations);
            }
            if(!$A.util.isEmpty(response.jobs)) {
                cmp.set('v.jobErrors', response.jobs);
            }
            if(!$A.util.isEmpty(response.surveys)) {
                cmp.set('v.surveyErrors', response.surveys);
            }
        }
    },
    
    handleErrors: function(cmp, error) {
        this.hideSpinner(cmp);
        this.showToast('Error', error, 'error');
        //this.onError(cmp, error);
    }, 
    
    notifyProjectUpdate: function(cmp) {
        this.showSpinner(cmp);
        var projectId = cmp.get("v.recordId");
        this.getDispatcher(cmp)
        .className(this.HttpRequest.className)
        .action(this.HttpRequest.methods.submitProject)
        .body({"projectId": projectId})
        .onSuccess(this.handleGetProjectSuccess)
        .onError(this.handleErrors)
        .run();
    },
    
    handleGetProjectSuccess: function(cmp,response){
          console.log('----success----');
         this.hideSpinner(cmp);
         if(!$A.util.isEmpty(response)) {
            cmp.set('v.status', response.status);
            if(response.status == 'ERROR') {
                if(!$A.util.isEmpty(response.errors)) {
                	cmp.set('v.errors', response.errors)
          		}
            } else {
                this.publishAppRefreshEvent(cmp);
         		$A.get("e.force:closeQuickAction").fire(); 
            }    
        } 
    },

    publishAppRefreshEvent: function(cmp) {
        var refreshAppEvent = $A.get("e.c:EventProjectRefresh");
        refreshAppEvent.fire();
        $A.get('e.force:refreshView').fire();
    },
        
    CloseActionModal : function(cmp) {
		var dismissActionPanel = $A.get("e.force:closeQuickAction");
        dismissActionPanel.fire();        
    },
    
    showToast : function(title, message, type) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "message": message,
            "type": type
        });
        toastEvent.fire();
    },
    
    showSpinner: function(component) {
        var spinner = component.find("submitSpinner");
        $A.util.removeClass(spinner, "slds-hide");
    },

    hideSpinner: function(component) {
        var spinner = component.find("submitSpinner");
        $A.util.addClass(spinner, "slds-hide");
    },
})