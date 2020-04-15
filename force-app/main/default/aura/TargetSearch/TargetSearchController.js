({
    switchToPasteView : function(component, event, helper) {        
        component.set("v.view", "paste");
    },
    
    switchToSearchView : function(component, event, helper) {        
        component.set("v.view", "search");
    },
    
    doInit : function(component, event, helper) { 
        
          helper.onInit(component, event, helper);
       
    },
    onChangeTargetUseType:function(component, event, helper)
    {
        var targetUseType = event.getSource().get("v.value");
       // console.log(targetUseType);
       
      // var x = component.find("targetuseTypeId").get("v.value");
        component.set("v.selectedUseType",targetUseType);
    },
    
    close : function(component, event, helper) {  
        
        var userevent = $A.get("e.c:EventHideModal");
        userevent.fire();
    },
    
    addProducts : function(component, event, helper) {   
     
        var targets = component.get("v.targets");
        var projectServiceId = component.get("v.projectServiceId");       
       // console.log("Target-ProjectServiceId:" + projectServiceId);
       var targetuseTypes = component.get("v.targetuseTypes");
        var selectedTarget='';
        
        if(!$A.util.isEmpty(targetuseTypes))
        {
            targetuseTypesCount = targetuseTypes.length;
            
           // console.log('targetuseTypesCount::'+targetuseTypesCount);
            //console.log('first element++++'+ targetuseTypes[0].toString());
            
            if(targetuseTypesCount > 0)
            {
                if(!$A.util.isEmpty(component.get("v.selectedUseType")))
                {
                    selectedTarget = component.get("v.selectedUseType");
                }
                else
                {
                
                     var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                      "message": 'Please Select TargetUse Type',
                      "type": 'error'
                    });
                    toastEvent.fire();
                    return;
                }
                
              
                                 
            }
            else
            {
               selectedTarget = targetuseTypes[0].toString();
            }
        }
        
            
        var targetStrings = [];
        
        targets.forEach(function(element) { if(element.Selected) { targetStrings.push(element.TargetId); }});

        console.log("Targets:" + targets);
        console.log("TargetString:" + targetStrings);

        //alert(targetStrings);
        if(targetStrings == null || targetStrings == ''){
            return;
        }
        
        
        
       var action = component.get("c.AddTargets");
        action.setParams({            
            "targetArray" : targetStrings,
            "projectServiceId" :projectServiceId,
            "targetUserType": selectedTarget
        });
        
        
        action.setCallback(this,function(response){   
            var result = JSON.parse(response.getReturnValue());
            
            
            var userevent = $A.get("e.c:EventHideModal");
            userevent.fire();
            
            
            var appEvent = $A.get("e.c:ProjectServiceTargetChange"); 
            appEvent.setParams({ "state" : result.State });
            appEvent.setParams({ "message" : result.Message });
            console.log(appEvent);
            appEvent.fire();
            $A.util.addClass(component.find("addTargetSpinner"), "slds-hide");
            
        });
        
        $A.enqueueAction(action);
    },
    showToast: function(title, message, type) {
    var toastEvent = $A.get("e.force:showToast");
    toastEvent.setParams({
      "message": message,
      "type": type
    });
    toastEvent.fire();
  },
    
    onKeyHandle: function(component, event, helper) {
        var isEnterKey = event.keyCode === 13;
        if (!!isEnterKey) {
           helper.handleSearch(component, event, helper);   
        }
    },
    
    handleSearch : function(component, event, helper) {
        helper.handleSearch(component, event, helper);
    },
    
   
    
    handleCSVSearch : function(component, event, helper)
    {       
        
        var searchText = component.find("searchTextCSV").get("v.value");
        if (!searchText) return;
        
        
        
        var selectedProjectServiceId = component.get("v.projectServiceId");
        
        
        //var selectedTargetType = component.find("selectType").get("v.value")
        var action = component.get("c.GetTargetsCSV");
        action.setParams({            
            "searchTextCSV" : searchText,
             "projectServiceId": selectedProjectServiceId
        });
        
        action.setCallback(this,function(response){   
            var targets = response.getReturnValue();
            
            if(targets.length == 0)
            {                
                component.set("v.showNoCSVResultsMessage",true);               
            }
            else
            {
                component.set("v.showNoCSVResultsMessage",false);
            }
            
            component.set("v.targets",targets); 
            component.set("v.showCSVResults",true);
            
        });
        
        $A.enqueueAction(action);
    },
    back: function(cmp, e, h) {
        cmp.set('v.view', "chooseMethod");
    },
    
    
    
    
})