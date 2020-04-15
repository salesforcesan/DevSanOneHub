/*
License: MIT
Author: David Zhao
Date: 11/03/2016
Descri[tion: PDF render is a client side PDF generation engine, based on fabric.js library. The PDF generation workflow is as follows:
1. convert all amCharts and custom canvas elements into PNG file
2. create PDF layout object and add all PNG and related info on it
3. generate PDF document based on the layout
*/
(function(window) {
    'use strict';
    var _fontSize = {
            xsmall: 10,
            small: 11,
            normal: 12,
            large: 14,
            xlarge: 16
        },
        _width = 554;

    function PDF() {
        var _self = {},
            _layout = {
                'content': [],
                pageSize: 'A4',
                pageOrientation: 'portrait',
                pageMargins: [20, 40, 20, 40],
                footer: genFooter
            };

        function initLayout() {
            _layout.content = [];
        }

        function genFooter(page, pages) {
            var color = '#aaaaaa';

            return {
                columns: [{
                    text: 'The information in this Project Summary is not complete until all works have been reported and the project has reached a closed status. Counts on jobs and locations are updated every 15 minutes.',
                    color: color,
                    width: 450,
                    fontSize: _fontSize.xsmall
                }, {
                    alignment: 'right',
                    text: [
                        { text: page.toString(), italics: true, color: color },
                        { text: ' of ', color: color, fontSize: _fontSize.xsmall },
                        { text: pages.toString(), italics: true, color: color, fontSize: _fontSize.xsmall }
                    ]
                }],
                margin: [30, 0]
            };
        }

        function addContent(content) {
            _layout.content.push(content);
        }

        function StackContent() {
            var _r = {},
                _isAddColumn = '0',
                _content = {},
                _stack = [],
                _columns = [];
            _content.alignment = 'justify';

            function cloneWhat(what) {
                var obj = {}
                for (var prop in what) {
                    obj[prop] = what[prop];
                }
                return obj;
            }

            _r.newInstance = function() {
                _stack = [];
                _content = {};
                _columns = [];
                _isAddColumn = '0';
                return _r;
            };

            _r.alignment = function(align) {
                _content.alignment = align;
                return _r;
            }
            _r.width = function(w) {
                _content.width = w;
                return _r;
            };
            _r.height = function(h) {
                _content.height = h;
                return _r;
            };
            _r.margin = function(margin) {
                _content.margin = margin;
                return _r;
            };

            _r.addObject = function(obj) {
                _r['add' + _isAddColumn](obj);
                return _r;
            };

            _r.addText = function(content, opt) {
                var o = cloneWhat(opt);
                o.text = content;
                _r['add' + _isAddColumn](o);
                return _r;
            };

            _r.addImage = function(imgData, opt) {
                var o = cloneWhat(opt);
                o.image = imgData;
                _r['add' + _isAddColumn](o);
                return _r;
            };
            _r.addLine = function(opt) {
                var o = genSectionDivider({
                    left: opt.left,
                    top: opt.top,
                    color: opt.color,
                    width: opt.width
                });

                _r['add' + _isAddColumn](o);
                return _r;
            };

            _r.addGap = function(opt) {
                var o = genSectionDivider({
                    left: opt.left,
                    top: opt.top,
                    width: opt.width,
                    color: OH.colors.white
                });
                _r['add' + _isAddColumn](o);
                return _r;
            };

            _r.add0 = function(obj) {
                _stack.push(obj);
            };

            _r.add1 = function(obj) {
                _columns.push(obj);
            };

            _r.beginColumns = function() {
                _isAddColumn = '1';
                _columns = [];
                return _r;
            };

            _r.endColumns = function() {
                _stack.push({
                    columnGap: 5,
                    columns: _columns
                });
                _columns = [];
                _isAddColumn = '0';
                return _r;
            };
            _r.toContent = function() {
                _content.stack = _stack;
                return _content;
            }

            return _r;
        }

        function genSectionDivider(opt) {
            return {
                canvas: [{
                    type: 'line',
                    x1: opt.left || 0,
                    y1: opt.top || 0,
                    x2: opt.width || 554,
                    y2: opt.top || 0,
                    color: opt.color || OH.color.label,
                    lineWidth: 1
                }]
            };
        }

        function addSectionDivider(marginTop, color) {
            addContent(genSectionDivider({
                top: marginTop,
                color: color
            }));
        }

        _self.createLayout = function() {
            _layout.content = [];
            return _self;
        }

        _self.pngifyCanvasElements = function() {
            var obj;
            for (var domId in OH.charts.instances) {
                obj = OH.charts.instances[domId];
                obj.dataUrl = obj.canvas.toDataURL({
                    format: 'png'
                });
            }
            return _self;
        };

        _self.addPageTitle = function() {
            addContent({
                'text': document.getElementById('pageTitle').innerHTML,
                'fontSize': _fontSize.xlarge,
                'color': OH.colors.azure
            });
            addSectionDivider(4, OH.colors.white);
            addContent({
                'text': document.getElementById('pageSubTitle').innerHTML,
                'fontSize': _fontSize.xsmall,
                'color': OH.colors.label
            });
            addSectionDivider(8, OH.colors.azure);
            return _self;
        };

        _self.addSummary = function() {
            var stack, val, cols = [],
                w = 240,
                h = 120;
            addSectionDivider(20, '#fff');

            //add summary titles
            stack = new StackContent();
            stack.width('49%')
                .margin([100, 0, 0, 0])
                .beginColumns()
                .addImage(OHIMAGES['icon_check_green'], {
                    width: 12,
                    height: 12,
                    alignment: 'right'
                })
                .addText('Execution', {
                    alignment: 'left',
                    width: '*',
                    color: '#4bca81s',
                    fontSize: _fontSize.normal,
                    bold: '700'
                })
                .endColumns();
            cols.push(stack.toContent());

            stack = stack.newInstance();
            stack.width('49%')
                .margin([100, 0, 0, 0])
                .beginColumns()
                .addImage(OHIMAGES['icon_map_orange'], {
                    width: 12,
                    height: 12,
                    alignment: 'right'
                })
                .addText('Locations', {
                    width: '*',
                    alignment: 'left',
                    color: '#ffb75d',
                    bold: '700'
                })
                .endColumns();
            cols.push(stack.toContent());

            addContent({
                'margin': 10,
                'columns': cols,
                'columnGap': 5,
                'alignment': 'center'
            });

            //add textbox
            cols = [];
            cols.push({
                'width': '49%',
                'image': OH.charts.instances['ohExecution'].dataUrl,
                'fit': [w, h]
            });
            cols.push({
                'width': '49%',
                image: OH.charts.instances['ohLocations'].dataUrl,
                fit: [w, h]
            });

            addContent({
                'columns': cols,
                'columnGap': 20,
                'alignment': 'center'
            });
            addSectionDivider(40, '#fff');

            //add account and project detail title
            cols = [];
            stack = stack.newInstance();
            stack.width('49%')
                .margin([100, 0, 0, 0])
                .beginColumns()
                .addImage(OHIMAGES['icon_account_blue'], {
                    width: 12,
                    height: 12,
                    alignment: 'right'
                })
                .addText('Accounts', {
                    width: 'auto',
                    alignment: 'left',
                    color: '#0070d2',
                    bold: '700'
                })
                .endColumns();
            cols.push(stack.toContent());

            stack = stack.newInstance();
            stack.width('49%')
                .margin([100, 0, 0, 0])
                .beginColumns()
                .addImage(OHIMAGES['icon_project_detail'], {
                    width: 12,
                    height: 12,
                    alignment: 'right'
                })
                .addText('Project Detail', {
                    width: 'auto',
                    alignment: 'left',
                    color: '#0070d2',
                    bold: '700'
                })
                .endColumns();
            cols.push(stack.toContent());
            addContent({
                'columns': cols,
                'columnGap': 5,
                'alignment': 'center'
            });

            //add account textbox and project detail
            addSectionDivider(10, '#fff');
            cols = [];
            cols.push({
                'width': '49%',
                'image': OH.charts.instances['ohAccounts'].dataUrl,
                'fit': [w, h]
            });
            stack = stack.newInstance();
            stack.width('49%')
                .addLine({
                    left: 0,
                    top: 0,
                    color: '#0000ff',
                    width: 250
                })
                .addGap({
                    top: 10,
                    width: 200
                })
                .beginColumns();
            val = document.getElementById('ohProjectCycle');
            if (!val.classList.contains('hide')) {

                stack.addImage(OHIMAGES['icon_refresh_blue'], {
                        width: 8,
                        height: 8
                    })
                    .addText(val.innerText, {
                        color: '#54698d',
                        alignment: 'left',
                        fontSize: _fontSize.xsmall
                    });
            }
            val = document.getElementById('ohProgramName');
            if (!val.classList.contains('hide')) {
                stack.addImage(OHIMAGES['icon_target_blue'], {
                        width: 8,
                        height: 8
                    })
                    .addText(val.innerText, {
                        color: '#54698d',
                        alignment: 'left',
                        fontSize: _fontSize.xsmall
                    });
            }

            stack.endColumns()
                .addGap({
                    top: 10,
                    width: 200
                })
                .beginColumns()
                .addImage(OHIMAGES['icon_person_blue'], {
                    width: 8,
                    height: 8
                })
                .addText(document.getElementById('ohProjectOwner').innerText, {
                    color: '#54698d',
                    alignment: 'left',
                    fontSize: _fontSize.xsmall
                });

            var builder = document.getElementById('ohProjectBuilder');
            if (!builder.classList.contains('hide')) {
                stack.addImage(OHIMAGES['icon_person_blue'], {
                    width: 8,
                    height: 8
                }).addText(builder.innerText, {
                    color: '#54698d',
                    alignment: 'left',
                    fontSize: _fontSize.xsmall
                });
            }

            stack.endColumns()
                .addGap({
                    top: 10,
                    width: 200
                })
                .beginColumns()
                .addImage(OHIMAGES['icon_dollar'], {
                    width: 8,
                    height: 8
                })
                .addText(document.getElementById('ohBillableTime').innerText, {
                    color: '#54698d',
                    alignment: 'left',
                    fontSize: _fontSize.xsmall
                })
                .endColumns();
            cols.push(stack.toContent());
            addContent({
                'columns': cols,
                'columnGap': 5,
                'alignment': 'center'
            });
            return _self;
        };

        _self.addDisclaimer = function() {
            addSectionDivider(10, OH.colors.white);
            addContent({
                'text': document.getElementById('ohDisclaimer').innerText,
                'fontSize': _fontSize.small,
                'color': OH.colors.hintText
            });
            addSectionDivider(10, OH.colors.white);
            return _self;
        };

        _self.addProjectTimeline = function() {
            addSectionDivider(10, '#fff');

            addContent({
                stack: [{
                    'image': OH.charts.instances['projectTimeline'].dataUrl,
                    'fit': [542, 100]
                }],
                margin: [0, 0, 0, 0]
            });
            return _self;
        };

        _self.addExecutedLocationsByDay = function() {
            var stack = new StackContent();
            addSectionDivider(30, '#fff');
            addContent(
                stack.margin([180, 0, 0, 0])
                .beginColumns()
                .addImage(OHIMAGES['icon_calendar_green'], {
                    width: 12,
                    height: 14
                })
                .addText('Executed Locations By Day', {
                    width: '*',
                    alignment: 'left',
                    fontSize: _fontSize.large,
                    color: OH.colors.green
                })
                .endColumns()
                .toContent()
            );

            addSectionDivider(8, OH.colors.green);
            //add line chart
            addSectionDivider(15, OH.colors.white);
            addContent({
                image: OH.amCharts['chartExecutedLocationsByDay'].exportedImage,
                "fit": [523, 200]
            });
            return _self;
        };

        _self.addPageBreak = function() {
            addContent({
                canvas: [{
                    type: 'line',
                    x1: 0,
                    y1: 0,
                    x2: 554,
                    y2: 0,
                    color: OH.colors.white,
                    lineWidth: 0.5
                }],
                'pageBreak': 'after'
            });
            return _self;
        };

        _self.addServiceTitle = function(title, subTitle) {
            addContent({
                'text': title,
                'fontSize': _fontSize.large,
                'color': OH.colors.azure
            });
            addContent({
                'text': subTitle,
                'fontSize': _fontSize.xsmall,
                'color': OH.colors.label
            });
            addSectionDivider(4, OH.colors.azure);
            return _self;
        };

        _self.addServiceSummary = function(service) {
            var cols = [],
                stack = new StackContent(),
                w = 12,
                h = 12;
            cols.push(
                stack.width('66%')
                .height(200)
                .addText(document.getElementById('serviceObjectiveLabel_' + service.id).innerHTML || '', {
                    alignment: 'left',
                    color: OH.colors.azure,
                    fontSize: _fontSize.normal
                })
                .addGap({
                    top: 5,
                    width: 200
                })
                .addText(document.getElementById('serviceObjective_' + service.id).innerText || '', {
                    alignment: 'left',
                    color: OH.colors.hintText,
                    fontSize: _fontSize.small
                })
                .toContent()
            );

            stack = stack.newInstance();
            cols.push(
                stack.width('33%')
                .height(200)
                .addGap({
                    top: 5,
                    width: 200
                })
                .beginColumns()
                .addImage(OHIMAGES['icon_cancel_location_blue'], {
                    width: w,
                    height: h
                })
                .addText([service.cancelledLocations || '0', 'Canceled Job(s)'].join(' '), {
                    alignment: 'left',
                    color: OH.colors.label,
                    fontSize: _fontSize.small
                })
                .endColumns()
                .addGap({
                    top: 5,
                    width: 200
                })
                .beginColumns()
                .addImage(OHIMAGES['icon_team_member_blue'], {
                    width: w,
                    height: h
                })
                .addText([service.workers > 1 ? 'Multiple' : 'Single', 'Worker(s)'].join(' '), {
                    alignment: 'left',
                    color: OH.colors.label,
                    fontSize: _fontSize.small
                })
                .endColumns()
                .addGap({
                    top: 5,
                    width: 200
                })
                .beginColumns()
                .addImage(OHIMAGES['icon_clock_blue'], {
                    width: w,
                    height: h
                })
                .addText([service.estimatedMinutes || '0', 'Minutes Estimated'].join(' '), {
                    alignment: 'left',
                    color: OH.colors.label,
                    fontSize: _fontSize.small
                })
                .endColumns()
                .toContent()
            );

            addSectionDivider(10, OH.colors.white);
            addContent({
                'columns': cols,
                'columnGap': 20,
                'alignment': 'justify'
            });

            return _self;
        };

        _self.addServiceSummaryCharts = function(service) {
            var stack,
                cols = [];

            stack = new StackContent();
            stack.width('40%')
                .beginColumns()
                .addImage(OHIMAGES['icon_check_green'], {
                    left: 100,
                    width: 12,
                    height: 12,
                    alignment: 'right'
                })
                .addText('Job Execution', {
                    alignment: 'left',
                    width: '*',
                    color: '#4bca81s',
                    fontSize: _fontSize.normal,
                    bold: '700'
                })
                .endColumns()
                .addGap({
                    top: 10,
                    width: 200
                })
                .addObject({
                    left: 0,
                    image: OH.charts.instances['ohJobExecution_' + service.id].dataUrl,
                    fit: [160, 130]
                })
            cols.push(stack.toContent());

            stack = new StackContent();
            stack.width('60%')
                .beginColumns()
                .addObject({
                    image: OH.amCharts['chartJobCompletion_' + service.id].exportedImage,
                    fit: [160, 160]
                })
                .addObject({
                    image: OH.charts.instances['ohJobCompletionLegend_' + service.id].dataUrl,
                    fit: [160, 300]
                })
                .endColumns();
            cols.push(stack.toContent());

            addContent({
                'margin': 10,
                'columns': cols,
                'columnGap': 5
            });

            return _self;
        };

        _self.addServiceExecutionByDayChart = function(service) {
            var stack = new StackContent();
            addSectionDivider(30, '#fff');
            addContent(
                stack.margin([180, 0, 0, 0])
                .beginColumns()
                .addImage(OHIMAGES['icon_calendar_green'], {
                    width: 12,
                    height: 14
                })
                .addText('Services Executed By Day', {
                    width: '*',
                    alignment: 'left',
                    fontSize: _fontSize.large,
                    color: OH.colors.green
                })
                .endColumns()
                .toContent()
            );

            addSectionDivider(8, OH.colors.green);
            //add line chart
            addSectionDivider(15, OH.colors.white);
            addContent({
                image: OH.amCharts['chartServicesExecutedByDay_' + service.id].exportedImage,
                "fit": [523, 200]
            });
            addSectionDivider(5, OH.colors.white);
            addContent({
                width: '*',
                alignment: 'center',
                text: 'individual service executions are independent of each other.',
                color: '#bbbbbb',
                fontSize: _fontSize.xsmall
            });

            return _self;
        };

        _self.addQuestionSectionTitle = function(service) {
            addSectionDivider(30, OH.colors.white);
            addContent({
                'text': document.getElementById('questions_' + service.id).innerHTML,
                'fontSize': _fontSize.normal,
                'color': OH.colors.azure
            });
            addSectionDivider(4, OH.colors.azure);
            return _self;
        };

        _self.addQuestionResponses = function(service) {
            var arr = [],
                index = 0;

            function getImageString(q) {
                var domId = [q.id, service.id].join('_');
                if (q.type == 'picklist' || q.type == 'yesno') {
                    return OH.amCharts[domId].exportedImage
                } else {
                    return OH.charts.instances[domId].dataUrl
                }
            }

            function getPicklistFit(q) {
                var count = (q.data || []).length;
                if (count == 0) {
                    return [500, 500];
                }
                return [540, 35 * count];
            }

            function getImageFit(q) {
                switch (q.type) {
                    case 'date':
                        return [300, 200];
                    case 'text':
                        return [200, 100];
                    case 'photo':
                        return [200, 100];
                    case 'signature':
                        return [200, 100];
                    case 'picklist':
                        return getPicklistFit(q);
                    case 'yesno':
                        return [400, 400];
                    case 'number':
                        return [300, 200];
                    case 'currency':
                        return [300, 200];
                    case 'time':
                        return [300, 200];
                }
                return [300, 200];
            }

            function drawResponses(q1) {
                var stack = new StackContent(),
                    cols = [];
                index++;
                stack.width('100%')
                    .addText(['Q', index, ' - ', q1.value].join(''), {
                        fontSize: _fontSize.small,
                        color: OH.colors.activeLabel
                    })
                    .addGap({
                        top: 10,
                        width: 200
                    })
                    .addObject({
                        image: getImageString(q1),
                        fit: getImageFit(q1)
                    });
                cols.push(stack.toContent());
                addContent({
                    'margin': 10,
                    'columns': cols,
                    'columnGap': 5
                });
            }

            service.questions.forEach(function(q) {
                drawResponses(q);
            });

            return _self;
        }

        _self.toPDF = function() {

            //add project summary
            _self.createLayout()
                .pngifyCanvasElements()
                .addPageTitle()
                // .addDisclaimer()
                .addProjectTimeline()
                .addSummary()
                .addExecutedLocationsByDay();

            //loop services and add each service
            OHPROJECT.services.forEach(function(service) {
                _self.addPageBreak()
                    .addServiceTitle(service.title, service.name)
                    .addServiceSummary(service)
                    .addServiceSummaryCharts(service)
                    .addServiceExecutionByDayChart(service)
                    .addQuestionSectionTitle(service)
                    .addQuestionResponses(service);
            });

            try {
                var fileName = ['project_summary_report_', window['OHPROJECT'].id || '', '.pdf'].join('');
                pdfMake.createPdf(_layout).download(fileName);
            } catch (e) {
                console.log(e);
            }
            var id = window.setTimeout(function() {
                window.clearTimeout(id);
                showBusyIndicator();
            }, 500);
            /*
                  OH.amCharts['chartExecutedLocationsByDay']["export"].toPDF(_layout, function(data) {
                    this.download(data, 'application/pdf', ['project_summary_report_', OHPROJECT.id, '.pdf'].join(''));
                  });
            */
        };

        function showBusyIndicator() {
            var e = document.getElementById('ohBusyIndicator');
            e.classList.toggle('cmk-hide');
        }

        function pngifyAllAmchartsAsync() {
            var id, prop, cursor = 0,
                propCount, props = [],
                chart;
            showBusyIndicator()
            for (prop in OH.amCharts) {
                props.push(prop);
            }
            propCount = props.length;

            function toPNGs() {
                if (cursor == propCount) {
                    id = setTimeout(function() {
                        _self.toPDF();
                        if (!!id) {
                            clearTimeout(id);
                        }
                    }, 10);
                    return;
                }

                prop = props[cursor];
                cursor++;
                chart = OH.amCharts[prop];
                if (!!chart.exportedImage) {
                    toPNGs();
                    return;
                }
                chart['export'].capture({}, function() {
                    this.toPNG({}, function(data) {
                        this.setup.chart.exportedImage = data;
                        toPNGs();
                    });
                });
            }
            toPNGs();
        }

        return {
            create: function() {
                pngifyAllAmchartsAsync();
            }
        };
    }

    window['OHPDF'] = window['OHPDF'] || new PDF();
})(window);