/* crossmark Salesforce Design System datagrid implementation */
(function($, window) {
    var _htmlContainer = '<article class="cm-article"><header class="clearfix"><div class="float-left"><h2 class="text-heading--label text-heading--large cm-article-title">{{{title}}}</h2></div><div class="float-right">{{{toolbarHtml}}}{{{searchHtml}}}{{#each navBars}}<button data-id="{{id}}" title="{{text}}" class="button button--icon-border-filled cm-widget-hdr-button"><svg aria-hidden="true" class="button__icon button__icon--small cm-icon"><use xlink:href="{{iconUrl}}"></use></svg><span class="assistive-text">{{text}}</span></button>{{/each}}</div></header><div class="cm-article-body">{{{bodyHtml}}}</div>{{{footer}}}</article>',
        _templateContainer = Handlebars.compile(_htmlContainer),
        _htmlFooter = '<footer class="cm-article-footer {{hide}}"><div class="clearfix"><div class="float-left"><span>Showing {{page}} to {{pageCount}} of {{count}} entries</span></div><div class="float-right"><ul class="cm-pagination"><li><a href="#">&lt;</a></li>{{#each pages}}<li><a href="#">{{page}}</a></li>{{/each}}<li><a href="#">&gt;</a></li></ul></div></div></footer>',
        _templateFooter = Handlebars.compile(_htmlFooter),
        _templateKanbanTableIcon = Handlebars.compile('<svg aria-hidden="true" class="button__icon button__icon--small cm-icon"><use xmlns:xlink="http://www.w3.org/1999/xlink" xlink:href="/assets/icons/utility-sprite/svg/symbols.svg{{iconType}}"></use></svg><span class="assistive-text">{{text}}</span>'),
        _id = 1;

    function getNextId() {
        _id++;
        return "_sys" + _id;
    }

    function genFooter(count, page, pageSize) {
        var pages = [],
            idx = 1,
            len = Math.round(count / pageSize);
        if (count % pageSize !== 0) {
            len++;
        }
        for (var i = 1; i <= len; i++) {
            pages.push({
                page: i
            });
        }

        return _templateFooter({
            page: page,
            pageCount: len,
            pages: pages,
            count: count
        });
    }

    function DataGrid(config) {
        var _self = {},
            _header = "",
            _config = {
                id: config.id || genNextId,
                parentId: config.parentId,
                cols: undefined,
                resourcePath: config.resourcePath
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

        _self.id = function() {
            return _config.id;
        };

        function resolveOperation(result, labels) {
            var rule;
            if (!labels || labels.length === 0) {
                return result;
            }
            for (var i = 0; i < labels.length; i++) {
                if (!!labels[i].rule) {
                    rule = labels[i].rule;
                    if (!!rule.eq) {
                        if (rule.eq === result.value) {
                            result.css = labels[i].css,
                                result.text = labels[i].text || result.text;
                            break;
                        }
                    } else if (!!rule.contain) {
                        result.value = result.value + "";
                        if (result.value.indexOf(rule.contain + "") !== -1) {
                            result.css = labels[i].css;
                            result.text = labels[i].text || result.text;
                            break;
                        }
                    } else if (!!rule.gt) {
                        if (result.value > rule.gt) {
                            result.css = labels[i].css;
                            result.text = labels[i].text || result.text;
                            break;
                        }
                    } else if (!!rule.lt) {
                        if (result.value < rule.lt) {
                            result.css = labels[i].css;
                            result.text = labels[i].text || result.text;
                            break;
                        }
                    } else if (!!rule.between || rule.between.length === 2) {
                        if (result.value >= rule.between[0] && result.value <= rule.between[1]) {
                            result.css = labels[i].css;
                            result.text = labels[i].text || result.text;
                            break;
                        }
                    } else if (!!rule.in || rule.in.length > 0) {
                        if (rule.in.indexOf(result.value) !== -1) {
                            result.css = labels[i].css;
                            result.text = labels[i].text || result.text;
                            break;
                        }
                    }
                }
            }
            return result;
        }

        function resolveLabel(col) {
            var result = {
                value: col.value || "",
                text: col.value || "",
                css: ""
            };

            if (!!col.value) {
                switch (col.dataType) {
                    case "number":
                        result.value = parseInt(col.value || 0);
                        result.text = result.value;
                        break;
                    case "date":
                        result.value = Date.parse(col.value);
                        result.text = new Date(col.value);
                        break;
                    case "datetime":
                        result.value = Date.parse(col.value);
                        result.text = new Date(col.value).toISOString();
                        break;
                }
            }
            return resolveOperation(result, col.labels);
        }

        function genTableCell(col) {
            var label, html = ['<td class="truncate" data-label="', col.title, '">'];

            switch (col.uiType) {
                case "text":
                    html.push(["<span>", col.value, "</span>"].join(""));
                    break;
                case "link":
                    html.push(['<a href="#">', col.value, '</a>'].join(""));
                    break;
                case "label":
                    label = resolveLabel(col);
                    html.push(['<span class="label ', label.css, '">', label.text, '</span>'].join(""));
                    break;
                case "icon":
                    html.push(['<svg aria-hidden="true" class="button__icon button__icon--small cm-icon"><use xlink:href="', _config.resourcePath, col.icon, '"></use></svg>'].join(""));
                    break;
                default:
                    html.push(["<span>", col.value, "</span>"].join(""));
                    break;
            }
            html.push("</td>");
            return html.join("");
        }

        function genHeaderHtml() {
            var html = '<thead><tr>{{#each headers}}<th data-id="{{id}}" data-type="{{dataType}}" class="is-interactive{{selected}}{{locked}}"><span class="truncate">{{title}}</span><button class="button button--icon-bare button--icon-border-small"><svg aria-hidden="true" class="button__icon button__icon--small"><use xlink:href="' + _config.resourcePath + '/assets/icons/utility-sprite/svg/symbols.svg#arrowdown"></use></svg><span class="assistive-text">Sort</span></button></th>{{/each}}</tr></thead>',
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

        function toggleSortIcon(source) {
            var svg = source.find("svg");
            $("#" + _config.parentId + " thead > tr > th").removeClass("cm-is-selected");
            source.parent("th").addClass("cm-is-selected");
            if (svg.html().indexOf("#arrowdown") !== -1) {
                svg.html(svg.html().replace("#arrowdown", "#arrowup"));
                return 1;
            } else {
                svg.html(svg.html().replace("#arrowup", "#arrowdown"));
                return 0;
            }
        }

        function sortTable(source) {
            var selColIndex, rows = [],
                tbodySelector,
                html = [],
                selCol, isASC = 1;

            isASC = toggleSortIcon(source);
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

        function searchTable(keyword) {
            var vals, domId = "#" + _config.parentId;
            if (!!keyword) {
                keyword = keyword.toLowerCase();
            }

            $(domId).find("tbody > tr").each(function() {
                vals = [];
                $(this).find("td > a").each(function() {
                    vals.push($(this).text());
                })
                $(this).find("td > span").each(function() {
                    vals.push($(this).text());
                })

                if (_.findIndex(vals, function(v) {
                        return v && v.toLowerCase().indexOf(keyword) !== -1;
                    }) == -1) {
                    $(this).hide();
                } else {
                    $(this).show();
                }
            });
        }

        _self.search = function(keyword) {
            searchTable(keyword);
        };

        _self.renderCard = function(source, template) {
            var i, html = ['<div class="cm-card-container">'],
                count = _config.cols.length,
                row = {},
                cardTemplate,
                col, domId = "#" + _config.parentId;

            if ($(domId).find("table").hasClass("hide")) {
                $(domId).find("table").removeClass('hide');
                $(domId).find(".cm-card-container").addClass('hide');
                source.html(_templateKanbanTableIcon({
                    iconType: "#kanban",
                    text: "View Card"
                })).attr("title", "View Card");
                return;
            }
            source.html(_templateKanbanTableIcon({
                iconType: "#table",
                text: "View Table"
            })).attr("title", "View Table");
            cardTemplate = Handlebars.compile(template),
                $(domId).find("tbody > tr").each(function() {
                    if (!$(this).is(":hidden")) {
                        for (i = 0; i < count; i++) {
                            col = _config.cols[i];
                            switch (col.uiType) {
                                case "text":
                                    row[col.id] = $(this).find(["td:eq(", i, ")"].join("")).html();
                                    break;
                                case "link":
                                    row[col.id] = $(this).find(["td:eq(", i, ")"].join("")).html();
                                    break;
                                case "label":
                                    row[col.id] = $(this).find(["td:eq(", i, ")"].join("")).html();
                                    break;
                                case "icon":
                                    row[col.id] = $(this).find("td").eq(i).html();
                                    break;
                                default:
                                    row[col.id] = $(this).find("td").eq(i).html();
                                    break;
                            }
                        }
                        row["id"] = $(this).attr("data-id");
                        html.push(cardTemplate(row));
                    }
                });
            html.push("</div>");
            $(domId).find("table").addClass("hide");
            $(domId).find(".cm-article-body").append(html.join(""));
        };

        _self.init = function(options) {
            $("#" + _config.parentId).on("click", "thead > tr > th button", function(e) {
                e.preventDefault();
                if (options.sortOnServer) {
                    var isASC = $(this).html().indexOf("arrowdown") !== -1 ? 1 : 0;
                    options.sortEvent($(this).parent("th").attr("data-id"), isASC);
                    toggleSortIcon($(this));
                } else {
                    sortTable($(this));
                }
            }).on("click", "tbody > tr > td > a", function(e) {
                e.preventDefault();
                options.cellSelectEvent($(this).parents("tr").attr("data-id"));
            }).on("click", ".cm-article-body .cm-card a", function(e) {
                e.preventDefault();
                options.cellSelectEvent($(this).parents(".cm-card").attr("data-id"));
            });


        };

        _self.html = function(context) {
            setCurrentData(context);
            return renderTable();
        };

        return _self;

    }

    function initFooter() {
        
    }

    $.widget("crossmark.datagrid", {
        //default options
        options: {
            title: "List",
            sortOnServer: 1,
            hasContainer: 1,
            hasFooter: 1,
            canExpand: 1,
            showCheckBox: 0,
            showRowEdit: 0,
            showRowDelete: 0,
            canPage: 1,
            pageSize: 10,
            canInfiniteScroll: 0,
            canViewCard: 1,
            cardTemplate: "",
            canSearch: 1,
            resourcePath: "",
            columns: [],
            dataSet: [],
            navBars: [],
            height: 400,
            sortEvent: function(sortBy, isASC) {
                console.log("sortBy:" + sortBy + " isAsc: " + isASC);
            },
            pageEvent: function(pageNumber) {
                console.log("select page: " + pageNumber);
            },
            cellSelectEvent: function(id) {
                console.log("select object id: " + id);
            },
            navBarClickEvent: function(source) {
                console.log(source);
            }
        },
        _create: function() {
            // this.element: the container jquery object
            var _self = this.element,
                _that = this,
                _options = this.options,
                _searchHtml = "",
                _footerHtml = "",
                _dataGrid = new DataGrid({
                    id: getNextId(),
                    parentId: _self.attr("id"),
                    resourcePath: _options.resourcePath,
                    cols: _.map(_options.columns, function(e) {
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
                    })
                });


            if (_options.canViewCard) {
                _options.navBars.push({
                    id: getNextId() + "_kanban",
                    iconUrl: this.options.resourcePath + "/assets/icons/utility-sprite/svg/symbols.svg#kanban",
                    text: "View Card",
                    callback: function(source) {
                        _dataGrid.renderCard(source, _options.cardTemplate);
                    }
                });
            }

            if (_options.canExpand) {
                _options.navBars.push({
                    id: getNextId() + "_expand",
                    iconUrl: this.options.resourcePath + "/assets/icons/utility-sprite/svg/symbols.svg#expand",
                    text: "Expand",
                    callback: function(source) {
                        zoomIn(source);
                    }
                });
            }

            if (_options.canSearch) {
                _searchHtml = '<input type="text" class="cm-widget-search" placeholder="Search"/>';
            }

            if (_options.hasFooter) {
                _footerHtml = genFooter(_options.dataSet.length, 1, _options.pageSize);
            }

            if (_options.hasContainer === 1) {
                _self.html(_templateContainer({
                    title: _options.title,
                    navBars: _options.navBars,
                    searchHtml: _searchHtml,
                    footer: _footerHtml,
                    bodyHtml: _dataGrid.html({
                        data: _options.dataSet
                    })
                }));
                _self.find(".cm-article-body").slimScroll({
                    position: "right",
                    height: _options.height + "px",
                    color: "#888",
                    alwaysVisible: true
                }).bind('slimscroll', function(e, pos) {
                    if (pos === "bottom") {
                        console.log("need to load more data");
                    }
                });

                //hook up event
                if (_options.canSearch) {
                    _self.on("keyup", "header input.cm-widget-search", function(e) {
                        _dataGrid.search($(this).val());
                    })
                }
                _self.on("click", "header button", function(e) {
                    var btnId = $(this).attr("data-id");
                    if (btnId.indexOf("_kanban") !== -1) {
                        e.preventDefault();
                        _dataGrid.renderCard($(this), _options.cardTemplate);
                        return;
                    }
                    if (btnId.indexOf("_expand") !== -1) {
                        e.preventDefault();
                        _that._resize(_that, _dataGrid);
                    } else {
                        _options.navBarClickEvent(btnId);
                    }
                });
            } else {
                _self.html(_dataGrid.html({
                    data: _options.dataSet
                }));
            }

            _dataGrid.init(_options);
            if (_options.hasFooter) {

            }
        },
        _resize: function(who, dataGrid) {
            var isFullScreen = $("body").hasClass("cm-body-full-screen"),
                height = who.options.height;
            who.element.toggleClass('cm-widget-full-screen');
            $("body").toggleClass('cm-body-full-screen');

            if (!isFullScreen) {
                height = $(window).height() - 150;
            }
            who.element.find(".cm-article-body").height(height);
            who.element.find(".cm-article-body").parent("div").height(height);
        }
    });

})(jQuery, window);
