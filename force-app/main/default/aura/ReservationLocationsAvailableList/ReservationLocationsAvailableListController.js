({
    doInit : function(component, event, helper) {		                
 
   		
        var reservationid = component.get("v.recordId");
        helper.getReservationDetails(component, reservationid); 
        component.set('v.errorColumns', [
            {	label: 'Club #', 
             	fieldName: 'LocationNumber', 
             	type: 'text',
             	sortable:true
            },
            {	label: 'Issue', 
             	fieldName: 'ReservationErrorMessage', 
                type: 'String', 
                cellAttributes: { 
						iconName: 'utility:warning', 
                        iconPosition: 'left', 
            	},
            	sortable:true
            },
            { type: 'button', cellAttributes: { alignment:'right'}, typeAttributes: { iconName:'utility:replace', label:'Resolve', name:'resolveError', disabled:false }},
            { type: 'button', cellAttributes: { alignment:'right'}, typeAttributes: { iconName:'utility:error', label:'Override', name:'overrideError', disabled:false }, sortable:true}

        ]);

        component.set('v.columns', [     
            {label: 'Club #', fieldName: 'LocationNumber', type: 'text',sortable:true},	
            {label: 'Address', fieldName: 'LocationAddress', type: 'text',sortable:true},
            {label: 'City', fieldName: 'LocationCity', type: 'text',sortable:true},
            {label: 'State', fieldName: 'LocationState', type: 'text',sortable:true},
            {label: 'Available', fieldName: 'AvailableCapacity', type: 'text',sortable:true},
           {label: 'Date', fieldName: 'ReservationDate', type: 'text',sortable:true}
        ]);
        
        var filters = '';
        component.set('v.filters', filters);
                                       
    },
    
    selectAllFinder: function(component, event, helper){
        var selectAll = component.find('selectAll').get('v.checked');
        var requestedCount = component.get('v.requestedCount');
        var pasteButton = component.find('pasteButton').getElement();
        var numberOfLocations = component.find('numberOfLocations');
        var uploadButton = component.find('uploadButton').getElement();
        
        if(selectAll) {
            numberOfLocations.set("v.value", ''); 
            numberOfLocations.set("v.disabled", true);
            uploadButton.disabled = true;
            pasteButton.disabled = true;
        } else {
            numberOfLocations.set("v.value", requestedCount); 
            numberOfLocations.set("v.disabled", false);
            uploadButton.disabled = false;
            pasteButton.disabled = false;
        }
    },
    findClubs: function(component, event, helper) {
        var togglePaste = component.find("togglePaste");
        if($A.util.hasClass(togglePaste, "togglePaste")) {
           $A.util.toggleClass(togglePaste, "togglePaste");
        }
        var date = component.find('requestedDate').get("v.value");
        var count = component.find('numberOfLocations').get("v.value"); 
        var uploadJSON = component.get('v.importedJSON');
        var reservationid = component.get("v.recordId");
        var filters = component.find('searchText').get('v.value');
        var pasteList = component.get('v.pasteList');
        var pasteContainer = component.find('togglePaste');
        
        component.set('v.filters', filters);
        component.set('v.endIteration', 10);
        
        pasteList.length > 0 ? uploadJSON = pasteList : ''; 
        
        var upload;
        uploadJSON.length > 0 ? (upload = true, uploadJSON = JSON.stringify(uploadJSON)) : (upload = false, uploadJSON = '');
    
		if (!helper.validateReservation(component, event, upload))
            return;
        
        if (!count)
            count = -1;
 		
        helper.getLocations(component, reservationid, count, date, filters, uploadJSON); 
        //helper.getLocationsByNumber(component, reservationid, count, date, filters); 
    },    
    
    reserveSelected: function (component, event, helper) {
        var data = component.get('v.selectedLocations');
        if(data.length == 0) {
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                "type" : "Warning",
                "message": "No clubs selected to reserve. "
            });
            toastEvent.fire();
            return;
        }
        
        
        var reservationId = component.get('v.recordId');
        helper.reserveLocations(component, reservationId, data);
        
    },
    advancedFiltersToggle:function(component, event,  helper) {
        
    },
    
    updateColumnSorting: function (cmp, event, helper) {
        var fieldName = event.getParam('fieldName');
        var sortDirection = event.getParam('sortDirection');
        cmp.set("v.sortedBy", fieldName);
        cmp.set("v.sortedDirection", sortDirection);
        helper.sortData(cmp, fieldName, sortDirection);
    },
    
    handleRowAction: function (cmp, event, helper) {
        //h.handleAction(cmp, event, helper);  
    },
    
    selectedLocations : function(component, event, helper){
        var selectedRows = event.getParam('selectedRows'); 
        component.set("v.selectedLocations" , selectedRows);
    },
    
    selectUpload: function(cmp, evt, helper) {
        var filters = cmp.find('searchText').get('v.value');
        cmp.set('v.filters', filters);
        var upload = true;

		if (!helper.validateReservation(cmp, event, upload))
            return;
        
        helper.selectUpload(cmp, evt, helper);
    },
    
    uploadClubs: function(component, event, helper) {
        helper.uploadClubs(component, event, helper); 
    },

    errorUpdateColumnSorting: function (cmp, event, helper) {
        var fieldName = event.getParam('fieldName');
        var sortDirection = event.getParam('sortDirection');
        cmp.set("v.errorSortedBy", fieldName);
        cmp.set("v.errorSortedDirection", sortDirection);
        helper.errorSortData(cmp, fieldName, sortDirection);
    },
    
    clearList: function(cmp, e, h) {
      	cmp.set('v.data', []);  
    },
    recordUpdated: function(component, event, helper) {
/*
       var FoodPairing = component.get('v.reservationRecord.FoodPairing__c');
       var ABType = component.get('v.reservationRecord.ABType__c');
       
        FoodPairing == true ? 
            component.find('foodPairing').getElement().checked = true :  
        	component.find('foodPairing').getElement().checked = false;
     

        if($A.util.isEmpty(ABType) || ABType == '') {
            return;
        } else {
            if ( ABType.includes('Beer')) {
                  var beerWet = component.find('beerWet').getElement();
                  beerWet.checked = true;
                  console.log('has beer');
            }
            if (ABType.includes('Wine')) {
                  var wineWet = component.find('wineWet').getElement();
                  wineWet.checked = true;
                  console.log('has wine');
            }
            if (ABType.includes('Spirits')) {
                  var spiritsWet = component.find('spiritsWet').getElement();
                  spiritsWet.checked = true;
                  console.log('has spirits');
            }
        }*/
          //ABType__c
   			//FoodPairing__c
       //component.set('v.reservationRecord.FoodPairing__c', true);
       //console.log('food pairing: ', component.get('v.reservationRecord.FoodPairing__c'));
        
       // var abType = component.get('v.reservationRecord' + '.' + nameSpace + 'RequestedDate__c');

    },    
    
    toggleErrors: function(cmp, e, h){
        var dataErrors = cmp.find('dataErrors');
        var elem = dataErrors.getElement();
        var showErrors = cmp.find('showErrors');
        var arrowElem = showErrors.getElement();
        
        h.collapsedTest(elem, arrowElem);
    },
    
    errorResolve: function(cmp, e, helper) {
       var data = cmp.get('v.data');
       if(data.length > 0) {
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                "type" : "Warning",
                "message": "Reserve clubs in your available list before continuing to resolve the errors"
            });
            toastEvent.fire();
            return;
        }
        const reservationId = cmp.get('v.recordId'); 
        var filters = cmp.get('v.filters');
        var locationId = e.getSource().get('v.value');
        var errorData = cmp.get('v.errorData');
        var selectedError = errorData.filter(item => item.LocationId == locationId);
        console.log('selectedError: ', selectedError);
        var date = selectedError[0].ReservationDate;
        cmp.set('v.locId', locationId);
        cmp.set('v.selectedError', selectedError);
        cmp.set('v.resolutionDate', date);
        helper.replaceClub(cmp, locationId, reservationId, date, filters);
    },
    
    errorOverride: function(cmp, e, helper) {
      var data = cmp.get('v.data');
     if(data.length > 0) {
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                "type" : "Warning",
                "message": "Reserve all clubs in your available list before continuing to resolve the errors"
            });
            toastEvent.fire();
            return;
        }
       const reservationId = cmp.get('v.recordId'); 
       var locationId = e.getSource().get('v.value');
       var errorData = cmp.get('v.errorData');
       var selectedError = errorData.filter(item => item.LocationId == locationId);
       var date = selectedError[0].ReservationDate;
       cmp.set('v.locId', locationId);
       cmp.set('v.selectedError', selectedError);
       var overrideData = [{
                   'ReservationDate':date,
                   'LocationId':locationId,
                    'CapacityOverride':true
       }];
       helper.reserveResolutionLocation(cmp, reservationId, overrideData);
    },
    
    handleRowActions: function (cmp, e, helper) {
        cmp.set('v.warnings', []); 
        var action = e.getParam('action');
        var row = e.getParam('row');
        var isShown = cmp.get('v.showWarnings');
        switch (action.name) {
            case 'Warnings':
                 isShown ? cmp.set('v.warnings', row) : 
                		 (cmp.set('v.warnings', row),  cmp.set('v.showWarnings', true));
                break;      
        }
    },
    
    closeWarnings: function (cmp, e, h) {
      var isShown = cmp.get('v.showWarnings');
      isShown ? cmp.set('v.showWarnings', false) : null;
    },
    
    handleSelectTab: function(cmp, e, h) {
        cmp.set('v.locations', []);
        var tab = cmp.get('v.resolutionTabs');
        var newtab = tab.filter((item) => item.id === e.getParam('id'));
 		newtab.forEach(item => item.content.map(item => item.latlng = [item.LocationLatitude, item.LocationLongitude]));
        cmp.set('v.resolutionDate', newtab[0].label);
        cmp.set('v.locations', newtab[0].content);
    },
                                 
   handleClick: function (cmp, e, h) {
        var radio = e.currentTarget;
        var checked = radio.checked;
		var clubId = radio.id.substr(0, 18);
        var newClub = cmp.set("v.selectedResolutionClub", clubId);
   },
                                 
   handleResolve: function (cmp, e, h) {
        var date = cmp.get('v.resolutionDate');
        var reservationId = cmp.get('v.recordId');  
        var selectedClubId = cmp.get('v.selectedResolutionClub');
        var data = [{
           'ReservationDate':date,
           'LocationId':selectedClubId
       }];
        $A.util.toggleClass(cmp.find("panel"), "drawer-hide");
        h.reserveResolutionLocation(cmp, reservationId, data);
   },
                                 
    toggleResolution : function(component, event, helper) {
        
        $A.util.toggleClass(component.find("panel"), "drawer-hide");   
    },
    
    handleLocationSelected: function(component, event, helper) {
        
    },
    
    clearUpload: function(component, event, helper) {
       var selectAll = component.find('selectAll');
       var numberOfLocations = component.find('numberOfLocations');
       var pasteButton = component.find('pasteButton').getElement();
       pasteButton.disabled = false;
       component.set('v.importedJSON', []); 
	   selectAll.set('v.disabled', false);
       numberOfLocations.set('v.disabled', false);
    } , 
    clearPaste: function(component, event, helper) {
       var selectAll = component.find('selectAll');
       var numberOfLocations = component.find('numberOfLocations');
       var uploadButton = component.find('uploadButton').getElement();
       component.set('v.pasteList', []); 
	   selectAll.set('v.disabled', false);
       numberOfLocations.set('v.disabled', false);
	   uploadButton.disabled = false;
    } ,
     clearPasteTextarea: function(component, event, helper) {
       var pasted = component.find('pasteClubs');
       pasted.set('v.value', null);
       component.set('v.pasteList', []); 
    } ,
    toggleFilter: function(cmp, e, helper) {
        var togglePaste = cmp.find("togglePaste");
        if($A.util.hasClass(togglePaste, "togglePaste")) {
           $A.util.toggleClass(togglePaste, "togglePaste");
        }
    	helper.toggleFilter(cmp, e, helper); 
	},
    
    toggleAvailableClubs:function(cmp, e, helper){
        helper.toggleAvailable(cmp, e, helper);   
    },
    
    showMore: function(cmp, e, helper) {
       var iterations = cmp.get('v.endIteration');
        cmp.set('v.endIteration', iterations + 10);
       
    },
    
    addPasteClubs: function(cmp, event, helper) {
        helper.addPasteClubs(cmp, event, helper);
    }, 
    
    openPaste: function(cmp, event, helper) {
        var upload = true;
		if (!helper.validateReservation(cmp, event, upload))
            return; 
        var numberOfLocations = cmp.find('numberOfLocations');
        numberOfLocations.set('v.value', 0);

        var togglePaste = cmp.find("togglePaste");
        $A.util.toggleClass(togglePaste, "togglePaste");
    },
    
    togglePaste : function(cmp, evt, helper) {
        var togglePaste = cmp.find("togglePaste");
        $A.util.toggleClass(togglePaste, "togglePaste");
  }, 
    showErrorList : function(cmp, e, h) {
      	var targetId = e.currentTarget.getAttribute('data-id');
        var elemId = document.getElementById(targetId);
        
        if(elemId.classList.contains("slds-hide")){
           elemId.classList.add("slds-show");
           elemId.classList.remove('slds-hide');
        } else {
           elemId.classList.add("slds-hide");
           elemId.classList.remove('slds-show'); 
        };
        
        /*
        console.log('current target', targetId);
        var target = cmp.find(targetId);
        console.log('target', elemId);
      	$A.util.toggleClass(target, "slds-hide");  */    
  },
    
})