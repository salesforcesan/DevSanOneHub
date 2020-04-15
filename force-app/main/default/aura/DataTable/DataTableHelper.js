({
  onInit: function(cmp, evt) {
    this._initTable(cmp);
  },

  afterRender: function(cmp, evt) {
    this.showSpinner(cmp);
    this._initFields(cmp);
  },

  _canSelectAll: function(cmp) {
    return $A.util.getBooleanValue(cmp.get('v.canSelectAll'));
  },

  _initTable: function(cmp) {
    var height = parseInt(cmp.get('v.height'));
    if (height > 0) {
      cmp.set('v.style', 'height:' + height + 'px;');
    }
  },

  _initFields: function(cmp) {
    var thead, canSelectAll, tableWidth, self = this,
      fields = cmp.get('v.fields') || [];
    if (fields.length > 0) {
      return;
    }
    canSelectAll = this._canSelectAll(cmp);
    tableWidth = cmp.find('datatableContainer').getElement().clientWidth - 14;
    thead = this._getThead();
    thead.style.width = tableWidth + 'px';

    function genCheckbox(field, id, checked) {
      return [
        '<button class="checkbox',
        checked ? ' checked"' : '"',
        ' data-id="',
        id,
        '"',
        ' data-type="checkbox"><i class="fa fa-icon fa-check"></i></button>'
      ].join('');
    }

    function transformColumns() {
      var i = 0,
        spaceWidth = tableWidth,
        c0 = 0,
        id = cmp.get('v.id'),
        cols = cmp.get('v.columns');

      cols.forEach(function(c) {
        if (!!c['width']) {
          spaceWidth -= parseInt(c['width'].replace('px', ''));
        } else {
          c0++;
        }
      });
      if (c0 > 0) {
        spaceWidth = (spaceWidth / c0 - 15) + 'px';
      }
      fields = cols.map(function(f) {
        var _extend, obj = {};
        Object.keys(f).forEach(function(nm) {
          obj[nm] = f[nm] || '';
        });

        _extend = {
          'header': (obj['type'] === 'button') ? '' : obj['label'],
          'sorted': false,
          'canSort': obj['type'] !== 'button',
          'id': [id, ++i].join('_'),
          'style': ['width', !!obj['width'] ? obj['width'] : spaceWidth].join(':')
        };
        _extend.html = function(record) {
            return ['<div class="td" style="',
              _extend.style,
              '" data-col-id="',
              obj.id,
              '"><div class="slds-truncate">',
              record[obj.id],
              '</div></div>'
            ].join('');
          },

          obj['__extend'] = _extend;
        return obj;
      });

      if (canSelectAll) {
        var obj = {
            'name': 'selectRow',
            'label': '',
            'id': 'selectRow',
            'type': 'checkbox',
            'class': 'align-center'
          },
          _extend = {
            'header': '',
            'canSort': false,
            'id': id + '_selectRow',
            'style': 'width:50px;'
          };
        _extend.html = function(record) {
          return ['<div class="td align-center" style="', _extend.style, '">', genCheckbox(obj, record['__id'], record['__checked'] || 0), '</div>'].join('');
        };

        obj['__extend'] = _extend;
        fields.unshift(obj);
      }
      return fields;
    }
    cmp.set('v.fields', transformColumns(cmp));
  },

  onCheckboxChange: function(cmp, evt) {    
    if (!cmp.find('chkSelectAll')) {
      return; }
    var selectAllTokenList = cmp.find('chkSelectAll').getElement().classList,
      source = evt.target;
    if (source.classList.contains('fa')) {
      source = source.parentNode;
    }
    source.classList.toggle('checked');
    if (selectAllTokenList.contains('checked')) {
      selectAllTokenList.remove('checked');
    }
  },

  _nodeListToArray: function(nodeList) {
    var list = nodeList || [];
    return Array.prototype.slice.call(list);
  },

  calculateValue: function(cmp, evt) {
    var selected, arrCheck = [],
      arrNoCheck = [],
      tbody = cmp.find('tbody').getElement(),
      checkArr = tbody.querySelectorAll('.tr button[class="checkbox checked"]'),
      noCheckArr = tbody.querySelectorAll('.tr button[class="checkbox"]'),
      store = cmp.get('v.dataStore');


    cmp.set('v.skipRender', true);

    function notInUncheck(s) {
      return !arrNoCheck.some(function(chk) {
        return chk.getAttribute('data-id') === s.__id;
      });
    }

    function inCheck(s) {
      return arrCheck.some(function(chk) {
        return chk.getAttribute('data-id') === s.__id;
      });
    }

    if (checkArr.length === 0 || store.length === 0) {
      cmp.set('v.value', []);
      return;
    }

    if (checkArr.length === store.length) {
      cmp.set('v.value', store);
      return;
    }
    arrCheck = this._nodeListToArray(checkArr);
    arrNoCheck = this._nodeListToArray(noCheckArr);

    if (checkArr.length / store.length > 0.5) {
      selected = store.filter(notInUncheck);
    } else {
      selected = store.filter(inCheck)
    }
    selected.forEach(function(s) {
      s['__checked'] = true;
    })
    cmp.set('v.value', selected);
    cmp.set('v.dataStore', store);
  },


  onSelectAll: function(cmp, evt) {
    var self = this;

    var checked = this._toggleSelectAll(cmp),
      boxes = cmp.find('tbody').getElement().querySelectorAll('.tr button.checkbox');

    boxes.forEach(function(box) {
      var tokenList = box.classList;
      if (checked) {
        if (!tokenList.contains('checked')) {
          tokenList.add('checked');
        }
      } else {
        if (tokenList.contains('checked')) {
          tokenList.remove('checked');
        }
      }
    });
  },

  _toggleSelectAll: function(cmp) {
    var tokenList = cmp.find('chkSelectAll').getElement().classList;
    tokenList.toggle('checked');
    return tokenList.contains('checked');
  },

  _isSelected: function(node) {
    return node.classList.contains('checked');
  },

  onSort: function(cmp, evt) {
    var self = this,
      id = evt.currentTarget.getAttribute('data-id') || '',
      cols = cmp.get('v.fields');

    function predicate(col) {
      return col.__extend.id === id;
    }

    function doSort(cmp) {
      var selCol = cols.filter(predicate)[0],
        canSelectAll = self._canSelectAll(cmp),
        selectAll = canSelectAll ? self._isSelected(cmp.find('chkSelectAll').getElement()) : false,
        data = cmp.get('v.dataStore'),
        algrithm = (selCol.__extend.sorted) ? function(d1, d2) {
          return d1[selCol.id] > d2[selCol.id] ? -1 : 1;
        } : function(d1, d2) {
          return d1[selCol.id] > d2[selCol.id] ? 1 : -1;
        };
      cols.forEach(function(col) {
        if (col.__extend.id == id) {
          col.__extend.sorted = !col.__extend.sorted;
        } else {
          col.__extend.sorted = false;
        }
      });
      cmp.set('v.fields', cols);

      data.sort(algrithm);
      if (canSelectAll) {
        if (selectAll) {
          data.forEach(function(d) {
            d.__checked = true;
          });
        } else if (cmp.find('tbody').getElement().querySelectorAll('.tr button[class="checkbox checked"]').length > 0) {
          data = self._setPartialDatasetCheck(cmp, data);
        } else {
          data.forEach(function(d) {
            d.__checked = false;
          });
        }
      }
      self._buildHTML(cmp, data, self);
      cmp.set('v.dataStore', data);
    }

    if (id && cols.some(predicate)) {
      this.showSpinner(cmp);
      this._async(cmp, doSort, 1);
    }
  },

  _setPartialDatasetCheck: function(cmp, data) {
    var checkArr = [],
      tbody = cmp.find('tbody').getElement(),
      checkedNodeList = tbody.querySelectorAll('.tr button[class="checkbox checked"]'),
      noCheckArr = [],
      noCheckNodeList = tbody.querySelectorAll('.tr button[class="checkbox"]');
    if (!data || data.length === 0) {
      return [];
    }

    if (checkedNodeList.length === data.length) {
      checkedNodeList.forEach(function(d) {
        d.__checked = true;
      });
      return data;
    }
    checkArr = this._nodeListToArray(checkedNodeList);
    noCheckArr = this._nodeListToArray(noCheckNodeList);

    if (checkArr.length / data.length > 0.5) {
      data.forEach(function(d) {
        d.__checked = !noCheckArr.some(function(chk) {
          return chk.getAttribute('data-id') === d.__id;
        });
      });
    } else {
      data.forEach(function(d) {
        d.__checked = checkArr.some(function(chk) {
          return chk.getAttribute('data-id') === d.__id;
        });
      });
    }
    return data;
  },

  _getThead: function() {
    return document.querySelector('.datatable-container .table .thead');
  },

  _getBody: function(cmp) {
    return cmp.find('tbody').getElement();
  },

  _fixHeader: function(self, thead) {
    thead = thead || self._getThead();
    if (thead.getAttribute('data-toggled') === '0') {
      thead.classList.add('fixed');
      thead.setAttribute('data-toggled', '1');
    }
  },

  _releaseHeader: function(self, thead) {
    thead = thead || self._getThead();
    if (thead.getAttribute('data-toggled') === '1') {
      thead.classList.remove('fixed');
      thead.setAttribute('data-toggled', '0');
    }
  },

  rerender: function(cmp) {
    var self = this;

    if (!cmp.get('v.skipRender')) {
      // var tbody = self._getBody(cmp);
      // tbody.innerHTML = cmp.get('v.html');
      cmp.getEvent('dataTableRendered').fire();
    } else {
      cmp.set('v.skipRender', false);
    }

    this._async(cmp, self.hideSpinner, 250);
  },

  onDataChange: function(cmp, evt) {
    var i = 0,
      checkAll = this._canSelectAll(cmp) ? cmp.find('chkSelectAll').getElement() : 0,
      data = cmp.get('v.data');
    data.forEach(function(d) {
      i++;
      d.__id = 'row' + i;
      d.__checked = false;
    });
    this._buildHTML(cmp, data);
    checkAll && (checkAll.checked = false);
    cmp.set('v.dataStore', data);
  },

  _buildHTML: function(cmp, data, self) {
    self = self || this;

    function genHtml(cmp) {
      var obj,
        fields = cmp.get('v.fields'),
        i = 0,
        body = [];

      data.forEach(function(r) {
        body.push('<div class="tr">');
        fields.forEach(function(f) {
          body.push(f.__extend.html(r));
        });
        body.push('</div>')
      });
      cmp.set('v.html', body.join(''));
      self.hideSpinner(cmp);
    }
    //cmp.set('v.html', '');
    self._async(cmp, genHtml, 250);
  },

  showSpinner: function(cmp) {
    cmp.find('spinner').show();
  },

  hideSpinner: function(cmp) {
    cmp.find('spinner').hide();
  },

  _async: function(cmp, callback, duration) {
    if (!callback) {
      return;
    }
    duration = duration || 500;
    var id = window.setTimeout($A.getCallback(function() {
      window.clearTimeout(id);
      if (cmp.isValid()) {
        try {
          callback(cmp);
        } catch (e) {
          console.log(e);
        }

      }
    }), duration);
  }
})