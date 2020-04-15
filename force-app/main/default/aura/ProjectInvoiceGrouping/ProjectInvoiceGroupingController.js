({
    doInit : function(component, event, helper) {
        
        component.set('v.columns', [
            {label: 'Invoice Name', fieldName: 'Name', type: 'text',sortable:true},
            {label: 'Project ID', fieldName: 'ProjectId', type: 'text',sortable:true},
            {label: 'Project Title', fieldName: 'recordLink', type: 'url',
             typeAttributes: {label: { fieldName: 'ProjectTitle' }, target: '_blank'}},
            {label: 'Start Date', fieldName: 'ProjectStartDate', type: 'date',sortable:true},
            {label: 'Inv Description', fieldName: 'Description', type: 'text',sortable:true}
        ]);
        helper.getActiveGroupedInvoices(component, event, helper);
        helper.getNameSpace(component);
    },
    
    updateColumnSorting: function (component, event, helper) {
        var fieldName = event.getParam('fieldName');
        var sortDirection = event.getParam('sortDirection');
        component.set("v.sortedBy", fieldName);
        component.set("v.sortedDirection", sortDirection);
        var invoices = component.get('v.invoices');
        var data = helper.sortData(component, fieldName, sortDirection, invoices);
        component.set('v.invoices', data);
    },
    
    closeWarningHandler: function (component, event, helper) {
        component.set('v.initialGroupedCount', 0);    
    },
    
    updateSelectedInvoices : function(component, event, helper){
        var selectedRows = event.getParam('selectedRows');
        component.set("v.selectedInvoices" , selectedRows );
        component.set("v.selectedRowsCount" , selectedRows.length );
        console.log('selected rows: ', selectedRows);
    },
    
    getInvoices: function (component, event, helper) {
        var val = component.find('groupedInvoices').get('v.value');
        if(!val || $A.util.isEmpty(val)){ return; }
        console.log('val: ', val);
        component.set('v.selectedGroup', val);
        component.set('v.invoices', []);
        helper.getInvoices(component, event, val); 
    },
    
    addToGroupedHandler: function (component, event, helper) {	
        var invoiceIds = [];
        var invoices =  component.get("v.selectedInvoices");
        var selectedGroup = component.get("v.selectedGroup");
        if(!invoices || !selectedGroup) { return; } 
        invoices.forEach(item => invoiceIds.push(item.Id));
        helper.updateGroupedInvoice(component, event, invoiceIds, selectedGroup);    
    },
    
    createGroupedInvoice: function (component, event, helper) {
        helper.createGroupedInvoice(component, event);
    }
    
    
})