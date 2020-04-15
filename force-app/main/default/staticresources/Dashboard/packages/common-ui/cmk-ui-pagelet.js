 /* CROSSMARK angular-ui-salesforce design system
  * Version: 0.0.1 - 2015-08-05
  * License: MIT
  *
  *
  * Pagelet Container UI component
  */

 (function(A) {

   A.module("cmk.ui.pagelet", ["cmk.web.context", "ngSanitize"])

   .directive("cmkPagelet", ["$timeout", "$log", "$window", function($timeout, $log, $window) {
     return {
       restrict: "EA",
       transclude: true,
       scope: {
         model: "=options",
         onResize: "&onResize",
         onNavbarClick: "&navbarClick",
         onFooterLinkClick: "&footerClick"
       },
       require: ["cmkPagelet"],
       controller: "PageletController",
       template: function(tElement, tAttrs) {
         return '<article class="cm-article">' +
           '<header class="clearfix">' +
           '<div class="float-left"><h2 class="text-heading--label text-heading--large cm-article-title" ng-bind-html="uiModel.title"></h2></div>' +
           '<div class="float-right"><div class="cm-widget-hdr-group" ng-bind-html="uiModel.toolbarHTML"></div></div>' +
           '</header>' +
           '<div class="cm-article-body"><ng-transclude></ng-transclude></div>' +
           '<footer class="cm-article-footer" ng-if="!!uiModel.footerHTML" ng-bind-html="uiModel.footerHTML"></footer>' +
           '</article>';
       },
       link: function(scope, element, attrs, controllers) {
         var _timeout, 
           _target = "div.ui-grid-viewport";

         element.on("click", "header a", function(e) {
           e.preventDefault();
           var href = A.element(this).attr("href");
           if (href === "#_sys_expand") {
             controllers[0].resize(A.element(this));
             element.find(_target).slimScroll({
               scrollTo: "0px",
               railVisible: true,
               alwaysVisible: true
             });
             element.find(_target).focus();
           } else {
            scope.onNavbarClick({href:href});
           }
         });

         _timeout = $timeout(function() {
           element.find(_target).slimScroll({
             position: "right",
             color: "#666",
             railColor: "#ccc",
             railVisible: true,
             height: scope.uiModel.height + "px",
             size: "10px",
             alwaysVisible: true
           })
         }, 10);

       }
     };
   }])

   .controller("PageletController", ["$scope", "$log", "cmkWebContext", function($scope, $log, webContext) {
     var _self = this,
       _element,
       _scope = $scope,
       _uiModel = _scope.uiModel = {};

     function buttonHtml(bar) {
       return ['<a href="#',
         bar.id,
         '" title="',
         bar.text,
         '" class="button button--icon-border-filled cm-widget-hdr-button">',
         '<svg aria-hidden="true" class="button__icon button__icon--small cm-icon">',
         '<use xlink:href="',
         bar.iconUrl,
         '"></use></svg><span class="assistive-text">',
         bar.text,
         '</span></a>'
       ].join("");
     }

     function initUiModel() {
       var m = _scope.model,
         html = [];
       _uiModel.title = m.title,
         _uiModel.height = m.height;

       m.navBars.forEach(function(bar) {
         html.push(buttonHtml(bar));
       });
       if (!!m.canExpand && m.canExpand) {
         html.push(buttonHtml({
           id: "_sys_expand",
           text: "Zoom In & Out",
           iconUrl: webContext.staticResourcePath + "/assets/icons/utility-sprite/svg/symbols.svg#expand"
         }));
       }
       _uiModel.toolbarHTML = html.join("");
       _uiModel.footerHTML = m.footerHTML || "";
     }

     //bootstrap ui model
     initUiModel();

     _self.resize = function(element) {
       var isFullScreen = A.element("body").hasClass("cm-body-full-screen");
       var height = _uiModel.height + 50;
       var colContainer = element.parents(".cm-col-container");

       colContainer.toggleClass('cm-widget-full-screen');
       A.element("body").toggleClass('cm-body-full-screen');

       if (!isFullScreen) {
         height = colContainer.height() - colContainer.find("header").outerHeight(true) - colContainer.find(".cm-article-footer").outerHeight(true);
       }
       colContainer.find(".cm-article-body").height(height);
       if ((colContainer.find(".ui-grid-viewport").html() + "").length > 0) {
         colContainer.find(".ui-grid-viewport")
           .height(height - 40)
           .parent("div").height(height - 40);
       }
       _scope.onResize({
         height: height
       });
     };

   }]);

 })(angular);
