({
  CMP_STEP_EVENT: "stepFooterEvent",

  init: function(cmp) {
    var marginGap = cmp.get("v.marginGap");
    if (!!marginGap) {
      cmp.set("v.hasGap", true);
      cmp.set(
        "v.style",
        ["margin-left:", marginGap, ";margin-right:", marginGap, ";"].join("")
      );
    }
  },

  nextEnabledChanged: function(cmp, evt) {
    if (cmp.get("v.nextEnabled")) {
      cmp.set("v.isNextDead", cmp.get("v.nextDisabled"));
    } else {
      cmp.set("v.isNextDead", true);
    }
  },

  stepDefsChanged: function(cmp, evt) {
    var stepFlag = false;
    var currentId = 0;

    var steps = (cmp.get("v.stepDefs") || []).map(el => {
      return {
        id: el.id,
        label: el.label,
        flag: el.flag
      };
    });

    if (steps.length > 0) {
      steps.forEach(el => {
        if (el.flag === 1) {
          currentId = el.id;
          stepFlag = true;
        }
      });

      if (!stepFlag) {
        currentId = steps[0].id;
        steps[0].flag = 1;
      }
    }

    cmp.set("v.hasSteps", steps.length > 0);
    cmp.set("v.currentStep", currentId);
    cmp.set("v.steps", steps);
    if (this._isFirstStep(cmp)) {
      cmp.set("v.prevDisabled", true);
    }
  },

  nextClicked: function(cmp) {
    if (
      !this._hasSteps(cmp) ||
      this._hasOneStep(cmp) ||
      this._isNextDisabled(cmp)
    ) {
      return;
    }

    var currentStep = this._currentStep(cmp);
    cmp.set("v.prevDisabled", false);
    var cursor = this._steps(cmp).findIndex(step => step.id === currentStep);
    cmp.set("v.currentStep", this._toStep(cmp, cursor + 1).id);
    this._resetStep(cmp);

    if (this._isLastStep(cmp)) {
      cmp.set("v.nextDisabled", false);
      this.dispatchEvent(
        cmp,
        this.CMP_STEP_EVENT,
        this.genCustEvent(this.EVENT_LAST_STEP, this._currentStep(cmp))
      );
    } else {
      cmp.set("v.nextDisabled", false);
    }

    this.dispatchEvent(
      cmp,
      this.CMP_STEP_EVENT,
      this.genCustEvent(this.EVENT_NEXT_STEP, this._currentStep(cmp))
    );
  },

  prevClicked: function(cmp) {
    if (
      !this._hasSteps(cmp) ||
      this._hasOneStep(cmp) ||
      this._isPrevDisabled(cmp)
    ) {
      return;
    }

    var currentStep = this._currentStep(cmp);
    var cursor = this._steps(cmp).findIndex(step => step.id === currentStep);
    cmp.set("v.nextDisabled", false);
    cmp.set("v.currentStep", this._toStep(cmp, cursor - 1).id);
    this._resetStep(cmp);
    cmp.set("v.prevDisabled", this._isFirstStep(cmp));
    this.dispatchEvent(
      cmp,
      this.CMP_STEP_EVENT,
      this.genCustEvent(this.EVENT_PREVIOUS_STEP, this._currentStep(cmp))
    );
  },

  cancelClicked: function(cmp) {
    this.dispatchEvent(
      cmp,
      this.CMP_STEP_EVENT,
      this.genCustEvent(this.EVENT_CANCEL_STEP, 0)
    );
  },

  captureEvents: function(evt) {
    evt.preventDefault();
    evt.stopPropagation();
  },

  _hasSteps: function(cmp) {
    return this._steps(cmp).length > 0;
  },

  _hasOneStep: function(cmp) {
    return this._steps(cmp).length === 1;
  },

  _isNextDisabled: function(cmp) {
    return cmp.get("v.nextDisabled");
  },

  _isPrevDisabled: function(cmp) {
    return cmp.get("v.prevDisabled");
  },

  _isLastStep: function(cmp) {
    var steps = this._steps(cmp);
    return steps[steps.length - 1].id === cmp.get("v.currentStep");
  },

  _isFirstStep: function(cmp) {
    return this._steps(cmp)[0].id == cmp.get("v.currentStep");
  },

  _resetStep: function(cmp) {
    var steps = this._steps(cmp);
    var currentStep = cmp.get("v.currentStep");
    cmp.set(
      "v.steps",
      steps.map(e => {
        return {
          id: e.id,
          label: e.label,
          flag: e.id === currentStep ? 1 : 0
        };
      })
    );
  },

  _hasOneStep: function(cmp) {
    return this._steps(cmp).length === 1;
  },

  _steps: function(cmp) {
    return cmp.get("v.steps") || [];
  },

  _currentStep: function(cmp) {
    return cmp.get("v.currentStep");
  },

  _isFirstStep: function(cmp) {
    var steps = cmp.get("v.steps") || [];
    if (steps.length === 0) return true;
    return cmp.get("v.currentStep") === steps[0].id;
  },

  _toStep: function(cmp, cursor) {
    var step = cmp.get("v.steps")[cursor];
    return {
      id: step.id,
      label: step.label,
      flag: step.flag
    };
  }
});