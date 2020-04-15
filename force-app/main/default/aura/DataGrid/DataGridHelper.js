({
  DataGridEvents: {
    'ButtonClick': 'dataGridButtonCellClick',
    'LinkClick': 'dataGridLinkCellClick',
    'DataGridRendered': 'dataGridRendered',
    'DataGridSelectRowChanged': 'dataGridSelectRowChanged'
  },

  onInit: function(cmp, evt) {
    var border = $A.util.getBooleanValue(cmp.get('v.hasBorder')) ? 'border:1px solid rgb(216, 221, 230);' : 'border:0;',
      height = ['height:', cmp.get('v.height') || 'auto', ';'].join('');
    cmp.set('v.style', [border, height, 'border-radius:4px;'].join(''));
  },

  afterRender: function(cmp) {
    this._canSpin(cmp) && this._showSpinner(cmp);
    this._async(cmp, this._initColumns);
  },

  _initColumns: function(cmp) {
    var fields = cmp.get('v.fields') || [];
    if (fields.length > 0) {
      return;
    }

    function transformColumns() {
      var i = 0,
        id = cmp.get('v.id'),
        cols = cmp.get('v.columns')
        .map(function(f) {
          var obj = {};
          Object.keys(f).forEach(function(nm) {
            obj[nm] = f[nm] || '';
          });

          obj['__extend'] = {
            'header': (obj['type'] === 'button') ? '' : obj['label'],
            'sorted': false,
            'canSort': obj['type'] !== 'button',
            'id': [id, ++i].join('_'),
            'style': !!obj['width'] ? ['width', obj['width']].join(':') : '',
          };

          return obj;
        });

      if ($A.util.getBooleanValue(cmp.get('v.showCheckbox'))) {
        var hide = ($A.util.getBooleanValue(cmp.get('v.hideCheckboxOnHeader'))) ? ' hide' : '';
        cols.unshift({
          'name': 'Select Row',
          'label': '',
          'id': 'selectRow',
          'type': 'checkbox',
          'class': hide,
          '__extend': {
            'header': '',
            'canSort': false,
            'id': id + '_selectRow',
            'style': 'width:3.25rem;'
          }
        });
      }
      return cols;
    }
    cmp.set('v.fields', transformColumns(cmp));
  },

  onCellButtonClick: function(cmp, evt) {
    this._raiseEvent(cmp, this.DataGridEvents.ButtonClick, this._transformEventContext(evt));
  },

  onCellLinkClick: function(cmp, evt) {
    this._raiseEvent(cmp, this.DataGridEvents.LinkClick, this._transformEventContext(evt));
  },

  onCellCheckboxClick: function(cmp, evt) {
    var cell = evt.getParam('context'),
      records = cmp.get('v.dataStore');
    records.filter(function(r) {
      return r.__id === cell.__parent.__id;
    }).forEach(function(r) {
      r.__selected = cell.__selected;
    });
    cmp.set('v.isSelectAll', false);
    cmp.set('v.dataStore', records);
    this._raiseEvent(cmp, this.DataGridEvents.DataGridSelectRowChanged, null);
  },

  onSort: function(cmp, evt) {
    var self = this,
      id = evt.currentTarget.getAttribute('data-id') || '',
      cols = cmp.get('v.fields');

    function predicate(col) {
      return col.__extend.id === id;
    }

    function doSort() {
      var selCol = cols.filter(predicate)[0],
        store = cmp.get('v.dataStore'),
        algrithm = (selCol.__extend.sorted) ? function(rec1, rec2) {
          return rec1[selCol.id] > rec2[selCol.id] ? -1 : 1;
        } : function(rec1, rec2) {
          return rec1[selCol.id] > rec2[selCol.id] ? 1 : -1;
        };

      cols.forEach(function(col) {
        if (col.__extend.id == id) {
          col.__extend.sorted = !col.__extend.sorted;
        } else {
          col.__extend.sorted = false;
        }
      });

      store.sort(algrithm);
      cmp.set('v.fields', cols);
      cmp.set('v.dataStore', store);
      if (cmp.get('v.enablePagination')) {
        cmp.find('pager').gotoFirstPage();
      } else {
        self._rerenderPage(cmp, 1, self);
        self._hideSpinner(cmp);
      }
    }

    if (id && cols.some(predicate)) {
      this._showSpinner(cmp);
      this._async(cmp, doSort, 250);
    }

  },

  selectAll: function(cmp, evt) {
    var self = this;

    function selAll() {
      var rec, selected = $A.util.getBooleanValue(cmp.get('v.isSelectAll')),
        records = cmp.get('v.dataStore'),
        page = self._getPagerId(cmp),
        body = cmp.get('v.body'),
        rs = self._pageRecords(cmp, page);

      rs.forEach(function(r) {
        r['__selected'] = selected;
      });

      body.forEach(function(r) {
        rec = r.get('v.record');
        if (!!rec) {
          rec['__selected'] = selected;
          r.set('v.record', rec);
        }
      });
      cmp.set('v.dataStore', records);
      cmp.set('v.body', body);
      self._async(cmp, self._hideSpinner, 1);
    }

    this._showSpinner(cmp);
    this._async(cmp, selAll);
  },

  _getPagerId: function(cmp) {
    var pager = cmp.find('pager');
    return !!pager ? parseInt(pager.get('v.value') || 1) : 1;
  },

  assignSelectedValue: function(cmp, evt) {
    var obj,
      data = cmp.get('v.dataStore')
      .filter(function(d) {
        return d['__selected'] === true;
      }).map(function(d) {
        obj = {};
        Object.keys(d).filter(function(nm) {
            return nm.indexOf('__') === -1;
          })
          .forEach(function(nm) {
            obj[nm] = d[nm];
          });
        return obj;
      });
    cmp.set('v.value', data);
  },

  _rerenderPage: function(cmp, page, self) {
    var idx = 0,
      body = cmp.get('v.body'),
      self = self || this,
      rs = self._pageRecords(cmp, page),
      pageSize = parseInt(cmp.get('v.pageSize')) || 100,
      rsCount = rs.length;
    if (rs.length > 0) {
      if (rs.some(function(r) {
          return r && r['__selected'] === false;
        })) {
        cmp.set('v.isSelectAll', false);
      } else {
        cmp.set('v.isSelectAll', true);
      }
    }
    if (body.length === rsCount) {
      body.forEach(function(r) {
        r.set('v.record', rs[idx++]);
        r.set('v.visible', true);
      });
    } else {
      rs.forEach(function(r) {
        body[idx].set('v.record', r);
        body[idx++].set('v.visible', true);
      });
      for (idx = rsCount; idx < body.length; idx++) {
        body[idx].set('v.record', '');
        body[idx].set('v.visible', false);
      }
    }
    self._raiseEvent(cmp, self.DataGridEvents.DataGridRendered);
  },

  gotoPage: function(cmp, evt) {
    var self = this;

    function renderPage(cmp) {
      var page = parseInt(evt.getParam('context'));
      self._rerenderPage(cmp, page, self);
      self._hideSpinner(cmp);
    }
    self._showSpinner(cmp);
    self._async(cmp, renderPage);
  },

  dataChanged: function(cmp, evt) {
    var self = this,
      isFirstTime = $A.util.getBooleanValue(cmp.get('v.isFirstTime'));
    this._initColumns(cmp);
    cmp.set('v.isSelectAll', false);

    function genData() {
      var obj, i = 0,
        selectedFieldId = cmp.get('v.selectedFieldId') || 'selected',
        rs, data = cmp.get('v.data') || [];
      rs = data.map(function(rec) {
        obj = {};
        Object.keys(rec).forEach(function(nm) {
          obj[nm] = rec[nm];
        });
        obj['__id'] = ['row', ++i].join('_');
        obj['__selected'] = obj[selectedFieldId] || false;

        return obj;
      });
      cmp.set('v.dataStore', rs);
      self._initPager(cmp, rs.length);
      self._buildComponents(cmp, self._pageRecords(cmp, 1), self);
      self._canSpin(cmp) && self._hideSpinner(cmp);
    }
    if (isFirstTime) {
      cmp.set('v.isFirstTime', false);
    } else {
      self._canSpin(cmp) && this._showSpinner(cmp);
    }

    this._async(cmp, genData);
  },

  _pageRecords: function(cmp, page) {
    var start, pageSize = parseInt(cmp.get('v.pageSize')) || 100,
      rs = cmp.get('v.dataStore'),
      pages = Math.ceil(rs.length / pageSize);

    if (page < pages) {
      start = (page - 1) * pageSize;
      return rs.slice(start, start + pageSize);
    }
    return rs.slice((pages - 1) * pageSize);
  },

  _initPager: function(cmp, totalCount) {
    var canPage = $A.util.getBooleanValue(cmp.get('v.enablePagination')),
      pageSize = parseInt(cmp.get('v.pageSize')) || 100;
    if (!canPage) {
      return;
    }
    cmp.find('pager').set('v.pages', Math.ceil(totalCount / pageSize));
  },

  _buildComponents: function(cmp, records, self) {
    var fields = cmp.get('v.fields'),
      body = cmp.get('v.body');
    if (records.length <= body.length) {
      self._rerenderPage(cmp, records, self);
      return;
    }
    var items = records.map(function(rec) {
      return [
        'c:DataGridRow', {
          'record': rec,
          'fields': fields
        }
      ];
    });
    $A.createComponents(items, function(cmps, status, messsages) {
      if (status === 'SUCCESS') {
        cmp.set('v.body', cmps);
        self._raiseEvent(cmp, self.DataGridEvents.DataGridRendered);
      } else {
        console.log(messages);
      }
    });
  },

  _hideSpinner: function(cmp) {
    cmp.find('busyIndicator').hide();
  },

  _showSpinner: function(cmp) {
    cmp.find('busyIndicator').show();
  },

  _async: function(cmp, callback, duration) {
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

  _raiseEvent: function(cmp, eventName, context) {
    var cmpEvt = cmp.getEvent(eventName);
    cmpEvt.setParams({
      'id': eventName,
      'context': context
    });
    cmpEvt.fire();
  },
  _transformEventContext: function(event) {
    var cell = event.getParam('context'),
      rec = {},
      col = {};
    Object.keys(cell.__parent).filter(function(nm) {
      return nm.indexOf('__') === -1;
    }).forEach(function(nm) {
      rec[nm] = cell.__parent[nm];
    });
    Object.keys(cell).filter(function(nm) {
      return nm.indexOf('__') === -1;
    }).forEach(function(nm) {
      col[nm] = cell[nm];
    });
    return {
      'record': rec,
      'field': col
    };
  },
  _canSpin: function(cmp) {
    return $A.util.getBooleanValue(cmp.get('v.showSpinner'));
  }
})