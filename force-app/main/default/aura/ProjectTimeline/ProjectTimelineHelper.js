({
    getTimelinePoint: function(status) {

        var timelinePoint = 0;
        if (status == 'Planning') {
            timelinePoint = 1;
        } else if (status == 'Pending') {
            timelinePoint = 2;
        } else if (status == 'Booked') {
            timelinePoint = 3;
        } else if (status == 'Launched') {
            timelinePoint = 4;
        } else if (status == 'In Progress') {
            timelinePoint = 5;
        } else if (status == 'Ended') {
            timelinePoint = 6;
        } else if (status == 'Closed') {
            timelinePoint = 7;
        } else if (status == 'Canceled') {
            timelinePoint = -1;
        }
        return timelinePoint;

    },
    setTimelinePoints: function(component, timelinePoint) {
        var comp,
            timelineClass;

        if (timelinePoint < 0) {
            timelineClass = 'timeline-bar-activated-1';
            comp = component.find('planning');
            $A.util.addClass(comp, 'activated');
            var statusText = component.find("planningText");
            var ele = statusText.getElement();
            ele.innerText = "CANCELED";
            var circle = component.find('planningCircle');
            //$A.util.removeClass(circle,'timeline-circle');
            $A.util.addClass(circle, 'timeline-circle-canceled');
        }

        if (timelinePoint > 0) {
            timelineClass = 'timeline-bar-activated-1';
            comp = component.find('planning');
            $A.util.addClass(comp, 'activated');
        }
        if (timelinePoint > 1) {
            timelineClass = 'timeline-bar-activated-2';
            comp = component.find('pending');
            $A.util.addClass(comp, 'activated');
        }
        if (timelinePoint > 2) {
            timelineClass = 'timeline-bar-activated-3';
            comp = component.find('booked');
            $A.util.addClass(comp, 'activated');
        }
        if (timelinePoint > 3) {
            timelineClass = 'timeline-bar-activated-4';
            comp = component.find('launched');
            $A.util.addClass(comp, 'activated');
        }
        if (timelinePoint > 4) {
            timelineClass = 'timeline-bar-activated-5';
            comp = component.find('started');
            $A.util.addClass(comp, 'activated');
            $A.util.removeClass(component.find('ended'), 'activated');
            $A.util.removeClass(component.find('timeline'), 'timeline-bar-activated-6');
        }
        if (timelinePoint > 5) {
            timelineClass = 'timeline-bar-activated-6';
            comp = component.find('ended');
            $A.util.addClass(comp, 'activated');
        }
        if (timelinePoint > 6) {
            timelineClass = 'timeline-bar-activated-7';
            comp = component.find('closed');
            $A.util.addClass(comp, 'activated');
        }

        if (timelinePoint > 7) {
            timelineClass = 'timeline-bar-activated-8';
            comp = component.find('canceled');
            $A.util.addClass(comp, 'activated');
        }

        comp = component.find('timeline');
        $A.util.removeClass('timeline-circle');
        $A.util.addClass(comp, timelineClass);

    },
    getProjectDetails: function(cmp) {
        var action = cmp.get("c.GetProject");
        console.log('Project Id: ' + cmp.get("v.recordId"));

        action.setParams({recordId: cmp.get("v.recordId")});
        var self = this;
        action.setCallback(this, function(response) {
            console.log('Project Data: ' + response.getReturnValue());
            cmp.set("v.project", response.getReturnValue());

            var project = cmp.get("v.project");
            if (project) {
                timelinePoint = self.getTimelinePoint(project.StatusDisplay);
            } else {
                timelinePoint = self.getTimelinePoint("Planning");
            }
            self.setTimelinePoints(cmp, timelinePoint);

        });
        $A.enqueueAction(action);
    }
})