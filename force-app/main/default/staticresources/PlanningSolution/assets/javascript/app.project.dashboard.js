
(function() {
  var _app = window["ShoppingEvent.crossmark.com"].getApplication(),
    _controllerId = "dashboard",
    _async = _app.Async;

  function getDate(i, isStart) {
    var reportDate = new Date();
    i = isStart ? i : -i;
    reportDate.setDate(reportDate.getDate() + i);
    return new Date(reportDate.getFullYear(), reportDate.getMonth(), reportDate.getDate(), 0, 0, 0, 0);
  }


  var Model = function() {
    var self = this;
    var titles = [
      "Distribution Check 2014-123",
      "Client Shop Event ",
      "Boy Bicycle Demo"
    ];

    function getIdNameMappings() {
      return [{
        from: "Id",
        to: "key"
      }, {
        from: "Name",
        to: "value"
      }];
    }

    self.saveQuery = function(query) {
      alert("saveQuery");
    };

    
    //query = {
    //    name: "dropdown selected value",
    //    sortField: "CreatedDate | other field name" 
    //    sortDir: "ASC | DESC"
    //    recordLimit: 
    //    recordOffset: 0 | 101 | 201 | 301
    //}
    
    self.getProjects = function(query) {
      var project = new SObjectModel.Project__c();

      var fieldMaps = [{
        from: "Id",
        to: "id"
      }, {
        from: "ExternalId__c",
        to: "eid"
      }, {
        from: "Name",
        to: "title"
      }, {
        from: "ClientName__c",
        to: "client"
      }, {
        from: "Client__c",
        to: "clientId"
      }, {
        from: "ProjectType__c",
        to: "typeId"
      }, {
        from: "canReschedule__c",
        to: "canReschedule"
      }, {
        from: "ProjectTypeName__c",
        to: "type"
      }, {
        from: "OwnerName__c",
        to: "owner"
      }, {
        from: "NumberOfDays__c",
        to: "days"
      }, {
        from: "ExecutionDates__c",
        to: "execDate"
      }, {
        from: "NumberOfDays__c",
        to: "days"
      }, {
        from: "Status__c",
        to: "status"
      }];
      var view = "My Projects",

        sortField = "CreatedDate",

        sortDir = "DESC",

        recordLimit = 100,

        recordOffset = 1;

      var queryParam = {
        orderby: [],
        limit: recordLimit
      };
      var orderby = {};
      orderby[sortField] = sortDir;
      queryParam.orderby[0] = orderby;

      //eval("QueryParam = { orderby: [ {" + sortField + ":'" + sortDir + "'}], limit: recordLimit }");
      var CurrentUser = _app.LogonUser.userId;
      CurrentUser = CurrentUser.substring(0, 15);

      switch (view) {

        case "My Projects":
          queryParam.where = {
            OwnerId__c: {
              eq: CurrentUser
            }
          };
          break;
        case "Scheduled":
          queryParam.where = {
            Status__c: {
              eq: 'Scheduled'
            }
          };
          break;
        case "Planning":
          queryParam.where = {
            Status__c: {
              eq: 'Planning'
            }
          };
          break;
        case "Complete":
          queryParam.where = {
            Status__c: {
              eq: 'Complete'
            }
          };
          break;
        case "In Progress":
          queryParam.where = {
            Status__c: {
              eq: 'In Progress'
            }
          };
          break;

      }

      return _async.call(project.retrieve, queryParam, fieldMaps);
    };

    self.getFilterQueries = function() {
      var fieldMaps = [{
          from: "Query__c",
          to: "key"
        }, {
          from: "Query__c",
          to: "value"
        }],
        projectQueries = new SObjectModel.ProjectCustomQuery(),
        userId = _app.LogonUser.userId;

      var queryParam = {
        orderby: [{
          Name: 'ASC'
        }]
      };

      queryParam.where = {
        or: {
          IsCustom__c: {
            eq: false
          },
          OwnerId: {
            eq: userId
          }
        }
      };

      return _async.call(projectQueries.retrieve, queryParam, fieldMaps);
    };

    self.getProjectTypes = function() {
      var projectTypes = new SObjectModel.ProjectType();
      var fieldMaps = getIdNameMappings();
      return _async.call(projectTypes.retrieve, "", fieldMaps);
    };



    return self;
  };

  var Viewer = function() {
    var self = Object.create(_app.createView());
    var selectQuery = _app.UI.htmlSelect("selectQuery", "cm-label-10", "", 1);
    var selectNewProject = _app.UI.htmlSelect("selectNewProject", "cm-label-10", "cm-picklist-options-left-5", 0);
    var dropdownQueryActions = _app.UI.htmlDropdown("dropdownQueryActions");
    var dropdownTableLayout = _app.UI.htmlDropdown("dropdownTableLayout", 1);
    var zChart1 = _app.UI.widget({
      containerId: "zChart1",
      title: "Widget Test",
      canExpand: 1,
      canClose: 1,
      navBars: [],
      bodyControl: _app.UI.placeHolder("zChart", "<svg></svg>")
    });
    var zChart2 = _app.UI.widget({
      containerId: "zChart2",
      title: "Widget Test2",
      canExpand: 1,
      canClose: 1,
      navBars: [],
      bodyControl: _app.UI.placeHolder("zChart", '<svg class="cm-chart-svg"></svg>')
    });
    var zChart3 = _app.UI.widget({
      containerId: "zChart3",
      title: "Widget Test3",
      canExpand: 1,
      canClose: 1,
      navBars: [],
      bodyControl: _app.UI.placeHolder("zChart", '<svg class="chartWrap"></svg>')
    });
    var zPlaceHolder = _app.UI.widget({
      containerId: "zPlaceHolder",
      title: "Project Distribution Chart<small>group by status and based on data and number of days</small>",
      canExpand: 1,
      canClose: 1,
      navBars: [],
      bodyControl: _app.UI.placeHolder("zChart", '<svg class="chartWrap"></svg>')
    });

    //override default
    self.render = function() {};

    self.renderProjectType = function(data) {
      selectNewProject.render({
        "selValue": "New Project",
        "options": data
      });
    };

    self.renderFilterQueries = function(options) {
      selectQuery.render({
        "selValue": options[0].value,
        "options": options
      });
    }

    self.renderHome = function(data) {

      var projects = data,
        queryActions = {
          title: "List View Actions",
          menuItems: [{
            key: 1,
            value: "Rename...",
            leftIconUrl: _app.Resources.path + "/assets/icons/utility-sprite/svg/symbols.svg#copy",
            rightIconUrl: "",
            disabled: 0
          }, {
            key: 2,
            value: "Share...",
            leftIconUrl: _app.Resources.path + "/assets/icons/utility-sprite/svg/symbols.svg#share",
            rightIconUrl: "",
            disabled: 1
          }, {
            key: 3,
            value: "Delete",
            leftIconUrl: _app.Resources.path + "/assets/icons/utility-sprite/svg/symbols.svg#delete",
            rightIconUrl: "",
            disabled: 1
          }, {
            key: 4,
            value: "Save",
            leftIconUrl: _app.Resources.path + "/assets/icons/utility-sprite/svg/symbols.svg#paste",
            rightIconUrl: "",
            disabled: 1
          }, {
            key: 5,
            value: "Save As...",
            leftIconUrl: _app.Resources.path + "/assets/icons/utility-sprite/svg/symbols.svg#package",
            rightIconUrl: "",
            disabled: 0
          }, {
            key: 6,
            value: "Discard Changes To List",
            leftIconUrl: _app.Resources.path + "/assets/icons/utility-sprite/svg/symbols.svg#undo",
            rightIconUrl: "",
            disabled: 0
          }]
        },
        tableLayouts = {
          title: "Display As",
          menuItems: [{
            key: 1,
            value: "Table",
            leftIconUrl: "",
            rightIconUrl: _app.Resources.path + "/assets/icons/utility-sprite/svg/symbols.svg#table",
            disabled: 0
          }, {
            key: 2,
            value: "Cards",
            leftIconUrl: "",
            rightIconUrl: _app.Resources.path + "/assets/icons/utility-sprite/svg/symbols.svg#kanban",
            disabled: 0
          }, {
            key: 3,
            value: "Compact List",
            leftIconUrl: "",
            rightIconUrl: _app.Resources.path + "/assets/icons/utility-sprite/svg/symbols.svg#side_list",
            disabled: 0
          }]
        };


      dropdownQueryActions.render(queryActions);
      dropdownTableLayout.render(tableLayouts);

      zChart1.render({
        data: projects
      });
      zChart2.render({
        data: projects
      });
      zChart3.render({
        data: projects
      });
      zPlaceHolder.render({
        data: projects,
        onRendered: function(widget, containerId, data) {
          var svgId = ["#", containerId, " div.cm-article-body > svg"].join("");
          $("#" + containerId + " .cm-article-body").addClass("cm-height-450");
          _app.Charts.scatterPlotChart(widget, svgId, data);
        }
      });

      $("#projectList").datagrid({
        dataSet: projects,
        title: "Projects",
        cardTemplate: '<div class="cm-card" data-id="{{id}}"><header><div class="clearfix"><div class="float-left"><span class="icon__container icon-action-description"><svg aria-hidden="true" class="icon icon--small"><use xlink:href="/assets/icons/action-sprite/svg/symbols.svg#description"></use></svg><span class="assistive-text"></span></span><h2 class="cm-card-title"><div class="truncate">{{{title}}}</div><small>{{{execDate}}}</small></h2></div><div class="float-right">{{{status}}}</div></div></header><section><div class="grid wrap"><div class="col size--6-of-12 small-size--1-of-1 medium-size--6-of-6 large-size--6-of-12"><div class="grid wrap"><div class="col size--1-of-3"><label class="form-element__label" for="projectStartDate">Project Type</label></div><div class="col size--2-of-3">{{{type}}}</div></div></div><div class="col size--6-of-12 small-size--1-of-1 medium-size--6-of-6 large-size--6-of-12"><div class="grid wrap"><div class="col size--1-of-3"><label class="form-element__label" for="projectStartDate"># of Days</label></div><div class="col size--2-of-3">{{{days}}}</div></div></div></div><div class="grid wrap"><div class="col size--6-of-12 small-size--1-of-1 medium-size--6-of-6 large-size--6-of-12"><div class="grid wrap"><div class="col size--1-of-3"><label class="form-element__label">Client</label></div><div class="col size--2-of-3">{{{client}}}</div></div></div><div class="col size--6-of-12 small-size--1-of-1 medium-size--6-of-6 large-size--6-of-12"><div class="grid wrap"><div class="col size--1-of-3"><label class="form-element__label">Owner</label></div><div class="col size--2-of-3">{{{owner}}}</div></div></div></div></section></div>',
        hasFooter: 0,
        sortOnServer: 0,
        resourcePath: _app.Resources.path,
        cellSelectEvent: function(projectId) {
          _app.router().route("dashboard/selectProject", projectId);
        },
        navBars: [],
        columns: [{
          id: "title",
          dataType: "string",
          title: "Title",
          canSort: 1,
          sorted: 1,
          locked: 0,
          uiType: "link"
        }, {
          id: "execDate",
          dataType: "string",
          title: "Execute. Date",
          canSort: 1,
          sorted: 0,
          locked: 0,
          uiType: "text"
        }, {
          id: "status",
          dataType: "string",
          title: "Status",
          canSort: 1,
          sorted: 0,
          locked: 0,
          uiType: "label",
          labels: [{
            rule: {
              eq: "Planning"
            },
            css: ""
          }, {
            rule: {
              eq: "Scheduled"
            },
            css: "label--warning"
          }, {
            rule: {
              eq: "Complete"
            },
            css: "label--success"
          }]
        }, {
          id: "client",
          dataType: "string",
          title: "Client",
          canSort: 1,
          sorted: 0,
          locked: 0,
          uiType: "text"
        }, {
          id: "type",
          dataType: "string",
          title: "type",
          canSort: 1,
          sorted: 0,
          locked: 0,
          uiType: "text"
        }, {
          id: "owner",
          dataType: "string",
          title: "Owner",
          canSort: 1,
          sorted: 0,
          locked: 0,
          uiType: "text"
        }, {
          id: "days",
          dataType: "number",
          title: "# of Days",
          canSort: 1,
          sorted: 0,
          locked: 0,
          uiType: "text",
          labels: [{
            rule: {
              lt: 4
            },
            css: "label--error"
          }, {
            rule: {
              between: [5, 8]
            },
            css: "label-warning"
          }, {
            rule: {
              gt: 8
            },
            css: ""
          }]
        }, {
          id: "id",
          dataType: "string",
          title: "Id",
          canSort: 1,
          sorted: 0,
          locked: 0,
          uiType: "link"
        }]
      });
      $("#zDataGrid").datagrid({
        dataSet: projects,
        sortOnServer: 0,
        cardTemplate: '<div class="cm-card" data-id="{{id}}"><header><div class="clearfix"><div class="float-left"><span class="icon__container icon-action-description"><svg aria-hidden="true" class="icon icon--small"><use xlink:href="/assets/icons/action-sprite/svg/symbols.svg#description"></use></svg><span class="assistive-text"></span></span><h2 class="cm-card-title"><div class="truncate">{{{title}}}</div><small>{{{execDate}}}</small></h2></div><div class="float-right">{{{status}}}</div></div></header><section><div class="grid wrap"><div class="col size--6-of-12 small-size--1-of-1 medium-size--6-of-6 large-size--6-of-12"><div class="grid wrap"><div class="col size--1-of-3"><label class="form-element__label" for="projectStartDate">Project Type</label></div><div class="col size--2-of-3">{{{type}}}</div></div></div><div class="col size--6-of-12 small-size--1-of-1 medium-size--6-of-6 large-size--6-of-12"><div class="grid wrap"><div class="col size--1-of-3"><label class="form-element__label" for="projectStartDate"># of Days</label></div><div class="col size--2-of-3">{{{days}}}</div></div></div></div><div class="grid wrap"><div class="col size--6-of-12 small-size--1-of-1 medium-size--6-of-6 large-size--6-of-12"><div class="grid wrap"><div class="col size--1-of-3"><label class="form-element__label">Client</label></div><div class="col size--2-of-3">{{{client}}}</div></div></div><div class="col size--6-of-12 small-size--1-of-1 medium-size--6-of-6 large-size--6-of-12"><div class="grid wrap"><div class="col size--1-of-3"><label class="form-element__label">Owner</label></div><div class="col size--2-of-3">{{{owner}}}</div></div></div></div></section></div>',
        resourcePath: _app.Resources.path,
        cellSelectEvent: function(projectId) {
          _app.router().route("dashboard/selectProject", projectId);
        },
        navBars: [],
        columns: [{
          id: "title",
          dataType: "string",
          title: "Title",
          canSort: 1,
          sorted: 1,
          locked: 0,
          uiType: "link"
        }, {
          id: "execDate",
          dataType: "string",
          title: "Execute. Date",
          canSort: 1,
          sorted: 0,
          locked: 0,
          uiType: "text"
        }, {
          id: "status",
          dataType: "string",
          title: "Status",
          canSort: 1,
          sorted: 0,
          locked: 0,
          uiType: "label",
          labels: [{
            rule: {
              eq: "Planning"
            },
            css: ""
          }, {
            rule: {
              eq: "Scheduled"
            },
            css: "label--warning"
          }, {
            rule: {
              eq: "Complete"
            },
            css: "label--success"
          }]
        }, {
          id: "client",
          dataType: "string",
          title: "Client",
          canSort: 1,
          sorted: 0,
          locked: 0,
          uiType: "text"
        }, {
          id: "type",
          dataType: "string",
          title: "type",
          canSort: 1,
          sorted: 0,
          locked: 0,
          uiType: "text"
        }, {
          id: "owner",
          dataType: "string",
          title: "Owner",
          canSort: 1,
          sorted: 0,
          locked: 0,
          uiType: "text"
        }, {
          id: "days",
          dataType: "number",
          title: "# of Days",
          canSort: 1,
          sorted: 0,
          locked: 0,
          uiType: "text",
          labels: [{
            rule: {
              lt: 4
            },
            css: "label--error"
          }, {
            rule: {
              between: [5, 8]
            },
            css: "label-warning"
          }, {
            rule: {
              gt: 8
            },
            css: ""
          }]
        }, {
          id: "id",
          dataType: "string",
          title: "Id",
          canSort: 1,
          sorted: 0,
          locked: 0,
          uiType: "link"
        }]
      });
    };

    self.addEvent(function() {
      selectQuery.init(function(option) {
        console.log(option);
      });
      selectNewProject.init(function(option) {
        _app.router().route("dashboard/createProject", option);
      });
      dropdownQueryActions.init(function(dropdownItem) {
        console.log(dropdownItem);
      });
      dropdownTableLayout.init(function(dropdownItem) {
        console.log(dropdownItem);
      });
      zChart1.init();
      zChart2.init();
      zChart3.init();
      zPlaceHolder.init();

    });

    function flipDashboardAndFormWizard() {
      $("#masterContainer").toggleClass('cm-hide');
      $("#formWizard").toggleClass('cm-hide');
    }

    self.renderCreateProject = function(option) {
      flipDashboardAndFormWizard();
    }

    return self;
  };

  var Controller = function(id) {
    var self = Object.create(_app.createController(id));

    self.goHome = function() {
      var view = self.view,
        model = self.model;

      model.getProjectTypes()
        .done(function(projectTypes) {
          view.renderProjectType(projectTypes);
        })
        .fail(function(err) {
          alert(err);
        });

      model.getFilterQueries()
        .done(function(options) {
          view.renderFilterQueries(options);
        })
        .fail(function(err) {
          alert(err);
        });

      model.getProjects()
        .done(function(result) {
          view.renderHome(result);
        })
        .fail(function(err) {
          alert(err);
        });
    };

    self.goCreateProject = function(option) {
      _app.router().route("project/gotoCreateProject", {
        data: option,
        pageTitle: "Dashboard"
      });
    }

    self.selectProject = function(id) {
      window.location.href = "/apex/ProjectView?id=" + id
    };

    self.selectAction = function() {
      messageBox("selectAction");
    }

    self.selectQuery = function() {
      messageBox("selectQuery");
    };

    self.runAction = function(selAction) {
      messageBox("runAction: " + selAction);
    }

    self.runQuery = function(selQuery) {
      messageBox("runQuery: " + selQuery);
    }

    self.clickFilter = function() {
      messageBox("clickFilter");
    }

    self.clickLayout = function() {
      messageBox("clickLayout");
    }

    self.clickFilter = function() {
      messageBox("clickFilter");
    }

    self.clickChart = function() {
      messageBox("clickChart");
    }

    self.clickNewProject = function() {
      messageBox("clickNewProject");
    };

    self.sortData = function(selCol) {
      messageBox("sortData: " + selCol);
    };

    return self;
  };

  _app.addOnLoadEventListener(function() {
    _app.registerMVC(new Model(), new Viewer(), new Controller(_controllerId));
    _app.router()
      .addRoute("dashboard/goHome", _controllerId, "goHome")
      .addRoute("dashboard/selectAction", _controllerId, "selectAction")
      .addRoute("dashboard/selectQuery", _controllerId, "selectQuery")
      .addRoute("dashboard/runAction", _controllerId, "runAction")
      .addRoute("dashboard/runQuery", _controllerId, "runQuery")
      .addRoute("dashboard/clickFilter", _controllerId, "clickFilter")
      .addRoute("dashboard/clicklayout", _controllerId, "clickLayout")
      .addRoute("dashboard/clickChart", _controllerId, "clickChart")
      .addRoute("dashboard/clickNewProject", _controllerId, "clickNewProject")
      .addRoute("dashboard/sortData", _controllerId, "sortData")
      .addRoute("dashboard/createProject", _controllerId, "goCreateProject")
      .addRoute("dashboard/selectProject", _controllerId, "selectProject")
      .setDefault("dashboard/goHome");
  });
})();

(function(A) {
  'use strict';

  A.module("projectDashboard", ['ngRoute', "ui.grid", "cmk.ui.picklist","cmk.web.context","cmk.ui.dropdown"])
    .controller("ProjectDashboardController", ["$scope", "cmkWebContext", "$log", function($scope, webContext, $log) {
      var _self = this,
        _path = webContext.staticResourcePath,
        _scope = $scope;

      _scope.dashboard = {
        projectQueryId: "",
        projectTypeId: "",
        projects: []
      };
      _scope.customQueryModel = {
        option: {
          key: "1",
          value: "test 1"
        },
        options: [{
          key: "1",
          value: "test 1"
        }, {
          key: "2",
          value: "test 2"
        }, {
          key: "3",
          value: "test 3"
        }]
      };

      _scope.projectTypeModel = {
        option: {
          key: "",
          value: ""
        },
        options: [{
          key: "1",
          value: "Road Show"
        }, {
          key: "2",
          value: "In Store Event & Show"
        }]
      }

      _scope.projectTypeChanged = function() {

        $log.log("projectType: " + _scope.dashboard.projectTypeId);
      };

      _scope.onChanged = function() {
        $log.log(_scope);
      };

      _scope.queryActionModel = {
        title: "Custom Query View Actions",
        helpText: "Custom Query Action",
        buttonUrl: _path + "/assets/icons/utility-sprite/svg/symbols.svg#settings",
        menuItems: [{
          key: "rename",
          value: "Rename...",
          leftIconUrl: _path + "/assets/icons/utility-sprite/svg/symbols.svg#copy",
          rightIconUrl: "",
          disabled: 0
        }, {
          key: "share",
          value: "Share...",
          leftIconUrl: _path + "/assets/icons/utility-sprite/svg/symbols.svg#share",
          rightIconUrl: "",
          disabled: 1
        }, {
          key: "delete",
          value: "Delete",
          leftIconUrl: _path + "/assets/icons/utility-sprite/svg/symbols.svg#delete",
          rightIconUrl: "",
          disabled: 1
        }, {
          key: "save",
          value: "Save",
          leftIconUrl: _path + "/assets/icons/utility-sprite/svg/symbols.svg#paste",
          rightIconUrl: "",
          disabled: 1
        }, {
          key: "saveas",
          value: "Save As...",
          leftIconUrl: _path + "/assets/icons/utility-sprite/svg/symbols.svg#package",
          rightIconUrl: "",
          disabled: 0
        }, {
          key: "discard",
          value: "Discard Changes To List",
          leftIconUrl: _path + "/assets/icons/utility-sprite/svg/symbols.svg#undo",
          rightIconUrl: "",
          disabled: 0
        }]
      };

      _scope.queryActionClicked = function (key) {
        $log.log("--- query action:" + key);
      };

    }]);
})(angular);
