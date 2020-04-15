({
	doInit : function(cmp, event, helper) {
		var spinner = cmp.find("displaySpinner");
        var action = cmp.get("c.GetJobCancelReasons");
        var inputsel = cmp.find("jobCancelReason");        
        var opts = [];      
        $A.util.removeClass(spinner, "slds-hide"); 
        action.setCallback(this, function(a) {
            for(var i=0;i< a.getReturnValue().length;i++){
                opts.push({"class": "optionClass", label: a.getReturnValue()[i], value: a.getReturnValue()[i]});
            }
            inputsel.set("v.options", opts);
            $A.util.addClass(spinner, "slds-hide"); 
        });
        $A.enqueueAction(action);      
	},
   ConfirmCancelJobs:function(component, event, helper)
    {   
        var jobIds = component.get("v.jobIds");
        var inputCmp = component.find("jobCancelReason");
        var value = inputCmp.get("v.value");       
        var commentCmp = component.find("cancelReasonComment");		
        var commentTxt = commentCmp.get("v.value");
        var spinner = component.find("displaySpinner");
        
        inputCmp.set("v.errors", null);
        commentCmp.set("v.errors",null);
        
        if (value==null || value=='--SELECT--') {            
            inputCmp.set("v.errors", [{message:"Select cancel reason"}]);
        } else if (value=='Other' && (commentTxt==null || commentTxt.trim()=='')) {        
            commentCmp.set("v.errors", [{message:"Please enter comments"}]);
        }
        else {                        
            helper.cancelSelectedJobs(component,jobIds,value,commentTxt);            
        }
    }
})