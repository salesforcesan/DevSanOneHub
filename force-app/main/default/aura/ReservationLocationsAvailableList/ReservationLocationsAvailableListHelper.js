({
    AppSettings: {
        'Actions': {
            'GetLocations': 'getLocationsApex',
            'GetLocationsByNumber': 'getLocationsByNumberApex',
            'GetLocationsByList': 'getLocationsByListApex',
            'ReserveLocations': 'reserveLocationsApex',
            'GetLocationsCount': 'getTotalLocationsApex',
            'GetResolutionLocations': 'getAlternateReservationOptions',
            'GetReservationDetails': 'GetReservation',
            'GetChunkSize': 'getChunkSize'
        }
    },
    getLocations: function(component, reservationid, requestedcount, requesteddate, filters, uploadJSON) {
        this.showSpinner(component);
        this.getDispatcher(component)
        .action(this.AppSettings.Actions.GetLocations)
        .onSuccess(this.handleglnSuccess)
        .onError(this.handleglnError)
        .run({ "reservationId": reservationid, 
              "maxCount": requestedcount, 
              "requestedDate": requesteddate,
              "advancedFilters": filters,
              "reservationData": uploadJSON
             });
    },
    
    getLocationsByNumber: function(component, reservationid, requestedcount, requesteddate, filters) {
        
        this.showSpinner(component);
        this.getDispatcher(component)
        .action(this.AppSettings.Actions.GetLocationsByNumber)
        .onSuccess(this.handleglnSuccess)
        .onError(this.handleglnError)
        .run({ "reservationId": reservationid, 
              "maxCount": requestedcount, 
              "requestedDate": requesteddate,
              "advancedFilters": filters
             });
    },
    
    
    handleglnSuccess: function(component, response, helper) {
        this.hideSpinner(component);
        component.set("v.data", response);
        let data = component.get('v.data');
        const errors = data.filter(function(item){ return item.ReservationErrorCode != '' });
        const dataNew = data.filter(function(item){ return item.ReservationErrorCode == '' || !item.ReservationErrorCode});
        errors.sort(function(a, b) {
            return (a.IsResolvable > b.IsResolvable) ? -1 : (a.IsResolvable < b.IsResolvable) ? 1 : 0;
        });
        component.set('v.data', dataNew);
        component.set('v.errorData', errors);
        if(dataNew.length == 0 ) {
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({ "type": "error", "message":'There are no clubs available on this date that meet your criteria' });
            toastEvent.fire();
            return;
        }
        
        
        console.log('data: ', dataNew);
        const findVal = dataNew.find(item => item.NumberofWarningMessages > 0);
        if (findVal) {
            const dataMappedWarnings = dataNew.map(item => {
                item.NumberofWarningMessages > 0 ? (item.iconValue = 'utility:warning', 
                item.variantValue = 'destructive',
                item.disabledValue = false) : 
                (item.iconValue ='utility:success',
                 item.disabledValue = true, 
                 item.variantValue = 'base',
                 item.NumberofWarningMessages = null
                );
            });
            
            component.set('v.columns', [     
                {label: 'Club #', fieldName: 'LocationNumber', type: 'text',sortable:true},	
                {label: 'Address', fieldName: 'LocationAddress', type: 'text',sortable:true},
                {label: 'City', fieldName: 'LocationCity', type: 'text',sortable:true},
                {label: 'State', fieldName: 'LocationState', type: 'text',sortable:true},
                {label: 'Available', fieldName: 'AvailableCapacity', type: 'text',sortable:true,}, //'utility:warning'
                {type: 'button', label:'Warnings', sortable:true, fixedWidth:"200px", typeAttributes: { iconName: {fieldName:'iconValue'}, label:{fieldName: 'NumberofWarningMessages'}, variant:{fieldName:'variantValue'}, name:'Warnings', disabled:{fieldName:'disabledValue'} }}
            ]);
        }
        
        
        this.toggleFilter(component);
        var availableClubs = component.find('availableClubs');
        var availableElem = availableClubs.getElement();
        availableElem.getAttribute('data-collapsed') === 'true' ? this.toggleAvailable(component) : '';
    },
    
    
    handleglnError: function(component, error) {
        this.hideSpinner(component);
        this.onError(component, error);
    },    
    
    handleglnSuccessReserve: function(component, response, helper) {
        this.hideSpinner(component);
        component.set("v.data", []);
        $A.get('e.force:refreshView').fire();
        this.toggleFilter(component);
    },
    
    handleglnSuccessReserveResolution: function(component, response, helper) {
        this.hideSpinner(component);
        component.set("v.data", []);
        var errorArray = component.get('v.errorData');
        var locationId = component.get('v.locId');
        var newErrorArray = errorArray.filter((item) => item.LocationId != locationId );
        component.set("v.errorData", newErrorArray);
        $A.get('e.force:refreshView').fire();
        this.toggleFilter(component);
    },
    
    handleglnSuccessCount: function(component, response, helper) {
        this.hideSpinner(component);
        component.set("v.totalLocationsCount", response);
    },
    
    getLocationsByList: function(component, reservationId, uploadJson, filters) {
        this.showSpinner(component);
        var upload = JSON.stringify(uploadJson);
        this.getDispatcher(component)
        .action(this.AppSettings.Actions.GetLocationsByList)
        .onSuccess(this.handleglnSuccess)
        .onError(this.handleglnError)
        .run({ "reservationId": reservationId, 
              "reservationData": upload,
              "filters": filters,
             });
        
    },
    getReservationDetails: function(component, reservationId) {
        this.getDispatcher(component)
        .action(this.AppSettings.Actions.GetReservationDetails)
        .onSuccess(this.handlegrdSuccess)
        .onError(this.handlegrdError)
        .run({ "reservationId": reservationId
             });
        
    },
    
    handlegrdSuccess: function(component, response, helper) {
        var reservation = JSON.parse(response);
        reservation.RequestedLocationCount != null ?
            component.set('v.requestedCount', reservation.RequestedLocationCount) :
        component.set('v.requestedCount', 0);
        reservation.RequestedDate != null ? 
            component.set('v.requestedDate', reservation.RequestedDate) : '';
        reservation.RequestedService != null ?
            component.set('v.requestedService', reservation.RequestedService) : '';  
    },
    
    handlegrdError: function(component, error) {
        this.onError(component, error);
    },    
    
    reserveLocations: function(component, reservationId, data) {
        this.showSpinner(component);
        var reserve = JSON.stringify(data);
        this.getDispatcher(component)
        .action(this.AppSettings.Actions.ReserveLocations)
        .onSuccess(this.handleglnSuccessReserve)
        .onError(this.handleglnError)
        .run({ "reservationId": reservationId, 
              "reservationData": reserve
             });
    },
    
    reserveResolutionLocation: function(component, reservationId, data) {
        console.log('calling resolve: ', reservationId + ': data: ', data);
        this.showSpinner(component);
        var reserve = JSON.stringify(data);
        this.getDispatcher(component)
        .action(this.AppSettings.Actions.ReserveLocations)
        .onSuccess(this.handleglnSuccessReserveResolution)
        .onError(this.handleglnError)
        .run({ "reservationId": reservationId, 
              "reservationData": reserve
             });
        
    },
    
    getLocationsCount: function(component, event, retailerAccountId) {
        this.showSpinner(component);
        this.getDispatcher(component)
        .action(this.AppSettings.Actions.GetLocationsCount)
        .onSuccess(this.handleglnSuccessCount)
        .onError(this.handleglnError)
        .run({ "retailerAccountId": retailerAccountId 
             });
    },
    
    uploadClubs: function(component, event, helper) {
        this.showUploadSpinner(component);
        var filters = component.find('searchText').get('v.value');
        component.set('v.filters', filters);
        var date = component.find('requestedDate').get("v.value");
        var reservationId = component.get('v.recordId');
        var file = component.find("upload").getElement().files[0];
        var data;
        if (file) {
            var reader = new FileReader();
            component.set('v.filename', file.name);
            reader.readAsText(file, "UTF-8");
            reader.onload = function (event) {
                var locations = (reader.result || '').split(/\n|\r\n/g); 
                var uploadJson = [];
                
                //var headers = locations[0].split(',');
                var fields = ["LocationNumber","ReservationDate"];
                for(var i = 0; i < locations.length; i++) {
                    var dataNew = locations[i].split(',');
                    var obj = {};
                    for(var j = 0; j < dataNew.length; j++) {
                        obj[fields[j].trim()] = dataNew[j].trim();//.trim()] = dataNew[j].trim();
                    }
                    uploadJson.push(obj);
                }
                var filtered = uploadJson.filter(item => item.LocationNumber != '');
                
                filtered.map(function(item,index){
                    item.ReservationDate = date;
                });
                
                component.set('v.importedJSON', filtered);
                helper.hideUploadSpinner(component);
                var selectAll = component.find('selectAll');
                var numberOfLocations = component.find('numberOfLocations');
                var pasteButton = component.find('pasteButton').getElement();
                pasteButton.disabled = true;
                selectAll.set('v.disabled', true);
                numberOfLocations.set('v.disabled', true);
                //helper.getLocationsByList(component, reservationId, uploadJson);
                
            }
            reader.onerror = function (event) {
                console.log("error reading file");
                helper.hideUploadSpinner(component);
            }
        } 
        
        else {
            return; 
        }
    },
    selectUpload: function(cmp, evt, helper) {
        var importFile = cmp.find('upload').getElement();
        importFile.click();
    },
    
    disableCheck: function(cmp){
        var arr = cmp.get('v.data');
        var filtered = arr.filter(function(item){item.ReservationErrorCode, item.Id});     
    },
    
    
    sortData: function(cmp, fieldName, sortDirection) {
        var data = cmp.get("v.data");
        var reverse = sortDirection !== 'asc';
        data.sort(this.sortBy(fieldName, reverse))
        cmp.set("v.data", data);
    },
    
    errorSortData: function(cmp, fieldName, sortDirection) {
        var data = cmp.get("v.errorData");
        var reverse = sortDirection !== 'asc';
        data.sort(this.sortBy(fieldName, reverse))
        cmp.set("v.errorData", data);
    },
    sortBy: function(field, reverse, primer) {
        var key = primer ?
            function(x) {
                return primer(x[field])
            } :
        function(x) {
            return x[field]
        };
        reverse = !reverse ? 1 : -1;
        return function(a, b) {
            return a = key(a) ? key(a) : '',
                b = key(b) ? key(b) : '',
                reverse * ((a > b) - (b > a));
        }
    },
    
    showSpinner: function(component) {
        var spinner = component.find("loadingSpinner");
        $A.util.removeClass(spinner, "slds-hide");
    },
    
    hideSpinner: function(component) {
        var spinner = component.find("loadingSpinner");
        $A.util.addClass(spinner, "slds-hide");
    },
    
    showUploadSpinner: function(component) {
        var spinner = component.find("uploadSpinner");
        $A.util.removeClass(spinner, "slds-hide");
    },
    
    hideUploadSpinner: function(component) {
        var spinner = component.find("uploadSpinner");
        $A.util.addClass(spinner, "slds-hide");
    },
    
    replaceClub: function(component, locationId, reservationId, date, filters) {
        this.showSpinner(component);       
        this.getDispatcher(component)
        .action(this.AppSettings.Actions.GetResolutionLocations)  
        .onSuccess(this.handleglnSuccessResolutions)
        .onError(this.handleglnError) 
        .run({ "reservationId": reservationId, 
              "locationId": locationId,
              "requestedDate": date,
              "advancedFilters": filters
             });
    },
    
    handleglnSuccessResolutions: function(component, response, helper) {
        this.hideSpinner(component);
        component.set("v.resolutionData", Object.values(response));   
        var resolutionResponse = Object.entries(response).map(([label, content]) => 
                                                              ({label,content,id:label}));
        resolutionResponse.forEach((item,index) => 
                                   item.content.forEach(function(item, index){ 
                                       item.LocationId = item.LocationId + 'new' + Math.random().toString(10).substr(2, 6);
                                       item.Proximity = parseFloat(Number(item.Proximity).toFixed(1)).toString();
                                   }));
        
        component.set('v.resolutionTabs', resolutionResponse);
        
        // SET ACTIVE TAB IN RESOLUTION WITH DATE FILTERED
        var selected = component.get("v.selectedError");
        var activeTab = resolutionResponse.filter(item => item.label == selected[0].ReservationDate)
        var restabset = component.find('resolutionTabset');
        restabset.set("v.selectedTabId",activeTab[0].label);
        
        // SET CURRENT LOCATION AND FIRST LOCATION SET FOR MAP IN RESOLUTION
        var newCurrent = selected.map(item => item.latlng = [item.LocationLatitude, item.LocationLongitude]);
        component.set('v.currentLocation', selected);
        component.set('v.locations', activeTab);
        
        $A.util.toggleClass(component.find("panel"), "drawer-hide");
        
    },
    validateReservation : function(component, event, upload) {
        
        var date = component.find('requestedDate').get("v.value");
        var count = component.find('numberOfLocations').get("v.value"); 
        var selectAll = component.find('selectAll').get('v.checked');        
        var toastEvent = $A.get("e.force:showToast");
        var today = new Date();
        today.setHours(0,0,0,0);       
        
        if(!date) {
            toastEvent.setParams({
                "type" : "Warning",
                "message": "Please enter a valid date. "
            });
            toastEvent.fire();
            return false;
            
        }        
        
        if (Date.parse(date) < Date.parse(today))
        {
            toastEvent.setParams({
                "type" : "Warning",
                "message": "Reservations can be made for future dates only. "
            });
            toastEvent.fire();
            return false;
            
        }
        
        
        if (upload)
            return true;
        
        //Don't do this validation for upload
        
        if(((!count || count <= 0) && !selectAll)) {
            toastEvent.setParams({
                "type" : "Warning",
                "message": "You must either specify (# of clubs) or select (All Clubs). "
            });
            toastEvent.fire();
            return false;
            
        }
        
        return true;
        
    }, 
    expandSection: function(elem, arrowElem) {
        var sectionHeight = elem.scrollHeight;
        elem.style.height = sectionHeight + 'px';
        elem.style.transform = 'translateY(10px)';
        arrowElem.style.transform = 'rotate(0deg)';
        elem.style.overflow = 'hidden';
        elem.style.opacity = 1;
        
        
        setTimeout(function(){
            elem.style.overflow = 'visible';
            elem.style.height = 'auto';
            elem.setAttribute('data-collapsed', 'false');
        }, 420);
    },
    
    collapseSection: function(elem, arrowElem) {
        var sectionHeight = elem.scrollHeight;
        var elementTransition = elem.style.transition;
        elem.style.transition = '';
        requestAnimationFrame(function() {
            elem.style.height = sectionHeight + 'px';
            elem.style.transition = elementTransition;
            
            requestAnimationFrame(function() {
                elem.style.height = 0 + 'px';
                elem.style.transform = 'translateY(0px)';
                
                arrowElem != null ? arrowElem.style.transform = 'rotate(-90deg)' : '';
                elem.style.opacity = 0;
            });
        });
        
        elem.setAttribute('data-collapsed', 'true');
    },
    
    collapsedTest: function(elem, arrowElem, helper) {
        
        var isCollapsed = elem.getAttribute('data-collapsed') === 'true';
        elem.style.overflow = 'hidden';
        if (isCollapsed) {
            this.expandSection(elem, arrowElem);
        } else {
            this.collapseSection(elem, arrowElem);
        }    
    },
    addPasteClubs: function(component, event, helper) {
        var pasted = component.find('pasteClubs').get('v.value');
        var date = component.find('requestedDate').get('v.value');
        var pasteList = [];
        if(pasted) {
            pasted =  pasted.replace(/(\r\n|\n|\r)/gm,",");
            var dataNew = pasted.split(','); 
            var obj = [];
            
            for (var i= 0; i < dataNew.length; i++) {
                obj[i] = { 
                    'LocationNumber': dataNew[i].trim(),
                    'ReservationDate': date
                };
            }
            var newObj = obj.filter(item => item.LocationNumber != '');
            component.set('v.pasteList', newObj);
            var selectAll = component.find('selectAll');
            var numberOfLocations = component.find('numberOfLocations');
            var uploadButton = component.find('uploadButton').getElement();
            uploadButton.disabled = true;
            selectAll.set('v.disabled', true);
            numberOfLocations.set('v.disabled', true);  
        } 
        var togglePaste = component.find("togglePaste");
        $A.util.toggleClass(togglePaste, "togglePaste");
    }, 
    
    toggleFilter: function(cmp, e, helper) {
        var filters = cmp.find('filters');
        var arrow = cmp.find('arrowDownTop');
        var elem = filters.getElement();
        var arrowElem = arrow.getElement();
        this.collapsedTest(elem, arrowElem); 
    },
    
    toggleAvailable: function(cmp, e, helper) {
        var availableClubs = cmp.find('availableClubs');
        var arrow = cmp.find('arrowDown');
        var elem = availableClubs.getElement();
        var arrowElem = arrow.getElement();
        this.collapsedTest(elem, arrowElem);
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
})