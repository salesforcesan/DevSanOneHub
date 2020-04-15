({
	doInit : function(component, event, helper) {        
        var today = new Date();
        component.set('v.day', today.getFullYear() + "-" + (today.getMonth() + 1) + "-" + today.getDate());
        /*
        var dtPicker = component.find("rescheduleDate");        
        var project = component.get("v.project");        
        dtPicker.set("v.startDate",project.StartDate);
        dtPicker.set("v.endDate",project.EndDate);
        dtpicker.set("v.value",component.get("v.day"));
        dtpicker.set("v.isMultipleSelection",false);*/
	},
    ConfirmAttemptJobs:function(component, event, helper)
    {
        var dtPicker = component.find('rescheduleDate');
        var selectedJobIds = component.get("v.selectedJobIds");         
		
		if(selectedJobIds.length<=0)            
             dtPicker.set("v.errors", [{message:"No Jobs selected to Re-Attempt"}]);
        
        var project = component.get("v.project");
        var selectedDate = component.get('v.day');
        var todaysDate = new Date();
        
        if((selectedDate>project.EndDate) || (selectedDate<project.StartDate))
        	{dtPicker.set("v.errors", [{message:'Re-Attempt Date should be within the Project Start:' + project.StartDate +' and End:' + project.EndDate +' Dates'}]);}        
        else if(selectedDate<todaysDate)
        	{dtPicker.set("v.errors", [{message:"Re-Attempt Date should be greater than today"}]);}
        else
            helper.createAttempts(component, event, helper);
    }
})