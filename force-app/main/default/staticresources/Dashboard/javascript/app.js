(function($, window) {
    var _nextId = 0;
    var _application, _resources;

    if (typeof Object.create !== 'function') {
        Object.create = function(o) {
            function Hidden() {

            }
            Hidden.prototype = 0;
            return new Hidden();
        };
    }

    function genNextId() {
        _nextId++;
        return "ctrl" + _nextId;
    }

    function Application() {
        var _router = new Router(),
            _ctls = [],
            _onLoadSubscribers = [];
        _self = this;

        function ControllerBase(name) {
            this.name = name;
            this.view = 0;
            this.model = 0;
        }
        ControllerBase.prototype.inject = function(model, view) {
            this.model = model, this.view = view;
        };


        function ViewBase() {
            this.events = [];
            this.render = function() {
                throw "The view is not implemented.";
            };
        }

        ViewBase.prototype.addEvent = function(callback) {
            this.events.push(callback);
        };

        ViewBase.prototype.registerEvents = function() {
            _.forEach(this.events, function(e) {
                e();
            });
        };

        function Router() {
            var _rules = [];
            var _defaultRouteUrl = "";

            this.addRoute = function(url, controllerName, actionName) {
                _rules.push({
                    url: url,
                    controller: controllerName,
                    action: actionName
                });
                return this;
            };

            this.setDefault = function(routeUrl) {
                _defaultRouteUrl = routeUrl;
                return this;
            };

            this.routeToDefault = function() {
                if (!!_defaultRouteUrl) {
                    this.route(_defaultRouteUrl);
                }
            };

            this.getRoute = function(url) {
                var i = _.findIndex(_rules, function(r) {
                    return r.url === url;
                });
                return i !== -1 ? _rules[i] : undefined;
            };

            this.route = function(url, args) {
                var c, i = _.findIndex(_rules, function(r) {
                    return r.url === url;
                });
                if (i === -1) {
                    alert("The rounter can't understand the route url:" + url);
                    return;
                }
                c = getC(_rules[i].controller);
                if (c) {
                    return c[_rules[i].action](args);
                } else {
                    alert("Failed to find the controller based on the route url:" + url);
                }
            };
        }

        function getC(name) {
            return _.find(_ctls, function(ctl) {
                return ctl.name === name;
            });
        }

        function onLoad() {
            _.each(_onLoadSubscribers, function(e) {
                e();
            });

            _.forEach(_ctls, function(c) {
                c.view.registerEvents();
            });

            _application.router().routeToDefault();
        }

        return {
            registerMVC: function(m, v, c) {
                c.inject(m, v);
                _ctls.push(c);

                return this;
            },

            router: function() {
                return _router;
            },

            getController: function(url) {
                var route = _router.getRoute(url);
                return !!route ? getC(route.controller) : 0;
            },

            createController: function(name) {
                return new ControllerBase(name);
            },

            createView: function() {
                return new ViewBase();
            },

            setDefaultRouteCallback: function(routeCallback) {
                _defaultRouteCallAPI = routeCallback();
            },

            addOnLoadEventListener: function(callback) {
                _onLoadSubscribers.push(callback || function() {});
            },

            onLoad: function() {
                onLoad();
            }
        };
    }

    function HtmlElement() {
        this.render = function(context) {
            throw "The render(context) is not implemented."
        };
        this.init = function(callback) {
            throw "The init(callback) is not implemented.";
        };
        this.html = function(context) {
            throw "The html(context) is not implemented.";
        };
    };


    var UI = function() {};

    UI.prototype.htmlSelect = function(containerId, cssClass, cssOptions, enableSelect) {
        var _containerId = containerId,
            _cssClass = cssClass,
            _selectEnabled = (!!enableSelect) ? 1 : 0,
            _cssOptions = (!!cssOptions) ? " " + cssOptions + " " : " ",
            _self = Object.create(new HtmlElement());



        _self.init = function(selCallback) {
            $("#" + containerId).on("click", ".picklist__label", function(e) {
                e.preventDefault();
                $(this).parent(".picklist").find(".picklist__options").toggle();
            }).on("click", ".picklist__options > li", function(e) {
                e.preventDefault();
                var target = $(this);
                var options = target.parent(".picklist__options");
                var selectedIcon = _application.Resources.getSelectedIcon();
                if (_selectEnabled) {
                    target.prevAll().removeClass('is-selected').attr("aria-selected", "false").find("svg.icon").remove();
                    target.nextAll().removeClass('is-selected').attr("aria-selected", "false").find("svg.icon").remove();
                    target.addClass('is-selected');
                    target.append(selectedIcon);
                    target.attr("aria-selected", "true");
                    var html = target.find("span").html() + '<svg aria-hidden="true" class="icon"><use xlink:href="' + _application.Resources.path + '/assets/icons/utility-sprite/svg/symbols.svg#down"></use></svg>';
                    target.parents(".picklist").find(".picklist__label").html(html);
                }
                target.parent(".picklist__options").toggle();
                selCallback({
                    key: target.attr("data-id"),
                    value: target.find("span").html()
                });
            });
        };

        _self.render = function(context) {
            var html = '<span tabindex="0" class="picklist__label {{class}} truncate" aria-haspopup="true">{{selOption}}<svg aria-hidden="true" class="icon"><use xlink:href="' + getResourcePath() + '/assets/icons/utility-sprite/svg/symbols.svg#down"></use></svg></span><ul class="picklist__options cm-picklist-options{{cssOptionsClass}}hide">{{#each options}} {{#if selected }}<li data-id="{{key}}" class="picklist__options-item is-selected" aria-selected="true" tabindex="-1" role="option"><svg aria-hidden="true" class="icon icon--small icon--left"><use xlink:href="' + getResourcePath() + '/assets/icons/standard-sprite/svg/symbols.svg#task2"></use></svg><span>{{{value}}}</span></li>{{else}}<li data-id="{{key}}" class="picklist__options-item" aria-selected="false" tabindex="-1" role="option"><span>{{{value}}}</span></li>{{/if}}{{/each}}</ul>',
                template = Handlebars.compile(html),
                options = _.map(context.options, function(e) {
                    return {
                        "key": e.key,
                        "value": e.value,
                        "selected": e.value === context.selValue ? 1 : 0
                    };
                });
            $("#" + _containerId).empty().html(template({
                id: this.id,
                class: cssClass,
                cssOptionsClass: _cssOptions,
                selOption: context.selValue,
                options: options
            }));
        };

        _self.html = function(context) {

        };

        return _self;
    };

    UI.prototype.htmlDropdown = function(containerId, enableSelect) {
        var _self = Object.create(new HtmlElement()),
            _containerId = containerId,
            _selectEnabled = enableSelect;

        _self.render = function(context) {
            var html = '{{#if hasTitle}}<div class="dropdown__header"><span class="text-heading--label">{{title}}</span></div>{{/if}}<ul class="dropdown__list" role="menu">{{#each menuItems}} {{#if disabled}}<li data-id="{{key}}" disabled="" href="#rename" class="dropdown__item has-icon--left" role="menuitem option" tabindex="0"><a href="#{{key}}" tabindex="-1" aria-disabled="true">{{#if hasLeftIcon}}<svg aria-hidden="true" class="icon icon--small icon--left"><use xlink:href="{{leftIconUrl}}"></use></svg>{{/if}}<span>{{{value}}}</span>{{#if hasRightIcon}}<svg aria-hidden="true" class="icon icon--small icon--right"><use xlink:href="{{rightIconUrl}}"></use></svg>{{/if}}</a></li>{{else}}<li data-id="{{key}}" href="#rename" class="dropdown__item has-icon--left" role="menuitem option" tabindex="0"><a href="#{{key}}" tabindex="-1" aria-disabled="false">{{#if hasLeftIcon}}<svg aria-hidden="true" class="icon icon--small icon--left"><use xlink:href="{{leftIconUrl}}"></use></svg>{{/if}}<span>{{value}}</span>{{#if hasRightIcon}}<svg aria-hidden="true" class="icon icon--small icon--right"><use xlink:href="{{rightIconUrl}}"></use></svg>{{/if}}</a></li>{{/if}} {{/each}}</ul>',
                template = Handlebars.compile(html);
            items = _.map(context.menuItems || [], function(e) {
                return {
                    "key": e.key,
                    "value": e.value,
                    "disabled": e.disabled,
                    "hasLeftIcon": (!!e.leftIconUrl) ? 1 : 0,
                    "leftIconUrl": _resources.getResource(e.leftIconUrl),
                    "hasRightIcon": (!!e.rightIconUrl) ? 1 : 0,
                    "rightIconUrl": _resources.getResource(e.rightIconUrl)
                };
            });
            $("#" + containerId).empty().html(template({
                hasTitle: (!!context.title) ? 1 : 0,
                title: context.title || "",
                menuItems: items
            }));
        };

        _self.init = function(selectCallback) {
            $("#" + containerId).on("click", "ul.dropdown__list > li > a", function(e) {
                e.preventDefault();
                var selectedIcon = _application.Resources.getSelectedIcon();

                if (_selectEnabled) {
                    var li = $(this).parent("li");
                    li.prevAll().removeClass('is-selected').find("a svg.icon--left").remove();
                    li.nextAll().removeClass('is-selected').find("svg.icon--left").remove();
                    li.addClass('is-selected');
                    $(this).prepend(selectedIcon);
                } else {

                }
                selectCallback({
                    "key": $(this).parent("li").attr("data-id"),
                    "value": $(this).find("span").html()
                });
            });
        };

        _self.html = function(context) {

        };


        return _self;
    };

    UI.prototype.placeHolder = function(containerId, html) {
        var _self = Object.create(new HtmlElement()),
            _html = html;


        _self.init = function(callback) {

        };

        _self.render = function(context) {
            $("#" + containerId).empty().html(html);
        }

        _self.html = function(context) {
            return _html;
        };

        return _self;
    }

    /*
        config = {
            containerId: "", 
            title: "", 
            canExpand: 1/0,
            canClose: 1/0,
            navBars: [{id: "", iconUrl: "", text: "", callback: function () {}}], 
            body: child Control is used to generated body
        }
    */
    UI.prototype.widget = function(config) {
        var _self = Object.create(new HtmlElement()),
            _config = {
                containerId: config.containerId,
                title: config.title || "No Title",
                canExpand: config.canExpand ? 1 : 0,
                canClose: config.canClose ? 1 : 0,
                navBars: config.navBars || [],
                bodyControl: config.bodyControl || new HtmlElement()
            },
            _id = 0,
            _chart = undefined,
            _html = '<article class="cm-article"><header class="clearfix"><div class="float-left"><h2 class="text-heading--label text-heading--large cm-article-title">{{{title}}}</h2></div><div class="float-right">{{#each navBars}}<button data-id="{{id}}" title="{{text}}" class="button button--icon-border button--icon-border-small"><svg aria-hidden="true" class="button__icon button__icon--small cm-icon"><use xlink:href="{{iconUrl}}"></use></svg><span class="assistive-text">{{text}}</span></button>{{/each}}</div></header><div class="cm-article-body">{{{bodyHtml}}}</div></article>',
            _template = Handlebars.compile(_html);

        function getSelCol(source) {
            return {
                col: source.parents("div.col"),
                container: source.parents("div.cm-col-container")
            };
        }

        function zoomIn(source) {
            var id = "div.cm-col-container",
                colContainer = source.parents(id),
                height = 450,
                isFullScreen = $("body").hasClass("cm-body-full-screen");

            colContainer.toggleClass('cm-widget-full-screen');
            $("body").toggleClass('cm-body-full-screen');
            if (!isFullScreen) {
                height = $(window).height() - 150;
            }
            colContainer.find(".cm-article-body").height(height);
            colContainer.find(".cm-article-body").parent("div").height(height);


            if (!!_chart) {
                _chart.update();
            }
        }

        function close(source) {
            var col = source.parents("div.col"),
                row = source.parents("div.cm-row"),
                container = source.parents("div.cm-col-container"),
                closedCols = 0,
                count = 0;

            if($("body").hasClass("cm-body-full-screen")) {
                $("body").removeClass("cm-body-full-screen");
            }

            if (container.hasClass('cm-zoomin')) {
                zoomIn(source);
            }
            col.toggleClass("cm-close");
            if (!container.hasClass("cm-col-right")) {
                if (row.find(".cm-col-right")) {
                    row.find(".cm-col-right").addClass('cm-col-right-0');
                }
            }
            col.prevAll("div.col").each(function(i, c) {
                if ((!!c.getAttribute("class")) && c.getAttribute("class").indexOf("cm-close") !== -1) {
                    closedCols++;
                }
                count++;
            });
            col.nextAll("div.col").each(function(i, c) {
                if ((!!c.getAttribute("class")) && c.getAttribute("class").indexOf("cm-hide") !== -1) {
                    closedCols++;
                }
                count++;
            });
            if (closedCols === count) {
                row.toggleClass('cm-close');
            }
        }

        if (config.canExpand) {
            _id++;
            _config.navBars.push({
                id: "_sys" + _id,
                iconUrl: _application.Resources.path + "/assets/icons/utility-sprite/svg/symbols.svg#expand",
                text: "Expand",
                callback: function(source) {
                    zoomIn(source);
                }
            });
        }
        if (config.canClose) {
            _id++;
            _config.navBars.push({
                id: "_sys" + _id,
                iconUrl: _application.Resources.path + "/assets/icons/utility-sprite/svg/symbols.svg#close",
                text: "Close",
                callback: function(source) {
                    close(source);
                }
            });
        }

        _self.init = function(callback) {
            _config.bodyControl.init();
            $("#" + config.containerId).on("click", "article > header div.float-right button", function(e) {
                var source = $(this);
                var id = source.attr("data-id");
                var sel = _.find(config.navBars, function(e) {
                    return e.id === id;
                });
                if (sel) {
                    sel.callback(source);
                }
            });
        };

        _self.setChart = function(chart) {
            _chart = chart;
        }

        _self.render = function(context) {
            var config = {
                    containerId: _config.containerId,
                    title: _config.title,
                    canExpand: _config.canExpand,
                    canClose: _config.canClose,
                    navBars: _config.navBars,
                    bodyHtml: _config.bodyControl.html(context)
                },
                timeId,
                onRendered = context.onRendered || function() {},
                html = _template(config);
            $("#" + config.containerId).empty().html(html);
            timeId = setTimeout(function() {
                clearTimeout(timeId);
                onRendered(_self, config.containerId, context.data);
            }, 10);
        };

        return _self;
    };

    /*
        config = {
            id: "",
            cols: [
              {
                id: "record field identitifer",
                dataType: "number" | "string" | date,
                title: "",
                canSort: 1/0,
                sorted: 1/0, 
                locked: 1/0,
                uiType: "link" | "label" | "icon" | "text",
                labels: [{key: "ok", text: "", css: "label-success"}],
                onClick: function (source) {}
              }   
            ]
        }

        here click source: {
            id: "fieldId",
            record: "select record"
        }
    */
    /*    
        cell: {title: "",
        value: "",
        uiType: "link" | "label" | "icon" | "text",
        labels: [{key: "ok", text: "Succeeded", css: "label-success"}]
        }
    */
    UI.prototype.dataGrid = function(config) {
        var _self = Object.create(new HtmlElement()),
            _header = "",
            _config = {
                id: config.id || genNextId,
                parentId: config.parentId,
                cols: undefined
            },
            _data = undefined;

        _config.cols = _.map(config.cols || [], function(e) {
            return {
                id: e.id,
                dataType: e.dataType || "string",
                title: e.title || "None",
                canSort: e.canSort ? 1 : 0,
                sorted: e.sorted ? 1 : 0,
                locked: e.locked ? 1 : 0,
                uiType: e.uiType || "text",
                labels: e.labels || [],
                click: e.onClick || undefined
            };
        });



        function genTableCell(col) {
            var html = ['<td class="truncate" data-label="', col.title, '">'];

            switch (col.uiType) {
                case "text":
                    html.push(["<span>", col.value, "</span>"].join(""));
                    break;
                case "link":
                    html.push(['<a href="#">', col.value, '</a>'].join(""));
                    break;
                case "label":
                    selLabel = _.find(col.labels, function(l) {
                        return l.key === col.value + "";
                    }) || {
                        key: col.value,
                        text: col.value,
                        css: ""
                    };
                    html.push(['<span class="label ', selLabel.css, '">', selLabel.text, '</span>'].join(""));
                    break;
                case "icon":
                    html.push(['<svg aria-hidden="true" class="button__icon button__icon--small cm-icon"><use xlink:href="', getResourcePath(), col.icon, '"></use></svg>'].join(""));
                    break;
                default:
                    html.push(["<span>", col.value, "</span>"].join(""));
                    break;
            }
            html.push("</td>");
            return html.join("");
        }

        function genHeaderHtml() {
            var html = '<thead><tr>{{#each headers}}<th data-id="{{id}}" data-type="{{dataType}}" class="is-interactive{{selected}}{{locked}}"><span class="truncate">{{title}}</span><button class="button button--icon-bare button--icon-border-small"><svg aria-hidden="true" class="button__icon button__icon--small"><use xlink:href="' + getResourcePath() + '/assets/icons/utility-sprite/svg/symbols.svg#arrowdown"></use></svg><span class="assistive-text">Sort</span></button></th>{{/each}}</tr></thead>',
                template = Handlebars.compile(html),
                cols = _.map(_config.cols, function(e) {
                    return {
                        id: e.id,
                        dataType: e.dataType,
                        selected: (e.canSort && e.sorted) ? " cm-is-selected" : "",
                        locked: (e.canSort) ? "" : " locked",
                        title: e.title
                    };
                });
            return template({
                headers: cols
            });
        }

        function genBodyHtml() {
            var html = ["<tbody>"],
                cols = _.map(_config.cols, function(col) {
                    return {
                        id: col.id,
                        title: col.title,
                        dataType: col.dataType,
                        value: "",
                        uiType: col.uiType,
                        labels: col.labels
                    }
                });
            _.each(_data, function(rec) {
                html.push(['<tr class="hint-parent" data-id="', rec.id, '">'].join(""));
                _.each(cols, function(col) {
                    if (col.dataType === "date") {
                        col.value = (!!rec[col.id]) ? rec[col.id].toLocaleDateString() : "";
                    } else {
                        col.value = rec[col.id] || "";
                    }
                    html.push(genTableCell(col))
                })
                html.push("</tr>");
            });
            html.push("</tbody>");

            return html.join("");
        }


        function setCurrentData(context) {
            _data = (!!context) ? (context.data || []) : [];
        }

        function renderTable() {
            var html = ['<table class="table table--bordered wrap" id="', _config.id, '">'];
            html.push(genHeaderHtml());
            html.push(genBodyHtml());
            html.push("</table>");
            return html.join("");
        }


        _self.render = function(context) {
            var html;
            setCurrentData(context);
            html = renderTable();
            $("#" + containerId).empty().html(html);
        };

        function getColIndex(dataId) {
            return _.findIndex(_config.cols, function(col) {
                return col.id === dataId;
            });
        }

        function parseDate(r1, r2) {
            try {
                return {
                    date1: Date.parse(r1.value),
                    date2: Date.parse(r2.value)
                };
            } catch (e) {
                return {
                    date1: r1.value,
                    date2: r2.value
                };
            }
        }

        function sortByDateASC(r1, r2) {
            var e = parseDate(r1, r2);
            return e.date1 > e.date2 ? 1 : -1;
        }

        function sortByNumberASC(r1, r2) {
            return parseInt(r1.value) > parseInt(r2.value) ? 1 : -1;
        }

        function sortByStringASC(r1, r2) {
            return r1.value > r2.value ? 1 : -1;
        }

        function sortByDateDESC(r1, r2) {
            var e = parseDate(r1, r2);
            return e.date1 > e.date2 ? -1 : 1;
        }

        function sortByNumberDESC(r1, r2) {
            return parseInt(r1.value) > parseInt(r2.value) ? -1 : 1;
        }

        function sortByStringDESC(r1, r2) {
            return r1.value > r2.value ? -1 : 1;
        }

        function sortTable(source) {
            var selColIndex, rows = [],
                tbodySelector,
                svg = source.find("svg"),
                html = [],
                selCol, isASC = 1;

            $("#" + _config.parentId + " thead > tr > th").removeClass("cm-is-selected");
            source.parent("th").addClass("cm-is-selected");
            if (svg.html().indexOf("#arrowdown") !== -1) {
                svg.html(svg.html().replace("#arrowdown", "#arrowup"));
            } else {
                svg.html(svg.html().replace("#arrowup", "#arrowdown"));
                isASC = 0;
            }
            selColIndex = getColIndex(source.parent("th").attr("data-id"));
            if (selColIndex === -1) {
                console.log("can't find column based on header data-id:" + source.parent("th").attr("data-id"));
            } else {
                selCol = _config.cols[selColIndex];
                tbodySelector = "#" + _config.parentId + " tbody";
                $(tbodySelector + " tr").each(function() {
                    var selCell = "";
                    switch (selCol.uiType) {
                        case "text":
                            selCell = $(this).find(["td:eq(", selColIndex, ") span"].join("")).html();
                            break;
                        case "link":
                            selCell = $(this).find(["td:eq(", selColIndex, ") a"].join("")).html();
                            break;
                        case "label":
                            selCell = $(this).find(["td:eq(", selColIndex, ") span"].join("")).html();
                            break;
                        case "icon":
                            selCell = $(this).find("td").eq(selColIndex).html();
                            break;
                        default:
                            selCell = $(this).find("td").eq(selColIndex).html();
                            break;
                    }
                    rows.push({
                        id: $(this).attr("data-id"),
                        value: selCell,
                        tr: $(this)
                    });
                });



                switch (selCol.dataType) {
                    case "date":
                        if (isASC) {
                            rows.sort(sortByDateASC);
                        } else {
                            rows.sort(sortByDateDESC);
                        }
                        break;

                    case "number":
                        if (isASC) {
                            rows.sort(sortByNumberASC);
                        } else {
                            rows.sort(sortByNumberDESC);
                        }
                        break;
                    default:
                        if (isASC) {
                            rows.sort(sortByStringASC);
                        } else {
                            rows.sort(sortByStringDESC);
                        }

                        break;
                }
                _.each(rows, function(row) {
                    var e = ['<tr data-id="', row.id, '" class="hint-parent">'];
                    e.push(row.tr.html());
                    e.push("</tr>");
                    html.push(e.join(""));
                });
                $(tbodySelector).empty().html(html.join(""));
            }
        }

        _self.init = function(callback) {
            $("#" + _config.parentId).on("click", "thead > tr > th button", function(e) {
                e.preventDefault();
                sortTable($(this));
            }).on("click", "tbody > tr > td > a", function(e) {
                var colId;
                e.preventDefault();
                colId = $(this).parent("td").attr("data-label");
                var col = _.find(_config.cols, function(c) {
                    return c.title === colId;
                });
                if (!!col) {
                    col.click($(this).parents("tr").attr("data-id"));
                }
            });
        };

        _self.html = function(context) {
            setCurrentData(context);
            return renderTable();
        };

        return _self;
    };

    UI.prototype.lookupMenu = function(config) {
        var _self = Object.create(new HtmlElement()),
            _domId = "#" + config.containerId,
            _isMouseOver = 0,
            _template = Handlebars.compile('<li class="lookup__item truncate" role="presentation" data-id="{{key}}"><a href="#" role="option"><svg aria-hidden="true" class="icon icon-standard-account icon--small"><use xlink:href="' + _application.Resources.path + '/assets/icons/standard-sprite/svg/symbols.svg#account"></use></svg>{{{value}}}</a></li>');

        function renderLookup(options) {
            var html = ['<ul class="lookup__list" role="presentation">'];
            _.each(options, function(option) {
                html.push(_template(option));
            });
            html.push("</ul>");

            return html.join("");
        }

        _self.init = function(callback) {
            $(_domId).on("click", "ul > li > a", function(e) {
                e.preventDefault();
                callback({
                    key: $(this).parent("li").attr("data-id"),
                    value: $(this).text()
                });
            }).on("mouseover", function(e) {
                e.preventDefault();
                _isMouseOver = 1;
            }).on("mouseleave", function(e) {
                _isMouseOver = 0;
            });
        };


        _self.render = function(context) {
            var options = context.options || [];
            var width = $(_domId.replace("Lookup", "")).width() + 45;
            $(_domId).empty().html(renderLookup(options)).width(width);
            $(_domId + " ul").slimScroll({
                position: "right",
                height: "200px",
                width: width + "px",
                color: "#666",
                railColor: "#ccc",
                railVisible: true,
                size: "10px",
                alwaysVisible: true
            });
            return _self;
        };

        _self.show = function() {
            $(_domId).removeClass("hide").show();
        };

        _self.isMouseOver = function() {
            return _isMouseOver;
        }

        _self.isHidden = function() {
            return $(_domId).hasClass('hide');
        }

        _self.hide = function() {
            $(_domId).addClass("hide").hide();
        };

        _self.html = function(context) {
            var options = context.options || [];
            return renderLookup(options);
        };

        return _self;
    };

    /* jquery UI Datepicker */
    UI.prototype.datepicker = function(dateInputControlId, options) {
        var _domId = "#" + dateInputControlId;
        var settings = $.extend({
            changeMonth: true,
            changeYear: true,
            showOtherMonths: true,
            selectOtherMonths: false
        }, options);

        return $(_domId).datepicker(settings);
    };
    /*
    config = {
        containerId = "projectStartDateContainer",
        id: "input field control id",
        label: "field label"
    }

    */
    /*
    UI.prototype.datepicker = function(config) {
        var _selTmpl = Handlebars.compile('<td class="is-selected" headers="{{header}}" role="gridcell" aria-selected="true"><span class="day">{{day}}</span></td>'),
            _tmpl = Handlebars.compile('<td headers="{{header}}" role="gridcell" aria-selected="false"><span class="day">{{day}}</span></td>'),
            _disabledTmpl = Handlebars.compile('<td class="disabled-text" headers="{{header}}" role="gridcell" aria-disabled="true"><span class="day">{{day}}</span></td>'),
            _days = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"],
            _domId = "#" + config.containerId,
            _config = config,
            _month = new Array(6),
            _self = Object.create(new HtmlElement());
        var JAN = 0,
            FEB = 1,
            MAR = 2,
            APR = 3,
            MAY = 4,
            JUN = 5,
            JUL = 6,
            AUG = 7,
            SEP = 8,
            OCT = 9,
            NOV = 10,
            DEC = 11;
        var SUN = 0,
            MON = 1,
            TUE = 2,
            WED = 3,
            THU = 4,
            FRI = 5,
            SAT = 6;
        var MONTHNAMES = ["January", "Feburary", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"];

        for (var i = 0; i < _month.length; i++) {
            _month[i] = new Array(7);
        }

        function getMonthLastDateNumber(year, month) {
            var date, _year = year,
                _month = month;
            if ([JAN, MAR, MAY, JUL, AUG, OCT, DEC].indexOf(_month) !== -1) {
                return 31;
            } else if ([APR, JUN, SEP, NOV].indexOf(_month) !== -1) {
                return 30;
            } else {
                date = new Date(_year, FEB, 28);
                date.setDate(29);
                return (date.getMonth() === FEB) ? 29 : 28;
            }
        }

        function getLastMonthLastDateNumber(year, month) {
            var _month = month - 1,
                _year = year;
            _year = (_month < 0) ? _year - 1 : _year;
            _month = (_month < 0) ? 12 : _month;

            return getMonthLastDateNumber(_year, _month);
        }

        function assignDateToMonthMatrix(selContext) {
            var row = 0,
                col = 0,
                day = 1,
                month = selContext.month,
                year = selContext.year,
                selDateNumber = selContext.date,
                firstDate,
                lastDateNumber,
                lastDate,
                firstDay,
                lastMonthLastDateNumber,
                isSelected = 0,
                selCell = {
                    row: 0,
                    col: 0,
                    selDate: selDateNumber
                };
            firstDate = new Date(year, month, 1, 0, 0, 0, 0);
            lastDateNumber = getMonthLastDateNumber(year, month);
            lastDate = new Date(year, month, lastDateNumber, 0, 0, 0, 0);
            firstDay = firstDate.getDay();
            lastMonthLastDateNumber = getLastMonthLastDateNumber(year, month);

            for (col = firstDay - 1; col > -1; col--) {
                _month[row][col] = lastMonthLastDateNumber;
                lastMonthLastDateNumber--;
            }

            if (selDateNumber === 0) {
                isSelected = 1;
                for (col = firstDay; col < 7; col++) {
                    _month[row][col] = day;
                    day++;
                }
            } else {
                for (col = firstDay; col < 7; col++) {
                    _month[row][col] = day;
                    if (day === selDateNumber) {
                        isSelected = 1;
                        selCell.row = row;
                        selCell.col = col;
                    }
                    day++;
                }
            }
            for (row = 1; row < 6; row++) {
                for (col = 0; col < 7; col++) {
                    _month[row][col] = day;
                    if (isSelected === 0 && day === selDateNumber) {
                        selCell.row = row;
                        selCell.col = col;
                        isSelected = 1;
                    }
                    day = (day < lastDateNumber) ? day + 1 : 1;
                }
            }

            return selCell;
        }

        function genDatePickerBody(selCell) {
            var row = 0,
                col, tr, html = [],
                isPrevMonth = 1,
                isSelected = 0;
            if (selCell.selDate === 0) {
                isSelected = 1;
            }

            function resolveTemplate(r, c) {
                if (isSelected === 0 && selCell.row === r && selCell.col === c) {
                    isSelected = 1;
                    return _selTmpl;
                } else {
                    return _tmpl;
                }
            }



            function resolveTemplateForRow5To6(r, c) {
                if (isSelected === 0 && selCell.row === r && selCell.col === c) {
                    isSelected = 1;
                    return _selTmpl;
                } else {
                    return _month[row][col] < 20 ? _disabledTmpl : _tmpl;
                }
            }

            html.push("<tr>");
            for (col = 0; col < 7; col++) {
                if (isPrevMonth && _month[row][col] > 1) {
                    html.push(_disabledTmpl({
                        day: _month[row][col]
                    }));
                } else {
                    isPrevMonth = 0;
                    html.push(resolveTemplate(row, col)({
                        day: _month[row][col]
                    }));
                }
            }
            html.push("</tr>");

            for (row = 1; row < 4; row++) {
                html.push("<tr>");
                for (col = 0; col < 7; col++) {
                    html.push(resolveTemplate(row, col)({
                        day: _month[row][col]
                    }));
                }
                html.push("</tr>");
            }

            for (row = 4; row < 6; row++) {
                html.push("<tr>");
                for (col = 0; col < 7; col++) {
                    html.push(resolveTemplateForRow5To6(row, col)({
                        day: _month[row][col]
                    }));
                }
                html.push("</tr>");
            }
            return html.join("");
        }

        function renderDatePickerControl(context, isFirstTime) {
            var today = new Date();
            context = {
                year: context && context.year || today.getFullYear(),
                month: context && context.month || today.getMonth(),
                date: context && context.date || 0
            };
            var years = [];
            var html = _application.Cache.get("datepicker"),
                tmpl = Handlebars.compile(html);
            for (var i = 0; i < 10; i++) {
                years[i] = {
                    year: context.year + i
                };
            }

            $(_domId).html(tmpl({
                id: _config.id,
                label: _config.label,
                path: _application.Resources.path,
                selMonthLabel: MONTHNAMES[context.month],
                selMonth: context.month,
                selYear: context.year,
                years: years
            }));
            var id = window.setTimeout(function() {
                window.clearTimeout(id);
                var selCell = assignDateToMonthMatrix(context);
                var htmlBody = genDatePickerBody(selCell);
                $(_domId + " table tbody").empty().html(htmlBody);
                initEvent(function(selDate) {
                    alert(selDate);
                });
            }, 5);
        }

        // 7 cols X 6 rows. get 1 day of each month and check its day, check previous month days that we can poppulate on this month table
        // get last day of this month, check next month first several day to populate rest of table cells.
        // context = {year: 2014, month: 1, date: 12} if date = 0, it mean no selection
        _self.render = function(context) {

            if (_application.Cache.exists("datepicker")) {
                renderDatePickerControl(context);
            } else {
                _application.Http.getHtml(_application.Resources.appPath + "/templates/datepicker.html")
                    .done(function(html) {
                        _application.Cache.add("datepicker", html);
                        renderDatePickerControl(context);
                    }).fail(function(err) {
                        alert(err);
                    });
            }

        };

        //context = {year: 2014, month: 1}
        _self.renderBodyOnly = function(context) {

        }

        _self.init = function(callback) {};

        function handleDateSelectEvent(selItem) {
            var selDate = parseInt(selItem.find("span").html()),
                parent = selItem.parents(".datepicker");
            var selYear = parseInt(parent.find(".datepicker__filter--year button span").html());
            var selMonth = parseInt(parent.find(".datepicker__filter--month button").attr("data-id"));
            var selDateString = new Date(selYear, selMonth, selDate, 0, 0, 0, 0).toLocaleDateString();
            selItem.parents("div.cm-input-lookup").find('input[data-role="date"]').val(selDateString);
            $(_domId).find(".datepicker").addClass('hide');
        }

        function initEvent(callback) {
            var isDatepickerMouseOver = 0;

            $(_domId).on("click", ".datepicker .datepicker__month tbody > tr > td", function(e) {
                e.preventDefault();
                handleDateSelectEvent($(this));
            });
            $(_domId).on("click", ".datepicker .datepicker__filter .datepicker__filter--year button", function(e) {
                e.preventDefault();
                $(_domId + " .datepicker .datepicker__filter .datepicker__filter--year .dropdown").toggleClass('hide');
                renderBodyOnly();
            }).on("click", ".datepicker__filter--month button", function(e) {
                e.preventDefault();
                $(_domId + " .datepicker__filter--month .dropdown--menu").toggleClass('hide');
                renderBodyOnly();
            });

            $(_domId).on("click", ".datepicker .datepicker__filter .dropdown a", function(e) {
                e.preventDefault();
                var option = {
                    key: $(this).parent("li").attr("data-id"),
                    value: $(this).html()
                };
                $(this).parents(".dropdown--menu").addClass('hide');
                $(this).parents(".picklist").find("button").attr("data-id", option.key);
                $(this).parents(".picklist").find("button span").text(option.value);
                callback(option);
            }).on("focus", "input[data-role='date']", function(e) {
                e.preventDefault();
                var id = $(this).attr("id");
                $(["#", id, "_Dropdown .datepicker"].join("")).removeClass('hide');
            }).on("blur", "input[data-role='date']", function(e) {
                e.preventDefault();
                if (isDatepickerMouseOver) {
                    return;
                }
                var id = $(this).attr("id");
                $(["#", id, "_Dropdown .datepicker"].join("")).addClass('hide')
            }).on("mouseover", ".datepicker", function(e) {
                e.preventDefault();
                isDatepickerMouseOver = 1;
            }).on("mouseleave", ".datepicker", function(e) {
                e.preventDefault();
                isDatepickerMouseOver = 0;
            });
        }

        _self.html = function(context) {
            var selCell, selContext, today = new Date();
            selContext = context || {
                year: today.getFullYear(),
                month: today.getMonth(),
                date: 0
            };
            selCell = assignDateToMonthMatrix(selContext);
            return genDatePickerBody(selCell);
        };

        return _self;
    };
    */
    /* chart library definition area */

    function randomData(groups, points) { //# groups,# points per group
        var data = [],
            shapes = ['circle'],
            random = d3.random.normal();

        for (i = 0; i < groups; i++) {
            data.push({
                key: 'Group ' + i,
                values: [],
                slope: Math.random() - .01,
                intercept: Math.random() - .5
            });

            for (j = 0; j < points; j++) {
                data[i].values.push({
                    x: random(),
                    y: random(),
                    size: Math.random(),
                    shape: shapes[j % shapes.length]
                });
            }
        }
        return data;
    }

    function ChartLibrary() {}
    ChartLibrary.prototype.scatterPlotChart = function(parent, containerId, data) {
        var chart;
        nv.addGraph(function() {
            chart = nv.models.scatterChart()
                .showDistX(true)
                .showDistY(true)
                .duration(300)
                .color(d3.scale.category10().range());

            chart.dispatch.on('renderEnd', function() {
                parent.setChart(chart);
            });

            chart.xAxis.tickFormat(d3.format('.02f'));
            chart.yAxis.tickFormat(d3.format('.02f'));

            d3.select(containerId)
                .datum(nv.log(randomData(4, 40)))
                .call(chart);

            nv.utils.windowResize(chart.update);
            chart.dispatch.on('stateChange', function(e) {
                nv.log('New State:', JSON.stringify(e));
            });
            return chart;
        });
        return chart;
    }

    function Resources() {
        this.path = "";
        this.appPath = "";
    }

    Resources.prototype.getResource = function(url) {
        return this.path + url;
    };

    Resources.prototype.getAppResource = function(url) {
        return this.appPath + url;
    }

    Resources.prototype.getSelectedIcon = function() {
        return '<svg aria-hidden="true" class="icon icon--small icon--left"><use xlink:href="' + this.getResource("/assets/icons/standard-sprite/svg/symbols.svg#task2") + '"></use></svg>';
    }

    function getResourcePath() {
        return _resources.path;
    }


    function Http() {}

    function ajaxGet(url, type) {
        var defer = $.Deferred();

        $.ajax({
            type: "GET",
            url: url,
            dataType: type
        }).done(function(result) {
            defer.resolve(result);
        }).fail(function(xhr, status, err) {
            console.log(xhr);
            defer.reject(["status:", status, " err:" + err].join(""));
        });

        return defer;
    }

    Http.prototype.getHtml = function(url) {
        return ajaxGet(url, "html");
    };

    Http.prototype.getJson = function(url) {
        return ajaxGet(url, "json");
    };

    function LogonUser() {
        this.userId = "";
    }

    function Async() {}
    Async.prototype.call = function(method, args, fieldMaps) {
        var defer = $.Deferred();

        function mapRecords(records, fieldMaps) {
            var result = [];
            records.forEach(function(record) {
                var e = {};
                _.forEach(fieldMaps, function(map) {
                    e[map.to] = record.get(map.from);
                });
                result[result.length] = e;
            });
            console.log(result);
            return result;
        }

        console.log("---ajax call----");
        console.log(!!args ? JSON.stringify(args) : "no args");

        if (!!args) {
            method(args, function(err, records, event) {
                if (err) {
                    defer.reject(err);
                } else {
                    console.log(records);
                    defer.resolve(mapRecords(records, fieldMaps));
                }
            });
        } else {
            method(function(err, records, event) {
                if (err) {
                    defer.reject(err);
                } else {
                    console.log(records);
                    if (fieldMaps.length === 0) {
                        defer.resolve(records[0]);
                    } else {
                        defer.resolve(mapRecords(records, fieldMaps));
                    }
                }
            });
        }

        return defer;
    };

    function Cache() {
        var cacheStore = [],
            Self = function() {};

        function find(key) {
            return _.findIndex(cacheStore, function(d) {
                return d.key === key;
            });
        }

        Self.prototype.add = function(key, obj) {
            var idx = find(key);
            if (idx !== -1) {
                cacheStore[idx].item = obj;
            } else {
                cacheStore.push({
                    key: key,
                    item: obj
                });
            }
        };

        Self.prototype.get = function(key) {
            var idx = find(key);
            if (idx !== -1) {
                return cacheStore[idx].item;
            } else {
                return undefined;
            }
        };

        Self.prototype.exists = function(key) {
            return find(key) !== -1 ? 1 : 0;
        };

        return new Self();
    }


    function createApplication() {
        var app = new Application();

        app.UI = new UI();
        app.Charts = new ChartLibrary();
        app.Resources = new Resources();
        app.Http = new Http();
        app.LogonUser = new LogonUser();
        app.Async = new Async();
        app.Cache = new Cache();

        return app;
    }

    _application = createApplication();
    _resources = _application.Resources;
    window["ShoppingEvent.crossmark.com"] = window["ShoppingEvent.crossmark.com"] || {};
    window["ShoppingEvent.crossmark.com"].getApplication = function() {
        return _application;
    }

    //bootstrap the application
    $(function() {
        _application.onLoad();
    })
})(jQuery, window);
