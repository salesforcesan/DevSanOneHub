({
  AppSettings: {
    GO_TO_PAGE_EVENT: 'gotoPage',
    PREVIOUS_VALUE: 0,
    NEXT_VALUE: 9999,
    NEXT_PAGE_ID: 8,
    PREVIOUS_PAGE_ID: 0,
    ELLIPSIS_VALUE: '...'
  },

  onInit: function(cmp, evt) {
    for (var i = 0; i < 9; i++) {
      cmp.set('v.page' + i, {
        'id': i,
        'class': 'in-processing',
        'value': i
      });
    }
  },

  gotoFirstPage: function(cmp, evt) {
    var pages = cmp.get('v.pages'),
      page = cmp.get('v.page1');
    this._renderUI1(cmp, pages, page.value);
    page.class = "selected";
    cmp.set('v.page1', page);
    cmp.set('v.value', page.value);
    this._raisePageEvent(cmp, page.value);
  },

  selectPage: function(cmp, evt) {
    var self = this,
      pageId = parseInt(evt.currentTarget.getAttribute('data-id')),
      pages = cmp.get('v.pages'),
      page = cmp.get('v.page' + pageId);

    if (page.value === this.AppSettings.ELLIPSIS_VALUE || page.class === 'selected') {
      return;
    }

    if (pages < 8) {
      this._renderUI1(cmp, pages, page.value);
    } else {
      this._renderUI2(cmp, pages, page.value);
    }

    page.class = "selected";
    cmp.set('v.page' + pageId, page);
    cmp.set('v.value', page.value);
    this._raisePageEvent(cmp, page.value);
  },

  nextPage: function(cmp, evt) {
    var next = parseInt(cmp.get('v.value')) + 1,
      pages = parseInt(cmp.get('v.pages')),
      nextPage = cmp.get('v.page' + this.AppSettings.NEXT_PAGE_ID);

    if (nextPage.class === 'disabled') {
      return;
    }

    if (pages < 8) {
      this._renderUI1(cmp, pages, next);
    } else {
      this._renderUI2(cmp, pages, next);
    }
    cmp.set('v.value', next);
    this._raisePageEvent(cmp, next);
  },

  prevPage: function(cmp, evt) {
    var prev = parseInt(cmp.get('v.value')) - 1,
      pages = parseInt(cmp.get('v.pages')),
      prevPage = cmp.get('v.page' + this.AppSettings.PREVIOUS_PAGE_ID);

    if (prevPage.class === 'disabled') {
      return;
    }
    if (pages < 8) {
      this._renderUI1(cmp, pages, prev);
    } else {
      this._renderUI2(cmp, pages, prev);
    }
    cmp.set('v.value', prev);
    this._raisePageEvent(cmp, prev);
  },

  _raisePageEvent: function(cmp, pageNumber) {
    var evt = cmp.getEvent(this.AppSettings.GO_TO_PAGE_EVENT);
    evt.setParams({
      'id': this.AppSettings.GO_TO_PAGE_EVENT,
      'context': pageNumber
    });
    evt.fire();
  },

  watchPagesChanged: function(cmp, evt) {
    var pages = parseInt(cmp.get('v.pages')),
      value = parseInt(cmp.get('v.value')) || 1;
    if (pages < 8) {
      this._renderUI1(cmp, pages, value);
    } else {
      this._renderUI2(cmp, pages, value);
    }
  },

  _renderUI1: function(cmp, pages, value) {
    var self = this;
    this._renderPrevNextButton(cmp, pages, value);
    [1, 2, 3, 4, 5, 6, 7].forEach(function(id) {
      if (id === value) {
        self._setPage(cmp, id, 'selected', id);
      } else if (id > pages) {
        self._setPage(cmp, id, 'hide', id);
      } else {
        self._setPage(cmp, id, '', id);
      }
    });
  },

  _renderUI2: function(cmp, pages, value) {
    this._renderPrevNextButton(cmp, pages, value);

    if (value > (pages - 5)) {
      this._renderUI2LastRange(cmp, pages, value);
      return;
    }
    if (value < 6) {
      this._renderUI2FirstRange(cmp, pages, value);
      return;
    }
    this._renderUI2MiddleRange(cmp, pages, value);

  },
  _renderPrevNextButton: function(cmp, pages, value) {
    this._setPage(cmp, this.AppSettings.PREVIOUS_PAGE_ID, value === 1 ? 'disabled' : '', this.AppSettings.PREVIOUS_VALUE);
    this._setPage(cmp, this.AppSettings.NEXT_PAGE_ID, value === pages ? 'disabled' : '', this.AppSettings.NEXT_VALUE);
  },

  _renderUI2LastRange: function(cmp, pages, value) {
    var cssClass, page, self = this,
      pValue,
      pageValue = pages - 4;

    [3, 4, 5, 6, 7].forEach(function(i) {
      page = cmp.get('v.page' + i);
      pValue = pageValue + i - 3;
      cssClass = (pValue === value) ? 'selected' : '';
      self._setPage(cmp, i, cssClass, pValue);
    });

    self._setPage(cmp, 2, 'disabled', '...');
    self._setPage(cmp, 1, '', 1);
  },

  _renderUI2FirstRange: function(cmp, pages, value) {
    var cssClass, page, self = this;

    [1, 2, 3, 4, 5].forEach(function(i) {
      page = cmp.get('v.page' + i);
      cssClass = (i === value) ? 'selected' : '';
      self._setPage(cmp, i, cssClass, i);
    });

    self._setPage(cmp, 6, 'disabled', self.AppSettings.ELLIPSIS_VALUE);
    self._setPage(cmp, 7, '', pages);
  },
  _renderUI2MiddleRange: function(cmp, pages, value) {
    var cssClass, page, self = this,
      pageValue, pValue;
    if (value === 6) {
      pageValue = 6;
    } else if (value === (pages - 5)) {
      pageValue = pages - 7;
    } else {
      pageValue = self._getPageValue(value);
    }

    [3, 4, 5].forEach(function(i) {
      page = cmp.get('v.page' + i);
      pValue = pageValue - 3 + i;
      cssClass = (pValue === value) ? 'selected' : '';
      self._setPage(cmp, i, cssClass, pValue);
    });

    self._setPage(cmp, 1, '', 1);
    self._setPage(cmp, 2, 'disabled', self.AppSettings.ELLIPSIS_VALUE);
    self._setPage(cmp, 6, 'disabled', self.AppSettings.ELLIPSIS_VALUE);
    self._setPage(cmp, 7, '', pages);
  },

  _getPageValue: function(value) {
    var end = 8;
    while (value > end) {
      end += 3;
    }
    return end - 2;
  },

  _setPage: function(cmp, pageId, cssClass, value) {
    var page = cmp.get('v.page' + pageId);
    page.class = cssClass;
    page.value = value;
    cmp.set('v.page' + pageId, page);
  }
})