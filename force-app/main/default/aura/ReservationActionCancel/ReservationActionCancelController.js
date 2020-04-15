({
	 doInit : function(cmp,event,helper) {
       //component.set("v.callbackresult","NONE");  
       
        helper.getReservationDetails(cmp);
        helper.loadReservationCancelReasons(cmp);
    },
   donotcancelButtonClicked : function(component, event, helper) { 
        helper.CancelClicked(component, event, helper);
    },
    cancelButtonClicked : function(component, event, helper)
    {
        //Validation
        var inputCmp = component.find("reservationCancelReason");
        var value = inputCmp.get("v.value");        
		var commentCmp = component.find("cancelReasonComment");		
        var commentTxt = commentCmp.get("v.value");
              
        inputCmp.set("v.errors", null);
        commentCmp.set("v.errors",null);
            
        
        if (value==null || value=='--SELECT--') {            
            inputCmp.set("v.errors", [{message:"Select cancel reason"}]);
        }else if (value=='Other' && (commentTxt==null || commentTxt.trim()=='')) {        
            commentCmp.set("v.errors", [{message:"Please enter comments"}]);
        }
        else {            
            helper.cancelSelectedReservation(component, event, helper);            
        }
    }
    
    
})