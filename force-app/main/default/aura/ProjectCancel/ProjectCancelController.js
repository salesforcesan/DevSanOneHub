({
    doInit : function(cmp,event,helper) {
        helper.loadProjectDetails(cmp);
    },
    ConfirmCancelProject:function(component, event, helper)
    {
        //Validation
        var inputCmp = component.find("projectCancelReason");
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
            helper.cancelSelectedProject(component, event, helper);            
        }
    }
})