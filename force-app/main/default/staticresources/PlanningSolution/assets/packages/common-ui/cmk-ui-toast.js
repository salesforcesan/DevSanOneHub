(function(A){
  "use strict";

  function getThemeCSS(type){
    var _type;
    if (!type) { return "";}
    _type = ["slds-theme--", type.toLowerCase()].join("");
    return _.find([
      "slds-theme--error",
      "slds-theme--warning",
      "slds-theme--success"], function(e){
        return e === _type;
      }) || "";
  }

  function getIconType(type){
    var _type;
    if (!type) {return "info";}
    _type = type.toLowerCase();

    return _.find([
      "error",
      "warning",
      "success"
    ], function(e){
      return e === _type;
    }) || "info";
  }

  A.module("cmk.ui.toast",["cmk.web.context", "ngSanitize"])
  .directive("cmkToast",[
    "cmkWebContext",
    function(webContext){
      var _staticPath = webContext.staticResourcePath;
      return {
        restrict: "EA",
        scope: {
          model: "=model"
        },
        template: function(){
          return '<div class="slds-notify-container">' +
              '<div class="slds-notify slds-notify--toast {{uiModel.cssTheme}}" role="alert">' +
                '<span class="slds-assistive-text" data-reactid=".c.4.0.0">Error</span>' +
                '<button class="slds-button slds-button--icon-inverse slds-notify__close" ng-click="onClose($event)" >' +
                  '<svg aria-hidden="true" class="slds-button__icon slds-button__icon--large cm-svg-fill-white">' +
                    '<use xlink:href="" ng-href="{{uiModel.staticResource}}/assets/icons/utility-sprite/svg/symbols.svg#close"></use>' +
                  '</svg>' +
                  '<span class="slds-assistive-text">Close</span>' +
                '</button>' +
                '<div class="notify__content slds-grid">' +
                    '<svg aria-hidden="true" class="slds-icon slds-icon--small slds-m-right--small slds-col slds-no-flex">' +
                    '<use xlink:href="" ng-href="{{uiModel.staticResource}}/assets/icons/utility-sprite/svg/symbols.svg#{{uiModel.iconType}}"></use>' +
                    '</svg>' +
                  '<div class="slds-col slds-align-middle">' +
                    '<h2 class="slds-text-heading--small">{{uiModel.title}}</h2>' +
                    '<div ng-bind-html="uiModel.content" />' +
                  '</div>' +
                '</div>' +
              '</div>' +
            '</div>';
        },
        controller: "ToastController"
      };
    }
  ])
  .controller("ToastController",[
    "$scope",
    "cmkWebContext",
    "$timeout",
    function($scope, webContext, $timeout){
      var uiModel, model = $scope.model || {};
      uiModel = {};

      uiModel.iconType = getIconType(model.messageType);
      uiModel.cssTheme = getThemeCSS(model.messageType);
      uiModel.staticResource = webContext.staticResourcePath;
      uiModel.cssTheme = getThemeCSS(model.messageType);
      uiModel.title = model.title || "Toast Title Place Holder";
      uiModel.content = model.content || "Toast Body Content Place Holder";
      $scope.uiModel = uiModel;
      $scope.onClose = function($event){
        var $this = A.element($event.currentTarget).parents("cmk-toast");
        $this.fadeOut(250, function(){
          $this.remove();
        });
      };
      if (model.autoHide === true) {
        $timeout(function(){
          var $this = A.element("body").find("div.slds > cmk-toast");
          if(!!$this) {
          $this.fadeOut(500, function(){
            $this.remove();
          });
        }
        },5000);
      }
    }
  ]);

  A.module("cmk.ui.toastService", ["cmk.ui.toast"])
  .factory("cmkToastService",[
    "$compile",
    function($compile){
    var model, html, toast, toastId = "div.slds > cmk-toast";

    function showToast($scope, options) {
      model = {};
      html = [];
      toast = A.element("body").find(toastId);
      options = options || {};

      if(!!toast) { toast.remove();}
      model.messageType = options.messageType || "info";
      model.autoHide = options.autoHide || false;
      model.title = options.title || "Notification";
      model.content = options.content || "<p>Notification Detail</p>";
      $scope.__toastModel = model;
      var template = A.element('<cmk-toast model="__toastModel"></cmk-toast>');
      A.element("body").find("div.slds").append(template);
      $compile(template)($scope);
    }

    function hideToast(){
      toast = A.element("body").find(toastId);
      if (!!toast) {
        toast.fadeOut(250, function(){
          toast.remove();
        });
      }
    }

    return {
      show: showToast,
      hide: hideToast
    };
  }]);
})(angular);
