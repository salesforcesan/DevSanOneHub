({
    parentInit : function(component,event,helper){
        var args = event.getParam("arguments");
        
        var SearchWrapperList = args.SearchWrapper[0];
        var groupInvoiceType = args.Type;
        
        component.set("v.recordId",SearchWrapperList.InvoiceId);
        component.set('v.SearchWrapper',SearchWrapperList);
        component.set('v.groupInvoiceType',groupInvoiceType);
        
        var a = component.get('c.loadData');
        $A.enqueueAction(a);
    },
    doInit : function(component, event, helper) {
        
        var recordId = component.get("v.recordId");
        if (recordId != null && recordId != undefined) {
            var recordId = component.get("v.recordId");
            
            component.set('v.SearchWrapper',[{"InvoiceId" : recordId, 
                                              "Account" : "", "BillToContact" : "", 
                                              "LawsonCompnanyCode" : "", "InvoiceType" : "", 
                                              "FilterDateRange" : "", "FromDate" : "", 
                                              "ToDate" : "", 
                                              "PONumber" : "", 
                                              "ProjectNumber" : "", 
                                              "ProjectName" : ""}]);
            var a = component.get('c.loadData');
            $A.enqueueAction(a);
        }
        
        helper.getInvoiceInfo(component, event, helper); 
        
    },
    showConfirmation : function(cmp) {                
        
        $A.createComponent(
            "c:ModalConfirmation",
            {
                "title": "Modal Confirmation Box",
                "tagline": "This is a modal confirmation box",
                "message": "Are you sure you want to continue?",
                //"confirm": cmp.getReference("c.handleConfirm"),
                "param": cmp.get("v.recordId")
            },
            function(modalWindow, status, errorMessage){
                //Add the new button to the body array
                if (status === "SUCCESS") {
                    var body = cmp.get("v.body");
                    body.push(modalWindow);
                    cmp.set("v.body", body);
                }
                else if (status === "INCOMPLETE") {
                    console.log("No response from server or client is offline.")
                    // Show offline error
                }
                else if (status === "ERROR") {
                    console.log("Error: " + errorMessage);
                    // Show error message
                }
            }
        );
    },
     handleConfirm : function(cmp, event, helper) {
        //retrieve the value of the parameter
        var recordId = event.getParam("v.param");
        
        // Add your confirmation logic here ...
    },
    loadData:function(component, event, helper){
        
        component.set('v.columns', [
            {label: 'Invoice Name', 
             fieldName: 'Name', 
             type: 'text',
             sortable:true, 
             cellAttributes: {
                 'class': {
                     "fieldName": "showClass"
                 },
                 'iconName': {
                     'fieldName': "displayIconName"
                 }
             }},            
            {label: 'Project Title', fieldName: 'recordLink', type: 'url',
             typeAttributes: {label: { fieldName: 'ProjectTitle' }, target: '_blank'}, cellAttributes: {
                 'class': {
                     "fieldName": "showClass"
                 },
                 'iconName': {
                     'fieldName': "displayIconName"
                 }
             }},
            {label: 'Project Number', fieldName: 'ProjectNumber', type: 'text',sortable:true, cellAttributes: {
                'class': {
                    "fieldName": "showClass"
                },
                'iconName': {
                    'fieldName': "displayIconName"
                }
            }},
            {label: 'Total Invoice Amount', fieldName: 'InvoiceTotalAmount', type: 'currency',sortable:true, cellAttributes: {
                'class': {
                    "fieldName": "showClass"
                },
                'iconName': {
                    'fieldName': "displayIconName"
                }
            }},
            
        ]);
            helper.getInvoices(component, event, helper); 
            
            },
            
            findClubs: function(component, event, helper){
            
            var serachList = component.get('v.SearchWrapper');  
            var serach = serachList[0];
                      
			var poNumbersVal = component.find('poNumbers').get('v.value');
            var projectNumbers = component.find("projectNumbers").get("v.value");
            var projectName = component.find("projectName").get("v.value");
            var filterDateRange = component.find("FilterDateRange").get("v.value");
            var fromDate = component.find("FromDate").get("v.value");
            var toDate = component.find("ToDate").get("v.value");     
            var filterDateRange = component.get("v.optionValue");
        
        serach.FilterDateRange = filterDateRange;
        serach.PONumber = poNumbersVal;
        serach.ProjectNumber = projectNumbers;                
        serach.FilterDateRange = filterDateRange;
        serach.FromDate = fromDate;
        serach.ProjectName = projectName;
        serach.ToDate = toDate;
        component.set('v.SearchWrapper',serachList);
        
        helper.getInvoices(component, event, helper); 
    },
    
    updateSelectedInvoices : function(component, event, helper){
        var selectedRows = event.getParam('selectedRows');
        component.set("v.selectedInvoices" , selectedRows );
        component.set("v.selectedRowsCount" , selectedRows.length );
        console.log('selected rows: ', selectedRows);
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
    },
    
    toggleFilter: function(cmp, e, helper) {
        var togglePaste = cmp.find("togglePaste");
        if($A.util.hasClass(togglePaste, "togglePaste")) {
            $A.util.toggleClass(togglePaste, "togglePaste");
        }
        helper.toggleFilter(cmp, e, helper); 
    },
    handleSearch: function(cmp, event, helper) {        
        helper.handleSearch(cmp, event, helper);        
    },
    manageInvoice: function(component, event, helper){
        helper.manageGroupInvoice(component, event, helper);
        //helper.openMessageBox(component, event, helper);
    },
    
    removeInvoice: function(component, event, helper){
        
        var data = component.get('v.selectedInvoices');
        
         if(data.length == 0) {
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                "type" : "Warning",
                "message": "No data selected. "
            });
            toastEvent.fire();
            return;
        }
        
        var invoices = component.get('v.invoices');
        component.set('v.toBeRemovedInvoices',data);
        
        var appEvent = $A.get("e.c:aeEvent");
        appEvent.setParams({
            "action" : "ToBeRemoved",
            "toBeRemovedInvoices" : data
        });
        appEvent.fire();        
        
        //To remove selected invoices
        invoices = invoices.filter( ( el ) => !data.includes( el ));
        data = data.filter( ( el ) => !data.includes( el ));
        component.set('v.selectedInvoices', data);        
        component.set('v.invoices',invoices);
    },
    handleApplicationEvent : function(cmp, event) {
        var actionName = event.getParam("action");
        var data = event.getParam("toBeGroupedInvoices");
        
        if (actionName === 'AddToGroup'){
            // set the handler attributes based on event data
            
            cmp.set("v.toBeGroupedInvoices",data);
            var invoices = cmp.get('v.invoices');        
            
            if (data != undefined){
                if ( invoices != undefined) {
                    data.forEach(function(item) {
                        item.showClass ='redcolor';
                        invoices.push(item);
                    });
                }
                else {
                    invoices = data;
                    invoices.forEach(function(item) {
                        item.showClass ='redcolor';
                    });
                }
            }
            
            cmp.set("v.invoices",invoices);
            
        }
    },
    
    onMessageBoxEvent: function(component, evt, helper) {
        helper.handleMessageBoxEvent(component, evt,helper);
        
    },
})