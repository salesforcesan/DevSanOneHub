(function(A){
  var _busy_indicator_id = 0;
  function getNextId(){
    return "_busyIndicator_" + _busy_indicator_id++;
  }

  A.module("cmk.ui.busyindicator", ["cmk.web.context", "ngSanitize"])
    .directive("cmkBusyIndicator", ["cmkWebContext", "$log", function(webContext, $log){
      var _staticPath = webContext.staticResourcePath;
      return {
        restrict: "EA",
        scope: {
          model: "=model"
        },
        controller: "BusyIndicatorController",
        template: function(){
          return '<div id="{{uiModel.id}}">' +
            '<div aria-hidden="false" role="dialog" class="slds-modal slds-fade-in-open" style="position:absolute;">' +
              '<div class="slds-modal__container">' +
                '<div class="slds-container--center">' +
                  '<div class="{{uiModel.css}}">' +
                    '<img src="{{uiModel.icon}}" alt="Loading..." />' +
                  '</div>' +
                '</div>' +
              '</div>' +
            '</div>' +
            '<div class="cm-backdrop cm-backdrop--open"></div>' +
          '</div>';
        }
      };
   }])
   .controller("BusyIndicatorController", ["$scope", "cmkWebContext",
    function($scope, webContext){
     var uiModel = {}, model = $scope.model;
     uiModel.id = model.id || getnextId();
     uiModel.css = model.css || "slds-spinner--medium";
     uiModel.icon = webContext.staticResourcePath + (model.icon || "/assets/images/spinners/slds_spinner_brand.gif");
     $scope.uiModel = uiModel;
   }]);

   A.module("cmk.ui.busyIndicatorService",["cmk.ui.busyindicator"])
   .factory("cmkBusyIndicatorService", [
     "$compile",
     function($compile){
       var _busyIndicatorId = getNextId(), _scope,
           _busyIndicatorModelName = _busyIndicatorId + "Model";

       function showBusyIndicator($scope, options){
          var template, model = {
            id: _busyIndicatorId,
            css: options.css,
            icon: options.icon,
            containerId: options.containerId || "body > div.slds"
          };
          _scope = $scope;
          $scope[_busyIndicatorModelName] = model;
          template = A.element(['<cmk-busy-indicator model="', _busyIndicatorModelName, '"></cmk-busy-indicator>'].join(""));
          A.element(model.containerId).append(template);
          $compile(template)($scope);
       }
       function hideBusyIndicator(){
          if (!!_scope){
            A.element(_scope[_busyIndicatorModelName].containerId).find("cmk-busy-indicator").remove();
          }
       }

       return {
         show: showBusyIndicator,
         hide: hideBusyIndicator
       };
     }
   ]);
})(angular);
