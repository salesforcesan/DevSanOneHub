({
    getActiveGroupedInvoices : function(component, event, invoice) {
        this.showSpinner(component);
        //var initialRows = component.get('v.initialRows');
        var action = component.get("c.getActiveGroupedInvoicesApex");
        action.setCallback(this, function(response){
            this.hideSpinner(component);
            var state = response.getState();
            if(state === 'SUCCESS'){ 
                var res = JSON.parse(response.getReturnValue());
                if(!$A.util.isEmpty(res)) {
                  res.map(item => item.Selected = false);
                  component.set("v.availableGroupedInvoices", res);   
                }   
            } else if (state === 'ERROR'){
                this.errorMessage(component, 'Error', response);
            }
        });
        $A.enqueueAction(action);
        
    },
    getNameSpace: function(cmp) {
        var action = cmp.get("c.getNamespaceApex");
        action.setCallback(this, function(response) {
            if($A.util.isEmpty(response.getReturnValue())){
                cmp.set("v.ns", ''); 
            } else {
                cmp.set("v.ns", response.getReturnValue()); 
            	console.log('ns: ', response.getReturnValue());
            }

        });
        $A.enqueueAction(action);
    },
    getInvoices : function(component, event, invoice) {
        this.showSpinner(component);
        //var initialRows = component.get('v.initialRows');
        var invoiceId = invoice;
        var allAvailable = component.get('v.availableGroupedInvoices');
        var action = component.get("c.getAvailableInvoicesforGroupedInvoiceApex");
        action.setParams({
            'groupedInvoiceId': invoice,
        });
        action.setCallback(this, function(response){
            this.hideSpinner(component);
            var state = response.getState();
            if(state === 'SUCCESS'){  
                var res = JSON.parse(response.getReturnValue());
                if(!$A.util.isEmpty(res)) {
                    var current = [];
                    var currentIds = [];
                    var allInvoices = [];
                    res.forEach(function(item) {
                         if(item.GroupedProjectInvoice === invoice) {
                        	currentIds.push(item.Id);
                            current.push(item);
                    	} else{
                        	allInvoices.push(item);
                        }
                    	return item;
                	});
                    if(!$A.util.isEmpty(current)){
                        current.forEach(item => allInvoices.unshift(item));
                    };
                	
                    allAvailable.forEach(item => item.Id === invoice ? item.Selected = true : item.Selected = false); 
                    allInvoices.forEach(item => item.recordLink = '/'+ item.ProjectId);
                    
                    component.set('v.availableGroupedInvoices', allAvailable)
                    component.set('v.selectedGroup', invoice);                    
                    component.set("v.invoices", allInvoices);
                   
                    if(!$A.util.isEmpty(currentIds)){
                        console.log('current: ', current);
                        component.set('v.selectedInvoices', current);
                        component.set('v.initialGroupedCount', currentIds.length);    
                        component.set('v.selectedRows', currentIds);
                        component.set('v.selectedRowsCount', currentIds.length);
                    }
                  
                    console.log('selected default', component.get('v.selectedRows'));
                   
                }  else {
                    component.set('v.selectedGroup', '');
                }         
            } else if (state === 'ERROR'){
                this.errorMessage(component, 'Error', response);
            }
        });
        $A.enqueueAction(action);
        
    }, 
    
    updateGroupedInvoice : function(component, event, invoiceIds, groupedId) {
        this.showSpinner(component);
        //var initialRows = component.get('v.initialRows');
        var action = component.get("c.getInvoicesApex");
        action.setParams({
            'invoiceIds':invoiceIds,
            'groupedInvoiceId': groupedId,
        });
        action.setCallback(this, function(response){
            this.hideSpinner(component);
            var state = response.getState();
            if(state === 'SUCCESS'){  
                 this.showToast('Success','You successfully grouped the invoices','success' ); 
                 //this.getInvoices(component, event, groupedId);
                 this._navigateHandler(component, groupedId);
                 //this._closeActionDialog(component);
            } else if (state === 'ERROR'){
                this.errorMessage(component, 'Error', response);
            }
        });
        $A.enqueueAction(action);
        
    },
    
    showToast : function(title, message, type) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "message": message,
            "type": type
        });
        toastEvent.fire();
    },
    
   errorMessage: function(cmp, messageTitle, response) {
        var message;
        console.log(response.getError());
        var errors = response.getError();
        if (errors[0] && errors[0].message) // To show other type of exceptions
            message = errors[0].message;
        if (errors[0] && errors[0].pageErrors) // To show DML exceptions
            message = errors[0].pageErrors[0].message;
        
        this.showToast(messageTitle, message, 'error');  
    },
    

    sortData: function (cmp, fieldName, sortDirection, invoices) {
        var reverse = sortDirection !== 'asc';
        invoices.sort(this.sortBy(fieldName, reverse))
        return invoices;
    },
    
    sortBy: function (field, reverse, primer) {
        var key = primer ?
            function(x) {return primer(x[field])} :
        function(x) {return x[field]};
        reverse = !reverse ? 1 : -1;
        return function (a, b) {
            return a = key(a)?key(a):'', b = key(b)?key(b):'', reverse * ((a > b) - (b > a));
        }
    },
    
    showSpinner: function(component) {
        var spinner = component.find("lilspin");
        $A.util.removeClass(spinner, "slds-hide");
    },
    
    hideSpinner: function(component) {
        var spinner = component.find("lilspin");
        $A.util.addClass(spinner, "slds-hide");
    },
    
    _closeActionDialog: function(cmp) {
        var dismissActionPanel = $A.get("e.force:closeQuickAction");
        dismissActionPanel.fire();
    },
     _navigateHandler: function(cmp, recordId) {
        var ns = cmp.get('v.ns');
        var navService = cmp.find("navService");
        // Sets the route to /lightning/o/Account/home
        navService.navigate({
           type: 'standard__recordPage',
            attributes: {
                objectApiName: ns + 'ProjectInvoice__c',
                recordId: recordId,
                actionName: 'view'
            }
        }, true); 
    },
    createGroupedInvoice: function(cmp, event){
        var ns = cmp.get('v.ns');
        var groupedInvoice = $A.get("e.force:createRecord");
        if($A.util.isEmpty(ns)) {
        	groupedInvoice.setParams({
                "entityApiName": "ProjectInvoice__c",
                "defaultFieldValues": {
                    'IsGroupedInvoice__c' : true,
                    'Status__c' : 'Created',
                    'Description__c' : 'My New Grouped Invoice Description'
                }
            });   
        } else {
            groupedInvoice.setParams({
                "entityApiName": "CMKOneHub__ProjectInvoice__c",
                "defaultFieldValues": {
                   'CMKOneHub__IsGroupedInvoice__c' : true,
                    'CMKOneHub__Status__c' : 'Created',
                    'CMKOneHub__Description__c' : 'My New Grouped Invoice Description'
                }
            });  
        }

        groupedInvoice.fire();
    }
    
})