({
    onInit : function(component, event, helper)
    {
       //this._getTargetTypes(component, event, helper);
       this._getTargetUseTypes(component, event, helper);
       this._getTargetTypes(component, event, helper);
        
    },
    _getTargetTypes: function (component, event, helper)
 	{
      var action = component.get("c.GetTargetTypes");
        action.setCallback(this,function(response){   
            var targetTypesResults = response.getReturnValue();
            var opts = targetTypesResults.map(function(element) {
                return { class: "optionClass", label: element, value: element};
            });
            component.set("v.targetTypes", opts);
        });
        $A.util.addClass(component.find("addTargetSpinner"), "slds-hide");
        $A.enqueueAction(action);
 	},
    _getTargetUseTypes: function(component, event, helper)
    {
        
        var projectServiceId = component.get("v.projectServiceId"); 
        console.log(projectServiceId);
          var action = component.get("c.GetTargetUseTypes");
           action.setParams({            
           "projectServiceId": projectServiceId
        });
        
        action.setCallback(this,function(response){   
            var targetTypesResults = response.getReturnValue();
           if(!$A.util.isEmpty(targetTypesResults))
            {
          	  component.set("v.targetuseTypes", targetTypesResults);
            }
           
        });
     
        $A.enqueueAction(action);
    },
   
  
   handleSearch : function(component, event, helper)
    {   
        var searchText = component.find("searchText").get("v.value");
        if (!searchText) return;
        
        var selectedTargetType = component.find("selectType").get("v.value");
        var action = component.get("c.GetTargets");
        //var button = event.getSource();
        var selectedProjectServiceId = component.get("v.projectServiceId");
        
        action.setParams({            
            "searchText" : searchText,
            "targetType" :selectedTargetType,
            "projectServiceId": selectedProjectServiceId
        });
        
        component.set("v.targets",null);
        component.set("v.disabled",true); // Disable the button while we execute the search
        
        action.setCallback(this,function(response){   
            var targets = response.getReturnValue();
            if (!targets) { targets = []; }
            console.log("targets", targets);
            
            if(targets.length == 0)
            {                
                component.set("v.showNoResultsMessage",true);               
            }
            else
            {
                component.set("v.showNoResultsMessage",false);
            }
            
            component.set("v.targets",targets); 
            
            component.set("v.disabled",false); // Enable the button when search returns
           
        });
        
        $A.enqueueAction(action);
    },
})