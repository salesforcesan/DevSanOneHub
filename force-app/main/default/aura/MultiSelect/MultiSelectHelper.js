({
  'ID': {
    'MENULIST': 'menuList',
    'DROPDOWN': 'dropdown',
    'SEARCH': 'search',
    'INPUT': 'inputContainer'
  },

  'PROPERTY': {
    'SKIP_VALUECHANGE_WATCH': 'v.skipValueChangeWatch',
    'VALUE': 'v.value',
    'IS_HOVERED': 'v.isHovered'
  },

  'STYLES': {
    'OPEN': 'slds-is-open',
    'SELECTED': 'sd-select'
  },

  blur: function(cmp, evt) {
    console.log('--- on blurej----');
    if (cmp.get(this.PROPERTY.IS_HOVERED)) {
      return;
    }
    this._closeDropdown(cmp);
  },

  enterDropdown: function(cmp, evt) {
    cmp.set(this.PROPERTY.IS_HOVERED, true);
  },

  leaveDropdown: function(cmp, evt) {
    cmp.set(this.PROPERTY.IS_HOVERED, false);
  },

  startSelect: function(cmp, evt) {
    var tkList = cmp.find(this.ID.MENULIST).getElement().classList;
    tkList.toggle(this.STYLES.OPEN);
    if (tkList.contains(this.STYLES.OPEN)) {
      cmp.find(this.ID.INPUT).getElement().focus();
    }
  },

  _openDropdown: function(cmp) {
    var tkList = cmp.find(this.ID.MENULIST).getElement().classList;
    if (!tkList.contains(this.STYLES.OPEN)) {
      tkList.add(this.STYLES.OPEN);
    }
  },

  _closeDropdown: function(cmp) {
    var tkList = cmp.find(this.ID.MENULIST).getElement().classList;
    if (tkList.contains(this.STYLES.OPEN)) {
      tkList.remove(this.STYLES.OPEN);
    }
  },

  valueChanged: function(cmp, evt) {
    var item, search, selId, id, items, self = this,
      val = cmp.get(this.PROPERTY.VALUE) || [];
    if (cmp.get(this.PROPERTY.SKIP_VALUECHANGE_WATCH)) {
      cmp.set(this.PROPERTY.SKIP_VALUECHANGE_WATCH, false);
      return;
    }
    items = this._getItems(cmp);
    search = cmp.find(this.ID.SEARCH).getElement();

    if (val.length === 0) {
      items.forEach(function(a) {
        item = a.querySelector('i.fa');
        if (item && item.classList.contains(self.STYLES.SELECTED)) {
          item.classList.remove(self.STYLES.SELECTED);
        }
      });
      search.innerHTML = '0 Selected';
    } else {
      items.forEach(function(a) {
        id = a.getAttribute('data-id');
        item = a.querySelector('i.fa');
        if (item) {
          if (val.some(function(v) {
              return v === id;
            })) {
            if (!item.classList.contains(self.STYLES.SELECTED)) {
              item.classList.add(self.STYLES.SELECTED);
            }
          } else {
            if (item.classList.contains(self.STYLES.SELECTED)) {
              item.classList.remove(self.STYLES.SELECTED);
            }
          }
        }
      });
      selId = 'i.' + this.STYLES.SELECTED;
      search.innerHTML = items.filter(function(a) {
        return !!a.querySelector(selId);
      }).length + ' Selected';
    }
  },

  itemSelected: function(cmp, evt) {
    this._toggleItemSelect(cmp, evt);
    this._assignValue(cmp, evt);
  },

  _toggleItemSelect: function(cmp, evt) {
    var dataId = evt.currentTarget.getAttribute('data-id'),
      dropdown = cmp.find(this.ID.DROPDOWN),
      selItemIcon = dropdown.getElement().querySelector(['a[data-id="', dataId, '"] i.fa'].join(''));
    if (selItemIcon.classList.contains(this.STYLES.SELECTED)) {
      selItemIcon.classList.remove(this.STYLES.SELECTED);
    } else {
      selItemIcon.classList.add(this.STYLES.SELECTED);
    }
  },

  _assignValue: function(cmp, evt) {
    var dropdown = cmp.find(this.ID.DROPDOWN),
      selId = 'i.' + this.STYLES.SELECTED,
      selItems = this._getItems(cmp)
      .filter(function(a) {
        return !!a.querySelector(selId);
      }).map(function(a) {
        return a.getAttribute('data-id');
      });
    cmp.find(this.ID.SEARCH).getElement().innerHTML = (selItems || []).length + ' Selected';
    cmp.set(this.PROPERTY.SKIP_VALUECHANGE_WATCH, true);
    cmp.set(this.PROPERTY.VALUE, selItems);
  },

  _getItems: function(cmp) {
    return Array.prototype.slice.call(cmp.find(this.ID.DROPDOWN).getElement().querySelectorAll('ul>li>a'));
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
})