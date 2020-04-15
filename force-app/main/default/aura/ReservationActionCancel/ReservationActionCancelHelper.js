({
	loadReservationCancelReasons : function(cmp){    
       var action = cmp.get("c.GetReservationCancelReasons");
        var opts = [];   
        this.showSpinner(cmp);
        action.setCallback(this, function(response) {
            console.log('Cancel Reasons: ' + response.getReturnValue());
            for(var i=0;i< response.getReturnValue().length;i++){
                opts.push({"class": "optionClass", label: response.getReturnValue()[i], value: response.getReturnValue()[i]});
            }
            cmp.set("v.cancelreasons", opts);
            this.hideSpinner(cmp);
        });
        $A.enqueueAction(action);                
    },
    
     getReservationDetails : function(cmp){                
        var action = cmp.get("c.GetReservation");
        console.log('Reservation Id: ' + cmp.get("v.recordId"));
        
        action.setParams({
            reservationId : cmp.get("v.recordId"),
        });
        
        this.showSpinner(cmp);
        action.setCallback(this, function(response) {
            
            console.log('Reservation Data: ' + JSON.parse(response.getReturnValue()));
            
            if(!$A.util.isEmpty(JSON.parse(response.getReturnValue())))
            cmp.set("v.Reservation", JSON.parse(response.getReturnValue()));
           this.hideSpinner(cmp);
        });
        $A.enqueueAction(action);                
    }, 
    
     CancelClicked : function(component, event, helper) {
		var dismissActionPanel = $A.get("e.force:closeQuickAction");
        dismissActionPanel.fire();        
        
    },
   
    cancelSelectedReservation : function (component, event, helper) {
        var self = this; 
        var reservation = component.get("v.Reservation");
        var comment = component.find("cancelReasonComment").get("v.value");		
        var action = component.get("c.cancelReservationApex");
        component.set("v.callbackresult","NONE");        
               
       action.setParams({
            reservationId : reservation.Id,
            cancelReason : reservation.CancelReason,
            cancelComments : comment
        });
        
         helper.callServerAction(component,event,helper,action);
        
    },
    callServerAction:  function(component,event,helper,action)    
    { 
      var self = this;  
      helper.showSpinner(component);
      component.set("v.callbackresult","NONE");        
      action.setCallback(this, function(response) {
            var state = response.getState();
          	if (!component.isValid())
                return;

            component.set("v.callbackresult",state);          
            if (state === "SUCCESS") {                
                helper.hideSpinner(component);
                console.log('Success returned: ' + response.getReturnValue());
                var responseWrapper = JSON.parse(response.getReturnValue());                

                if(responseWrapper.State==="SUCCESS"){
                    if (responseWrapper.Message != '' && responseWrapper.Message != null)
                    {
                        component.set("v.callbackmessage",responseWrapper.Message);
                    }
                }
                else{
                        component.set("v.callbackresult","ERROR");          
                }                
            }
            else if (state === "INCOMPLETE") {
               helper.hideSpinner(component);
				//console.log('do something here');
			} else if (state === "ERROR") {
                helper.hideSpinner(component);
				var errors = response.getError();                
				if (errors) {
					if (errors[0] && error[0].message) {    
                        component.set("v.callbackmessage",errors[0].message);
					}
				} else {
                    component.set("v.callbackmessage",'Unhandled Exception occurred:\r\nContact Administrator');
				}
			}
			self.closeActionDialog();
        });
        
        $A.enqueueAction(action);  
    },
     closeActionDialog: function(component){
        var self = this;
        window.setTimeout(
            $A.getCallback(function() {
                self.CancelClicked(component);
                self.gotoDashboard();
            }), 2000
        );                     
    },
    gotoDashboard : function () {
        var evt = $A.get("e.force:navigateToComponent");
        evt.setParams({
            componentDef: "c:ProjectDashboardLayout",
            componentAttributes: {}
        });
        evt.fire();    
    },
      
     showSpinner: function(cmp){
        var spinner = cmp.find("displaySpinner");
        $A.util.removeClass(spinner, "slds-hide"); 
    },
    hideSpinner: function(cmp){
        var spinner = cmp.find("displaySpinner");
        $A.util.addClass(spinner, "slds-hide"); 
    },
    notifyMessage: function(cmp, msg, msgType) {
        var e = cmp.find('notification');
        e.set('v.message', msg);
        e.set('v.type', msgType);
    },
    
})