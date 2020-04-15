({
  CMP_CLOSE_EVENT: "closeEvent",
  CMP_FILE_CONTENT_READY_EVENT: "fileContentEvent",
  CMP_FILE_INVALID_EVENT: "fileInvalidEvent",

  init: function(cmp) {
    this._setNextEnabled(cmp, false);
    this._setSteps(cmp, this._genSteps());
    this._loadProjects(cmp);
  },

  heightChanged: function(cmp) {
    cmp.set("v.custStyle", ["height:", cmp.get("v.height"), "px;"].join(""));
  },

  cancel: function(cmp) {
    this.dispatchEvent(
      cmp,
      this.CMP_CLOSE_EVENT,
      this.genCustEvent(this.EVENT_CLOSE_DIALOG, 1)
    );
  },

  close: function(cmp) {
    this.cancel(cmp);
  },

  submit: function(cmp) {
    this._showAppBusy(cmp);
    this._async(
      cmp,
      cmp => {
        var step3 = cmp.find("step3Control");
        var datasource = this._datasource(cmp);
        step3.uploadFile(
          datasource.id,
          datasource.chunkSize,
          datasource.stopImport
        );
      },
      5
    );
  },

  stepFooterEvent: function(cmp, evt) {
    var params = evt.getParams();
    switch (params.id) {
      case this.EVENT_LAST_STEP:
        this._handleLastStep(cmp);
        break;
      case this.EVENT_NEXT_STEP:
        this._handleNextStep(cmp, params.context);
        break;
      case this.EVENT_PREVIOUS_STEP:
        this._handlePrevious(cmp, params.context);
        break;
      case this.EVENT_CANCEL_STEP:
        this.cancel(cmp);
        break;
    }
  },

  step3Event: function(cmp, evt) {
    var params = evt.getParams();
    switch (params.id) {
      case this.EVENT_BUSY_INDICATOR:
        this._handleBusy(cmp, params.context);
        break;
      case this.EVENT_FILE_UPLOADED:
        this._endUploadFile(cmp, params.context);
        break;
    }
  },

  step1Event: function(cmp, evt) {
    var params = evt.getParams();
    switch (params.id) {
      case this.EVENT_BUSY_INDICATOR:
        this._handleBusy(cmp, params.context);
        break;
      case this.EVENT_FILE_CHANGED:
        this._handleFileChanged(cmp, params.context);
        break;
      case this.EVENT_FILE_INVALID:
        this._handleInvalidFile(cmp);
        break;
    }
  },

  step2Event: function(cmp, evt) {
    var params = evt.getParams();
    switch (params.id) {
      case this.EVENT_BUSY_INDICATOR:
        this._handleBusy(cmp, params.context);
        break;
      case this.EVENT_DATA_VALIDATED:
        this._endValidteFileData(cmp, params.context);
        break;
    }
  },

  fileContentReady: function(cmp, evt) {
    var content = evt.getParams().context;
    this._handleFileContent(cmp, content);
  },

  fileInvalid: function(cmp, evt) {
    var error = evt.getParams().context;
    this._setNextEnabled(cmp, false);
    this._setFileError(cmp, error);
    this._hideAppBusy(cmp);
  },

  //private method
  _beginValidateFileData: function(cmp) {
    var file = this._file(cmp);
    this._showAppBusy(cmp);
    this._setAppState(cmp, this.STAGE_FILE_VALIDATE);
    this._async(
      cmp,
      cmp => {
        cmp.find("step2Control").analyzeFile(file);
      },
      1
    );
  },

  _loadProjects: function(cmp) {
    if (!this._recordId(cmp)) {
      console.log("Error", "The program record id is not assigned.");
      return;
    }

    var recordId = this._recordId(cmp);
    this._showAppBusy(cmp);

    this.getDispatcher(cmp)
      .action("getProgram")
      .onSuccess((cmp, response) => {
        this._setTitle(cmp, "Import Jobs - " + response.name);
        this._setDatasource(cmp, response.datasource);
        this._setProjects(
          cmp,
          this._transformProjectIdNumbers(response.projects)
        );
        this._hideAppBusy(cmp);
      })
      .onError((cmp, error) => {
        this._msgBoxWithTitle(cmp, "error", error, "Validate Program");
        this._hideAppBusy(cmp);
      })
      .run({ recordId: recordId });
  },

  _transformProjectIdNumbers: function(projects) {
    var value = {};
    for (var p of projects) {
      if (p.length === 2) {
        value[p[0]] = p[1];
      }
    }
    return value;
  },

  _setProjects: function(cmp, projects) {
    cmp.set("v.projects", projects);
  },

  _recordId: function(cmp) {
    return cmp.get("v.recordId");
  },

  _setTitle: function(cmp, title) {
    cmp.set("v.title", title);
  },

  _endValidteFileData: function(cmp, detail) {
    var result = detail.result;
    var status = detail.status;

    this._setAppState(cmp, this.STAGE_FILE_VALIDATED);
    if (status === 0) {
      this._setNextEnabled(cmp, this._datasource(cmp).stopImport !== 1);
      this._setValidatedResult(cmp, null);
    } else {
      this._setNextEnabled(cmp, true);
      this._setValidatedResult(cmp, result);
    }

    this._hideAppBusy(cmp);
  },

  _handleFileContent: function(cmp, content) {
    try {
      var titles = this.parseCSVFile(content, 1);
      var schemas = this._datasource(cmp).schemas;
      if (!schemas) {
        this._msgBoxWithTitle(
          "error",
          "There is no schemas defined for this import file. Please contact system adminstrator.",
          "Validate Schema"
        );
        this._hideAppBusy(cmp);
        return;
      }
      var analysis = this.analyzeFileSchema(titles, schemas);
      this._setSchemaAnalysis(cmp, analysis.results);
      if (analysis.succeeded) {
        this._setNextEnabled(cmp, true);
        this._setAppState(cmp, this.STAGE_FILE_SELECTED);
      } else {
        this._setFileError(cmp, analysis.error);
        this._setNextEnabled(cmp, false);
      }
    } catch (e) {
      this._setNextEnabled(cmp, false);
      this._setFileError(cmp, e);
    }
    this._hideAppBusy(cmp);
  },

  _handleFileChanged: function(cmp, file) {
    function onSuccess(cmp, content) {
      this.dispatchEvent(
        cmp,
        this.CMP_FILE_CONTENT_READY_EVENT,
        this.genCustEvent(this.EVENT_FILE_CONTENT, content)
      );
    }

    function onError(cmp, error) {
      this.dispatchEvent(
        cmp,
        this.CMP_FILE_INVALID_EVENT,
        this.genCustEvent(this.EVENT_FILE_INVALID, error)
      );
    }

    this._setFile(cmp, file);
    if (!file) {
      console.log("--no file to process--");
      return;
    }
    this._setFileError(cmp, "");
    this._setAppState(cmp, this.STAGE_FILE_SELECT);
    this.fileHandler(cmp, file, onSuccess, onError);
  },

  _setSchemaAnalysis: function(cmp, results) {
    cmp.set("v.schemaAnalysis", results);
  },

  _schemaAnalysis: function(cmp) {
    return cmp.get("v.schemaAnalysis") || [];
  },

  _handleInvalidFile: function(cmp) {
    this._setFile(cmp, null);
    this._setNextEnabled(cmp, false);
    this._hideAppBusy(cmp);
  },

  _setFileError: function(cmp, err) {
    cmp.set("v.fileError", err);
  },

  _setFile: function(cmp, file) {
    cmp.set("v.file", file);
  },

  _file: function(cmp) {
    return cmp.get("v.file");
  },

  _handleBusy: function(cmp, result) {
    if (result.busy === 1) {
      this._setBusyAlternativeText(cmp, result.help || "processing...");
      this._showAppBusy(cmp);
    } else {
      this._setBusyAlternativeText(cmp, "processing...");
      this._hideAppBusy(cmp);
    }
  },

  _beginUploadFile: function(cmp) {
    this._showAppBusy(cmp);
    this._setAppState(cmp, this.STAGE_FILE_UPLOAD);
    this._async(
      cmp,
      cmp => {
        var result = this._validatedResult(cmp).filter(
          el => el.goodJobs.length > 0
        );
        cmp.find("step3Control").initUploadFile(result);
      },
      5
    );
  },

  _endUploadFile: function(cmp, result) {
    this._setAppState(cmp, this.STAGE_FILE_UPLOADED);
    var msgType = result.status === 1 ? "success" : "error",
      message = result.message;
    this._msgBoxWithTitle(msgType, message, "Import Jobs");
    this._setShowSubmitButton(cmp, false);
    this._setShowClose(cmp, true);
    this._hideAppBusy(cmp);
  },

  _setShowClose: function(cmp, visible) {
    cmp.set("v.showClose", visible);
  },

  _handleNextStep: function(cmp, step) {
    var appState = this._appState(cmp);
    this._showStep(cmp, step);
    switch (step) {
      case this.VALIDATE_DATASOURCE:
        if (appState < this.STAGE_FILE_VALIDATED) {
          this._beginValidateFileData(cmp);
        } else if (appState === this.STAGE_FILE_VALIDATED) {
          this._setNextEnabled(cmp, this._datasource(cmp).stopImport !== 1);
        }
        break;
      case this.UPLOAD_FILE_FOR_PROCESS:
        if (this._appState(cmp) < this.STAGE_FILE_UPLOADED) {
          this._beginUploadFile(cmp);
        }
        break;
    }
  },

  _handlePrevious: function(cmp, step) {
    this._showStep(cmp, step);
    this._setNextEnabled(cmp, true);
  },

  _handleLastStep: function(cmp) {
    this._setShowSubmitButton(cmp, true);
    this._setHideFootStepper(cmp, true);
  },

  _setShowSubmitButton: function(cmp, visible) {
    cmp.set("v.showSubmitButton", visible);
  },

  _setHideFootStepper: function(cmp, hidden) {
    cmp.set("v.hideSteps", hidden);
  },

  _showStep: function(cmp, step) {
    switch (step) {
      case this.SELECT_DATASOURCE:
        cmp.set("v.step1Class", "slds-is-expanded");
        cmp.set("v.step2Class", "slds-is-collapsed");
        cmp.set("v.step3Class", "slds-is-collapsed");
        break;
      case this.VALIDATE_DATASOURCE:
        cmp.set("v.step2Class", "slds-is-expanded");
        cmp.set("v.step1Class", "slds-is-collapsed");
        cmp.set("v.step3Class", "slds-is-collapsed");
        break;
      case this.UPLOAD_FILE_FOR_PROCESS:
        cmp.set("v.step3Class", "slds-is-expanded");
        cmp.set("v.step1Class", "slds-is-collapsed");
        cmp.set("v.step2Class", "slds-is-collapsed");
        break;
    }
  },

  _validatedResult: function(cmp) {
    return cmp.get("v.validatedResult");
  },

  _setValidatedResult: function(cmp, result) {
    cmp.set("v.validatedResult", result || []);
  },

  _datasource: function(cmp) {
    return cmp.get("v.datasource");
  },

  _setDatasource: function(cmp, datasource) {
    cmp.set("v.datasource", datasource);
  },

  _showAppBusy: function(cmp) {
    cmp.set("v.isAppBusy", true);
  },

  _hideAppBusy: function(cmp) {
    this._async(
      cmp,
      cmp => {
        cmp.set("v.isAppBusy", false);
      },
      230
    );
  },

  _setBusyAlternativeText: function(cmp, help) {
    cmp.set("v.busyAlternativeText", help);
  },

  _setSteps: function(cmp, steps) {
    cmp.set("v.steps", steps);
  },

  _steps: function(cmp) {
    return cmp.get("v.steps");
  },

  _setNextEnabled: function(cmp, enabled) {
    cmp.set("v.nextEnabled", enabled);
  },

  _nextEnabled: function(cmp) {
    return cmp.get("v.nextEabled");
  },

  _appState: function(cmp) {
    return cmp.get("v.appState");
  },

  _setAppState: function(cmp, state) {
    cmp.set("v.appState", state);
  },

  _genSteps: function() {
    return [
      { id: this.SELECT_DATASOURCE, label: "Step 1: Select File", flag: 1 },
      { id: this.VALIDATE_DATASOURCE, label: "Step 2: Validate File", flag: 0 },
      {
        id: this.UPLOAD_FILE_FOR_PROCESS,
        label: "Step 3: Upload File For Processing",
        flag: 0
      }
    ];
  }
});