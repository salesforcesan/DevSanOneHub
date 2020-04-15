({
    navToComponent: function(component) {
        var action = component.get("c.getNamespaceApex");
        action.setCallback(this, function(response) {
            
            var ns = '';
            
            if($A.util.isEmpty(response.getReturnValue())){
                ns = 'c__';
            }
                else{
                ns = response.getReturnValue().replace("__", ""); + ':';
            }
            
            component.find("navService").navigate({
                
                type: "standard__component",            
                attributes: {                
                    componentName: ns + "GroupInvoiceManagementContainer" 
                },            
                state: {                
                    "c__recordId": component.get("v.recordId") ,
                    "c__type": 'New'
                }            
            }, true);
            
            
        });
        $A.enqueueAction(action);
    },
})