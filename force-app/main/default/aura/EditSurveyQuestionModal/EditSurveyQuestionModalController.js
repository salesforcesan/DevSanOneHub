({
	doInit : function(component, event, helper) {
        helper.Init(component, event, helper);
        helper.getAILabelOptions(component, event, helper);
	},
    
    modelChange: function (cmp, evt, helper) {
        var val = cmp.find('aiModel').get('v.value');
        cmp.set('v.selectedValue', val);
        console.log('val: ', val);
    },
	saveChanges : function(component, event, helper) {
        
       	// Publish the changed filters  
       	/*
	   	var editQuestionEvent = $A.get("e.c:EventEditSurveyQuestion");
       	editQuestionEvent.setParams({ "question" : component.get("v.question")});
        console.log(component.get("v.question"));
       	editQuestionEvent.fire();
        
	   	var hideModalEvent = $A.get("e.c:EventHideModal");
       	hideModalEvent.fire();
        */
      
      /* if ((component.find("minVal")!= undefined))
    
          {
              console.log('inside++++++++');
            var inputMinCmp = component.find("minVal");
            var minValue = component.find("minVal").get("v.value");
            var message = ' Please enter Numeric Value in Minimum Value field';
            var  isemptycheck  =helper.isempty(component,minValue,message);
              console.log('inside++++++++'+ isemptycheck);
              
            if(isemptycheck)
              {
                  return;
              }
        
              
            if (isNaN(minValue))
             {
                 var message = ' Please enter Numeric Value in Minimum Value field';
                 
                 helper.showError(component,message)
                 return;
             }
           
          }
        
         if (component.find("MaxVal")!= undefined)
          {
         
            var maxValue = component.find("MaxVal").get("v.value");
             var message = ' Please enter Numeric Value in Maximum Value field';
            var  isemptycheck  = helper.isempty(component,maxValue,message);
             if(isemptycheck)
              {
                  return;
              }
              

            if (isNaN(maxValue))
             {
                 var message = ' Please enter Numeric Value in maxValue Value field';
                 
                 helper.showError(component,message)
                 return;
             }
           
            
          }*/
        
         var model = component.get('v.selectedValue');
         var question = component.get('v.question');
         console.log('question: ', question);
         question.AILabelId = model;
         if ((component.find("minVal")!= undefined) && (component.find("MaxVal")!= undefined))
         {
         var minValue = component.find("minVal").get("v.value");
         var maxValue = component.find("MaxVal").get("v.value");
         if (isNaN(minValue))
             {
                 var message = ' Please enter Numeric Value in min Value field';
                 
                 helper.showError(component,message)
                 return;
             }
           if (isNaN(maxValue))
             {
                 var message = ' Please enter Numeric Value in Max Value field';
                 
                 helper.showError(component,message)
                 return;
             }
          
             
        
         if(parseInt(minValue) > parseInt(maxValue))
         {
               var message = ' Please enter  minimum  Value less then maximum value';
                helper.showError(component,message)
                 return;
         }
         if(parseInt(maxValue) < parseInt(minValue))
         {
               var message = ' Please enter  maximum  Value greater then minimum value';
                helper.showError(component,message)
                 return;
         }
         }
      
        
        var editQuestionEvent = component.getEvent('editSurveyQuestion');
        editQuestionEvent.setParams({ "question": component.get("v.question") });
        editQuestionEvent.fire();

  },
  closeDialog: function(cmp, evt, helper) {
     
    var dlgEvt = cmp.getEvent('closeDialogEvent');
    dlgEvt.fire();
  }    
})