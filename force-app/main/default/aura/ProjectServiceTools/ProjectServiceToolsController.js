({
	
    doInit : function(component, event, helper) {
        
       
        var timestamp = new Date().getUTCMilliseconds();
        component.set("v.uid", timestamp);
         component.set("v.securityelements", "Project__c.RL_Tools");
        var projectServiceId = component.get("v.recordId");       
        console.log('PS Id: ' + projectServiceId)
        var action = component.get("c.GetProjectServiceTools");
        action.setParams({
            "projectServiceId": projectServiceId
        });

        action.setCallback(this,function(response){   
            var tools = response.getReturnValue();
            component.set("v.tools",tools);  
            var editableElements = component.get("v.editableelements");       
            if(!!editableElements && editableElements["Project__c.RL_Tools"])
            {
                component.set("v.securityDisabled", false);         
            }

        });
        $A.enqueueAction(action);
    },
    
    handleClick : function(component, event, helper) {        
        
        var pointerDiv = component.find("parentDiv"); 
        //$A.util.removeClass(pointerDiv, "marknotreadonly");    
        //$A.util.addClass(pointerDiv, "markreadonly");
        
        var message;
        var messageTitle;
        
        var projectServiceId = component.get("v.recordId");        
        var checkbox = event.target;
	    var checked = checkbox.checked;  
        checkbox.disabled = true;
        var equipmentId = checkbox.id.substring(4,22); 
        console.log("checked:" + checked + '___'+equipmentId+ '___'+projectServiceId);
        console.log("checkbox.nextSibling", checkbox.nextSibling);
        //checkbox.nextSibling.parentNode.className += ' foo';
        //console.log("checkbox.nextSibling.parentNode", checkbox.nextSibling.parentNode);
        
        if(checked)
        {
            console.log("checked",checked);
            checkbox.nextSibling.style.background = "#4BCA81";
            checkbox.nextSibling.style.color = "#FFF";
        }
        else
        {
            console.log("not-checked",checked);
            checkbox.nextSibling.style = "";
        }
        
        
        var action = component.get("c.SetProjectServiceTool");
        action.setParams({
            "projectServiceId": projectServiceId,
            "equipmentId": equipmentId,
            "checked":checked
        });
        
        action.setCallback(this,function(result){
            var state = result.getState();
            messageTitle = 'Server Message';
            message = '';
            checkbox.disabled = false;
            if (state === "SUCCESS") {
               
            }
            else {
                
                
                var errors = result.getError();
                if (errors[0] && errors[0].message) // To show other type of exceptions
                    message = errors[0].message;
                if (errors[0] && errors[0].pageErrors) // To show DML exceptions
                    message = errors[0].pageErrors[0].message;
               console.log(message);
                helper._notify(component,'An error was encountered while saving the changes.  Please refresh the page and try again.  If the problem persists please contact the support desk.' , 'error');
                
                
            }
        });
        $A.enqueueAction(action);        

        $A.util.removeClass(pointerDiv, "markreadonly");    
        $A.util.addClass(pointerDiv, "marknotreadonly");
        
    }

})