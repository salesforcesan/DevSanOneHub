({
    init : function(component, event, helper) {
       
         component.find("navService").navigate({
            
            type: "standard__component",            
            attributes: {                
                componentName: "c__GroupInvoiceManagementContainer" 
                },
            state: {                
                "c__recordId": component.get("v.recordId")
            }            
        }, true);
    }    
})