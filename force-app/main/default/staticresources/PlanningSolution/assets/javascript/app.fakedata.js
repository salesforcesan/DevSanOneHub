function getDate(i, isStart) {
    var reportDate = new Date();
    i = isStart ? i : i + 11;
    reportDate.setDate(reportDate.getDate() + i);
    return new Date(reportDate.getFullYear(), reportDate.getMonth(), reportDate.getDate(), 0, 0, 0, 0);
}

function FakeSalesForceModel() {


    function ProjectType() {}
    ProjectType.prototype.retrieve = function(callback) {
        var result = [];

        function Record(i) {
            this.data = {
                "Id": i === 0 ? "Road Show" : "In Store Event & Sample",
                "Name": i === 0 ? "Road Show" : "In Store Event & Sample"
            };
        }
        Record.prototype.get = function(field) {
            return this.data[field] || "";
        };
        for (var i = 0; i < 2; i++) {
            result.push(new Record(i));
        }
        console.log("---- get project type ----");
        console.log(result);
        callback(0, result);
    }

    function ProjectCustomQuery() {}
    ProjectCustomQuery.prototype.retrieve = function(query, callback) {
        var result = [];

        function Record(i) {
            this.data = {
                "Query__c": "query:" + i
            };
        }
        Record.prototype.get = function(field) {
            return this.data[field] || "";
        };
        for (var i = 0; i < 14; i++) {
            result.push(new Record(i));
        }
        console.log("---- get query list ----");
        console.log(result);
        callback(0, result);
    };

    function GetRecentlyViewedResults(suffix) {
        var result = [],
            chars = ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"];

        function Record(id, name) {
            this.data = {
                Id: id,
                Name: name
            };
        }
        Record.prototype.get = function(field) {
            return this.data[field] || "";
        };

        function getName(i, suffix) {
            var j, nm = [];
            for (j = i; j < i + 20; j++) {
                if (j === i) {
                    nm.push(chars[j % 26]);
                } else {
                    nm.push(chars[j % 26].toLowerCase());
                }
            }
            nm.push("+");
            nm.push(suffix);
            return nm.join("");
        }

        for (var i = 0; i < 100; i++) {
            result.push(new Record(i, getName(i, suffix)));
        }

        return result;
    };

    function getLookup(suffix) {

    }

    function Retailer__c() {}
    Retailer__c.prototype.retrieve = function(callback) {
        callback(0, GetRecentlyViewedResults("retailer"));
    };

    function User() {}
    User.prototype.retrieve = function(callback) {
        callback(0, GetRecentlyViewedResults("approver"));
    };

    function Client__c() {}
    Client__c.prototype.retrieve = function(callback) {
        callback(0, GetRecentlyViewedResults("client"));
    }

    function Project__c() {
        this.data = [];
    }

    function ProjectRecord(i) {
        var retailers = GetRecentlyViewedResults("retailer"),
            clients = GetRecentlyViewedResults("client"),
            approvers = GetRecentlyViewedResults("approver"),
            status = ["Planning", "Scheduled", "Complete"],
            types = ["Road Show", "Road Show", "In Store Event & Sample", "Road Show"]
        self = {};

        var data = {
            "Name": "Lorem ipsum dolor sit amet, consectetuer adipiscing elit, sed diam nonummy nibh :" + i,
            "ExternalId__c": "eid:" + i,
            "Id": i + 10000,
            "Client__c": clients[i % 50].get("Id"),
            "ClientName__c": clients[i % 50].get("Name"),
            "OwnerName__c": "owner:" + i,
            "Overview__c": "description:" + i,
            "ProjectType__c": types[i % 4],
            "ProjectTypeName__c": types[i % 4],
            "StartDate__c": getDate(i, 1),
            "EndDate__c": getDate(i, 0),
            "SalesGoal__c": 10000 + i,
            "Budgeted_Locations__c": i + 1,
            "Retailer__c": retailers[i % 25].get("Id"),
            "RetailerName__c": retailers[i % 25].get("Name"),
            "Approver1__c": approvers[i % 24].get("Id"),
            "Approver1Name__c": approvers[i % 24].get("Name"),
            "NumberOfPallets__c": i + 1,
            "NumberOfDays__c": (i + 1) % 1000,
            "ExecutionDates__c": [getDate(i, 1).toLocaleDateString(), " - ", getDate(i, 0).toLocaleDateString()].join(""),
            "Status__c": status[i % 3],
            "CanReschedule__c": i % 3 ? true : false
        };

        self.get = function(field) {
            return data[field] || "";
        };

        return self;
    }

    Project__c.prototype.retrieve = function(queryParam, callback) {
        var result = [],
            selId = 0,
            data;
        for (var j = 0; j < 50; j++) {
            result.push(new ProjectRecord(j));
        }
        if (queryParam && queryParam.where && queryParam.where.Id && queryParam.where.Id.eq) {
            selId = parseInt(queryParam.where.Id.eq);
        }
        if (!selId) {
            callback(0, result, 0);
            return;
        }
        data = _.find(result, function(r) {
            return r.get("Id") === selId;
        });
        callback(0, [data], 0);
    };
    Project__c.prototype.set = function(field, value) {
        this.data.push({
            "key": field,
            "value": value
        });
    };
    Project__c.prototype.create = function(callback) {
        console.log("---create prjoect ---");
        callback(0, ["2015"]);
    };
    Project__c.prototype.update = function(callback) {
        console.log("--- update project ----");
        callback(0, ["2015"]);
    };

    this.Project__c = Project__c;
    this.Retailer__c = Retailer__c;
    this.User = User;
    this.Client__c = Client__c;
    this.ProjectCustomQuery = ProjectCustomQuery;
    this.ProjectType = ProjectType;
}

var SObjectModel = new FakeSalesForceModel();
$(function() {
    var id = window.setTimeout(function() {
        window.clearTimeout(id);

        //hijack controller behavior
        var app = window["ShoppingEvent.crossmark.com"].getApplication();
        var controller = app.getController("project/cancel");
        if (!controller) {
            console.log("can't find the controller for project/cancel");
        } else {
            var v = controller.view,
                m = controller.model,
                data;
            controller.save = function() {
                if (!v.validateFormData()) {
                    return;
                }

                data = v.getFormData();
                m.saveProject(data)
                    .done(function(result) {
                      app.router().route("project/cancel");
                    }).fail(function(err) {
                        alert(err);
                    });
            };
        }

        controller = app.getController("dashboard/selectProject");
        if (controller) {
            controller.selectProject = function(id) {
                app.router().route("project/gotoEditProject", {
                    projectId: id,
                    pageTitle: "DashboardForEdit"
                });
            }
        }

    }, 10);
})
