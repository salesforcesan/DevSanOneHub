({
    init : function(component, event, helper) {
        /*
        component.find("navService").navigate({

            type: "standard__app",

            attributes: {

                componentName: "c__InvoiceGroupingManager" },

            state: {

              "c__ProjInvoiceRecId": component.get("v.recordId")

            }

        }, true);
        */
        
        
        component.find("navService").navigate({
            type: "standard__app",
            attributes: {                
                pageRef: {
                    type: "standard__recordPage",
                    attributes: {
                        recordId: "a1U11000001imDWEAY",
                        objectApiName: "ProjectInvoice__c",
                        actionName: "view"
                    }
                }
            }
        }, true);      }
})