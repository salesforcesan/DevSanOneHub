({
  AppSettings: {
    'Events': {
      'RemoteActionRequest': 'e.c:ActionRequestAppEvent'
    },
    'Methods': {
      'SearchKeyword': {
        'id': 'searchProjectJobsByKeyword',
        'name': 'searchProjectJobsByKeyword'
      },
      'FilterProjectJobs': {
        'id': 'filterJobs',
        'name': 'filterJobs'
      },
      'GetSettings': {
        'id': 'getSettings',
        'name': 'getSettings'
      },
    }
  },

  init: function(cmp, evt) {

  },

  _publishAppEvent: function(message) {
    var appEvent = $A.get(this.AppSettings.Events.RemoteActionRequest);
    appEvent.setParams(message);
    appEvent.fire();
  },

  _showSpinner: function(cmp, shown) {
    var evt = cmp.getEvent('showSpinnerEvent');
    evt.setParams({
      'context': {
        'show': shown
      }
    });
    evt.fire();
  },

  /* searchKeyword: function(cmp, evt) {
      var keyword = cmp.find('inputSearchKeyword').get('v.value') || '',
        message = {
          id: this.AppSettings.Methods.SearchKeyword.id,
          action: this.AppSettings.Methods.SearchKeyword.name,
          parameters: {
            'query': {
              'projectId': cmp.get('v.projectId'),
              'keyword': keyword
            }
          }
        };
      this._showSpinner(cmp, 1);
      this._publishAppEvent(message);
    },*/

  filterJobs: function(cmp, evt) {
    var query, message;
    try {
      query = this._getFilterQuery(cmp);
    } catch (ex) {
      if (ex instanceof RangeError) {
        $A.util.toggleClass(cmp.find('locationsearchKeywordContainer'), 'slds-has-error');
        $A.util.toggleClass(cmp.find('searchLocationKeywordError'), 'hide');
        return;
      }
      console.log(ex.name + ':' + ex.message);
      return;
    }
    this._cleanUpSearchIfHavingError(cmp);

    var message = {
      id: this.AppSettings.Methods.FilterProjectJobs.id,
      action: this.AppSettings.Methods.FilterProjectJobs.name,
      parameters: {
        'query': query
      }
    };

    this._showSpinner(cmp, 1);
    this._publishAppEvent(message);
    this._hideFilters(cmp);
  },
  _cleanUpSearchIfHavingError: function(cmp) {
    var obj = cmp.find('locationsearchKeywordContainer');
    if ($A.util.hasClass(obj, 'slds-has-error')) {
      $A.util.toggleClass(obj, 'slds-has-error');
      $A.util.toggleClass(cmp.find('searchLocationKeywordError'), 'hide');
    }
  },

  clearFilter: function(cmp, evt) {
    this._resetInput(cmp, [
      'inputlocationSearchKeyword',
      'inputjobSearchKeyword',
      'selService',
      'executionCompany',
      'scheduleDateFrom',
      'scheduleDateTo',
       'Completed'
    ]);
    this._resetCheckbox(cmp, [
      'chkExecuted'

    ]);
    cmp.find('multiJobStatus').set('v.value', '');
    cmp.find('multiexceptionReasons').set('v.value', '');

    var message = {
      id: this.AppSettings.Methods.SearchKeyword.id,
      action: this.AppSettings.Methods.SearchKeyword.name,
      parameters: {
        'query': {
          'projectId': cmp.get('v.projectId'),
          'keyword': ''
        }
      }
    };
    this._publishAppEvent(message);
    this._hideFilters(cmp);
  },

  _getFilterQuery: function(cmp) {
   console.log('Keyword'+ this._getKeywords(cmp));
     console.log('Job Keyword'+ this._getJobKeywords(cmp));
    return {
      'projId': cmp.get('v.projectId'),
      'keyword': this._getKeywords(cmp),
      'jobkeyword': this._getJobKeywords(cmp),
      'selService': this._getValue(cmp, 'selService'),
      'exeCompany': this._getValue(cmp, 'executionCompany'),
      //projjobStatus': this._getValue(cmp, 'jobStatus'),
      'projjobStatus': this._getList(cmp, 'multiJobStatus'),
      'scheduleDateFrom': this._getValue(cmp, 'scheduleDateFrom'),
      'scheduleDateTo': this._getValue(cmp, 'scheduleDateTo'),
      'chkExecuted': this._getChecked(cmp, 'chkExecuted'),
      'Completed': this._getValue(cmp, 'Completed'),
      //expReason': this._getValue(cmp, 'expReason')
      'expReason': this._getList(cmp, 'multiexceptionReasons')

    };
  },

  _getKeywords: function(cmp) {
    var reg, validObj, obj = cmp.find('inputlocationSearchKeyword'),
      val = obj.get('v.value') || '';
      if (!val) {
      return '';
    }
     if (val.indexOf(',') !== -1) {
      val = val.split(',');
    } else {
      reg = new RegExp(/\n|\r\n/g);
      val = val.split(reg);
    }
    reg = new RegExp(/\s/g);
    val = val.join('|').replace(reg, '').split('|');

    return val;
  },

  _getJobKeywords: function(cmp) {
    var reg, validObj, obj = cmp.find('inputjobSearchKeyword'),
      val = obj.get('v.value') || '';
    if (!val) {
      return '';
    }

    if (val.indexOf(',') !== -1) {
      val = val.split(',');
    } else {
      reg = new RegExp(/\n|\r\n/g);
      val = val.split(reg);
    }
    reg = new RegExp(/\s/g);
    val = val.join('|').replace(reg, '').split('|');

    return val;
  },

  _isDigitOnly: function(target) {
    var pattern = /\D/g;
    return target.match(pattern) == null;
  },


  _getList: function(cmp, auraId) {
    return cmp.find(auraId).get('v.value') || null;
  },

  _getValue: function(cmp, auraId) {
    return cmp.find(auraId).get('v.value') || '';
  },

  _getChecked: function(cmp, auraId) {
    return cmp.find(auraId).get('v.checked') ? 1 : 0;
  },

  _resetInput: function(cmp, arrAuraId) {
    arrAuraId.forEach(function(id) {
      cmp.find(id).set('v.value', '');
    });
  },

  _resetCheckbox: function(cmp, arrAuraId) {
    arrAuraId.forEach(function(id) {
      cmp.find(id).set('v.checked', false);
    });
  },
  _resetMultiCheckbox: function(cmp) {

    var appEvent = $A.get("e.c:UnCheckAllCheckboxesEvent");
    appEvent.fire();

  },
    _hideFilters: function(cmp) {
        var hideFilters = cmp.find("toggleFiltersId");
        if ($A.util.hasClass(hideFilters, 'toggleFilters')) {
            $A.util.toggleClass(hideFilters, 'toggleFilters');
        } 
    }
})