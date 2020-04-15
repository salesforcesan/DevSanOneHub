(function(A){
  'use strict';
  A.module("cmk.uk.messagebar",["cmk.web.context","ngSanitize"])
   .directive("cmkMessagebar", [
     "cmkWebContext",
     function(webContext) {
       var _staticPath = webContext.staticResourcePath;
       return {
         restrict: "EA",
         transclude: true,
         scope: {
           model: "=model"
         }
       };
     },
     template: function(){

     },
     controller: "MessagebarController",
     link: function(scope, element, attrs, controller) {

     }
   ])
   .controller("MessagebarController",[
     "$scope",
     function($scope) {

     }
   ]);

})(angular);
