({
    parentInit : function(component,event,helper){
        
        var args = event.getParam("arguments");        
        var SearchWrapperList = args.SearchWrapper[0];
        var groupInvoiceType = args.Type;
        
        component.set("v.recordId",SearchWrapperList.InvoiceId);        
    },
    handleApplicationEvent : function(component, event) {
        var actionName = event.getParam("action");
        var baseSearchCriteria = event.getParam("baseSearchCriteria");
        
        if( actionName == 'BaseSearchCriteria') {
            var invoices = component.get('v.invoices');            
            if (baseSearchCriteria != undefined) {               
                component.set('v.invoices',baseSearchCriteria);
            }
        }
    },
    cancelInvoice : function(component, event) {
        
        var recordId = component.get('v.recordId');        
        if(recordId != undefined){
            var navEvt = $A.get("e.force:navigateToSObject");
            navEvt.setParams({
                "recordId": recordId
            });
            navEvt.fire();
        }        
    }
})