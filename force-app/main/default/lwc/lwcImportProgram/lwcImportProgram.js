/* eslint-disable no-useless-return */
/* eslint-disable no-console */
import { LightningElement, api, track } from "lwc";
import {
  toast,
  SELECT_DATASOURCE,
  VALIDATE_DATASOURCE,
  UPLOAD_FILE_FOR_PROCESS,
  STAGE_FILE_SELECT,
  STAGE_FILE_SELECTED,
  STAGE_FILE_VALIDATE,
  STAGE_FILE_VALIDATED,
  STAGE_FILE_UPLOAD,
  STAGE_FILE_UPLOADED,
  genStep,
  defer,
  parseCSVFile,
  fileHandler,
  analyzeFileSchema,
  genCustEvent,
  EVENT_CLOSE_DIALOG
} from "c/lwcImportProgramLibrary";

import getProgram from "@salesforce/apex/lwcProgramController.getProgram";

export default class lwcImportProgram extends LightningElement {
  steps = [];
  isConnected = false;
  file = null;
  validatedResult = [];
  appState = STAGE_FILE_SELECT;

  @api recordId;
  @api height = "400";

  @track step1Class = "slds-is-expanded";
  @track step2Class = "slds-is-collapsed";
  @track step3Class = "slds-is-collapsed";
  @track nextEnabled = false;
  @track title = "Import Jobs - Loading";
  @track busyAlternativeText = "Processing...";
  @track showSubmitButton = false;
  @track showClose = false;
  @track isAppBusy = false;
  @track hasFileError = "";
  @track schemaAnalsyis = [];
  @track datasource;
  @track projects = null;

  constructor() {
    super();
    this.init();
  }

  init() {
    this.nextEnabled = false;
    this.steps = [
      genStep(SELECT_DATASOURCE, "Step 1: Select File", 1),
      genStep(VALIDATE_DATASOURCE, "Step 2: Validate File", 0),
      genStep(UPLOAD_FILE_FOR_PROCESS, "Step 3: Upload File For Processing", 0)
    ];
  }

  connectedCallback() {
    if (!this.isConnected) {
      this.loadProjects();
      this.isConnected = true;
    }
  }

  showAppBusy() {
    this.isAppBusy = true;
  }

  hideAppBusy() {
    defer(250).then(() => {
      this.isAppBusy = false;
    });
  }

  transformProjectIdNumbers = data => {
    const value = {};
    for (const p of data) {
      if (p.length === 2) {
        value[p[0]] = p[1];
      }
    }
    return value;
  };

  loadProjects() {
    if (this.recordId) {
      const self = this;
      const recordId = this.recordId;
      this.showAppBusy();

      getProgram({ recordId })
        .then(data => {
          self.title = `Import Jobs - ${data.name}`;
          self.datasource = data.datasource;
          self.projects = self.transformProjectIdNumbers(data.projects);
          self.hideAppBusy();
        })
        .catch(error => {
          toast(self, {
            variant: "error",
            title: "Validate Program",
            message: error.body.message
          });
          self.hideAppBusy();
        });
    }
  }

  genStep(id, label, flag) {
    return { id, label, flag };
  }

  get custStyle() {
    return `height: ${this.height}px;`;
  }

  showStep(step) {
    switch (step) {
      case SELECT_DATASOURCE:
        this.step1Class = "slds-is-expanded";
        this.step2Class = "slds-is-collapsed";
        this.step3Class = "slds-is-collapsed";
        break;
      case VALIDATE_DATASOURCE:
        this.step2Class = "slds-is-expanded";
        this.step1Class = "slds-is-collapsed";
        this.step3Class = "slds-is-collapsed";
        break;
      case UPLOAD_FILE_FOR_PROCESS:
        this.step3Class = "slds-is-expanded";
        this.step1Class = "slds-is-collapsed";
        this.step2Class = "slds-is-collapsed";
        break;
      default:
        break;
    }
  }

  handleNext(evt) {
    const step = evt.detail;
    this.showStep(step);
    switch (step) {
      case VALIDATE_DATASOURCE:
        if (this.appState < STAGE_FILE_VALIDATED) {
          this.beginValidateFileData();
        } else if (this.appState === STAGE_FILE_VALIDATED) {
          if (!this.validatedResult) {
            this.nextEnabled = this.datasource.stopImport !== 1;
          }
        }
        break;
      case UPLOAD_FILE_FOR_PROCESS:
        if (this.appState < STAGE_FILE_UPLOADED) {
          this.beginUploadFile();
        }
        break;
      default:
        break;
    }
  }

  beginUploadFile() {
    this.showAppBusy();
    this.appState = STAGE_FILE_UPLOAD;
    defer().then(() => {
      const result = this.validatedResult.filter(el => el.goodJobs.length > 0);
      this.template
        .querySelector("c-lwc-import-program-step3")
        .initUploadFile(result);
    });
  }

  endUploadFile(event) {
    const { result, status } = event.detail;
    this.appState = STAGE_FILE_UPLOADED;
    this.hideAppBusy();
  }

  beginValidateFileData() {
    this.showAppBusy();
    this.appState = STAGE_FILE_VALIDATE;
    defer().then(() => {
      this.template
        .querySelector("c-lwc-import-program-step2")
        .analyzeFile(this.file, this.datasource);
    });
  }

  endValidteFileData(event) {
    const { result, status } = event.detail;
    this.appState = STAGE_FILE_VALIDATED;
    if (status === 0) {
      this.nextEnabled = this.datasource.stopImport !== 1;
      this.validatedResult = null;
    } else {
      this.nextEnabled = true;
      this.validatedResult = result;
    }

    this.hideAppBusy();
  }

  handlePrevious(evt) {
    this.showStep(evt.detail);
    this.nextEnabled = true;
  }

  handleLastStep(evt) {
    this.showSubmitButton = true;
    this.template.querySelector("c-dialog-step-footer").showStepper(false);
  }

  handleCancel() {
    this.dispatchEvent(genCustEvent(EVENT_CLOSE_DIALOG));
  }

  handleSubmit() {
    this.showAppBusy();
    defer().then(() => {
      const step3 = this.template.querySelector("c-lwc-import-program-step3");
      step3.uploadFile(
        this.datasource.id,
        this.datasource.chunkSize,
        this.datasource.stopImport
      );
    });
  }

  handleFileUploaded(event) {
    const { status, message } = event.detail;
    toast(this, {
      variant: status === 1 ? "success" : "error",
      title: "Import Jobs",
      message
    });
    this.showSubmitButton = false;
    this.showClose = true;
    this.hideAppBusy();
  }

  handleClose() {
    this.dispatchEvent(genCustEvent(EVENT_CLOSE_DIALOG));
  }

  handleFileChanged(evt) {
    this.file = evt.detail;
    if (!this.file) {
      return;
    }
    this.hasFileError = "";
    this.appState = STAGE_FILE_SELECT;
    fileHandler(this.file)
      .then(content => {
        try {
          const titles = parseCSVFile(content, 1);
          const { schemas } = this.datasource || {};
          if (!schemas) {
            toast(this, {
              variant: "error",
              title: "Validate Schema",
              message:
                "There is no schemas defined for this import file. Please contact system adminstrator."
            });
            return;
          }
          const analysis = analyzeFileSchema(titles, schemas);
          this.schemaAnalsyis = analysis.results;
          if (analysis.succeeded) {
            this.nextEnabled = true;
            this.appState = STAGE_FILE_SELECTED;
          } else {
            this.hasFileError = analysis.error;
            this.nextEnabled = false;
          }
        } catch (e) {
          this.nextEnabled = false;
          this.hasFileError = e;
        }
        this.hideAppBusy();
      })
      .catch(error => {
        this.hasFileError = error;
        this.nextEnabled = false;
        this.hideAppBusy();
      });
  }

  handleInvalidFile() {
    this.file = null;
    this.nextEnabled = false;
    this.hideAppBusy();
  }

  handleBusy(event) {
    const detail = event.detail;
    if (detail.busy === 1) {
      this.busyAlternativeText = detail.help;
      this.showAppBusy();
    } else {
      this.busyAlternativeText = "processing...";
      this.hideAppBusy();
    }
  }
}