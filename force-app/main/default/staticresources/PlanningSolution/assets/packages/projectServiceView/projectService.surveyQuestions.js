(function(A){
  'use strict';

  A.module("app.projectServiceView.surveyQuestions.model",[
    "cmk.web.context",
    "cmk.system.async"
  ])
  .factory("projectServiceViewSurveyQuestionsModel",[
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

  A.module("app.projectServiceView.surveyQuestions",[
    "ui.router",
    "cmk.web.context",
    "app.projectServiceView.surveyQuestions.model"
  ])
  .config([
    "$stateProvider",
    "cmkWebContext",
    function($stateProvider, _webContext) {
      $stateProvider.state("projectServiceView.surveyQuestions", {
        resolve: {
          questions: [
            "projectServiceViewSurveyQuestionsModel",
            function(model) {
              return model.getQuestions();
            }
          ]
        },
        url: "/surveyQuestions",
        templateUrl: _webContext.applicationPath + "/assets/packages/projectServiceView/projectService.surveyQuestions.html",
        controller: "ProjectServiceViewSurveyQuestionsStateController"
      });
    }
  ])
  .controller("ProjectServiceViewSurveyQuestionsController", [
    "$scope",
    function($scope){
      console.log("---- init survy controller ---");
    }
  ])
  .controller("ProjectServiceViewSurveyQuestionsStateController", [
    "$scope",
    "$log",
    "questions",
    function($scope, $log, questions) {
      $log.log(questions);
      //todo add your controller logic here
    }
  ]);

})(angular);
