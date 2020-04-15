({
    
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
    }
})