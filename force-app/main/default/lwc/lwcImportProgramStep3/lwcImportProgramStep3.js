import { LightningElement, api, track } from "lwc";
import {
  defer,
  genCustEvent,
  EVENT_FILE_UPLOADED,
  EVENT_BUSY_INDICATOR,
  toast
} from "c/lwcImportProgramLibrary";
import addRequestQueueItem from "@salesforce/apex/lwcImportProgramController.addRequestQueueItem";
import createRequestQueue from "@salesforce/apex/lwcImportProgramController.createRequestQueue";
import submitQueue from "@salesforce/apex/lwcImportProgramController.submitQueue";
import deleteQueue from "@salesforce/apex/lwcImportProgramController.deleteQueue";

export default class lwcImportProgramStep3 extends LightningElement {
  uploadData = [];
  chunkSize = 1000;
  datasourceId = "";
  requestQueue = null;
  currentProject = null;
  stopImport = 0;

  @api custStyle = "";
  @api projects;

  @track columns = [];
  @track results = [];
  @track requestDef = [];

  constructor() {
    super();
    this.init();
  }

  init() {
    this.columns = [
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
    ];
  }

  @api
  initUploadFile(aggregateResult) {
    this.results = [];
    defer().then(() => {
      this.uploadData = this.transformResult(aggregateResult);
      this.results = this.genResults();
      this.hideBusy();
    });
  }

  genResults = () => {
    return this.uploadData.map(r => {
      const { done, groupId, groupTitle, jobCount, status, message } = r;
      return {
        done,
        groupId,
        groupTitle,
        jobCount,
        status,
        message
      };
    });
  };

  hideBusy = () => {
    defer(250).then(() => {
      this.dispatchEvent(
        genCustEvent(EVENT_BUSY_INDICATOR, {
          busy: 0
        })
      );
    });
  };

  transformResult = result => {
    return result.map(el => {
      const { groupId, groupTitle, badJobs, goodJobs } = el;
      const message =
        badJobs.length > 0
          ? `${goodJobs.length} jobs will be imported. ${badJobs.length} invalid jobs are skipped.`
          : `${goodJobs.length} jobs will be imported.`;

      return {
        done: false,
        groupId,
        groupTitle,
        jobCount: goodJobs.length,
        status: "Ready",
        cursor: 0,
        badJobs,
        goodJobs,
        message
      };
    });
  };

  renderRequestDef = queue => {
    this.requestDef = [
      { name: "Name", value: queue.name },
      { name: "Status", value: queue.status },
      { name: "Request Date", value: queue.queueDate },
      { name: "Requestor", value: queue.requestor }
    ];
  };

  @api
  uploadFile(datasourceId, chunkSize, stopImport) {
    this.chunkSize = chunkSize;
    this.datasourceId = datasourceId;
    this.stopImport = stopImport;

    //step 1 if no request created, create request
    if (!this.requestQueue || !this.hasRequestDef) {
      createRequestQueue({ datasource: datasourceId })
        .then(queue => {
          this.requestQueue = queue;
          this.renderRequestDef(queue);
          this.chunkAndUploadData();
        })
        .catch(error => {
          toast(self, {
            variant: "error",
            title: "Upload File",
            message: JSON.stringify(error)
          });
          this.hideBusy();
        });
    } else {
      this.chunkAndUploadData();
    }
  }

  chunkAndUploadData() {
    let firstTime = 1;
    if (!this.currentProject) {
      this.currentProject = this.getNextOneInitProject();
    } else if (this.currentProject.status !== "Ready") {
      firstTime = 0;
      this.results = this.genResults();
      this.currentProject = this.getNextOneInitProject();
    }

    if (this.currentProject) {
      const project = this.currentProject;
      if (!this.isProjectValid(project.groupId)) {
        project.status = "Error";
        project.message = "The project does not belong to the program";
        this.chunkAndUploadData();
        return;
      }

      if (firstTime) {
        this.processProject(project);
      } else {
        defer().then(() => {
          this.processProject(project);
        });
      }
      return;
    }

    const { status, message } = this.analyzeLoadResult();
    switch (status) {
      case 1: //success
        this.batchSubmitQueue(status, message);
        break;
      case 2: //partial success
        if (this.stopImport !== 1) {
          this.batchSubmitQueue(status, message);
        } else {
          this.rollbackChanges(status, message);
        }
        break;
      default:
        //failed
        this.rollbackChanges(status, message);
        break;
    }
  }

  batchSubmitQueue = (status, message) => {
    const queueId = this.requestQueue.queueId;
    submitQueue({ queueId })
      // eslint-disable-next-line no-unused-vars
      .then(result => {
        this.requestQueue.status = "Queued";
        this.renderRequestDef(this.requestQueue);
        this.notifyFileUploaded(status, message);
      })
      .catch(error => {
        status = 0;
        message = error.body.message;
        this.notifyFileUploaded(status, message);
      });
  };

  rollbackChanges = (status, message) => {
    const queueId = this.requestQueue.queueId;
    deleteQueue({ queueId })
      .then(result => {
        this.requestDef = [];
        this.notifyFileUploaded(status, message);
      })
      .catch(error => {
        message = `${message} ${error.body.message}`;
        this.notifyFileUploaded(status, message);
      });
  };

  analyzeLoadResult = () => {
    let count0 = 0,
      count1 = 0;
    for (const p of this.uploadData) {
      if (p.status === "Queued") {
        count1++;
      } else {
        count0++;
      }
    }
    if (count0 === 0) {
      return {
        status: 1,
        message: "The file is uploaded and queued successfully."
      };
    }
    if (count1 > 0) {
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
  };

  notifyFileUploaded = (status, message) => {
    this.dispatchEvent(genCustEvent(EVENT_FILE_UPLOADED, { status, message }));
  };

  isProjectValid = projectNumber => {
    return !!this.projects && !!this.projects[projectNumber];
  };

  processProject = project => {
    const projectQueued = () => {
      project.status = "Queued";
      project.message = "Queued";
      project.done = true;
    };

    if (project.cursor > project.jobCount) {
      projectQueued();
      this.chunkAndUploadData();
      return;
    }
    const { cursor, goodJobs } = project;
    const content = goodJobs.slice(cursor, cursor + this.chunkSize);
    if (content.length === 0) {
      projectQueued();
      this.chunkAndUploadData();
      return;
    }

    project.cursor = cursor + this.chunkSize;
    const projectId = this.projects[project.groupId];
    const queueId = this.requestQueue.queueId;
    addRequestQueueItem({ queueId, projectId, content })
      .then(result => {
        if (result.status === 1) {
          this.processProject(project);
        } else {
          project.status = "Error";
          project.message = result.message;
          this.chunkAndUploadData();
        }
      })
      .catch(error => {
        project.status = "Error";
        project.message = error.body.message;
        this.chunkAndUploadData();
      });
  };

  getNextOneInitProject = () => {
    const initQ = this.uploadData.filter(r => r.status === "Ready");
    return initQ.length > 0 ? initQ[0] : null;
  };

  get hasRequestDef() {
    return !!this.requestDef && this.requestDef.length > 0;
  }
}