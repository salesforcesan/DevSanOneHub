({
  CMP_STEP2_EVENT: "step2Event",
  CMP_FILE_CONTENT_READY_EVENT: "fileContentReadyEvent",
  CMP_FILE_INVALID_EVENT: "fileContentInvalidEvent",

  helpsChanged: function(cmp) {
    var helps = cmp.get("v.helps") || [];
    if (helps.length === 0) {
      cmp.set("v.guides", []);
    } else {
      cmp.set("v.guides", this._parseGuides(helps));
    }
  },

  schemasChanged: function(cmp) {
    this._init(cmp);

    var schemas = cmp.get("v.schemas") || [];
    if (schemas.length === 0) {
      return;
    }
    this._buildColumns(cmp, schemas);
  },

  fileContentReady: function(cmp, evt) {
    var params = evt.getParams();
    this._handleFileContent(cmp, params.context);
  },

  fileContentInvalid: function(cmp, evt) {
    var params = evt.getParams();
    this._handleFileContentInvalid(cmp, params.context);
  },

  analyzeFile: function(cmp, evt) {
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

    var file = evt.getParam("arguments").file;
    if (!file) {
      this._errorOut(cmp, "The file is not assigned.");
      return;
    }

    this.fileHandler(cmp, file, onSuccess, onError);
  },

  _handleFileContent: function(cmp, content) {
    try {
      var rows = this.parseCSVFile(content, 0);
      var result = this._validateData(cmp, rows);
      var responses = Object.keys(result).map(key => {
        return this._reportOneGroup(key, result[key]);
      });
      var status = 0;
      if (responses.some(e => !e.valid)) {
        this._errorOut(cmp, "The import file has invalid data.");
      } else {
        status = 1;
        this._messageOut(
          cmp,
          "The import file is validated and ready for import."
        );
      }
      this.dispatchEvent(
        cmp,
        this.CMP_STEP2_EVENT,
        this.genCustEvent(this.EVENT_DATA_VALIDATED, {
          status: status,
          result: responses
        })
      );
      cmp.set("v.results", responses);
    } catch (e) {
      this._errorOut(cmp, e.message);
    }
  },

  _handleFileContentInvalid: function(cmp, err) {
    this._errorOut(cmp, err);
  },

  _validateData: function(cmp, content) {
    content.shift();
    var result = {};
    var schemas = cmp.get("v.schemas");
    var groupKeyColumn = this._groupKeyColumn(cmp);
    var groupKeyNameColumn = this._groupKeyNameColumn(cmp);

    var initError = () => {
      var err = {};
      err[this.ERROR_COLUMN_NOT_MATCHED] = 0;
      err[this.ERROR_INVALID_DATE] = 0;
      err[this.ERROR_INVALID_EMPTY] = 0;
      err[this.ERROR_INVALID_NUMBER] = 0;
      err[this.ERROR_INVALID_TIME] = 0;
      err[this.ERROR_INVALID_FLOAT] = 0;
      err[this.ERROR_INVALID_PROJECT] = 0;
      return err;
    };

    //step 2: loop each data record
    var getGroup = rec => {
      var groupId = this.isEmpty(rec[groupKeyColumn])
        ? this.DEFAULT_GROUP_ID
        : rec[groupKeyColumn];

      var group = result[groupId];
      if (!group) {
        group = {
          title: rec[groupKeyNameColumn] || this.DEFAULT_GROUP_TITLE,
          goodJobs: [],
          badJobs: [],
          error: initError()
        };
        result[groupId] = group;
      }
      return group;
    };

    var ensureProjectInProgram = rec => {
      var projectNumber = rec[groupKeyColumn];
      return !this._projects(cmp)[projectNumber] ? 0 : 1;
    };
    for (var i = 0; i < content.length; i++) {
      var rec = content[i];
      var group = getGroup(rec);
      if (rec.length !== schemas.length) {
        group.error[this.ERROR_COLUMN_NOT_MATCHED]++;
        group.badJobs.push(rec);
        continue;
      }

      if (!ensureProjectInProgram(rec)) {
        group.error[this.ERROR_INVALID_PROJECT]++;
        group.badJobs.push(rec);
        continue;
      }

      var hasError = 0;
      for (let index = 0; index < schemas.length; index++) {
        var value = rec[index];
        var element = schemas[index];

        if (this.isEmpty(value)) {
          if (
            element.keyed === 1 ||
            element.groupBy === 1 ||
            element.required === 1
          ) {
            group.error[this.ERROR_INVALID_EMPTY]++;
            hasError = 1;
          }
          break;
        }

        if (!element.updatable) {
          continue;
        }

        switch (element.dataType) {
          case this.DATATYPE_DATE:
            if (!this.checkDate(value)) {
              group.error[this.ERROR_INVALID_DATE]++;
              hasError = 1;
            }
            break;
          case this.DATATYPE_TIME:
            if (!this.checkTime(value)) {
              group.error[this.ERROR_INVALID_TIME]++;
              hasError = 1;
            }
            break;
          case this.DATATYPE_NUMBER:
            if (!this.checkNumber(value)) {
              group.error[this.ERROR_INVALID_NUMBER]++;
              hasError = 1;
            }
            break;
          case this.DATATYPE_DATETIME:
            break;
          case this.DATATYPE_FLOAT:
            if (!this.checkFloat(value)) {
              group.error[this.ERROR_INVALID_FLOAT]++;
              hasError = 1;
            }
            break;
        }
        if (hasError === 1) {
          break;
        }
      }

      if (hasError === 1) {
        group.badJobs.push(rec);
      } else {
        group.goodJobs.push(rec);
      }
    }

    return result;
  },

  _projects: function(cmp) {
    return cmp.get("v.projects") || [];
  },

  _reportOneGroup: function(id, group) {
    var errors = Object.keys(group.error).map(key => {
      return [key, group.error[key]];
    });

    var errCount = group.badJobs.length;
    var genStatus = () => {
      if (errCount === 0) {
        return "Ready for import";
      }
      var data = [];
      for (var i = 0; i < errors.length; i++) {
        var err = errors[i];
        if (err[1] > 0) {
          switch (err[0]) {
            case this.ERROR_INVALID_FLOAT:
              data.push(err[1] + " records with invalid Decimal values.");
              break;
            case this.ERROR_COLUMN_NOT_MATCHED:
              data.push(err[1] + " records with non-matched columns.");
              break;
            case this.ERROR_INVALID_DATE:
              data.push(err[1] + " records with invalid Date values.");
              break;
            case this.ERROR_INVALID_NUMBER:
              data.push(err[1] + " records with invalid Number values.");
              break;
            case this.ERROR_INVALID_TIME:
              data.push(err[1] + " records with invalid Time values.");
              break;
            case this.ERROR_INVALID_EMPTY:
              data.push(err[1] + " records with invalid values.");
              break;
            case this.ERROR_INVALID_PROJECT:
              data.push(
                err[1] +
                  " records with the project not belonged to the program."
              );
              break;
            default:
              data.push("Unknown Error: " + err[0] + ":" + err[1]);
              break;
          }
        }
      }
      return "Import file is invalid: " + data.join(" ");
    };

    return {
      valid: group.badJobs.length === 0 ? 1 : 0,
      groupId: id === this.DEFAULT_GROUP_ID ? "Invalid ID" : id,
      groupTitle: group.title,
      total: group.badJobs.length + group.goodJobs.length,
      status: genStatus(),
      badJobs: group.badJobs,
      goodJobs: group.goodJobs
    };
  },

  _buildColumns: function(cmp, schemas) {
    var def = [
      { label: "Valid", fieldName: "valid", type: "boolean", fixedWidth: 70 }
    ];

    var index = 0;
    schemas.forEach(element => {
      if (element.groupBy === 1) {
        if (element.keyed === 1) {
          cmp.set("v.groupKeyColumn", index);
        } else {
          cmp.set("v.groupKeyNameColumn", index);
        }
        index++;
      }
    });

    var keyColumn = this._groupKeyColumn(cmp);
    var keyNameColumn = this._groupKeyNameColumn(cmp);
    def.push({
      label: keyColumn !== -1 ? schemas[keyColumn].title : "Group ID",
      fieldName: "groupId",
      fixedWidth: 150
    });

    def.push({
      label: keyNameColumn !== -1 ? "Project Title" : "Group Title",
      fieldName: "groupTitle",
      fixedWidth: 200
    });

    def.push({
      label: "Job Count",
      fieldName: "total",
      type: "number",
      fixedWidth: 100
    });
    def.push({ label: "Status", fieldName: "status" });

    cmp.set("v.columns", def);
    cmp.set("v.hasColumns", true);
  },

  _groupKeyColumn: function(cmp) {
    return cmp.get("v.groupKeyColumn");
  },

  _groupKeyNameColumn: function(cmp) {
    return cmp.get("v.groupKeyNameColumn");
  },

  _init: function(cmp) {
    cmp.set("v.columns", []);
    cmp.set("v.groupKeyColumn", -1);
    cmp.set("v.groupKeyNameColumn", -1);
  },

  _parseGuides: function(helps) {
    var id = 1;
    return helps.map(g => {
      return {
        id: id++,
        guide: g
      };
    });
  },

  _errorOut: function(cmp, msg) {
    this._msgBoxWithTitle("error", msg, "Validate Data");
    this._hideBusyIndicator(cmp);
  },

  _messageOut: function(cmp, msg) {
    this._msgBoxWithTitle("success", msg, "Validate Data");
    this._hideBusyIndicator(cmp);
  },

  _hideBusyIndicator: function(cmp) {
    this.dispatchEvent(
      cmp,
      this.CMP_STEP2_EVENT,
      this.genCustEvent(this.EVENT_BUSY_INDICATOR, {
        busy: 0
      })
    );
  }
});