({
	getReportUrl : function(component, event, helper) {
        
         var action = component.get("c.getReservationReportUrl");
           action.setParams({
            reservationId : component.get("v.recordId"),
        });
        
        //this.showSpinner(cmp);
        action.setCallback(this, function(response) {
            var self =this;
         
           //
           if(!$A.util.isEmpty(response.getReturnValue()))
           {
             self._reservationReport(component,response.getReturnValue());
           }
           
  
        });
        $A.enqueueAction(action);
       // this.hideSpinner(component);
		
	},
    
    _reservationReport: function(component,reportUrl)
    {
      $A.get("e.force:navigateToURL").setParams({ 
       "url":  reportUrl,
    }).fire();
         
        
        
    }
    
})