({
	doInit : function(cmp, event, helper) {

        var percentComplete = cmp.get('v.percentComplete') || 0;
        var percentSla = cmp.get('v.percentSla') || 0;
        var slaRemaining = 0;

        // Dev testing values
        //percentSla = 80;
        //percentComplete = Math.ceil(Math.random() * 100);

        if (percentSla - percentComplete > 0) {
           slaRemaining = percentSla - percentComplete;
        }

        cmp.set('v.barCompleteStyle', 'width:' + percentComplete + '%;');
        cmp.set('v.barSlaRemainingStyle', 'width:' + slaRemaining + '%;');

        // Dev testing
        //cmp.set('v.percentComplete', percentComplete);
	}
})