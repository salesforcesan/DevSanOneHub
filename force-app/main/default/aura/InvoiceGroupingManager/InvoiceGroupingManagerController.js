({
   parentInit : function(component,event,helper){
       var args = event.getParam("arguments");
       var SearchWrapperList = args.SearchWrapper[0];
       var recordActionType = args.type;

       component.set('v.SearchWrapper',SearchWrapperList);
       component.set('v.recordActionType',recordActionType);
       
       var a = component.get('c.loadData');
       $A.enqueueAction(a);
    },
    doInit : function(component, event, helper) {		                                       
        
        var recordId = component.get("v.recordId");
        if (recordId != null && recordId != undefined) {
            component.set('v.SearchWrapper',[{"InvoiceId" : recordId, 
                                              "Account" : "", 
                                              "BillToContact" : "", 
                                              "LawsonCompnanyCode" : "", 
                                              "InvoiceType" : "",  
                                              "FilterDateRange" : "", 
                                              "FromDate" : "", 
                                              "ToDate" : "", 
                                              "PONumber" : "", 
                                              "ProjectNumber" : "", 
                                              "ProjectName" : "",
                                              "InvoiceToInclude" : "",
                                             }]);
            
            var a = component.get('c.loadData');
            $A.enqueueAction(a);
        }
    },
    loadData:function(component, event, helper){
        component.set('v.columns', [
            {label: 'Invoice Name', fieldName: 'Name', type: 'text',sortable:true, cellAttributes: {'class': {"fieldName": "showClass"},'iconName': {'fieldName': "displayIconName"}}},            
            {label: 'Project Title', fieldName: 'recordLink', type: 'url',
             typeAttributes: {label: { fieldName: 'ProjectTitle' }, target: '_blank'},cellAttributes: {'class': {"fieldName": "showClass"},'iconName': {'fieldName': "displayIconName"}}},
            {label: 'Project Number', fieldName: 'ProjectNumber', type: 'text',sortable:true,cellAttributes: {'class': {"fieldName": "showClass"},'iconName': {'fieldName': "displayIconName"}}},
            {label: 'Total Invoice Amount', fieldName: 'InvoiceTotalAmount', type: 'currency',sortable:true,cellAttributes: {'class': {"fieldName": "showClass"},'iconName': {'fieldName': "displayIconName"}}},
            {label: 'PO #', fieldName: 'PONumber', type: 'text',sortable:true,cellAttributes: {'class': {"fieldName": "showClass"},'iconName': {'fieldName': "displayIconName"}}},
            {label: 'Created Date', fieldName: 'CreatedDate', type: 'date',sortable:true,cellAttributes: {'class': {"fieldName": "showClass"},'iconName': {'fieldName': "displayIconName"}}},
            {label: 'Due Date', fieldName: 'DueDate', type: 'date',sortable:true,cellAttributes: {'class': {"fieldName": "showClass"},'iconName': {'fieldName': "displayIconName"}}},
            {label: 'Start Date', fieldName: 'ProjectStartDate', type: 'date',sortable:true,cellAttributes: {'class': {"fieldName": "showClass"},'iconName': {'fieldName': "displayIconName"}}}
        ]);  
        helper.getInvoices(component, event, helper); 
        
    },
    clearFilter: function(component, event, helper){
       
        var serachList = component.get('v.SearchWrapper');  
        var serach = serachList[0];
        
        component.find('poNumbers').set('v.value','');
        component.find("projectNumbers").set("v.value",'');
        component.find("projectName").set("v.value",'');
        component.find("FilterDateRange").set("v.value",'');
        component.find("FromDate").set("v.value",'');
        component.find("ToDate").set("v.value",'');     
        component.get("v.optionValue",'');
        
        var a = component.get('c.searchInvoices');
        $A.enqueueAction(a);

    },
    searchInvoices: function(component, event, helper){
        
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
        
        var arr = [];
        var toBeRemovedInvoices = component.get('v.toBeRemovedInvoices');
        toBeRemovedInvoices.forEach(function(item) {            
                        arr.push(item.Name);                        
                    });
        serach.InvoiceToInclude = arr.join(",");
       
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
    
    addToGroupServer: function (component, event, helper) {
        var data = component.get('v.selectedInvoices');
        var invoices = component.get('v.invoices');
        var toBeGroupedInvoices = component.get('v.toBeGroupedInvoices');
        
        if(data.length == 0) {
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                "type" : "Warning",
                "message": "No data selected. "
            });
            toastEvent.fire();
            return;
        }        
        
        var appEvent = $A.get("e.c:aeEvent");
        appEvent.setParams({
            "action" : "AddToGroupServer",
            "toBeGroupedInvoices" : data
        });
        appEvent.fire();
    },
    
    addToGroup: function (component, event, helper) {
        var data = component.get('v.selectedInvoices');
        var invoices = component.get('v.invoices');
        var toBeGroupedInvoices = component.get('v.toBeGroupedInvoices');
        
        if(data.length == 0) {
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                "type" : "Warning",
                "message": "No invoice selected for grouping. "
            });
            toastEvent.fire();
            return;
        }        
        
        var appEvent = $A.get("e.c:aeEvent");
        appEvent.setParams({
            "action" : "AddToGroup",
            "toBeGroupedInvoices" : data
        });
        appEvent.fire();
        
       
        
        data.forEach(function(item) {
            toBeGroupedInvoices.push(item);
        });
        
        //To remove selected invoices
        invoices = invoices.filter( ( el ) => !data.includes( el ));
        data = data.filter( ( el ) => !data.includes( el ));
        component.set('v.selectedInvoices', data);        
        component.set('v.invoices',invoices);
        
		component.set('v.toBeGroupedInvoices',toBeGroupedInvoices);
    },
    
    
    handleApplicationEvent : function(component, event) {
        var actionName = event.getParam("action");
        var toBeRemovedInvoices = event.getParam("toBeRemovedInvoices");
        var toBeGroupedInvoices = component.get('v.toBeGroupedInvoices');
        
        if( actionName == 'ToBeRemoved') {
            var invoices = component.get('v.invoices');
            
            if (toBeRemovedInvoices != undefined){
                toBeGroupedInvoices = toBeGroupedInvoices.filter( s => 
                              toBeRemovedInvoices.every( t => { 
                                  return s['Name'] !== t['Name']
                              })
                             );
                
                if(invoices != null){
                    toBeRemovedInvoices.forEach(function(item) {    
                        item.showClass ='redcolor';
                        invoices.push(item);                        
                    });
                   
                }else{
                    toBeRemovedInvoices.forEach(function(item) {
                        item.showClass ='redcolor';
                    });
                    invoices = toBeRemovedInvoices;                    
                }
                
                component.set('v.toBeGroupedInvoices',toBeGroupedInvoices);
                component.set('v.toBeRemovedInvoices',toBeRemovedInvoices);
                component.set('v.invoices',invoices);
            }          
        }
    }

})