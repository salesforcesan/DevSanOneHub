({
  CMP_STEP3_EVENT: "step3Event",

  init: function(cmp) {
    cmp.set("v.columns", [
      {
        label: "",
        fieldName: "done",
        type: "boolean",
        fixedWidth: 30,
        cellAttributes: { alignment: "center" }
      },
      {
        label: "Project Number",
        fieldName: "groupId",
        fixedWidth: 150
      },
      {
        label: "Project Title",
        fieldName: "groupTitle",
        fixedWidth: 200
      },
      {
        label: "Job Count",
        fieldName: "jobCount",
        type: "number",
        fixedWidth: 100
      },
      { label: "Status", fieldName: "status", fixedWidth: 80 },
      { label: "Message", fieldName: "message" }
    ]);
  },

  initUploadFile: function(cmp, evt) {
    this._setResults(cmp, []);
    var aggregateResult = evt.getParam("arguments").aggregateResult;
    this._async(
      cmp,
      cmp => {
        this._setUploadData(cmp, this._transformResult(aggregateResult));
        this._setResults(cmp, this._genResult(cmp));
        this._hideBusy(cmp);
      },
      1
    );
  },

  uploadFile: function(cmp, evt) {
    var args = evt.getParam("arguments");
    var datasourceId = args.datasourceId;
    this._setStopImport(cmp, args.stopImport);
    this._setChunkSize(cmp, args.chunkSize);

    if (!!this._requestQueue(cmp) && this._hasRequestDef(cmp)) {
      this._chunkAndUploadData(cmp);
      return;
    }

    var onSuccess = (cmp, queue) => {
      this._setRequestQueue(cmp, queue);
      this._setRequestDef(cmp, queue);
      this._chunkAndUploadData(cmp);
    };
    var onError = (cmp, error) => {
      this._msgBox("error", JSON.stringify(error));
      this._hideBusy(cmp);
    };

    this.getDispatcher(cmp)
      .action("createRequestQueue")
      .onSuccess(onSuccess)
      .onError(onError)
      .run({ datasource: datasourceId });
  },

  _chunkAndUploadData: function(cmp) {
    var firstTime = 1;
    if (!this._currentProject(cmp)) {
      this._setCurrentProject(cmp, this._getNextOneInitProject(cmp));
    } else if (this._currentProject(cmp).status !== "Ready") {
      firstTime = 0;
      this._setResults(cmp, this._genResult(cmp));
      this._setCurrentProject(cmp, this._getNextOneInitProject(cmp));
    }

    if (this._currentProject(cmp)) {
      var project = this._currentProject(cmp);
      if (!this._isProjectValid(cmp, project.groupId)) {
        project.status = "Error";
        project.message = "The project does not belong to the program";
        this._chunkAndUploadData(cmp);
        return;
      }
      if (firstTime) {
        this._processProject(cmp, project);
      } else {
        this._async(
          cmp,
          cmp => {
            this._processProject(cmp, project);
          },
          1
        );
      }
      return;
    }
    var result = this._analyzeLoadResult(cmp);
    switch (result.status) {
      case 1: //success
        this._batchSubmitQueue(cmp, result.status, result.message);
        break;
      case 2: //partial success
        if (this._stopImport(cmp) !== 1) {
          this._batchSubmitQueue(cmp, result.status, result.message);
        } else {
          this._rollbackChanges(cmp, result.status, result.message);
        }
        break;
      default:
        //failed
        this._rollbackChanges(cmp, result.status, result.message);
        break;
    }
  },

  _analyzeLoadResult: function(cmp) {
    var uploadData = this._uploadData(cmp);
    var queueCount = uploadData.filter(p => p.status === "Queued").length;
    var otherCount = uploadData.length - queueCount;
    if (otherCount === 0) {
      return {
        status: 1,
        message: "The file is uploaded and queued successfully."
      };
    }
    if (queueCount > 0) {
      return {
        status: 2,
        message:
          "The file is not uploaded completedly. Some jobs are not uploaded."
      };
    }
    return {
      status: 0,
      message: "The jobs in the file are invalid."
    };
  },

  _batchSubmitQueue: function(cmp, status, message) {
    var onSuccess = (cmp, result) => {
      var queue = this._requestQueue(cmp);
      queue.status = "Queued";
      this._setRequestQueue(cmp, queue);
      this._setRequestDef(cmp, queue);
      this._notifyFileUploaded(cmp, status, message);
    };

    var onError = (cmp, error) => {
      var status = 0;
      var message = error.body.message;
      this._notifyFileUploaded(cmp, status, message);
    };
    var queueId = this._requestQueue(cmp).queueId;
    this.getDispatcher(cmp)
      .action("submitQueue")
      .onSuccess(onSuccess)
      .onError(onError)
      .run({ queueId: queueId });
  },

  _notifyFileUploaded: function(cmp, status, message) {
    this.dispatchEvent(
      cmp,
      this.CMP_STEP3_EVENT,
      this.genCustEvent(this.EVENT_FILE_UPLOADED, {
        status: status,
        message: message
      })
    );
  },

  _rollbackChanges: function(cmp, status, message) {
    var onSuccess = (cmp, result) => {
      this._setRequestDef(cmp, []);
      this._notifyFileUploaded(cmp, status, message);
    };
    var onError = (cmp, error) => {
      message = [message, error.body.message].join(" ");
      this._notifyFileUploaded(cmp, status, message);
    };
    this.getDispatcher(cmp)
      .action("deleteQueue")
      .onSuccess(onSuccess)
      .onError(onError)
      .run({ queueId: this._requestQueue(cmp).queueId });
  },

  _processProject: function(cmp, project) {
    var projectQueued = () => {
      project.status = "Queued";
      project.message = "The project is queued";
      project.done = true;
      this._updateUploadData(cmp, project);
    };

    if (project.cursor > project.jobCount) {
      projectQueued();
      this._chunkAndUploadData(cmp);
      return;
    }
    var cursor = project.cursor,
      goodJobs = project.goodJobs;
    var content = goodJobs.slice(cursor, cursor + this._chunkSize(cmp));
    if (content.length === 0) {
      projectQueued();
      this._chunkAndUploadData(cmp);
      return;
    }

    project.cursor = cursor + this._chunkSize(cmp);
    var projectId = this._projects(cmp)[project.groupId];
    var queueId = this._requestQueue(cmp).queueId;

    var onSuccess = (cmp, result) => {
      if (result.status === 1) {
        this._processProject(cmp, project);
      } else {
        project.status = "Error";
        project.message = result.message;
        this._updateUploadData(cmp, project);
        this._chunkAndUploadData(cmp);
      }
    };

    var onError = (cmp, error) => {
      project.status = "Error";
      project.message = error;
      this._updateUploadData(cmp, project);
      this._chunkAndUploadData(cmp);
    };

    this.getDispatcher(cmp)
      .action("addRequestQueueItem")
      .onSuccess(onSuccess)
      .onError(onError)
      .run({
        queueId: queueId,
        projectId: projectId,
        content: content
      });
  },

  _isProjectValid: function(cmp, projectNumber) {
    return !!this._projects(cmp)[projectNumber];
  },

  _projects: function(cmp) {
    return cmp.get("v.projects") || {};
  },

  _currentProject: function(cmp) {
    return cmp.get("v.currentProject");
  },

  _setCurrentProject: function(cmp, project) {
    cmp.set("v.currentProject", project);
  },

  _requestQueue: function(cmp) {
    return cmp.get("v.requestQueue");
  },

  _setRequestQueue: function(cmp, queue) {
    cmp.set("v.requestQueue", queue);
  },

  _hasRequestDef: function(cmp) {
    var def = this._requestDef(cmp);
    return def.length > 0;
  },

  _requestDef: function(cmp) {
    return cmp.get("v.requestDef") || [];
  },

  _setRequestDef: function(cmp, queue) {
    cmp.set("v.requestDef", [
      { name: "Name", value: queue.name },
      { name: "Status", value: queue.status },
      { name: "Request Date", value: queue.queueDate },
      { name: "Requestor", value: queue.requestor }
    ]);
    cmp.set("v.hasRequestDef", true);
  },

  _setStopImport: function(cmp, value) {
    cmp.set("v.stopImport", value);
  },

  _stopImport: function(cmp) {
    return cmp.get("v.stopImport");
  },

  _setChunkSize: function(cmp, chunkSize) {
    cmp.set("v.chunkSize", chunkSize);
  },

  _chunkSize: function(cmp) {
    return cmp.get("v.chunkSize");
  },

  _errorOut: function(cmp, error) {
    this._msgBoxWithTitle("error", error, "Upload File for Processing");
  },

  _hideBusy: function(cmp) {
    this.dispatchEvent(
      cmp,
      this.CMP_STEP3_EVENT,
      this.genCustEvent(this.EVENT_BUSY_INDICATOR, {
        busy: 0
      })
    );
  },

  _transformResult: function(results) {
    var index = 0;
    return results.map(el => {
      var message =
        el.badJobs.length > 0
          ? [
              el.goodJobs.length,
              "jobs will be imported.",
              el.badJobs.length,
              "invalid jobs are skipped."
            ].join(" ")
          : [el.goodJobs.length, "jobs will be imported"].join(" ");

      return {
        id: index++,
        done: false,
        groupId: el.groupId,
        groupTitle: el.groupTitle,
        jobCount: el.goodJobs.length,
        status: "Ready",
        cursor: 0,
        badJobs: el.badJobs,
        goodJobs: el.goodJobs,
        message: message
      };
    });
  },

  _genResult: function(cmp) {
    return this._uploadData(cmp).map(r => {
      return {
        done: r.done,
        groupId: r.groupId,
        groupTitle: r.groupTitle,
        jobCount: r.jobCount,
        status: r.status,
        message: r.message
      };
    });
  },

  _setResults: function(cmp, results) {
    cmp.set("v.results", results);
  },

  _getNextOneInitProject: function(cmp) {
    var initQ = this._uploadData(cmp).filter(r => r.status === "Ready");
    return initQ.length > 0 ? initQ[0] : null;
  },

  _updateUploadData: function(cmp, oneRecord) {
    var uploadData = this._uploadData(cmp);
    for (var i = 0; i < uploadData.length; i++) {
      if (uploadData[i].id === oneRecord.id) {
        uploadData[i] = oneRecord;
        break;
      }
    }
    this._setUploadData(cmp, uploadData);
  },

  _setUploadData: function(cmp, uploadData) {
    cmp.set("v.uploadData", uploadData);
  },

  _uploadData: function(cmp) {
    return cmp.get("v.uploadData");
  }
});