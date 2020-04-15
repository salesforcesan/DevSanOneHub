/* CROSSMARK angular-ui-salesforce design system
 * Version: 0.0.1 - 2015-08-05
 * License: MIT
 * Update: 2015-09-30
 * Description: Updated to SLDS
 * Dropdown UI component
 */
(function(A) {

  function selMenuItem(menuModel, selId) {
    var menuItems = menuModel.menuItems, selItem;

    if (!!selId) {
      menuItems.forEach(function(item) {
        if (item.key === selId) {
          selItem = item;
          item.selected = 1;
          item.cssSelected = "slds-is-selected";
        } else {
          item.cssSelected = "";
          item.selected = 0;
        }
      });
    } else {

      menuItems.forEach(function(item) {
        if (item.selected === 1) {
          selItem = item;
          item.cssSelected = "slds-is-selected";
        } else {
          item.cssSelected = "";
        }
      });
    }

    if (!!menuModel.setSelectIcon && !!selItem) {
      menuModel.buttonUrl = selItem.leftIconUrl || selItem.rightIconUrl;
    }
  }

  A.module("cmk.ui.dropdown", ["cmk.web.context"])
    .directive("cmkDropdown", ["cmkWebContext", "$log", function(webContext, $log) {
      var _staticPath = webContext.staticResourcePath;
      return {
        restrict: "EA",
        transclude: true,
        scope: {
          alignment: "@",
          onClicked: "&onClicked",
          model: "=datasource",
          cssclass: "@"
        },
        controller: "DropdownListController",
        template: function(tElement, tAttrs) {
          return '<div class="slds-dropdown-trigger {{cssclass}}" aria-haspopup="true">' +
            '<button class="slds-button slds-button--icon-more" aria-haspopup="true">' +
            '<svg aria-hidden="true" class="slds-button__icon"><use xlink:href="{{model.buttonUrl}}"></use></svg>' +
            '<span class="slds-assistive-text">{{model.helpText}}</span>' +
            '<svg aria-hidden="true" class="slds-button__icon slds-button__icon--x-small">' +
            '<use xlink:href="' + _staticPath + '/assets/icons/utility-sprite/svg/symbols.svg#down"></use></svg></button>' +
            '<div class="slds-dropdown slds-dropdown--nubbin-top {{uiModel.alignment}} slds-dropdown--small slds-dropdown--menu">' +
            '<div class="slds-dropdown__header" ng-hide="angular.isUndefined(model.title)"><span class="slds-text-heading--label">{{model.title}}</span></div>' +
            '<ul class="slds-dropdown__list" role="menu">' +
            '<li data-id="{{item.key}}" ng-disabled="item.disabled === 1" ng-repeat="item in model.menuItems" aria-selected="{{item.selected === 1}}" class="slds-dropdown__item slds-has-icon--left" ng-class="item.cssSelected" role="menuitem option" tabindex="0">' +
            '<a href="#{{item.key}}" tabindex="-1" aria-disabled="{{item.disabled === 1}}">' +
            '<svg ng-if="!!item.leftIconUrl" aria-hidden="true" class="slds-icon slds-icon--small slds-icon--left">' +
            '<use xlink:href="{{item.leftIconUrl}}"></use></svg>' +
            '<svg aria-hidden="true" ng-if="model.showSelectIcon && item.selected" class="slds-icon slds-icon--small slds-icon--left"><use xlink:href="' + _staticPath + '/assets/icons/standard-sprite/svg/symbols.svg#task2"></use></svg>' +
            '<span>{{item.value}}</span>' +
            '<svg ng-if="!!item.rightIconUrl" aria-hidden="true" class="slds-icon slds-icon--small slds-icon--right">' +
            '<use xlink:href="{{item.rightIconUrl}}"></use></svg></a></li></ul></div></div>';
        },
        link: function(scope, element, attrs, controller) {
          element.on("click", "a", function(e) {
            e.preventDefault();
            var id = A.element(this).parent("li").attr("data-id");
            selMenuItem(scope.model, id);
            scope.$digest();
            controller.onSelect(id);
          });
        }
      };
    }])
    .controller("DropdownListController", ["$scope", "$log", function($scope, $log) {
      var _self = this,
        _scope = $scope;
      _scope.uiModel = {
        alignment: ""
      };

      selMenuItem(_scope.model);

      if (!!_scope.alignment) {
        if (_scope.alignment === "left") {
          _scope.uiModel.alignment = "slds-dropdown--left";
        } else if (_scope.alignment === "right") {
          _scope.uiModel.alignment = "slds-dropdown--right";
        }
      }

      _self.onSelect = function(id) {
        if (!!_scope.onClicked) {
          _scope.onClicked({
            key: id
          });
        };
      }
    }]);

})(angular);
