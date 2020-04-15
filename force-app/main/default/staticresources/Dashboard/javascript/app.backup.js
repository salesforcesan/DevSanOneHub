(function($, window) {
    var _nextId = 0;

    if (typeof Object.create !== 'function') {
        Object.create = function(o) {
            var F = function() {};
            F.prototype = o;
            return new F();
        };
    }

    function genNextId() {
        _nextId++;
        return "ctrl" + _nextId;
    }

    function Application() {
        var _router = new Router(),
            _ctls = [],
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

            this.addRoute = function(url, controllerName, actionName) {
                _rules.push({
                    url: url,
                    controller: controllerName,
                    action: actionName
                });
                return this;
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

        function hookUpEvents() {
            _.forEach(_ctls, function(c) {
                c.view.registerEvents();
            });
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

            createController: function(name) {
                return new ControllerBase(name);
            },
            createView: function() {
                return new ViewBase();
            },
            createHttpService: function() {
                return new HttpService();
            },
            registerEvents: hookUpEvents
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
    var ICON_SELECTED_HTML = '<svg aria-hidden="true" class="icon icon--small icon--left"><use xmlns:xlink="http://www.w3.org/1999/xlink" xlink:href="/assets/icons/standard-sprite/svg/symbols.svg#task2"></use></svg>';

    UI.prototype.htmlSelect = function(containerId, cssClass, cssOptions, enableSelect) {
        var _containerId = containerId,
            _cssClass = cssClass,
            _selectEnabled = (!!enableSelect) ? 1 : 0,
            _cssOptions = (!!cssOptions) ? " " + cssOptions + " " : " ",
            _self = Object.create(new HtmlElement()),
            _html = '<span tabindex="0" class="picklist__label {{class}} truncate" aria-haspopup="true">{{selOption}}<svg aria-hidden="true" class="icon"><use xlink:href="/assets/icons/utility-sprite/svg/symbols.svg#down"></use></svg></span><ul class="picklist__options cm-picklist-options{{cssOptionsClass}}hide">{{#each options}} {{#if selected }}<li data-id="{{key}}" class="picklist__options-item is-selected" aria-selected="true" tabindex="-1" role="option"><svg aria-hidden="true" class="icon icon--small icon--left"><use xmlns:xlink="http://www.w3.org/1999/xlink" xlink:href="/assets/icons/standard-sprite/svg/symbols.svg#task2"></use></svg><span>{{value}}</span></li>{{else}}<li data-id="{{key}}" class="picklist__options-item" aria-selected="false" tabindex="-1" role="option"><span>{{value}}</span></li>{{/if}}{{/each}}</ul>',
            _template = Handlebars.compile(_html);


        _self.init = function(selCallback) {
            $("#" + containerId).on("click", ".picklist__label", function(e) {
                e.preventDefault();
                $(this).parent(".picklist").find(".picklist__options").toggle();
            }).on("click", ".picklist__options > li", function(e) {
                e.preventDefault();
                var target = $(this);
                var options = target.parent(".picklist__options");
                if (_selectEnabled) {
                    target.prevAll().removeClass('is-selected').attr("aria-selected", "false").find("svg.icon").remove();
                    target.nextAll().removeClass('is-selected').attr("aria-selected", "false").find("svg.icon").remove();
                    target.addClass('is-selected');
                    target.append(ICON_SELECTED_HTML);
                    target.attr("aria-selected", "true");
                    var html = target.find("span").html() +
                        '<svg aria-hidden="true" class="icon"><use xlink:href="/assets/icons/utility-sprite/svg/symbols.svg#down"></use></svg>';
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
            var options = _.map(context.options, function(e) {
                return {
                    "key": e.key,
                    "value": e.value,
                    "selected": e.value === context.selValue ? 1 : 0
                };
            });
            $("#" + _containerId).empty().html(_template({
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
            _selectEnabled = enableSelect,
            _html = '{{#if hasTitle}}<div class="dropdown__header"><span class="text-heading--label">{{title}}</span></div>{{/if}}<ul class="dropdown__list" role="menu">{{#each menuItems}} {{#if disabled}}<li data-id="{{key}}" disabled="" href="#rename" class="dropdown__item has-icon--left" role="menuitem option" tabindex="0"><a href="#{{key}}" tabindex="-1" aria-disabled="true">{{#if hasLeftIcon}}<svg aria-hidden="true" class="icon icon--small icon--left"><use xmlns:xlink="http://www.w3.org/1999/xlink" xlink:href="{{leftIconUrl}}"></use></svg>{{/if}}<span>{{value}}</span>{{#if hasRightIcon}}<svg aria-hidden="true" class="icon icon--small icon--right"><use xmlns:xlink="http://www.w3.org/1999/xlink" xlink:href="{{rightIconUrl}}"></use></svg>{{/if}}</a></li>{{else}}<li data-id="{{key}}" href="#rename" class="dropdown__item has-icon--left" role="menuitem option" tabindex="0"><a href="#{{key}}" tabindex="-1" aria-disabled="false">{{#if hasLeftIcon}}<svg aria-hidden="true" class="icon icon--small icon--left"><use xmlns:xlink="http://www.w3.org/1999/xlink" xlink:href="{{leftIconUrl}}"></use></svg>{{/if}}<span>{{value}}</span>{{#if hasRightIcon}}<svg aria-hidden="true" class="icon icon--small icon--right"><use xmlns:xlink="http://www.w3.org/1999/xlink" xlink:href="{{rightIconUrl}}"></use></svg>{{/if}}</a></li>{{/if}} {{/each}}</ul>',
            _template = Handlebars.compile(_html);

        _self.render = function(context) {
            var items = _.map(context.menuItems || [], function(e) {
                return {
                    "key": e.key,
                    "value": e.value,
                    "disabled": e.disabled,
                    "hasLeftIcon": (!!e.leftIconUrl) ? 1 : 0,
                    "leftIconUrl": e.leftIconUrl,
                    "hasRightIcon": (!!e.rightIconUrl) ? 1 : 0,
                    "rightIconUrl": e.rightIconUrl
                };
            });
            $("#" + containerId).empty().html(_template({
                hasTitle: (!!context.title) ? 1 : 0,
                title: context.title || "",
                menuItems: items
            }));
        };

        _self.init = function(selectCallback) {
            $("#" + containerId).on("click", "ul.dropdown__list > li > a", function(e) {
                e.preventDefault();
                if (_selectEnabled) {
                    var li = $(this).parent("li");
                    li.prevAll().removeClass('is-selected').find("a svg.icon--left").remove();
                    li.nextAll().removeClass('is-selected').find("svg.icon--left").remove();
                    li.addClass('is-selected');
                    $(this).prepend(ICON_SELECTED_HTML);
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
                bodyControl: config.bodyControl || htmlElement
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
                id1 = undefined,
                colContainer = source.parents(id),
                selId = colContainer.attr("id"),
                selRow = $("div#pageBody .cm-row").has('div[id="' + selId + '"]');

            selRow.prevAll("div.cm-row").toggle();
            selRow.nextAll("div.cm-row").toggle();
            selRow.find("div.col").toggleClass('cm-hide');
            source.parents("div.col").toggleClass('cm-hide');
            colContainer.toggleClass('cm-col-right-0');
            _chart.update();
            colContainer.toggleClass('cm-zoomin');
        }

        function close(source) {
            var col = source.parents("div.col"),
                row = source.parents("div.cm-row"),
                container = source.parents("div.cm-col-container"),
                closedCols = 0,
                count = 0;

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
            console.log(count + "=" + closedCols);
            if (closedCols === count) {
                row.toggleClass('cm-close');
            }
        }

        if (config.canExpand) {
            _id++;
            _config.navBars.push({
                id: "_sys" + _id,
                iconUrl: "/assets/icons/utility-sprite/svg/symbols.svg#expand",
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
                iconUrl: "/assets/icons/utility-sprite/svg/symbols.svg#close",
                text: "Close",
                callback: function(source) {
                    close(source);
                }
            });
        }

        _self.init = function(callback) {
            //_config.bodyControl.init();
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

        _self.setChart = function (chart) {
            _chart = chart;
            console.log(chart);
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
            onRendered = context.onRendered || function () {},
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
    cell: {
        title: "",
        value: "",
        uiType: "link" | "label" | "icon" | "text",
        labels: [{key: "ok", text: "Succeeded", css: "label-success"}]
    } 
    */
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
                html.push(['<svg aria-hidden="true" class="button__icon button__icon--small cm-icon"><use xlink:href="', col.icon, '"></use></svg>'].join(""));
                break;
            default:
                html.push(["<span>", col.value, "</span>"].join(""));
                break;
        }
        html.push("</td>");
        return html.join("");
    }

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
    UI.prototype.dataGrid = function(config) {
        var _self = Object.create(new HtmlElement()),
            _header = "",
            _config = {
                id: config.id || genNextId,
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

        function genHeaderHtml() {
            var html = '<thead><tr>{{#each headers}}<th data-id="{{id}}" data-type="{{dataType}}" class="is-interactive{{selected}}{{locked}}"><span class="truncate">{{title}}</span><button class="button button--icon-bare button--icon-border-small"><svg aria-hidden="true" class="button__icon button__icon--small"><use xlink:href="/assets/icons/utility-sprite/svg/symbols.svg#arrowdown"></use></svg><span class="assistive-text">Sort</span></button></th>{{/each}}</tr></thead>',
                template = Handlebars.compile(html),
                cols = _.map(_config.cols, function(e) {
                    return {
                        id: e.id,
                        dataType: e.dataType,
                        selected: (e.canSort && e.sorted) ? " is-selected" : "",
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
                html.push(['<tr class=""hint-parent">']);
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

        _self.init = function(callback) {
            console.log("datagrid render");
        };

        _self.html = function(context) {
            setCurrentData(context);
            return renderTable();
        };

        return _self;
    };

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

    var ChartLibrary = function() {};
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


    function createApplication() {
        var app = new Application();
        app.UI = new UI();
        app.Charts = new ChartLibrary();
        return app;
    }

    window["ShoppingEvent.crossmark.com"] = window["ShoppingEvent.crossmark.com"] || createApplication();
})(jQuery, window);
