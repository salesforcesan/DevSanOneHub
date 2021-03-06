(function(A) {
"use strict";
var _calendarId = "div#projectCalendar";

function getHeight() {
  var h = window.innerHeight - A.element("div#tab-default-1").offset().top;
  return (h > 400) ? h - 150 : 400;
}

function initCalendar() {
  A.element(_calendarId).fullCalendar({
    header: {
      right: 'prev,next',
      left: 'title'
    },
    allDayDefault: true,
    eventLimit: 5,
    businessHours: true,
    editable: true,
    handleWindowResize: true,
    height: getHeight() + 30
  });
}

function transformEvents(project){
  var events = [],
      ms1, type, ref,
      dt1 = project.StartDate,
      dt2 = project.EndDate;

  if ((!!dt1 && isFinite(dt1)) && (!!dt2 && isFinite(dt2))) {
    dt1 =  new Date(dt1);
    dt2 =  new Date(dt2);
    dt1 = new Date(dt1.getFullYear(), dt1.getMonth(), dt1.getDate(), 0, 0, 0, 0);
    dt2 = new Date(dt2.getFullYear(), dt2.getMonth(), dt2.getDate(), 23, 11, 59, 999);
    events.push({
      title: "",
      start: dt1.toISOString(),
      end: dt2.toISOString(),
      color: 'steelblue'
    });
  }

  return events;
}

function setMonthData(project) {
    var events = transformEvents(project),
    calendarTarget = A.element(_calendarId);
    calendarTarget.fullCalendar('removeEvents')
    calendarTarget.fullCalendar('addEventSource', events);
    if (!!project.StartDate && isFinite(project.StartDate)) {
      calendarTarget.fullCalendar('gotoDate', project.StartDate);
    }
}

A.module("app.project.detail", [
    "ui.router",
    "cmk.web.context",
    "cmk.system.async"
  ])

 .config(["$stateProvider", "cmkWebContext", function(_stateProvider, _webContext) {
   _stateProvider.state("project.detail",{
     url: "/detail",
     templateUrl: _webContext.applicationPath + "/assets/packages/project/project.detail.html",
     controller: "ProjectDetailController"
   });

 }])

 .controller('ProjectDetailController',
     ['$scope','$log',"projectData","cmkWebContext",
       function($scope, $log, projectData, webContext){
         var project = projectData;
         $scope.details = [
           {
             label1: "Retailer",
             value1: project.Retailer,
             label2: "Project Nubmer",
             value2: project.ProjectNumber
           },
           {
             label1: "Approver",
             value1: project.Approver,
             label2: "Group",
             value2: project.ProjectGroup
           },
           {
             label1: "Owner",
             value1: project.Owner,
             label2: "Sub Group",
             value2: project.ProjectSubGroup
           },
           {
             label1: "Can Reschedule",
             value1: (project.CanReschedule === true)
              ? ('<span class="cm-check"><svg aria-hidden="true" class="slds-button__icon--stateful">' +
                  '<use xlink:href="' + webContext.staticResourcePath + '/assets/icons/utility-sprite/svg/symbols.svg#check"></use></svg></span>')
              : '<span class="cm-uncheck"></span>',
             label2: "Imported Locations",
             value2: project.ImportedLocations
           },
           {
             label1: "Description",
             value1: project.Description,
             label2: "Budgeted Locations",
             value2: project.BudgetedLocations
           }
         ];
         $scope.projectViewModel.selDetail = true;
         $scope.audit = [
           {
             label1: "Created By",
             value1: project.CreatedBy,
             label2: "Created Date",
             value2: !isNaN(project.CreatedDate) ? new Date(project.CreatedDate).toISOString() : project.CreatedDate
           },
           {
             label1: "Last Modified By",
             value1: project.UpdatedBy,
             label2: "Last Modified Date",
             value2:  !isNaN(project.UpdatedDate) ? new Date(project.UpdatedDate).toISOString() : project.UpdatedDate
           }
         ];
         initCalendar();
         setMonthData(project);
     }]
 );


})(angular);
