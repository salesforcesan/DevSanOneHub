({
  AppSettings: {
    Events: {
      RemoteActionRequest: "e.c:ActionRequestAppEvent",
      ClearFilter: "clearFilter"
    },
    Routes: {
      SearchKeyword: "ProjectLocations/search",
      FilterProjectLocations: "ProjectLocations/filter"
    }
  },

  init: function(cmp, evt, helper) {
    helper.getCustomLocationType(cmp, evt, helper);
  },

  _dispatch: function(cmp, payload) {
    var action = cmp.getEvent("onRemoteRequest");
    action.setParams(payload);
    action.fire();
  },

  getCustomLocationType: function(cmp, evt, helper) {
    // Placeholder for Custom Settings
    var customLocationType = "Location";
    cmp.set("v.customLocationType", customLocationType);
  },

  _showSpinner: function(cmp, shown) {
    var evt = cmp.getEvent("showSpinnerEvent");
    evt.setParams({
      context: {
        show: shown
      }
    });
    evt.fire();
  },

  searchKeyword: function(cmp, evt) {
    var reg,
      validObj,
      obj = cmp.find("inputSearchKeyword"),
      val = obj.get("v.value") || "";
    if (!val) {
      return true;
    }

    if (val.indexOf(",") !== -1) {
      val = val.split(",");
    } else {
      reg = new RegExp(/\n|\r|\r\n/g);
      val = val.split(reg);
    }
    reg = new RegExp(/\s/g);
    val = val
      .join("|")
      .replace(reg, "")
      .split("|");

    return this._cleanUpSearchIfHavingError(cmp);
  },

  filterLocations: function(cmp, evt) {
    var query, message;
    try {
      query = this._getFilterQuery(cmp);
    } catch (ex) {
      if (ex instanceof RangeError) {
        this._showKeywordErrorIfHavingError(cmp);
        return;
      }
      console.log(ex);
      return;
    }
    this._cleanUpSearchIfHavingError(cmp);
    var message = {
      route: this.AppSettings.Routes.FilterProjectLocations,
      parameters: query
    };
    this._showSpinner(cmp, 1);
    this._dispatch(cmp, message);
    this._hideFilters(cmp);
  },

  _cleanUpSearchIfHavingError: function(cmp) {
    var obj = cmp.find("searchKeywordContainer");
    if ($A.util.hasClass(obj, "slds-has-error")) {
      $A.util.removeClass(obj, "slds-has-error");
      $A.util.addClass(cmp.find("searchKeywordError"), "hide");
    }
    return true;
  },
  _showKeywordErrorIfHavingError: function(cmp) {
    var obj = cmp.find("searchKeywordContainer");
    if (!$A.util.hasClass(obj, "slds-has-error")) {
      $A.util.addClass(obj, "slds-has-error");
      $A.util.removeClass(cmp.find("searchKeywordError"), "hide");
    }
    return true;
  },

  clearFilter: function(cmp, evt) {
    this._resetInput(cmp, [
      "inputSearchKeyword",
      "city",
      "state",
      "postal",
      "storeType",
      "selJobFilter",
      "scheduleDateFrom",
      "scheduleDateTo"
    ]);
    this._resetCheckbox(cmp, [
      "chkClosedLocations",
      "chkHasExceptions",
      "chkHasMaterials",
      "chkExecuted",
      "chkCompleted",
      "chkScheduled",
      "chkCanceled"
    ]);
    cmp.getEvent(this.AppSettings.Events.ClearFilter).fire();
    this._hideFilters(cmp);
  },

  _getFilterQuery: function(cmp) {
    return {
      projectId: cmp.get("v.projectId"),
      keyword: this._getKeywords(cmp),
      city: this._getValue(cmp, "city"),
      state: this._getValue(cmp, "state"),
      postal: this._getValue(cmp, "postal"),
      //'type': this._getValue(cmp, 'storeType'),
      jobFilter: this._getValue(cmp, "selJobFilter"),
      schedule1: this._getValue(cmp, "scheduleDateFrom"),
      schedule2: this._getValue(cmp, "scheduleDateTo"),
      chkClosed: this._getChecked(cmp, "chkClosedLocations"),
      chkException: this._getChecked(cmp, "chkHasExceptions"),
      chkMaterial: this._getChecked(cmp, "chkHasMaterials"),
      chkExecuted: this._getChecked(cmp, "chkExecuted"),
      chkCanceled: this._getChecked(cmp, "chkCanceled"),
      chkCompleted: this._getChecked(cmp, "chkCompleted"),
      //    'chkHasJobs': this._getChecked(cmp, 'chkHasJobs'),
      chkScheduled: this._getChecked(cmp, "chkScheduled")
    };
  },

  _getValue: function(cmp, auraId) {
    if (auraId == "storeType") {
      debugger;
    }
    var input = cmp.find(auraId);
    if (!input) {
      return "";
    }

    return input.get("v.value") || "";
  },

  _getKeywords: function(cmp) {
    var reg,
      validObj,
      obj = cmp.find("inputSearchKeyword"),
      val = obj.get("v.value") || "";
    if (!val) {
      return "";
    }

    if (val.indexOf(",") !== -1) {
      val = val.split(",");
    } else {
      reg = new RegExp(/\n|\r\n/g);
      val = val.split(reg);
    }
    reg = new RegExp(/\s/g);
    val = val
      .join("|")
      .replace(reg, "")
      .split("|");

    return val;
  },

  _getChecked: function(cmp, auraId) {
    var chk = cmp.find(auraId);
    if (!chk) {
      return 0;
    }
    return chk.get("v.checked") ? 1 : 0;
  },

  _resetInput: function(cmp, arrAuraId) {
    var input;
    arrAuraId.forEach(function(id) {
      input = cmp.find(id);
      !!input && input.set("v.value", "");
    });
  },

  _resetCheckbox: function(cmp, arrAuraId) {
    var chk;
    arrAuraId.forEach(function(id) {
      chk = cmp.find(id);
      !!chk && chk.set("v.checked", false);
    });
  },

  _hideFilters: function(cmp) {
    var hideFilters = cmp.find("toggleFiltersId");
    if ($A.util.hasClass(hideFilters, "toggleFilters")) {
      $A.util.toggleClass(hideFilters, "toggleFilters");
    }
  }
});