({
    AppSettings: {
        'Events': {
            'ActionRequestAppEvent': 'e.c:ActionRequestAppEvent',
            'CloseDialogEvent': 'closeDialogEvent'
        },
        Routes: {
            'AddLocations': 'ProjectLocations/add/pasteList'
        }
    },
    
    onInit: function(cmp, evt) {
        var cols = [{
            label: cmp.get('v.searchByOneHubId') ? 'Unique Id' : 'Pasted Location #',
            id: 'uid',
            type: 'text',
            width: '300px'
        }];
            
        cmp.set("v.useGuid", cmp.get('v.searchByOneHubId') ? "1" : "0");  

        if ($A.util.getBooleanValue(cmp.get('v.showSchedule'))) {
            cols.push({
                'label': 'Schedule Date',
                'id': 'schedule',
                'type': 'text'
            });
        }
        cols = cols.concat([{
            label: 'Location #',
            id: 'num',
            type: 'text'
        }, {
            label: 'Location Name',
            id: 'name',
            type: 'text'
        }, {
            label: 'Status',
            id: 'status',
            type: 'text'
        }]);
        cmp.find('dataTable').set('v.columns', cols);
    },
    
    _dispatch: function(cmp, payload){
        var action = cmp.getEvent('onRemoteRequest');
        action.setParams(payload);
        action.fire();
    },
    
    add: function(cmp, evt) {
        var pasteList = cmp.get('v.pasteList');
        var reg, locations, message, self = this,
            showSchedule = $A.util.getBooleanValue(cmp.get('v.showSchedule')),
            list = cmp.find('locationList').get('v.value') || '';
        var guidSelector = cmp.find("guidSelector");
        var useGuid = guidSelector.get("v.value");

        if (!list) {
            this._notify(cmp, 'Please type in the list of OneHub Location Identifiers.', 'error');
            return;
        }
        cmp.find('busyIndicator').show();
        
        reg = new RegExp(/\n|\r|\r\n/g);
        locations = list.split(reg);
        
        locations = locations.filter(function(e) {
            return (e || '').length > 0;
        }).map(function(loc) {
            var cols = loc.split(',');
            if (cols.length > 1 && showSchedule) {
                return {
                    'uid': cols[0].toUpperCase(),
                    'schedule': cols[1]
                };
            }
            return {
                'uid': cols[0].toUpperCase()
            };
        });
        cmp.set('v.rowCount', locations.length);
        cmp.find('dataTable').set('v.data',
                                  locations.map(function(loc) {
                                      return {
                                          'uid': loc.uid,
                                          'schedule': loc.schedule,
                                          'num': '',
                                          'name': '',
                                          'status': self._genStatusHtml('info', 'processing...')
                                      };
                                  })
                                 );
        cmp.set('v.pasteList', !pasteList);
        
        function doPublish(cmp) {
             message = {
                'route': self.AppSettings.Routes.AddLocations,
                'parameters': {
                    'projectId': cmp.get('v.projectId'),
                    'useGuid': useGuid,
                    'locations': locations
                }
            };
            self._dispatch(cmp, message);
        }
        self._asyncCall(cmp, doPublish, 200);
    },
    
    _isDigitOnly: function(target) {
        var pattern = /\D/g;
        return target.match(pattern) == null;
    },
    
    cancel: function(cmp, evt) {
        var event = cmp.getEvent(this.AppSettings.Events.CloseDialogEvent);
        event.fire();
    },
    
    onSuccess: function(cmp, evt) {
        var result;
        if (this._isInterested(evt)) {
            result = evt.getParam('value');
            this._renderResult(cmp, result.data || []);
            this._notify(cmp, result.message, result.state);
            cmp.find('busyIndicator').hide();
        }
    },
    
    _renderResult: function(cmp, result) {
        var self = this,
            items, r,
            data = cmp.find('dataTable').get('v.data'),
            color = '',
            predicate = this._isSearchByOneHubId(cmp) ? function(a, b) {
                return a.uid.toUpperCase() === b.uid.toUpperCase();
            } : function(a, b) {
                return a.uid === b.num;
            };
        
        data.forEach(function(d) {
            items = result.filter(function(f) {
                return predicate(d, f);
            });
            if (items.length > 0) {
                r = items[0];
                switch (r.status) {
                    case 'added':
                        color = 'success';
                        break;
                    case 'invalid':
                        color = 'error';
                        break;
                    case 'inactive':
                        color = 'error';
                        break;
                    case 'not found':
                        color = 'warning';
                        break;
                    case 'duplicated':
                        color = 'warning';
                        break;
                    default:
                        color = 'info';
                        break;
                }
                d.status = self._genStatusHtml(color, r.status);
                d.num = r.num;
                d.name = r.name;
            } else {
                d.status = self._genStatusHtml('error', 'invalid');
            }
        });
        cmp.find('dataTable').set('v.data', data);
    },
    
    _genStatusHtml: function(msgType, status) {
        return ['<span class="slds-badge slds-theme--', msgType, ' oh-badge">', status, '</span>'].join('');
    },
    
    _isInterested: function(evt) {
        return evt.getParam('route') === this.AppSettings.Routes.AddLocations ? 1 : 0;
    },
    
    onError: function(cmp, evt) {
        if (!this._isInterested(evt)) {
            return;
        }
        
        var self = this;
        var locations = cmp.find('dataTable').get('v.data');
        locations.forEach(function(loc) {
            loc.status = self._genStatusHtml('error', 'failed');
        });
        cmp.find('dataTable').set('v.data', locations);
        this._notify(cmp, evt.getParam('error'), 'error');
        cmp.find('busyIndicator').hide();
    },
    
    _notify: function(cmp, msg, type) {
        cmp.find('notification').show(msg, type);
    },
    
    _asyncCall: function(cmp, callback, duration) {
        if (!callback) {
            return;
        }
        duration = duration || 200;
        var id = window.setTimeout($A.getCallback(function() {
            window.clearTimeout(id);
            if (cmp.isValid()) {
                callback(cmp);
            }
        }), duration);
    },
    
    _isSearchByOneHubId: function(cmp) {
        return $A.util.getBooleanValue(cmp.get('v.searchByOneHubId'));
    },
    _downloadCSV: function(csv, filename) {
        var csvFile;
        var exportLink;
        
        csvFile = new Blob([csv], {type: "text/csv"});  
        exportLink = document.createElement("a");
    	exportLink.setAttribute('download', filename);
        exportLink.download = filename;
        exportLink.href = window.URL.createObjectURL(csvFile);
        exportLink.style.display = "none";
        document.body.appendChild(exportLink);
        exportLink.click();
        document.body.removeChild(exportLink);
    
    },
    export: function(cmp, evt, helper) {
        var projectId = cmp.get('v.projectId');
        var filename = "pasted-locations-download" + "_" + "Project-" + projectId;
        var csv = [];
        var rows = document.querySelectorAll(".table .tr");
        console.log(rows, "rows with querySelect")
        for (var i = 0; i < rows.length; i++) {
            var row = [], cols = rows[i].querySelectorAll(".td, .th");
            for (var j = 0; j < cols.length; j++) 
                row.push(cols[j].innerText);//cols[j].innerText
            	csv.push(row.join(","));  
 				console.log(csv,"combined csv")
        }

        for (var i = 0; i < csv.length; i++) {
            csv[i] = csv[i].replace(/(\r\n|\n|\r)/gm,"");
        }
   
        this._downloadCSV(csv.join("\n"), filename);
    },
    goBack: function(cmp, evt, helper) {
        var pasteList = cmp.get('v.pasteList');
        cmp.set('v.pasteList', !pasteList);
    }

})