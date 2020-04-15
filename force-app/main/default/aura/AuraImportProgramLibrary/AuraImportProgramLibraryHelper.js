({
  SELECT_DATASOURCE: 1,
  VALIDATE_DATASOURCE: 2,
  UPLOAD_FILE_FOR_PROCESS: 3,
  EVENT_LAST_STEP: "laststep",
  EVENT_NEXT_STEP: "nextstep",
  EVENT_PREVIOUS_STEP: "previousstep",
  EVENT_SUBMIT_STEP: "submit",
  EVENT_CANCEL_STEP: "cancel",
  EVENT_CLOSE_DIALOG: "close",
  EVENT_FILE_UPLOADED: "fileuploaded",
  EVENT_FILE_CHANGED: "filechanged",
  EVENT_FILE_CONTENT: "filecontent",
  EVENT_FILE_INVALID: "invalidfile",
  EVENT_DATA_VALIDATED: "validated",
  EVENT_BUSY_INDICATOR: "busy",
  STAGE_FILE_SELECT: 1,
  STAGE_FILE_SELECTED: 2,
  STAGE_FILE_VALIDATE: 3,
  STAGE_FILE_VALIDATED: 4,
  STAGE_FILE_UPLOAD: 5,
  STAGE_FILE_UPLOADED: 6,
  ERROR_COLUMN_NOT_MATCHED: "1",
  ERROR_INVALID_DATE: "2",
  ERROR_INVALID_TIME: "3",
  ERROR_INVALID_NUMBER: "5",
  ERROR_INVALID_EMPTY: "4",
  ERROR_INVALID_FLOAT: "6",
  ERROR_INVALID_PROJECT: "7",
  DEFAULT_GROUP_ID: "__default",
  DEFAULT_GROUP_TITLE: "Default Group",
  DATATYPE_TEXT: "Text",
  DATATYPE_NUMBER: "Number",
  DATATYPE_FLOAT: "Float",
  DATATYPE_DATE: "Date",
  DATATYPE_TIME: "Time",
  DATATYPE_DATETIME: "DateTime",

  genStep: function(id, label, flag) {
    return { id, label, flag };
  },

  genCustEvent: function(type, detail) {
    return {
      id: type,
      context: detail || {}
    };
  },

  dispatchEvent: function(cmp, name, custEvent) {
    var msg = cmp.getEvent(name);
    msg.setParams(custEvent);
    msg.fire();
  },

  isEmpty: function(value) {
    if (!value) {
      return true;
    }
    var v = this.trim(value);
    return v.length === 0;
  },

  fileHandler: function(cmp, file, onSuccess, onError) {
    var self = this;
    var reader = new FileReader();
    reader.onload = () => {
      onSuccess && onSuccess.call(self, cmp, reader.result);
    };
    reader.onerror = () => {
      onError && onError.call(self, cmp, reader.error);
    };
    reader.readAsText(file);
  },

  // headerOnly should be default = 0
  parseCSVFile: function(content, headerOnly) {
    var data = (content || "").split(/\n|\r|\r\n/g);
    if (!data || data.length === 0) {
      throw new Error("There are no data in the file for importing data.");
    }

    var pattern = new RegExp('"', "g");
    function doubleQuoteRemover(row) {
      return !!row && row.indexOf('"') !== -1 ? row.replace(pattern, "") : row;
    }

    if (headerOnly !== 0) {
      var row = data[0];
      return row.split(",").map(c => {
        return doubleQuoteRemover(c);
      });
    }

    return data
      .filter(row => {
        return (row || "").length > 0 && row.split(",").length > 1;
      })
      .map(row => {
        return row.split(",").map(c => {
          return doubleQuoteRemover(c);
        });
      });
  },

  genMatchResult: function(id, order, matched, schema, title) {
    return {
      id: id,
      order: order,
      matched: matched,
      schema: schema,
      title: title
    };
  },

  checkTitleCount: function(titles, schemas) {
    if (titles.length !== schemas.length) {
      return;
      [
        "The import file is invalid. The import file must have",
        schemas.length,
        "columns but the selected file has",
        titles.length,
        "columns."
      ].join(" ");
    }
    return "";
  },

  trim: function(v) {
    return (v + "").trim();
  },

  checkTime: function(tm) {
    return /(1[0-2]|0?[1-9]):[0-5][0-9] ([AaPp][Mm])/.test(this.trim(tm));
  },

  checkNumber: function(number) {
    return /^-?[0-9]+$/.test(this.trim(number));
  },

  checkFloat: function(float) {
    var v = this.trim(float);
    return Number(v) === parseFloat(v);
  },

  checkDate: function(dt) {
    var v = this.trim(dt);
    return (
      /\d\d\d\d-\d\d?-\d\d?|\d\d?\/\d\d?\/\d\d\d\d/.test(v) &&
      !isNaN(Date.parse(v))
    );
  },

  checkDatetime: function() {
    return false;
  },

  analyzeFileSchema: function(titles, schemas) {
    var results = [];
    var title, schema, matched;
    var error = this.checkTitleCount(titles, schemas);
    var errColumns = [];

    for (var index = 0; index < schemas.length; index++) {
      title = index < titles.length ? titles[index] : "";
      schema = schemas[index].title + "";
      matched = title.toLowerCase() === schema.toLowerCase();
      if (!matched) {
        errColumns.push(title);
      }
      results.push(this.genMatchResult(index, index, matched, schema, title));
    }

    if (errColumns.length > 0) {
      error =
        [error, "These columns are not matched:", errColumns.join(",")].join(
          " "
        ) + ".";
    }
    return {
      succeeded: error === "",
      error: error,
      results: results
    };
  }
});