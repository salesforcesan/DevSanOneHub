/* eslint-disable no-console */
/* eslint-disable no-alert */
import { LightningElement, api, track } from "lwc";
import {
  genCustEvent,
  EVENT_FILE_CHANGED,
  isEmpty,
  EVENT_FILE_INVALID,
  defer,
  EVENT_BUSY_INDICATOR
} from "c/lwcImportProgramLibrary";

export default class lwcImportProgramStep1 extends LightningElement {
  @api custStyle = "";

  @track errorMsg = "";
  @track matches = null;

  @api projects = null;

  get selectFileDisabled() {
    return this.projects == null;
  }

  @api
  set hasError(value) {
    if (isEmpty(value)) {
      this.errorMsg = "";
      this.fileInfo.variant = "success";
      this.fileInfo.icon = "doctype:csv";
      return;
    }

    this.errorMsg = value;
    this.fileInfo.variant = "error";
    this.fileInfo.icon = "utility:error";
  }
  get hasError() {
    return !isEmpty(this.errorMsg);
  }

  @track showFileInfo = false;
  @track fileProps = [
    { name: "FileName", value: "" },
    { name: "FileType", value: "" },
    { name: "FileSize", value: "" }
  ];

  handleFileChanged(event) {
    this.matches = null;
    const file = event.currentTarget.files[0];
    this.dispatchEvent(
      genCustEvent(EVENT_BUSY_INDICATOR, {
        help: "Validating Schema...",
        busy: 1
      })
    );

    defer().then(() => {
      this.fileProps[0].value = file.name;
      this.fileProps[1].value = file.type;
      this.fileProps[2].value = Math.ceil(file.size / 1024) + "KB";
      this.showFileInfo = true;
      this.validateFile(file);

      if (this.hasError) {
        this.dispatchEvent(genCustEvent(EVENT_FILE_INVALID));
      }

      this.dispatchEvent(genCustEvent(EVENT_FILE_CHANGED, file));
    });
  }

  @track fileInfo = {
    class: "slds-box",
    icon: "utility:check",
    variant: "success"
  };

  validateFile(file) {
    const fileName = (file.name || "").toLowerCase();
    if (
      [".txt", ".csv"].some(ext => {
        return fileName.indexOf(ext) !== -1;
      })
    ) {
      this.hasError = "";
    } else {
      this.hasError =
        "The upload file type is invalid. The CSV and Text files are supported. The file extension must be either .csv or .txt";
    }
  }

  handleSelectFile() {
    this.template.querySelector("input[type='file']").click();
  }

  @track schemas = [
    { label: "Matched", fieldName: "matched", type: "boolean", fixedWidth: 80 },
    { label: "Column#", fieldName: "order", type: "number", fixedWidth: 80 },
    { label: "Title", fieldName: "schema" },
    { label: "Import File Title", fieldName: "title" }
  ];

  @api
  set results(values) {
    if (!values || values.length === 0) {
      this.matches = null;
    } else {
      this.matches = values;
    }
  }
  get results() {
    return this.matches;
  }
}