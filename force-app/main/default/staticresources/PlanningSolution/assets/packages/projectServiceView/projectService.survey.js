(function(A){
  'use strict';

  A.module("app.projectService.survey.model",[
    "cmk.web.context",
    "cmk.system.async"
  ])
  .factory("projectServiceSurrveyModel",[
    "cmkSystemAsync",
    "cmkWebContext",
    function(async, webContext){
      return {
        getQuestions: function() {
          var projectServiceId = webContext.projectServiceId;
          console.log("please implement getQuestions() remoting call.");
        }
      };
    }
  ]);

  A.module("app.projectService.survey",[
    "ui.router",
    "cmk.web.context",
    "app.projectService.survey.model"
  ])
  .config([
    "$stateProvider",
    "cmkWebContext",
    function(stateProvider, webContext) {
      stateProvider.state("projectService.survey", {
        resolve: {
          questions: [
            "projectServiceSurveyModel",
            function(model) {
              return model.getQuestions();
            }
          ]
        },
        url: "/survey",
        templateUrl: webContext.applicationPath + "/assets/packages/projectServiceView/projectService.survey.html",
        controller: "ProjectServiceSurveyStateController"
      });
    }
  ])
  .controller("ProjectServiceSurveyController", [
    "$scope",
    function($scope){

    }
  ])
  .controller("ProjectServiceSurveyStateController", [
    "$scope",
    "$log",
    "questions",
    function($scope, $log, questions) {
      $log.log(questions);
      //todo add your controller logic here
    }
  ]);

})(angular);
