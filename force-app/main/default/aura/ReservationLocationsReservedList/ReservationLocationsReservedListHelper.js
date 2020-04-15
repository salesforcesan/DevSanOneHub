({
	AppSettings: {
        'Actions': {
            'getReservations': 'getReservationLocations',
            'cancelReservations': 'unreserveLocationsApex',
            'GetChunkSize': 'getChunkSize'
        }
    },
    
     getDataHelper: function(component, event) {
        this.showSpinner(component);
        var reservationId = component.get('v.recordId');
        this.getDispatcher(component)
            .action(this.AppSettings.Actions.getReservations)
            .onSuccess(this.handleglnSuccess)
            .onError(this.handleglnError)
            .run({ "reservationId": reservationId, 
            });
    },

    handleglnSuccess: function(component, response, helper) {
        this.hideSpinner(component);
        component.set("v.data", response);
        component.set("v.filterData", response);
        console.log('reserved data: ', component.get('v.data'));
    },
    
    handleglnSuccessCancel: function(component, response, helper) {
        this.hideSpinner(component);
        component.set("v.data", response);
        component.set("v.filterData", response);
        $A.get('e.force:refreshView').fire();
        console.log('reserved data: ', component.get('v.data'));
    },
   
    handleglnError: function(component, error) {
       this.hideSpinner(component);
       this.onError(component, error);
    },

    cancelLocations: function(component, reservationId, data ) {
        this.showSpinner(component);
        var reservationId = component.get('v.recordId');
        this.getDispatcher(component)
            .action(this.AppSettings.Actions.cancelReservations)
            .onSuccess(this.handleglnSuccessCancel)
            .onError(this.handleglnError)
            .run({ "reservationId": reservationId,
            	   "reservationData" : JSON.stringify(data)
            });
    },
        
    sortData: function (cmp, fieldName, sortDirection) {
        var data = cmp.get("v.data");
        var reverse = sortDirection !== 'asc';
        data.sort(this.sortBy(fieldName, reverse))
        cmp.set("v.data", data);
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
    
     fetchData: function(component , rows){
        return new Promise($A.getCallback(function(resolve, reject) {
            var action = component.get('c.getReservationLocations');
            var counts = component.get("v.currentCount");
            action.setParams({
                "reservationId": component.get('v.recordId'),
                "limits": component.get("v.initialRows"),
                "offsets": counts 
            });
            action.setCallback(this, function(a) {
                resolve(a.getReturnValue());
                var countstemps = component.get("v.currentCount");
                countstemps = countstemps+component.get("v.initialRows");
                component.set("v.currentCount",countstemps);
                
            });
            $A.enqueueAction(action);
            
            
        }));
        
    },
    handleSearch: function(component, event, helper) {
        let search = component.find("search").get("v.value");
        const data = component.get('v.filterData');
        if (!search || search == '') {
            component.set('v.data', data);
        }
        const filterByValue = (array, string) => 
         array.filter(values =>
            Object.keys(values).some(item => values[item].toString().toLowerCase().includes(string.toLowerCase())
         ));
        
        var filteredList = filterByValue(data, search);
        console.log(filterByValue(data, search)); 
        component.set('v.data', filteredList); 
    },
    
    getNameSpace: function(cmp) {
        var action = cmp.get("c.getNamespaceApex");
        var self = this;
        action.setCallback(self, function(result) {
            cmp.set("v.ns", result.getReturnValue()); 
            var namespace = cmp.get('v.ns');
            var targetFields = [namespace + 'RequestedLocations__c', namespace + 'RetailerAccount__c',namespace + 'RequestedDate__c'];
            cmp.set('v.targetFields', targetFields);
            cmp.get('v.targetFields');
        });
        $A.enqueueAction(action);
    },
     showSpinner: function(component) {
        var spinner = component.find("reserveSpinner");
        $A.util.removeClass(spinner, "slds-hide");
    },

    hideSpinner: function(component) {
        var spinner = component.find("reserveSpinner");
        $A.util.addClass(spinner, "slds-hide");
    },
})