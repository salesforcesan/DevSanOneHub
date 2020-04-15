({
  AppSettings: {
    'Events': {
      'CloseDialogEvent': 'closeDialogEvent'
    },
    Routes: {
      'SearchKeyword': 'Locations/search',
      'FilterLocations': 'Locations/filter',
      'AddLocations': 'ProjectLocations/add'
    }
  },

  _dispatch: function(cmp, payload){
    var action = cmp.getEvent('onRemoteRequest');
    action.setParams(payload);
    action.fire();
  },

  init: function(cmp, evt) {
    // this._initdataGrid(cmp);
    this._initdataTable(cmp);
    cmp.set('v.locations', []);
  },

  _initdataTable: function(cmp) {
    var table = cmp.find('dataTable');
    var fields = [{
      'name': 'Location Number',
      'type': 'text',
      'label': 'Location #',
      'id': 'num'
    }, {
      'name': 'Location Name',
      'type': 'text',
      'label': 'Location Name',
      'id': 'name'
    }, {
      'name': 'city',
      'label': 'city',
      'type': 'text',
      'id': 'city'
    }, {
      'name': 'state',
      'id': 'state',
      'label': 'state',
      'type': 'text'
    }, {
      'name': 'Postal Code',
      'type': 'text',
      'label': 'Postal Code',
      'id': 'postal'
    }];
    table.set('v.columns', fields);
  },


  _initdataGrid: function(cmp) {
    var grid = cmp.find('dataGrid');
    var fields = [{
      'name': 'Location Number',
      'type': 'text',
      'label': 'Location #',
      'id': 'num'
    }, {
      'name': 'Location Name',
      'type': 'text',
      'label': 'Location Name',
      'id': 'name'
    }, {
      'name': 'Postal Code',
      'type': 'text',
      'label': 'Postal Code',
      'id': 'postal'
    }];
    grid.set('v.columns', fields);
  },

  searchKeyword: function(cmp, evt) {
    var message, src = cmp.find('inputSearchKeyword'),
      keyword = src.get('v.value') || '',
      projectId = cmp.get('v.projectId');

    if (!this._checkProjectId(cmp, projectId)) {
      return;
    }

    message = {
      'route': this.AppSettings.Routes.SearchKeyword,
      'parameters': {
        'projectId': projectId,
        'keyword': keyword
      }
    };
    this._showSpinner(cmp);
    this._dispatch(cmp, message);
  },

  _checkProjectId: function(cmp, id) {
    if (!id) {
      this._notify(cmp, 'The project identifier is not specified.', 'error');
      return 0;
    }
    return 1;
  },

  applyFilter: function(cmp, evt) {
    var message, keyword = cmp.find('inputSearchKeyword').get('v.value') || '',
      city = cmp.find('inputCity').get('v.value') || '',
      state = cmp.find('inputState').get('v.value') || '',
      postal = cmp.find('inputZipCode').get('v.value') || '',
      type = cmp.find('storeType').get('v.value') || '',
      projectId = cmp.get('v.projectId');

    if (!this._checkProjectId(cmp, projectId)) {
      return;
    }

    if (![keyword, city, state, postal, type].some(function(e) {
        return (e || '').trim().length > 0;
      })) {
      this._notify(cmp, 'Please specify at least one filter before clicking the Filter button.', 'error');
      return;
    }

    message = {
      'route': this.AppSettings.Routes.FilterLocations,
      'parameters': {
        'projectId': projectId,
        'keyword': keyword,
        'city': city,
        'state': state,
        'postal': postal,
        'type': type
      }
    };
    this._showSpinner(cmp);
    this._dispatch(cmp, message);
  },

  addLocations: function(cmp, evt) {
    var selLocations, message, table = cmp.find('dataTable');
    var guidSelector = cmp.find('guidSelector');
    var useGuidFlag = this._isSearchByOneHubId(cmp);
    var useGuid = useGuidFlag ? "1" : "0";

    table.assignSelectedValue();
    var predicate = useGuidFlag ? function(e) {
      return !!e.uid;
    } : function(e) {
      return !!e.num;
    };
    var mapFunc = useGuidFlag ? function(e) {
      return {
        uid: e.uid
      };
    } : function(e) {
      return {
        uid: e.num
      };
    }

    selLocations = table.get('v.value').filter(predicate).map(mapFunc);

    if (selLocations.length === 0) {
      this._notify(cmp, 'There are no selected locations to add.', 'error');
      return;
    }
    message = {
      'route': this.AppSettings.Routes.AddLocations,
      'parameters': {
        'projectId': cmp.get('v.projectId'),
        'useGuid': useGuid,
        'locations': selLocations
      }
    };
    this._showSpinner(cmp);
    this._dispatch(cmp, message);
  },

  _isSearchByOneHubId: function(cmp) {
    return $A.util.getBooleanValue(cmp.get('v.searchByOneHubId'));
  },

  onSuccess: function(cmp, evt) {
    var route = evt.getParam('route');
    switch (route) {
      case this.AppSettings.Routes.AddLocations:
        this._handleAfterAddLocations(cmp, evt);
        break;
      case this.AppSettings.Routes.SearchKeyword:
      case this.AppSettings.Routes.FilterLocations:
        this._setLocations(cmp, evt.getParam('value'));
        this._asyncCall(cmp, this._hideSpinner, 1000);
        break;
      default:
        this._hideSpinner(cmp);
        break;
    }
  },

  dataTableRendered: function(cmp, evt) {
    var self = this,
      msg = cmp.get('v.captureDataTableRendered');

    function notify(cmp) {
      cmp.set('v.captureDataTableRendered', "");
      self._hideSpinner(cmp);
      self._notify(cmp, msg, 'success', true, 1);
    }

    if (!msg) {
      return;
    }

    self._asyncCall(cmp, notify, 1000);
  },

  _handleAfterAddLocations: function(cmp, evt) {
    var self = this,
      response = evt.getParam('value');
    cmp.set('v.captureDataTableRendered', response.message);

    function ok() {
      var remains, locations = cmp.get('v.locations'),
        selItems = cmp.find('dataTable').get('v.value');
      if (locations.length === selItems.length) {
        remains = [];
      } else {
        remains = locations.filter(function(loc) {
          return !selItems.some(function(e) {
            return loc.id === e.id;
          });
        });
      }
      self._setLocations(cmp, remains);
    }
    if (response.state === 'success') {
      this._asyncCall(cmp, ok, 1);
    } else {
      self._hideSpinner(cmp);
      self._notify(cmp, response.message, 'error');
    }
  },

  onError: function(cmp, evt) {
    var id = evt.getParam('id'),
      msg = evt.getParam('error');
    this._hideSpinner(cmp);
    this._notify(cmp, msg, 'error');
  },

  _setLocations: function(cmp, locations) {
    var data = (locations || []).map(function(e) {
      return {
        id: e.id,
        uid: e.uid,
        num: e.num,
        name: e.name,
        city: e.city,
        state: e.state,
        postal: e.postal,
        type: e.type,
        selected: false
      };
    });
    cmp.set('v.locations', data);
  },

  cancel: function(cmp, evt) {
    var event = cmp.getEvent(this.AppSettings.Events.CloseDialogEvent);
    event.fire();
  },

  clearFilter: function(cmp, evt) {
    cmp.find('inputSearchKeyword').set('v.value', '');
    cmp.find('inputCity').set('v.value', '');
    cmp.find('inputState').set('v.value', '');
    cmp.find('inputZipCode').set('v.value', '');
    cmp.find('storeType').set('v.value', '');
    cmp.set('v.locations', []);
  },

  _hideSpinner: function(cmp) {
    cmp.find('searchLocation_busyIndicator').hide();
  },

  _showSpinner: function(cmp) {
    cmp.find('searchLocation_busyIndicator').show();
  },

  _notify: function(cmp, msg, type, autoHide, duration) {
    cmp.find('notification').show(msg, type);
  },

  _asyncCall: function(cmp, callback, duration) {
    if (!callback) {
      return;
    }
    duration = duration || 500;
    var id = window.setTimeout($A.getCallback(function() {
      window.clearTimeout(id);
      if (cmp.isValid()) {
        callback(cmp);
      }
    }), duration);
  },

})