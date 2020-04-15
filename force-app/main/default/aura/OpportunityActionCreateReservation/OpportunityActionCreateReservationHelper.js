({
    AppSettings: {
        'Actions': {
            'ExistingReseravtions':'getAllReservationsForSelectedOpp',
            'CreateReservation': 'createReservationFromOpportunity',
            
        }
    },
    onInit: function(component, event, helper) {
          var opportunityId = component.get("v.recordId");
        console.log('opp: ' + opportunityId);
        if(!opportunityId){
            return;
        }
       
       var action = component.get("c.getAllReservationsForSelectedOpp");
       action.setParams({
           "opportunityId": opportunityId
       });
       action.setCallback(this, function(response) {
           var state = response.getState();
           console.log(state);
           if (state === "SUCCESS") 
           {
               var data = response.getReturnValue();
               component.set("v.ReservationId",response.getReturnValue().toString());
               // console.log(data);
               if ((!($A.util.isUndefinedOrNull(data))) && data.length > 0 && !($A.util.isEmpty(data)))
                   
               {
                   
                   var resId = data.toString(); 
                   var sObjectEvent = $A.get("e.force:navigateToSObject");
                   sObjectEvent.setParams({
                       "recordId": resId,
                       "slideDevName": "detail"
                   });
                   sObjectEvent.fire();
                   
                   //component.set("v.opportunityList",data);
               }
               else
               {
                   component.set("v.callbackresult","NONE");
               }
               
               
           }
       });
       $A.enqueueAction(action);
       
   },
   
    CreateReservation : function(component, event, helper) {
        var opportunityId = component.get("v.recordId");
        console.log('opp: ' + opportunityId);
        if(!opportunityId){
            return;
        }
        
        this.showSpinner(component);
        
        this.getDispatcher(component)
        .action(this.AppSettings.Actions.CreateReservation)
        .onSuccess(this.handleCreateResSuccess)
        .onError(this.handleCreateResError)
        .run({ "opportunityId": opportunityId
             });
        
    },    
    
    handleCreateResSuccess: function(component, response, helper) {
        console.log('success: ' + response);
        var jsonresponse = JSON.parse(response);
        var resid = jsonresponse.Data;
        
        console.log('resid: ' + resid);
        
        this.hideSpinner(component);
        
        var navEvt = $A.get("e.force:navigateToSObject");
        navEvt.setParams({
            "recordId": resid
        });
        navEvt.fire();
        
    },
    
    handleCreateResError: function(component, error) {
        this.hideSpinner(component);
        component.set('v.callbackresult','ERROR');
        component.set('v.callbackmessage',error);
    },  
    
    showSpinner: function(component) {
        var spinner = component.find("loadingSpinner");
        $A.util.removeClass(spinner, "slds-hide");
    },
    
    hideSpinner: function(component) {
        var spinner = component.find("loadingSpinner");
        $A.util.addClass(spinner, "slds-hide");
    },
    
    
})