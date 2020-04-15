({
  MONTHS: ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'],
  WEEKDAY: ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'],
  SUNDAY: 0,
  SATURDAY: 6,
  MONTH_LASTDATE: [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31],
  ONEDAY_MILLISECNDS: 86400000,
  TODAY: 0,
  CELL_DISABLED: 'slds-disabled-text',
  CELL_ISTODAY: 'slds-is-today',
  CELL_ISSELECTED: 'slds-is-selected',
  CELL_MULTIPLE_ISSELECTED: 'slds-is-selected slds-is-selected-multi',
  ROW_MULTISELECT: 'slds-has-multi-row-selection',

  afterRender: function(cmp) {
    this._recalculateDatePicker(cmp);
  },

  onInit: function(cmp) {
    this._initYearSelectionAndToday(cmp);
    this._initRows(cmp);
  },

  _initYearSelectionAndToday: function(cmp) {
    var years = [],
      yearRange = parseInt(cmp.get('v.yearRange')),
      today = this._getToday();
    for (var i = -yearRange; i < yearRange; i++) {
      years.push(today.year + i);
    }

    cmp.set('v.years', years);
    cmp.set('v.year', today.year);
    cmp.set('v.month', today.month);
    cmp.set('v.monthName', this.MONTHS[today.month]);
  },

  _getDateRange: function(cmp) {
    var dtStart = cmp.get('v.startDate') || '', dtEnd = cmp.get('v.endDate') || '';
    if(!!dtStart){
      dtStart = new Date(dtStart.getFullYear(), dtStart.getMonth(), dtStart.getDate(), 2,59,59,0);
    }
    if(!!dtEnd){
      dtEnd = new Date(dtEnd.getFullYear(), dtEnd.getMonth(), dtEnd.getDate(), 21, 59,59,0);
    }

    return {
      'from': dtStart,
      'to': dtEnd
    };
  },

  _getToday: function() {
    var td = new Date();
    return {
      'year': td.getFullYear(),
      'month': td.getMonth(),
      'date': td.getDate()
    };
  },

  _initRows: function(cmp) {
    try {
      this._calculateRows(cmp);
    } catch (e) {
      console.log(e);
    }
  },

  _calculateRows: function(cmp) {
    var i, j, v,
      week, row, cellsId, cells,
      year = parseInt(cmp.get('v.year')),
      month = parseInt(cmp.get('v.month')),
      firstCellDate = this._calculateFirstCellDate(cmp);

    for (i = 0; i < 6; i++) {
      row = this._getRowId(i);
      cells = [0, 0, 0, 0, 0, 0, 0];
      week = 'week' + this._getWeekNumber(firstCellDate);
      for (j = 0; j < 7; j++) {
        v = firstCellDate.getDate();
        cells[j] = this._genCell(
          j, [this.WEEKDAY[j], week].join(' '),
          (i < 2 && v > 20 || i > 3 && v < 20) ? '' : v,
          firstCellDate,
          false,
          false,
          ''
        );
        firstCellDate = this._addOneDay(firstCellDate);
      }
      cmp.set(row.id, '');
      cmp.set(row.cellsId, cells);
    }
  },

  _getRowId: function(rowNumber) {
    return {
      'id': ['v.row', rowNumber].join(''),
      'cellsId': ['v.row', rowNumber, 'Cells'].join(''),
    };
  },

  _calculateFirstCellDate: function(cmp) {
    var month = parseInt(cmp.get('v.month')),
      year = parseInt(cmp.get('v.year')),
      dateOne = new Date(year, month, 1, 0, 0, 0, 0),
      day = dateOne.getDay();
    if (day === this.SUNDAY) {
      if (month > 0) {
        return new Date(year, month - 1, this._getMonthLastDate(year, month - 1) - 6, 8, 59, 59, 0);
      }
      return new Date(year - 1, 11, 25, 8, 59, 59, 0);
    }

    if (month > 0) {
      return new Date(year, month - 1, this._getMonthLastDate(year, month - 1) - day + 1, 8, 59, 59, 0);
    } else {
      return new Date(year - 1, 11, 32 - day, 8, 59, 59, 0);
    }
  },

  _getSelYearMonth: function(cmp) {
    return {
      'year': parseInt(cmp.get('v.year')),
      'month': parseInt(cmp.get('v.month'))
    };
  },

  _genCell: function(id, header, value, dateValue, selected, disabled, tdClass) {
    return {
      'id': id,
      'header': header,
      'value': value,
      'date': dateValue,
      'ariaSelected': selected,
      'ariaDisabled': disabled,
      'class': tdClass
    };
  },

  _addOneDay: function(dtSource){
    return new Date(dtSource.getTime() + this.ONEDAY_MILLISECNDS);
  },

  _addDays: function(dtSource, days) {
    return new Date(dtSource.getTime() + this.ONEDAY_MILLISECNDS * days);
  },

  _getMonthLastDate: function(year, month) {
    if (1 !== month) {
      return this.MONTH_LASTDATE[month];
    }
    var dt = new Date(year, 2, 1, 0, 0, 0, 0),
      febLastDate = new Date(dt.getTime() - this.ONEDAY_MILLISECNDS);
    return febLastDate.getDate();
  },

  _getWeekNumber: function(dateInstance) {
    var year = dateInstance.getFullYear();
    var janOne = new Date(year, 0, 1);
    return Math.ceil((((dateInstance - janOne) / this.ONEDAY_MILLISECNDS) + janOne.getDay() + 1) / 7);
  },

  _recalculateDatePicker: function(cmp) {
    var i, callback, callback1, callback2, businessLogicCallback, today = this._getToday(),
      isMultipleSelection = this._isMultipleSelection(cmp),
      value = cmp.get('v.value'),
      dateRange = this._getDateRange(cmp),
      yearMonth = this._getSelYearMonth(cmp);

    callback1 = function(self, e, ym, today) {
      if (e.value > 20) {
        e.class = self.CELL_DISABLED;
      } else {
        if (today.date === e.value && today.year === ym.year && today.month === ym.month) {
          e.class = self.CELL_ISTODAY;
        } else {
          e.class = '';
        }
      }
    };

    callback2 = function(self, e, ym, today) {
      if (e.value > 20) {
        if (today.date === e.value && today.year === ym.year && today.month === ym.month) {
          e.class = self.CELL_ISTODAY;
        } else {
          e.class = '';
        }
      } else {
        e.class = self.CELL_DISABLED;
      }
    };

    businessLogicCallback = function(context) {
      var dateRange = context.dateRange,
        self = context.self,
        ret = 0,
        cell = context.cell;
      if (!!dateRange.from && !!dateRange.to) {
        if (cell.date < dateRange.from || cell.date > dateRange.to) {
          cell.class = [cell.class, self.CELL_DISABLED].join(' ');
        }
      } else if (!!dateRange.from) {
        if (cell.date < dateRange.from) {
          cell.class = [cell.class, self.CELL_DISABLED].join(' ');
        }
      } else if (!!dateRange.to) {
        if (cell.date > dateRange.to) {
          cell.class = [cell.class, self.CELL_DISABLED].join(' ');
        }
      }
      if (!context.value) {
        return 0;
      }

      if (context.isMultipleSelection) {
        context.value.forEach(function(e) {
          if (e.getTime() == cell.date.getTime()) {
            cell.class = self.CELL_MULTIPLE_ISSELECTED;
            cell.ariaSelected = true;
            ret = 1;
          }
        });
      } else {
        if (context.value instanceof Date) {
          if (cell.date.getTime() == context.value.getTime()) {
            cell.class = self.CELL_ISSELECTED;
            cell.ariaSelected = true;
            ret = 1;
          }
        }
      }
      return ret;
    }
    for (i = 0; i < 6; i++) {
      if (i < 2) {
        callback = callback1;
      } else if (i > 3) {
        callback = callback2;
      } else {
        callback = 0;
      }
      this._recalculateRow(cmp, {
        'isMultipleSelection': isMultipleSelection,
        'value': value,
        'rowNumber': i,
        'today': today,
        'yearMonth': yearMonth,
        'callback': callback,
        'dateRange': dateRange,
        'runBusinessRules': businessLogicCallback
      });
    }
  },

  _recalculateRow: function(cmp, option) {
    var row = this._getRowId(option.rowNumber),
      self = this,
      count = 0,
      cells = cmp.get(row.cellsId),
      dateRange = option.dateRange,
      businessLogicCallback = option.runBusinessRules,
      callback = option.callback;

    if (!callback) {
      callback = function(self, e, ym, today) {
        if (today.date === e.value && today.year === ym.year && today.month === ym.month) {
          e.class = self.CELL_ISTODAY;
        } else {
          e.class = '';
        }
      };
    }
    for (var j = 0; j < 7; j++) {
      callback(this, cells[j], option.yearMonth, option.today);
      count += businessLogicCallback({
        'self': this,
        'isMultipleSelection': option.isMultipleSelection,
        'value': option.value,
        'dateRange': dateRange,
        'cell': cells[j]
      });
    }
    cmp.set(row.cellsId, cells);
    if (count > 0 && option.isMultipleSelection) {
      cmp.set(row.id, self.ROW_MULTISELECT);
    }
  },

  _toDate: function(dtObj) {
    return {
      'year': dtObj.getFullYear(),
      'month': dtObj.getMonth(),
      'date': dtObj.getDate()
    }
  },

  selectToday: function(cmp, evt) {
    var today = this._getToday(),
      year = cmp.get('v.year'),
      month = cmp.get('v.month');
    if (year !== today.year || month !== today.month) {
      cmp.set('v.year', today.year);
      cmp.set('v.month', today.month);
      cmp.set('v.monthName', this.MONTHS[today.month]);
      this._initRows(cmp);
    }
    this._recalculateDatePicker(cmp);
  },

  selectDate: function(cmp, evt) {
    var dateSelectedEvent, selClass, rowClass, selCell, row, cells, dataId = evt.currentTarget.getAttribute('data-id'),
      isMultipleSelection = this._isMultipleSelection(cmp),
      self = this,
      params = dataId.split(':').map(function(e) {
        return parseInt(e);
      });
    row = this._getRowId(params[0]);
    cells = cmp.get(row.cellsId);

    selClass = isMultipleSelection ? self.CELL_MULTIPLE_ISSELECTED : self.CELL_ISSELECTED;
    rowClass = isMultipleSelection ? self.ROW_MULTISELECT : '';
    selCell = cells[params[1]];
    if (selCell.class.indexOf(self.CELL_DISABLED) !== -1) {
      return;
    } else if (selCell.class.indexOf(selClass) !== -1) {
      selCell.class = '';
      selCell.ariaSelected = false;
      cmp.set(row.cellsId, cells);
      this._removeValue(cmp, isMultipleSelection, selCell.date);
      return;
    }

    if (!isMultipleSelection) {
      this._resetSingleSelection(cmp);
    }

    selCell.class = selClass;
    selCell.ariaSelected = true;
    cmp.set(row.cellsId, cells);
    cmp.set(row.id, rowClass);
    this._setValue(cmp, isMultipleSelection, selCell.date);

    if (!isMultipleSelection) {
      dateSelectedEvent = cmp.getEvent('datePickerDateSelectedEvent');
      dateSelectedEvent.setParams({
        id: 'datePickerDateSeletedEvent',
        context: selCell.date
      });
      dateSelectedEvent.fire();
    }
  },

  _isMultipleSelection: function(cmp) {
    return $A.util.getBooleanValue(cmp.get('v.isMultipleSelection'));
  },

  _setValue: function(cmp, isMultiple, selDate) {
    var val = cmp.get('v.value') || (isMultiple ? [] : '');
    if (isMultiple) {
      if (-1 !== val.indexOf(selDate)) {
        return;
      }
      val.push(selDate);
    } else {
      val = selDate;
    }
    cmp.set('v.value', val);
  },

  _removeValue: function(cmp, isMultiple, selDate) {
    var pos, val = cmp.get('v.value') || (isMultiple ? [] : '');
    if (isMultiple) {
      pos = val.indexOf(selDate);
      if (-1 !== pos) {
        val.splice(pos, 1);
      }
    } else {
      val = '';
    }
    cmp.set('v.value', val);
  },


  _resetSingleSelection: function(cmp) {
    var changed, row, cells, self = this,
      yearMonth = this._getSelYearMonth(cmp);

    for (var i = 0; i < 5; i++) {
      changed = 0;
      row = this._getRowId(i);
      cells = cmp.get(row.cellsId);
      cells.filter(function(c) {
          return c.class === self.CELL_ISSELECTED;
        })
        .forEach(function(c) {
          changed = 1;
          if (self._isToday(yearMonth.year, yearMonth.month, c.value)) {
            c.class = self.CELL_ISTODAY;
          } else {
            c.class = '';
          }
          c.ariaSelected = false;
        });
      if (changed) {
        cmp.set(row.cellsId, cells);
      }
    }
  },

  _isToday: function(year, month, date) {
    var today = this._getToday();
    return (date === today.date && year === today.year && month === today.month);
  },

  onChangeYear: function(cmp, evt) {
    this._initRows(cmp);
    this._recalculateDatePicker(cmp);
  },

  goPreviousMonth: function(cmp, evt) {
    var month = cmp.get('v.month'),
      year = cmp.get('v.year');
    month -= 1;
    if (month < 0) {
      month = 11,
        year -= 1;
      cmp.set('v.year', year);
    }
    cmp.set('v.month', month);
    cmp.set('v.monthName', this.MONTHS[month]);
    this._initRows(cmp);
    this._recalculateDatePicker(cmp);
  },

  goNextMonth: function(cmp, evt) {
    var month = cmp.get('v.month'),
      year = cmp.get('v.year');
    month += 1;
    if (month > 11) {
      month = 0;
      year += 1;
      cmp.set('v.year', year);
    }

    cmp.set('v.month', month);
    cmp.set('v.monthName', this.MONTHS[month]);
    this._initRows(cmp);
    this._recalculateDatePicker(cmp);
  },

  valueChanged: function(cmp, evt) {
    this._recalculateDatePicker(cmp);
  }
})