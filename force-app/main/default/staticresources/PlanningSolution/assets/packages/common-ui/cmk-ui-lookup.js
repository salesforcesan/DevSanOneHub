/* global angular */
/* CROSSMARK angular-ui-salesforce design system
 * Version: 0.0.1 - 2015-08-05
 * License: MIT
 * Update On: 2015-09-30
 * Update: updated to SLDS
 */

(function (A) {
  A.module("cmk.ui.lookup", ["cmk.web.context", "ngSanitize"])

    .directive("cmkLookup", ["cmkWebContext", "$timeout", "$log", function (webContext, $timeout, $log) {
      var _staticPath = webContext.staticResourcePath;

      return {
        restrict: "EA",
        transclude: true,
        require: ["cmkLookup", "^ngModel"],
        scope: {
          model: "=datasource",
          onChanged: "&onChanged",
          onLookup: "&onLookup",
          onSelRow: "&onSelRow",
          cssclass: "@",
          required: "@",
          alignment: "@",
          placeholder: "@placeholder",
          error: "@",
          width: "@",
          height: "@",
          layout: "@",
          icon: "@",
          columns: "@"
        },
        controller: "LookupController",
        template: function () {
          var html = '<div class="slds-lookup cm-lookup" data-select="single" data-scope="single" data-typeahead="true">' +
            '<div class="slds-form-element">' +
            '<div class="slds-lookup__control slds-input-has-icon slds-input-has-icon--right cm-input-lookup {{cssclass}}" ng-click="wantToLookup($event)">' +
            '<svg aria-hidden="true" class="slds-input__icon cm-input-icon">' +
            '<use xlink:href="' + _staticPath + '/assets/icons/utility-sprite/svg/symbols.svg#search"></use></svg>' +
            '<input style="width: 400px;" ng-model="model.selRow.value" ng-keyup="keyClicked($event)" ng-blur="onBlur()" ' +
            'data-id="{{model.selRow.key}}" class="slds-input" required="required" ng-if="required == 1" type="text" aria-label="lookup" aria-haspopup="true" aria-autocomplete="list" ' +
            'role="combobox" value="{{model.selRow.value}}" placeholder="{{placeholder}}"/>' +
            '<input ng-model="model.selRow.value" ng-keyup="keyClicked($event)" ng-blur="onBlur()" ' +
            'data-id="{{model.selRow.key}}" class="slds-input" style="width: 400px;" ng-if="required == 0" type="text" aria-label="lookup" aria-haspopup="true" aria-autocomplete="list" ' +
            'role="combobox" value="{{model.selRow.value}}" placeholder="{{placeholder}}"/>' +
            '<span ng-if="required == 1" class="slds-form-element__help">{{error}}</span>' +
            '</div>' +
            '</div>' +
            '<div class="slds-lookup__menu cm-lookup-menu" ng-style="uiModel.lookupPostionStyle" ng-hide="uiModel.isHidden" role="listbox">' +
            '<div ng-if="layout == 0" class="cm-lookup-ul" ng-mouseover="onMouseOver()" ng-mouseleave="onMouseLeave()">' +
            '<ul ng-if="layout == 0" class="cm-lookup-list" role="presentation">' +
            '<li class="slds-lookup__item slds-truncate" role="presentation" ng-repeat="row in model.rowset">' +
            '<a href="#" role="option" data-id="{{row[uiModel.idField]}}"><svg aria-hidden="true" ng-if="icon !== undefined" class="slds-icon slds-icon-standard-account slds-icon--small">' +
           // '<use xlink:href="' + _staticPath + '/assets/icons/standard-sprite/svg/symbols.svg#account"></use>' +
           '<use xlink:href="{{icon}}"></use>' +
            '</svg><span ng-bind-html="row[uiModel.fields[0]]"></span></a></li>' +
            '</ul></div>' +
            '<div class="cm-lookup-table" ng-if="layout == 1" ng-mouseover="onMouseOver()" ng-mouseleave="onMouseLeave()" >' +
            '<table ng-if="layout == 1" class="slds-table slds-tble--bordered slds-table--striped cm-table-border-no-top"><thead><tr class="slds-text-heading--label"><th scope="col" ng-repeat="col in uiModel.fields" class="slds-truncate"><span>{{col}}</span></th></tr></thead>' +
            '<tbody><tr ng-repeat="row in model.rowset" data-id="{{row[uiModel.idField]}}"><td ng-repeat="col in uiModel.fields" class="slds-truncate"><span ng-bind-html="row[col]"></span></td></tr></tbody></table>' +
            '</div></div>' +
            '</div>';
          return html;
        },
        link: function (scope, element, attrs, controllers) {
          var _timeout, _target = scope.layout === "1" ? "div.cm-lookup-table" : "div.cm-lookup-ul",
            _height = (!!scope.height) ? scope.height + "px" : "300px";

          _timeout = $timeout(function () {
            element.find(_target).slimScroll({
              position: "right",
              color: "#666",
              railColor: "#ccc",
              railVisible: true,
              size: "10px",
              height: _height,
              alwaysVisible: true
            });
          }, 10);

          element.on("$destroy", function () {
            $timeout.cancel(_timeout);
          });
          /*
          element.on("change", "input", function(e) {
            e.preventDefault();
            controllers[0].changeLookup();
          });
          */

          element.on("click", "table > tbody > tr", function (e) {
            e.preventDefault();
            var id = A.element(this).attr("data-id");
            controllers[0].selectRow(id);
          });

          element.on("click", "ul > li > a", function (e) {
            e.preventDefault();
            var id = A.element(this).attr("data-id");
            controllers[0].selectRow(id);
          });
          controllers[0].setModelController(controllers[1]);

          scope.$watch("model.selRow.value", function (newValue, oldValue) {
            if (newValue != oldValue) {
              if (!scope.model.selRow) {
                scope.model.selRow = {
                  key: "",
                  value: ""
                };
              }
              controllers[0].lookup(scope.model.selRow.value);
            }
          });
        }
      };
    }])

    .controller("LookupController", ["$scope", "$log", function ($scope, $log) {
      var _self = this,
        _scope = $scope,
        _modelController,
        _uiModel = {},
        _fields = ($scope.columns || "key,value").split(",");

      function configModels() {
        var model = _scope.model || {};
        _uiModel.isMouseOver = 0;
        _uiModel.isHidden = true;
        _uiModel.required = _scope.required === "1" ? "required" : ""
        _uiModel.idField = _fields[0];
        _uiModel.fields = _fields.slice(1);
        _uiModel.alignment = _scope.alignment;
        _uiModel.width = _scope.width || "";
        _uiModel.isEmptyChanged = 0;
        _scope.uiModel = _uiModel;

        if (!model.selRow || !model.selRow.value) {
          model.selRow = {
            key: "",
            value: ""
          };
        }

        if (!model.rowset) {
          model.rowset = [];
        }

        _scope.model = model;
      }

      configModels();

      _self.setModelController = function (controller) {
        _modelController = controller;
      };

      function findSelRow(id) {
        var result,
          idField = _fields[0],
          rowset = _scope.model.rowset;
        for (var i = 0; i < rowset.length; i++) {
          if (rowset[i][idField] == id) {
            result = rowset[i];
            break;
          }
        }

        return result || {};
      }

      _self.selectRow = function (id) {
        var val, row = findSelRow(id);
        _scope.$apply(function () {
          val = _scope.onSelRow({
            row: row
          }) || row[_fields[1]];
          if (val.indexOf("&") !== -1) {
            val = A.element("<span></span>").html(val).text();
          }
          _scope.model.selRow = {
            key: row[_fields[0]],
            value: val
          };
          _modelController.$setViewValue(_scope.model.selRow.key);
          _uiModel.isHidden = true;
          _uiModel.isMouseOver = 0;
        });
        _uiModel.isEmptyChanged = 1;
        if (!!_scope.onChanged) {
          _scope.onChanged();
        }
      };

      function changeLookup() {
        _uiModel.isEmptyChanged = 0;
        _scope.model.selRow.key = "";
          _modelController.$setViewValue("");
        if (!!_scope.onChanged) {
          _scope.onChanged();
        }
      }

      _scope.onBlur = function () {
        if (_uiModel.isMouseOver === 0) {
          _uiModel.isHidden = true;
        }
        if (_uiModel.isEmptyChanged === 1) {
          if (!_scope.model.selRow.value) {
             changeLookup();
            }
        }
      };

      _self.lookup = function (keyword) {
        if (!!_scope.onLookup) {
          _scope.onLookup({
            keyword: keyword
          });
        } else {
          $log.log("[Warning]: No on-lookup attribute is defined on the UI component.")
        }
      };

      _scope.keyClicked = function (event) {
        switch (event.keyCode) {
          case 27: //esc key
            _uiModel.isMouseOver = 0;
            _uiModel.isHidden = true;
            break;
          case 13: //return key
            _uiModel.isHidden = false;
            break;
        }
      };

      _scope.wantToLookup = function (event) {
        var style, inputWidth, target = A.element(event.currentTarget);
        event.preventDefault();
        _uiModel.isHidden = !_uiModel.isHidden;
        if (_uiModel.isHidden) {
          return;
        }

        inputWidth = target.width();
        style = {
          top: target.height(),
          left: 0
        };
        if (!_uiModel.alignment) {
          style.width = inputWidth + "px";
        } else if (_uiModel.alignment === "left") {
          if (!!_uiModel.width) {
            style.width = _uiModel.width + "px";
          }
        } else if (_uiModel.alignment === "right") {
          if (!!_uiModel.width) {
            style.width = _uiModel.width + "px";
            if (parseInt(_uiModel.width) > inputWidth) {
              style["margin-left"] = (inputWidth - parseInt(_uiModel.width)) + "px";
            }
          } else {
            style.width = inputWidth + "px";
          }
        }

        _uiModel.lookupPostionStyle = style;
        target.find("input").select();
        _self.lookup("");
      };

      _scope.onMouseOver = function () {
        _uiModel.isMouseOver = 1;
      };

      _scope.onMouseLeave = function () {
        _uiModel.isMouseOver = 0;
      };

    }]);
})(angular);
