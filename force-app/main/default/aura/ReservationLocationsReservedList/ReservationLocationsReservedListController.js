({
	doInit : function(component, event, helper) {	
        component.set('v.columns', [
            {label: 'Club #', fieldName: 'LocationNumber', type: 'text',sortable:true},
            // {label: 'Club Name', fieldName: 'LocationName', type: 'text',sortable:true},
            {label: 'Status', fieldName: 'Status', type: 'text',sortable:true},
            {label: 'Date', fieldName: 'ReservationDate', type: 'text',sortable:true}
        ]);
        
        helper.getDataHelper(component, event);
		helper.getNameSpace(component, event, helper);
    },
    recordUpdated: function(component, event, helper) {
        var nameSpace = component.get('v.ns');
        var requestedLocations = component.get('v.reservationRecord' + '.' + nameSpace + 'RequestedLocations__c');
        component.set('v.requestedCount', requestedLocations);

    },    
    updateColumnSorting: function (cmp, event, helper) {
        var fieldName = event.getParam('fieldName');
        var sortDirection = event.getParam('sortDirection');
        cmp.set("v.sortedBy", fieldName);
        cmp.set("v.sortedDirection", sortDirection);
        helper.sortData(cmp, fieldName, sortDirection);
      },
    
     updateSelectedReserved : function(component, event, helper){
        var selectedReserved = event.getParam('selectedRows');
        //  console.log('selectedRows'+selectedRows);
        component.set("v.selectedReservedList" , selectedReserved);
        console.log("v.selectedReservedList", component.get('v.selectedReservedList'));     
    },
    handleSelect: function (component, event, helper) {
        var arr = component.get('v.data');
        var obj =  component.get("v.selectedReservedList");
        var selectedButtonLabel = event.getSource().get("v.label");
        
        
    },
  
     loadMoreData: function (component, event, helper) {
        component.set('v.loadMoreStatus', 'Loading...');
    },
      
    cancelSelected: function(cmp, event, helper) {   
        var data = cmp.get('v.selectedReservedList');
        var reservationId = cmp.get('v.recordId');
        helper.cancelLocations(cmp, reservationId, data);       
    },
    
    handleSearch: function(cmp, event, helper) {
        helper.handleSearch(cmp, event, helper);
        /*var isEnterKey = event.keyCode === 13;
        if (!!isEnterKey) {
           helper.filterList(component, event, helper);   
        }*/
    }
})