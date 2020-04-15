 /* CROSSMARK angular-ui-salesforce design system
  * Version: 0.0.1 - 2015-08-05
  * License: MIT
  * Update: 2015-09-30
  * Description: Update to SLDS 
  *
  * Pagelet Container UI component
  */

 (function(A) {
   A.module("cmk.ui.dropdown.area", ["cmk.web.context", "ngSanitize"])
     .directive("cmkDropdownArea", ["cmkWebContext", "$log", function(webContext, $log) {
       var _staticPath = webContext.staticResourcePath;
       return {
         restrict: "EA",
         transclude: true,
         //require: ["cmkPicklist", "^ngModel"],a
         require: ["cmkDropdownArea"],
         scope: {
           width: "=",
           title: "@",
           alignment: "@",
           onInit: "&onInit",
           placeHolder: "@placeholder",
           cssclass: "@",
           icon: "@"
         },
         controller: "DropdownAreaController",
         template: function() {
           return '<div aria-expanded="{{uiModel.isHidden === false}}" class="slds-picklist">' +
             '<button class="slds-button slds-button--icon-more {{cssclass}} slds-truncate" ng-click="wantToSelect($event)" ng-blur="onBlur()" aria-haspopup="true">' +
             '<svg aria-hidden="true" class="slds-button__icon">' +
             '<use xlink:href="{{icon}}"></use></svg></button>' +
             '<div class="slds-dropdown slds-dropdown--small slds-dropdown--nubbin-top slds-dropdown--menu {{uiModel.alignment}} cm-dropdown" ng-style="uiModel.lookupPostionStyle" ng-hide="uiModel.isHidden">' +
             '<div class="cm-dropdown-area" ng-mouseover="onMouseOver()" ng-mouseleave="onMouseLeave()">' + 
             '<div class="cm-article">' +
             '<header class="slds-clearfix">' +
             '<div class="slds-float--left">' +
             '<h2 class="slds-text-heading--label slds-text-heading--large cm-article-title">{{uiModel.title}}</h2></div>' + 
             '<div class="slds-float--right cm-float-right">' +
             '<button title="Close" ng-click="onClose()" class="slds-button slds-button--icon-border slds-button--icon-border-small">' +
             '<svg aria-hidden="true" class="slds-button__icon slds-button__icon--small cm-icon">' +
             '<use xlink:href="' + _staticPath + '/assets/icons/utility-sprite/svg/symbols.svg#close"></use>' +
             '</svg><span class="slds-assistive-text">Close</span></button></div></header></div>' +
             '<ng-transclude></ng-transclude></div>'  +
             '</div>' +
             '</div>';
         }
       };
     }])

   .controller('DropdownAreaController', ["$scope", "$log", function($scope, $log) {
     var _self = this,
       _isMouseOver = 0,
       _isFirstTime = 1,
       _scope = $scope,
       _width = !!_scope.width ? _scope.width : 200,
       _uiModel = _scope.uiModel = {
         isHidden: true,
         title: _scope.title,
         alignment: "slds-dropdown--" + (_scope.alignment || "left"),
         lookupPostionStyle: {
           width: _width
         }
       };

     if (!!_scope.alignment && _scope.alignment === "right") {
       _uiModel.alignment = "slds-dropdown--right";
     }


     _scope.wantToSelect = function(event) {
       _uiModel.isHidden = !_uiModel.isHidden;
       if (_isFirstTime && !!_scope.onInit && !_uiModel.isHidden) {
        _isFirstTime = 0,
        _scope.onInit();
       }
     };


     _scope.onBlur = function() {
       if (_isMouseOver === 0) {
         _uiModel.isHidden = true;
       }
     };

     _scope.onMouseOver = function() {
       _isMouseOver = 1;

     };

     _scope.onMouseLeave = function() {
       _isMouseOver = 0;
     };

     _scope.onClose = function() {
      _isMouseOver = 0;
      _scope.onBlur();
     }

   }]);

 })(angular);
