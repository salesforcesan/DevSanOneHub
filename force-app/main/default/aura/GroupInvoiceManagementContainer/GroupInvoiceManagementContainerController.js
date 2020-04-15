({
    doInit : function(component, event, helper) {		                                       
        var pageReference = component.get("v.pageReference");
                
        var recordId =  pageReference.state.c__recordId;   
        var type =  pageReference.state.c__type;  
        component.set("v.recordId", pageReference.state.c__recordId);
        
        if (recordId === null || recordId === undefined){
           var recordId = '';
        }
        
        if (recordId === ''){
            component.set("v.recordId", pageReference.state.c__recordId); 
            component.set("v.recordId", pageReference.state.c__accountId); 
            component.set("v.recordId", pageReference.state.c__billToContactId); 
            component.set("v.recordId", pageReference.state.c__lawsonCompnanyCodeId); 
        }
        
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
                                          "ProjectName" : ""}]);
        
        var invoiceGroupingManagerCmp = component.find("invoiceGroupingManagerCmp");
        var croupedInvoiceContainerCmp = component.find("croupedInvoiceContainerCmp");
        var invoiceBaseSearchCriteriaCmp = component.find("invoiceBaseSearchCriteriaCmp");
        
        var searchData = [{"InvoiceId" : recordId, 
                                          "Account" : "",
                                          "BillToContact" : "",
                                          "LawsonCompnanyCode" : "",
                                          "InvoiceType" : "",
                                          "FilterDateRange" : "", 
                                          "FromDate" : "", 
                                          "ToDate" : "", 
                                          "PONumber" : "", 
                                          "ProjectNumber" : "", 
                                          "ProjectName" : ""}];
        
        invoiceGroupingManagerCmp.getScoreMethod(searchData,type);
        croupedInvoiceContainerCmp.getScoreMethod(searchData,type);
        invoiceBaseSearchCriteriaCmp.getScoreMethod(searchData,type);
    },
})