 /* CROSSMARK angular-ui-salesforce design system
  * Version: 0.0.1 - 2015-08-05
  * License: MIT
  *
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
           return '<div aria-expanded="{{uiModel.isHidden === false}}" class="picklist">' +
             '<button class="button button--icon-more {{cssclass}} truncate" ng-click="wantToSelect($event)" ng-blur="onBlur()" aria-haspopup="true">' +
             '<svg aria-hidden="true" class="button__icon">' +
             '<use xlink:href="{{icon}}"></use></svg></button>' +
             '<div class="dropdown dropdown--small dropdown--nubbin-top dropdown--menu {{uiModel.alignment}} cm-dropdwon" ng-style="uiModel.lookupPostionStyle" ng-hide="uiModel.isHidden">' +
             '<div class="cm-dropdown-area" ng-mouseover="onMouseOver()" ng-mouseleave="onMouseLeave()">' + 
             '<div class="cm-article">' +
             '<header class="clearfix">' +
             '<div class="float-left">' +
             '<h2 class="text-heading--label text-heading--large cm-article-title">{{uiModel.title}}</h2></div>' + 
             '<div class="float-right cm-float-right">' +
             '<button title="Close" ng-click="onClose()" class="button button--icon-border button--icon-border-small">' +
             '<svg aria-hidden="true" class="button__icon button__icon--small cm-icon">' +
             '<use xlink:href="' + _staticPath + '/assets/icons/utility-sprite/svg/symbols.svg#close"></use>' +
             '</svg><span class="assistive-text">Close</span></button></div></header></div>' +
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
         alignment: "dropdown--" + (_scope.alignment || "left"),
         lookupPostionStyle: {
           width: _width
         }
       };

     if (!!_scope.alignment && _scope.alignment === "right") {
       _uiModel.alignment = "dropdown--right";
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
