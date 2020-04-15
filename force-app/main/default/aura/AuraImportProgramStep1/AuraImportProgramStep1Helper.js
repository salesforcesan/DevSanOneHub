({
  CMP_STEP1_EVENT: "step1Event",

  init: function(cmp) {
    this._setFileInfo(cmp, "success", "utility:check");
    this._initSchemas(cmp);
    this._setFileProps(cmp, "", "", "");
  },

  errorChanged: function(cmp) {
    this._setError(cmp, cmp.get("v.error"));
  },

  resultsChanged: function(cmp) {
    var results = cmp.get("v.results") || [];
    cmp.set("v.hasResults", results.length > 0 ? true : false);
  },

  fileChanged: function(cmp, evt) {
    var file = evt.currentTarget.files[0];
    this.dispatchEvent(
      cmp,
      this.CMP_STEP1_EVENT,
      this.genCustEvent(this.EVENT_BUSY_INDICATOR, {
        help: "Validating Schemas...",
        busy: 1
      })
    );
    this._async(
      cmp,
      cmp => {
        this._setFileProps(
          cmp,
          file.name,
          file.type,
          Math.ceil(file.size / 1024) + "KB"
        );
        this._setShowFileInfo(cmp, true);
        this._validateFile(cmp, file);
        if (this._hasError(cmp)) {
          this.dispatchEvent(
            cmp,
            this.CMP_STEP1_EVENT,
            this.genCustEvent(this.EVENT_FILE_INVALID)
          );
        }
        this.dispatchEvent(
          cmp,
          this.CMP_STEP1_EVENT,
          this.genCustEvent(this.EVENT_FILE_CHANGED, file)
        );
      },
      5
    );
  },

  fileSelected: function(cmp, evt) {
    cmp
      .find("inputFile")
      .getElement()
      .click();
  },

  _validateFile: function(cmp, file) {
    var fileName = (file.name || "").toLowerCase();
    if (
      [".txt", ".csv"].some(ext => {
        return fileName.indexOf(ext) !== -1;
      })
    ) {
      this._setError(cmp, "");
    } else {
      this._setError(
        cmp,
        "The upload file type is invalid. The CSV and Text files are supported. The file extension must be either .csv or .txt"
      );
    }
  },

  _setShowFileInfo: function(cmp, visible) {
    cmp.set("v.showFileInfo", visible);
  },

  _hasError: function(cmp) {
    return cmp.get("v.hasError");
  },

  _setError: function(cmp, err) {
    if (this.isEmpty(err)) {
      cmp.set("v.hasError", false);
      cmp.set("v.errorMsg", "");
      this._setFileInfo(cmp, "success", "doctype:csv");
    } else {
      cmp.set("v.hasError", true);
      cmp.set("v.errorMsg", err);
      this._setFileInfo(cmp, "error", "utility:error");
    }
  },

  _setFileInfo: function(cmp, variant, icon) {
    cmp.set("v.fileInfo", {
      class: "slds-box",
      variant: variant,
      icon: icon
    });
  },
  _setFileProps: function(cmp, name, type, size) {
    cmp.set("v.fileProps", [
      { name: "FileName", value: name },
      { name: "FileType", value: type },
      { name: "FileSize", value: size }
    ]);
  },
  _initSchemas: function(cmp) {
    cmp.set("v.schemas", [
      {
        label: "Matched",
        fieldName: "matched",
        type: "boolean",
        fixedWidth: 80
      },
      { label: "Column#", fieldName: "order", type: "number", fixedWidth: 80 },
      { label: "Title", fieldName: "schema" },
      { label: "Import File Title", fieldName: "title" }
    ]);
  }
});