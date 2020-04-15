(function($) {
    var _app = window["ShoppingEvent.crossmark.com"].getApplication(),
        _async = _app.Async;


    var Model = function() {
        var self = {};

        function getIdNameMappings() {
            return [{
                from: "Id",
                to: "key"
            }, {
                from: "Name",
                to: "value"
            }];
        }

        //doto: doesn't support INTL. if project type name is changed, this code need to change; otherwise not working.
        self.getCreateProjectUI = function(projectType) {
            var type = projectType.toLowerCase();
            var url = (type.indexOf("road") !== -1 && type.indexOf("show") !== -1) ? "/templates/project.create.roadshow.html" : "/templates/project.create.storedemo.html";
            return _app.Http.getHtml(_app.Resources.appPath + url);
        };

        self.getRetailers = function(name) {
            var fieldMaps = getIdNameMappings(),
                retailers = new SObjectModel.Retailer__c();
            return _async.call(retailers.retrieve, "", fieldMaps);
        };

        self.getClients = function(name) {
            var fieldMaps = getIdNameMappings(),
                clients = new SObjectModel.Client__c();
            return _async.call(clients.retrieve, "", fieldMaps);
        };

        self.getApprovers = function(name) {
            var fieldMaps = getIdNameMappings(),
                approvers = new SObjectModel.User();
            return _async.call(approvers.retrieve, "", fieldMaps);
        };

        self.saveProject = function(formData) {
            var project = new SObjectModel.Project__c(),
                isNew = 1;
            if (!!formData.id) {
                project.set("Id", formData.id.substr(0,15));
                isNew = 0;
            }
            
            project.set("ProjectType__c", formData.typeId);
            project.set("Retailer__c", formData.retailerId);
            project.set("Name", formData.title);
            project.set("Client__c", formData.clientId);
            project.set("StartDate__c", formData.startDate);
            project.set("EndDate__c", formData.endDate);
            project.set("Budgeted_Locations__c", formData.budgetLocations);
            project.set("Approver1__c", formData.approverId);
            project.set("Overview__c", formData.description);
            project.set("NumberOfDays__c", formData.days);
            project.set("SalesGoal__c", formData.salesGoal);
            project.set("NumberOfPallets__c", formData.pallets);
            project.set("CanReschedule__c", formData.canReschedule ? true : false);
            project.set("ResponsibleForExecution__c", "Execution Company");
            
            return isNew ? _async.call(project.create, "", []) : _async.call(project.update, "", []);
        }

        self.getProject = function(id) {
            var project = new SObjectModel.Project__c();
            var query = {
                where: {
                    Id: {
                        eq: id
                    }
                }
            };
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
                from: "Client__c",
                to: "clientId"
            }, {
                from: "ClientName__c",
                to: "clientName"
            }, {
                from: "ProjectTypeName__c",
                to: "typeName"
            }, {
                from: "ProjectType__c",
                to: "typeId"
            }, {
                from: "Retailer__c",
                to: "retailerId"
            }, {
                from: "RetailerName__c",
                to: "retailerName"
            }, {
                from: "Approver1__c",
                to: "approverId"
            }, {
                from: "Approver1Name__c",
                to: "approverName"
            }, {
                from: "NumberOfPallets__c",
                to: "pallets"
            }, {
                from: "NumberOfDays__c",
                to: "days"
            }, {
                from: "Budgeted_Locations__c",
                to: "locations"
            }, {
                from: "StartDate__c",
                to: "startDate"
            }, {
                from: "EndDate__c",
                to: "endDate"
            }, {
                from: "SalesGoal__c",
                to: "salesGoal"
            }, {
                from: "Overview__c",
                to: "description"
            }, {
                from: "CanReschedule__c",
                to: "canReschedule"
            }];
            return _async.call(project.retrieve, query, fieldMaps);
        };

        return self;
    };

    function flipDashboardAndFormWizard() {
        $("#masterContainer").toggleClass('cm-hide');
        $("#formWizard").toggleClass('cm-hide');
    }

    function toDateUTC(dateString) {
        var date = new Date(dateString);
        return new Date(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate());
    }

    var Viewer = function() {
        var _fromPageTitle = "Dashboard", _self = Object.create(_app.createView()),
            _templates = [],
            _startDatePicker, _endDatePicker,
            _retailerLookupMenu = _app.UI.lookupMenu({
                containerId: "projectRetailerLookup"
            }),
            _clientLookupMenu = _app.UI.lookupMenu({
                containerId: "projectClientLookup"
            }),
            _approverLookupMenu = _app.UI.lookupMenu({
                containerId: "projectApproverLookup"
            });

        _self.setFromPageTitle = function (title) {
            _fromPageTitle = title;
        };

        _self.error = function (err) {
            var html = ['<div class="cm-error-container"><span>', err.message, "</span></div>"].join("");
            if ($(".cm-form-wizard > .main section div").hasClass('cm-error-container')){
                $(".cm-form-wizard > .main section div.cm-error-container").remove();
            }
            $(".cm-form-wizard > .main > section:last-child > .cm-form").prepend(html);
        }

        _self.getFormData = function() {
            var form = $(".cm-form-wizard");
            return {
                id: form.attr("data-id"),
                typeId: form.attr("data-type-id"),
                title: form.find("#projectTitle").val(),
                retailerId: form.find("#projectRetailer").attr("data-id"),
                clientId: form.find("#projectClient").attr("data-id"),
                approverId: form.find("#projectApprover").attr("data-id"),
                startDate: toDateUTC(form.find("#projectStartDate").val()),
                endDate: toDateUTC(form.find("#projectEndDate").val()),
                budgetLocations: form.find("#projectBudgetLocations").val(),
                days: form.find("#projectDays").text(),
                pallets: form.find("#projectPallets").val(),
                description: form.find("#projectDescription").val(),
                salesGoal: form.find("#projectSalesGoal").val(),
                canReschedule: form.find("#canReschedule").is(":checked")
            };
        };

        _self.validateFormData = function() {
            var form = $(".cm-form-wizard"),
                noError = 1;
            form.find(".form-element__control input:required").each(function() {
                if (!$(this).val()) {
                    noError = 0;
                    $(this).parents("div.form-element").addClass("has-error");
                } else {
                    $(this).parents("div.form-element").removeClass("has-error");
                }
            });
            return noError;
        };

        _self.uiLoaded = function(projectTypeId) {
            var index = _.findIndex(_templates, function(t) {
                return t.id === projectTypeId;
            });
            return (index === -1) ? 0 : 1;
        };

        _self.setUI = function(projectTypeName, html) {
            _templates.push({
                id: projectTypeName,
                template: Handlebars.compile(html)
            });
            return _self;
        };

        _self.renderRetailerLookup = function(options) {
            _retailerLookupMenu.render({
                options: options
            }).show();
            _retailerLookupMenu.init(function(option) {
                handleRetailerLookupItemSelectEvent(option);
            });
        };

        _self.renderClientLookup = function(options) {
            _clientLookupMenu.render({
                options: options
            }).show();
            _clientLookupMenu.init(function(option) {
                $("#projectClient").val(option.value).attr("data-id", option.key);
                _clientLookupMenu.hide();
            });
        };

        _self.renderApproverLookup = function(options) {
            _approverLookupMenu.render({
                options: options
            }).show();
            _approverLookupMenu.init(function(option) {
                $("#projectApprover").val(option.value).attr("data-id", option.key);
                _approverLookupMenu.hide();
            });
        };

        function calculateNumberOfDays(startDate, endDate) {
            var days, domStartDate = $("#projectStartDate").val(),
                domEndDate = $("#projectEndDate").val();
            if (!domStartDate || !domEndDate) {
                return;
            }
            days = (Date.parse(domEndDate) - Date.parse(domStartDate)) / (Date.parse("2015-01-02") - Date.parse("2015-01-01"));
            $("#projectDays").html(days + 1);
        }

        function initDatePicker() {
            _app.UI.datepicker("projectStartDate", {
                onClose: function(selDate) {
                    
                    var date = new Date(selDate), endDateNotAssigned = (!$("#projectEndDate").val()) ? 1 : 0;
                    $("#projectEndDate").datepicker("option", "minDate", selDate);
                    if (endDateNotAssigned && !!selDate) {
                        date = new Date(selDate);
                        date.setDate(date.getDate() + 10);
                        $("#projectEndDate").val(date.toLocaleDateString());
                        $("#projectDays").text(11);
                    } else {
                        calculateNumberOfDays();
                    } 
                }
            });
            _app.UI.datepicker("projectEndDate", {
                onClose: function(selDate) {
                    calculateNumberOfDays();
                }
            });
        }

        _self.renderCreateProject = function(projectType) {
            var template = _.find(_templates, function(t) {
                return t.id === projectType.typeName;
            });

            var html = template.template({
                pageTitle: "Create Project",
                fromPageTitle: _fromPageTitle,
                projectTypeId: projectType.typeId,
                projectType: projectType.typeName,
                resourcePath: _app.Resources.path
            });
            $("#formWizard").empty().html(html);
            initDatePicker();
            flipDashboardAndFormWizard();
        };

        _self.renderEditProject = function(project) {
            var template = _.find(_templates, function(t) {
                return t.id === project.typeName;
            });
            var html = template.template({
                pageTitle: "Edit Project",
                fromPageTitle: _fromPageTitle,
                projectId: project.id,
                projectTypeId: project.typeId,
                projectType: project.typeName,
                projectTitle: project.title,
                resourcePath: _app.Resources.path,
                projectRetailerId: project.retailerId,
                projectRetailerName: project.retailerName,
                projectClientId: project.clientId,
                projectClientName: project.clientName,
                projectApproverId: project.approverId,
                projectApproverName: project.approverName,
                canRescheduleChecked: project.canReschedule ? 'checked="checked"' : "",
                projectStartDate: project.startDate.toLocaleDateString(),
                projectEndDate: project.endDate.toLocaleDateString(),
                projectDays: project.days,
                projectSalesGoal: project.salesGoal,
                projectBudgetLocations: 0,
                projectPallets: project.pallets,
                projectDescription: project.description,
                projectBudgetLocations: project.locations
            });
            $("#formWizard").empty().html(html);
            initDatePicker();
            flipDashboardAndFormWizard();
        };

        function handleRetailerLookupItemSelectEvent(option) {
            $("#projectRetailer").val(option.value).attr("data-id", option.key);
            _retailerLookupMenu.hide();
        }

        function handleLookupKeyDown(e) {
            console.log("handle lookup keydown:" + e);
        }

        _self.renderCancelbackToHome = function() {
                flipDashboardAndFormWizard();
            }
            //todo need to handle keyup event
        function initFormWizard() {
            $("#formWizard").on("click", ".breadcrumb > li > a", function(e) {
                e.preventDefault();
                flipDashboardAndFormWizard();
            });
            $("#formWizard").on("click", ".cm-form-footer button", function(e) {
                e.preventDefault();
                if ($(this).val() === "0") {
                    _app.router().route("project/cancel");
                } else {
                    _app.router().route("project/saveProject");
                }
            });
            //todo: init lookup button (typehead)
            $("#formWizard").on("click", "input#projectRetailer", function(e) {
                e.preventDefault();
                _app.router().route("project/lookupRetailers");
            }).on("focus", "input#projectRetailer", function(e) {
                e.preventDefault();
                _app.router().route("project/lookupRetailers");
            }).on("blur", "input#projectRetailer", function(e) {
                e.preventDefault();
                if (_retailerLookupMenu.isMouseOver()) {
                    return;
                }
                _retailerLookupMenu.hide();
            }).on("keyup", "input#projectRetailer", function(e) {
                e.preventDefault();
                handleLookupKeyDown(e);
            }).
            on("click", "input#projectClient", function(e) {
                e.preventDefault();
                _app.router().route("project/lookupClients");
            }).on("focus", "input#projectClient", function(e) {
                e.preventDefault();
                _app.router().route("project/lookupClients");
            }).on("blur", "input#projectClient", function(e) {
                e.preventDefault();
                if (_clientLookupMenu.isMouseOver()) {
                    return;
                }
                _clientLookupMenu.hide();
            }).on("keyup", "input#projectClient", function(e) {
                e.preventDefault();
                handleLookupKeyDown(e);
            }).
            on("click", "input#projectApprover", function(e) {
                e.preventDefault();
                _app.router().route("project/lookupApprovers");
            }).on("focus", "input#projectApprover", function(e) {
                e.preventDefault();
                _app.router().route("project/lookupApprovers");
            }).on("blur", "input#projectApprover", function(e) {
                e.preventDefault();
                if (_approverLookupMenu.isMouseOver()) {
                    return;
                }
                _approverLookupMenu.hide();
            }).on("keyup", "input#projectApprover", function(e) {
                e.preventDefault();
                handleLookupKeyDown(e);
            }).on("change", "#projectStartDate", function(e) {

            })
        }

        _self.addEvent(function() {
            initFormWizard();
        });

        return _self;
    };

    var Controller = function(id) {
        var self = Object.create(_app.createController(id));

        self.gotoCreateProject = function(data) {
            var v = self.view,
                m = self.model,
                option = data.data,
                context = {
                    typeId: option.key,
                    typeName: option.value
                };
            v.setFromPageTitle(data.pageTitle);
            if (v.uiLoaded(context.typeId)) {
                v.renderCreateProject(context);
            } else {
                m.getCreateProjectUI(context.typeName)
                    .done(function(html) {
                        v.setUI(context.typeName, html)
                            .renderCreateProject(context);
                    })
                    .fail(function(err) {
                        alert(err);
                    });
            }
        };

        self.gotoEditProject = function(data) {
            var v = self.view,
                m = self.model;

            m.getProject(data.projectId)
                .done(function(project) {
                    v.setFromPageTitle(data.pageTitle);
                    if (v.uiLoaded(project[0].typeId)) {
                        v.renderEditProject(project[0]);
                    } else {
                        m.getCreateProjectUI(project[0].typeName)
                            .done(function(html) {
                                v.setUI(project[0].typeName, html)
                                    .renderEditProject(project[0]);
                            }).fail(function(err) {
                                alert(err);
                            });
                    }
                }).fail(function(err) {
                    alert(err);
                });
        };

        self.save = function() {
            var data, m = self.model,
                v = self.view;
            if (!v.validateFormData()) {
                return;
            }
            data = v.getFormData();
            m.saveProject(data)
                .done(function(result) {
                    window.location.href = "/apex/ProjectView?id=" + result
                }).fail(function(err) {
                    v.error(err);
                });
        };

        self.cancel = function() {
            self.view.renderCancelbackToHome();
        };

        self.lookupRetailers = function(query) {
            var m = self.model,
                v = self.view,
                cacheKey = "project-retailers",
                retailers = _app.Cache.get(cacheKey);
            if (!!retailers) {
                v.renderRetailerLookup(retailers);
            } else {
                m.getRetailers(query && query.retailer)
                    .done(function(result) {
                        _app.Cache.add(cacheKey, result);
                        v.renderRetailerLookup(result);
                    })
                    .fail(function(err) {
                        alert(err);
                    });
            }
        };

        self.lookupApprovers = function(query) {
            var m = self.model,
                v = self.view,
                cacheKey = "project-approvers",
                approvers = _app.Cache.get(cacheKey);
            if (!!approvers) {
                v.renderApproverLookup(approvers);
            } else {
                m.getApprovers(query && query.client)
                    .done(function(result) {
                        _app.Cache.add(cacheKey, result);
                        v.renderApproverLookup(result);
                    })
                    .fail(function(err) {
                        alert(err);
                    });
            }
        };

        self.lookupClients = function(query) {
            var m = self.model,
                v = self.view,
                cacheKey = "project-clients",
                clients = _app.Cache.get(cacheKey);
            if (!!clients) {
                v.renderClientLookup(clients);
            } else {
                m.getClients(query && query.client)
                    .done(function(result) {
                        _app.Cache.add(cacheKey, result);
                        v.renderClientLookup(result);
                    })
                    .fail(function(err) {
                        alert(err);
                    });
            }
        };

        return self;
    };

    _app.addOnLoadEventListener(function() {
        var controllerId = "project";
        _app.registerMVC(new Model(), new Viewer(), new Controller(controllerId));
        _app.router().addRoute("project/gotoCreateProject", controllerId, "gotoCreateProject")
            .addRoute("project/gotoEditProject", controllerId, "gotoEditProject")
            .addRoute("project/cancel", controllerId, "cancel")
            .addRoute("project/saveProject", controllerId, "save")
            .addRoute("project/lookupRetailers", controllerId, "lookupRetailers")
            .addRoute("project/lookupApprovers", controllerId, "lookupApprovers")
            .addRoute("project/lookupClients", controllerId, "lookupClients");
    });

})(jQuery);
