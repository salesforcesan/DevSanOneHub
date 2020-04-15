/* CROSSMARK angular-ui-salesforce design system
 * Version: 0.0.1 - 2015-08-05
 * License: MIT
 */


/* 
 * cmkPicklist implementation
 * usage: 
 *  <cmk-picklist 
      model="picklistModel" 
      placeholder="Select a Hello" 
      on-changed="onChanged()" 
      cssclass="cm-label-10" 
      ng-cloak>
    </cmk-picklist>
 * model:{option: {key: "", value:""}, options: [{key:"",value:""}]}
 * cssclass: picklist box style 
 * code sample:

 .controller('SampleController', function($scope, $log) {
  var _self = this, _scope = $scope;
  $scope.dashboard = {
    queryId: "1"
  };

  var model = {
    option: {
      key: "1",
      value: "hi option 1"
    },
    options: [{
      key: "1",
      value: "hi 1option 1"
    }, {
      key: "2",
      value: "hi ption 2"
    }, {
      key: "3",
      value: "hi option 3"
    }]
  };

  _scope.model1 = model;

  _scope.$watch("dashboard.queryId", function(newValue, oldValue){
    if (newValue === oldValue) { return;}
    alert("old:" + oldValue + " new:" + newValue);
  });
 */
(function(A) {
  A.module("cmk.ui.picklist", ["cmk.web.context", "ngSanitize"])
    .directive("cmkPicklist", ["cmkWebContext", "$log", function(webContext, $log) {
      var _staticPath = webContext.staticResourcePath;
      return {
        restrict: "EA",
        transclude: true,
        require: ["cmkPicklist", "^ngModel"],
        scope: {
          width: "=",
          alignment: "@",
          placeHolder: "@placeholder",
          onChanged: "&onChanged",
          model: "=datasource",
          cssclass: "@"
        },
        controller: "PickListController",
        template: function() {
          return '<div aria-expanded="{{uiModel.isHidden === false}}" class="picklist">' +
            '<button class="button button--neutral picklist__label {{cssclass}} truncate" ng-blur="onBlur()" data-id="{{model.option.key}}" ng-click="wantToSelect($event)" aria-haspopup="true">' +
            '<span ng-bind-html="model.option.value"></span>' +
            '<svg aria-hidden="true" class="icon">' +
            '<use xlink:href="' + _staticPath + '/assets/icons/utility-sprite/svg/symbols.svg#down"></use></svg></button>' +
            '<div class="dropdown dropdown--small dropdown--menu {{uiModel.alignment}} cm-dropdown-menu" ng-hide="uiModel.isHidden">' +
            '<ul class="dropdown__list" role="menu" ng-style="uiModel.lookupPostionStyle" ng-mouseover="onMouseOver()" ng-mouseleave="onMouseLeave()">' +
            '<li ng-repeat="item in model.options" class="dropdown__item has-icon--left" aria-selected="{{item.selected}}" tabindex="-1" role="option">' +
            '<a href="#" data-id="{{$index}}" class="truncate">' +
            '<svg aria-hidden="true" ng-if="item.selected" class="icon icon--small icon--left"><use xlink:href="' + _staticPath + '/assets/icons/standard-sprite/svg/symbols.svg#task2"></use></svg>' +
            '<span ng-bind-html="item.value"></span></a></li></ul></div></div>';
        },
        link: function(scope, element, attrs, controllers) {
          element.on("click", "a", function(e) {
            e.preventDefault();
            var index = parseInt(A.element(this).attr("data-id"));
            controllers[0].onSelect(index, controllers[1]);
          });
        }
      };
    }])

  .controller('PickListController', ["$scope", "$log", function($scope, $log) {
    var _self = this,
      _isMouseOver = 0,
      _scope = $scope,
      _model = $scope.model,
      _width = !!_scope.width ? _scope.width : 200,
      _uiModel = _scope.uiModel = {
        isHidden: true,
        alignment: "dropdown--left",
        lookupPostionStyle: {
          width: _width
        }
      };

    if (!!_scope.alignment && _scope.alignment === "right") {
      _uiModel.alignment = "dropdown--right";
    }

    function enhanceModel() {
      if (!_model) {
        _model = {
          option: {
            key: "",
            value: "Select ..."
          },
          options: []
        };
        _scope.model = _model;
        return;
      }

      if (!_model.option || !_model.option.value) {
        _model.option = {
          key: "",
          value: (!!_scope.placeHolder) ? _scope.placeHolder : "Select ..."
        };
      }
      if (!_model.options) {
        _model.options = [];
      } else {
        _model.options.forEach(function(option) {
          if (option.key === _model.option.key) {
            option.selected = true;
          } else {
            option.selected = false;
          }
        });
      }
    }

    enhanceModel();

    _scope.wantToSelect = function(event) {
      _uiModel.isHidden = !_uiModel.isHidden;
    };

    function selectOption(index) {
      _model.options.forEach(function(item) {
        item["selected"] = false;
      });
      _uiModel.isHidden = true;
      _model.options[index]["selected"] = true;
      _model.option = _model.options[index];
      _isMouseOver = 0;
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

    _self.onSelect = function(index, modelController) {
      _scope.$apply(function() {
        selectOption(index);
        modelController.$setViewValue(_model.options[index].key);
        if (!!_scope.onChanged) {
          _scope.onChanged();
        }
      });
    };

  }]);


   /*
    * ------ how to use sfs PILL UI element ------
    *<div cmk-pill="1" data-id="12" title="modelTitle" img-url="" mode="text | link | portrait" on-click="onClick(dataId)"  on-remove="onRemove(dataId)" ></div>
    */

     A.module("cmk.ui.pill", ["cmk.web.context", "ngSanitize"])
       .directive("cmkPill", ["cmkWebContext", "$log", function(webContext, $log) {
         var _staticPath = webContext.staticResourcePath;
         return {
           restrict: "EA",
           scope: {
             isHidden: "@isHidden",
             onRemove: "&onRemove",
             title: "@"
           },
           template: function() {
             return '<span ng-if="isHidden == 0"><span class="pill"><span class="pill__label" ng-bind-html="title"></span><button class="button button--icon-bare">' +
               '<svg aria-hidden="true" class="button__icon"><use xlink:href="' + _staticPath + '/assets/icons/utility-sprite/svg/symbols.svg#close"></use>' +
               '</svg><span class="assistive-text">Remove</span></button></span></span>';
           },
           link: function(scope, element, attrs) {
             element.on("click", "button", function(e) {
               e.preventDefault();
               scope.$apply(function() {
                 scope.onRemove();
               });

             });
           }
         };
       }]);

})(angular);
