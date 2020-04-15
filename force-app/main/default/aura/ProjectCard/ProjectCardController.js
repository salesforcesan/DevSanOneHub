({
	doInit: function(cmp, event, helper) {

        //console.log('doInit from controller');
        //console.log(cmp.get('v.project'));
        var project = cmp.get('v.project');
        if(project.Status === undefined){
            debugger;
        }
        var projectStatus = project.Status,
    	projectState = 'Build',
        projectHealth = 'good',
        stateColor = '#0070D2',
        alertState = project.NumberofJobsException > 0 || project.NumberofJobsFailedQC;
        
        // Determine project state for hide/show charts and other card features
        if (projectStatus == 'Launched' || projectStatus == 'In Progress') {
            projectState = 'Execute';
        } else if (projectStatus == 'Finished' || projectStatus == 'Canceled' || projectStatus == 'Closed') {
            projectState = 'Report';
        }

        // Determine base bar color
        if (projectStatus == 'Launched' || projectStatus == 'In Progress') {
            stateColor = '#04844B';
        } else if (projectStatus == 'Finished') {
            stateColor = '#A8B7C7';
        } else if (projectStatus == 'Closed' || projectStatus == 'Canceled') {
            stateColor = '#54698D ';
        }

        // Determine error / alert state
        // Alert: #FFB75D
        // Error: #C23934
        if (alertState) {
        	stateColor = '#FFB75D';
        }

        cmp.set('v.alertState', alertState);
		cmp.set('v.stateStyle', 'background-color:' + stateColor + ';');

	},
    navigateToRecord: function(cmp, event, helper) {
        var navEvent = $A.get("e.force:navigateToSObject");
        console.log(navEvent, 'navEvent');
        console.log('IDDDD: '+ cmp.get("v.project").Id, 'cmp.get("v.project").Id');
        // recordId: "a0c41000000IP6pAAG",
        navEvent.setParams({
            "recordId": cmp.get("v.project").Id,
            "slideDevName": "detail"
        });
        navEvent.fire();
    }
})