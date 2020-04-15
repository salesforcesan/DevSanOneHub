({
    doInit: function(component, event, helper) {      

        var qtypecmp = component.find("QuestionType");
        qtypecmp.set("v.value",component.get("v.QuestionTypeValue"));
     
          	// Get the current filters
		var qtextcmp = component.find("QuestionText");
        var qtext = qtextcmp.get("v.value");

		var qtypecmp = component.find("QuestionType");
        var qtype = qtypecmp.get("v.value");
		
		var qtargetcmp = component.find("TargetQuestion");
        var qtarget = qtargetcmp.get("v.checked");
        
   	},
    keyPress: function(component, event, helper){
        if (event.getParams().keyCode === 13) {
           return false;
        }
	},
   	applyFilter: function(cmp, event, helper) {        
       	// Get the current filters
		var qtextcmp = cmp.find("QuestionText");
        var qtext = qtextcmp.get("v.value");

		var qtypecmp = cmp.find("QuestionType");
        var qtype = qtypecmp.get("v.value");
		
		var qtargetcmp = cmp.find("TargetQuestion");
        var qtarget = qtargetcmp.get("v.checked");


       	// Publish the changed filters  
	   	var appEvent = $A.get("e.c:EventSurveyQuestionFiltersChanged");
       	appEvent.setParams({ "questionText" : qtext });
       	appEvent.setParams({ "questionType" : qtype });
       	appEvent.setParams({ "targetQuestion" : qtarget });
       	appEvent.fire();
    },
   	clearFilter: function(cmp, event, helper) {
       	// Publish the changed filters  
	   	var appEvent = $A.get("e.c:EventSurveyQuestionFiltersChanged");
        
		var qtextcmp = cmp.find("QuestionText");
        qtextcmp.set("v.value", '');        

		var qtypecmp = cmp.find("QuestionType");
        qtypecmp.set("v.value",'None');
		
		var qtargetcmp = cmp.find("TargetQuestion");
		qtargetcmp.set("v.checked",false);
		
        
       	appEvent.setParams({ "questionText" : '' });
       	appEvent.setParams({ "questionType" : '' });
       	appEvent.setParams({ "targetQuestion" : '' });
       	appEvent.fire();
    }
    
})