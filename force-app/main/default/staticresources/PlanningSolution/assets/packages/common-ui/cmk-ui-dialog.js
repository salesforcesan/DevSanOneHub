(function(A){
  'use strict';
  A.module("cmk.ui.dialog",["cmk.web.context","ngSanitize"])
    .directive("cmkDialog",
    ["cmkWebContext",
    function(webContext){
      var _staticPath = webContext.staticResourcePath;
      return {
          restrict: "EA",
          transclude: true,
          scope: {
            model: "=model"
          },
          template: function() {
            return '<div class="cm-dialog-container cm-hide">' +
              '<div aria-hidden="false" role="dialog" class="slds-modal{{uiModel.cssModal}}slds-fade-in-open cm-hide">' +
              '<div class="slds-modal__container">' +
              '<div class="slds-modal__header" style="text-align: left">' +
              '<h2 class="slds-text-heading--medium">{{model.header}}</h2>' +
              '<button class="slds-button slds-button--icon-inverse slds-modal__close" ng-click="onClose()">' +
              '<svg aria-hidden="true" class="slds-button__icon slds-button__icon--large">' +
              '<use xlink:href="' + _staticPath + '/assets/icons/action-sprite/svg/symbols.svg#close"></use>' +
              '</svg>' +
              '<span class="slds-assistive-text">Close</span>' +
              '</button>' +
              '</div>' +
              '<div class="slds-modal__content"><ng-transclude></ng-transclude></div>' +
              '<div class="slds-modal__footer">' +
              '<button ng-repeat="btn in uiModel.buttons" class="slds-button slds-button--neutral{{btn.css}}" value="{{btn.value}}" ng-click="btn.onClick($event)">{{btn.label}}</button>' +
              '</div>' +
              '</div>' +
              '</div>' +
              '<div class="slds-modal-backdrop slds-modal-backdrop--open cm-hide"></div>' +
              '</div>';
          },
          controller: "DialogController",
          link: function(scope, element, attrs, controller) {
            scope.$watch(
              "model.showDialog",
              function(newValue, oldValue){
                if (newValue != oldValue){
                  element.find(".cm-dialog-container").toggleClass("cm-hide");
                  element.find(".slds-modal").toggleClass("cm-hide");
                  element.find(".slds-modal-backdrop").toggleClass("cm-hide");
                }
              }
            );
            element.bind("keydown", function(event){
              controller.onKeyPress(event);
            });
          }
      };
    }
    ])
    .controller("DialogController", [
      "$scope",
      function($scope){
        var self = this;

        function close(){
          $scope.model.showDialog = false;
        }

        $scope.uiModel = {
          cssModal: $scope.model.isLargeModal === 1 ? " slds-modal--large " : " ",
          buttons: _.map($scope.model.buttons, function(btn){
            return {
              label: btn.label,
              value: btn.value,
              css: btn.isPrimary === 1 ?  " slds-button--brand" : "",
              onClick: btn.onClick || function($event){ console.log($event);}
            };
          })
        };

        $scope.onClose = function(){
          close();
        };

        self.onKeyPress = function(event) {
          var keyCode = event.which || event.keyCode
          if (keyCode === 27){
            $scope.$apply(function(){
              close();
            });
            event.preventDefault();
          }
        };
      }
    ]);
})(angular);
