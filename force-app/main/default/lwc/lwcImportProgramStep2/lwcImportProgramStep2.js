import { LightningElement, api, track } from "lwc";
import {
  genCustEvent,
  EVENT_DATA_VALIDATED,
  fileHandler,
  toast,
  EVENT_BUSY_INDICATOR,
  parseCSVFile,
  DEFAULT_GROUP_ID,
  ERROR_COLUMN_NOT_MATCHED,
  ERROR_INVALID_DATE,
  ERROR_INVALID_NUMBER,
  ERROR_INVALID_TIME,
  ERROR_INVALID_EMPTY,
  ERROR_INVALID_FLOAT,
  ERROR_INVALID_PROJECT,
  isEmpty,
  DATATYPE_DATE,
  DATATYPE_NUMBER,
  DATATYPE_DATETIME,
  DATATYPE_FLOAT,
  DATATYPE_TIME,
  checkDate,
  checkTime,
  checkNumber,
  checkFloat,
  DEFAULT_GROUP_TITLE
} from "c/lwcImportProgramLibrary";

export default class lwcImportProgramStep2 extends LightningElement {
  schemas = null;
  groupKeyColumn = -1;
  groupKeyNameColumn = -1;

  @api projects;
  @api custStyle = "";
  @api chunkSize = 1000;

  @track results = [];
  @track columns;
  @track guides;

  init() {
    this.columns = null;
    this.schemas = null;
    this.groupKeyColumn = -1;
    this.groupKeyNameColumn = -1;
  }

  @api
  set helps(values) {
    if (!values || values.length === 0) {
      this.guides = null;
      return;
    }
    this.guides = this.parseGuides(values);
  }
  get helps() {
    return this.guides;
  }

  @api
  set schemasDefinition(values) {
    this.init();
    if (!values || values.length === 0) {
      return;
    }
    this.buildColumns(values);
    this.schemas = values;
  }
  get schemasDefinition() {
    return this.schemas;
  }

  buildColumns = values => {
    let def = [
      { label: "Valid", fieldName: "valid", type: "boolean", fixedWidth: 70 }
    ];

    for (const [index, element] of values.entries()) {
      if (element.groupBy === 1) {
        if (element.keyed === 1) {
          this.groupKeyColumn = index;
        } else {
          this.groupKeyNameColumn = index;
        }
      }
    }

    def.push({
      label:
        this.groupKeyColumn !== -1
          ? values[this.groupKeyColumn].title
          : "Group ID",
      fieldName: "groupId",
      fixedWidth: 150
    });

    def.push({
      label: this.groupKeyNameColumn !== -1 ? "Project Title" : "Group Title",
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

    this.columns = def;
  };

  @api analyzeFile(file) {
    fileHandler(file)
      .then(content => {
        try {
          const rows = parseCSVFile(content);
          const result = this.validateData(rows);
          const responses = Object.keys(result).map(key => {
            return this.reportOneGroup(key, result[key]);
          });
          let status = 0;
          if (responses.some(e => !e.valid)) {
            this.errorOut("The import file has invalid data");
          } else {
            status = 1;
            this.messageOut(
              "The import file is validated and ready for import."
            );
          }
          this.dispatchEvent(
            genCustEvent(EVENT_DATA_VALIDATED, {
              status,
              result: responses
            })
          );
          this.results = responses;
        } catch (e) {
          this.errorOut(e.message);
        }
      })
      .catch(error => {
        this.errorOut(error);
      });
  }

  reportOneGroup = (id, group) => {
    const errors = Object.keys(group.error).map(key => {
      return [key, group.error[key]];
    });

    const errCount = group.badJobs.length;
    const genStatus = () => {
      if (errCount === 0) {
        return "Ready for import";
      }
      let data = [];
      for (const err of errors) {
        if (err[1] > 0) {
          switch (err[0]) {
            case ERROR_INVALID_FLOAT:
              data.push(`${err[1]} records with invalid Decimal values.`);
              break;
            case ERROR_COLUMN_NOT_MATCHED:
              data.push(`${err[1]} records with non-matched columns.`);
              break;
            case ERROR_INVALID_DATE:
              data.push(`${err[1]} records with invalid Date values.`);
              break;
            case ERROR_INVALID_NUMBER:
              data.push(`${err[1]} records with invalid Number values.`);
              break;
            case ERROR_INVALID_TIME:
              data.push(`${err[1]} records with invalid Time values.`);
              break;
            case ERROR_INVALID_EMPTY:
              data.push(`${err[1]} records with invalid values.`);
              break;
            case ERROR_INVALID_PROJECT:
              data.push(
                `${err[1]} records with the project not belonged to the program.`
              );
              break;
            default:
              data.push(`Unknown Error: err[0]:err[1]`);
          }
        }
      }
      return `Import file is invalid. ${data.join(" ")}`;
    };

    return {
      valid: group.badJobs.length === 0 ? 1 : 0,
      groupId: id === DEFAULT_GROUP_ID ? "Invalid ID" : id,
      groupTitle: group.title,
      total: group.badJobs.length + group.goodJobs.length,
      status: genStatus(),
      badJobs: group.badJobs,
      goodJobs: group.goodJobs
    };
  };

  validateData = content => {
    //step 1: remove first row (assumed to be title)
    content.shift();
    let result = {};

    const initError = () => {
      let err = {};
      err[ERROR_COLUMN_NOT_MATCHED] = 0;
      err[ERROR_INVALID_DATE] = 0;
      err[ERROR_INVALID_EMPTY] = 0;
      err[ERROR_INVALID_NUMBER] = 0;
      err[ERROR_INVALID_TIME] = 0;
      err[ERROR_INVALID_FLOAT] = 0;
      err[ERROR_INVALID_PROJECT] = 0;
      return err;
    };

    //step 2: loop each data record
    const getGroup = rec => {
      const groupId = isEmpty(rec[this.groupKeyColumn])
        ? DEFAULT_GROUP_ID
        : rec[this.groupKeyColumn];

      let group = result[groupId];
      if (!group) {
        group = {
          title: rec[this.groupKeyNameColumn] || DEFAULT_GROUP_TITLE,
          goodJobs: [],
          badJobs: [],
          error: initError()
        };
        result[groupId] = group;
      }
      return group;
    };

    const ensureProjectInProgram = rec => {
      const projectNumber = rec[this.groupKeyColumn];
      return !this.projects[projectNumber] ? 0 : 1;
    };

    for (const rec of content) {
      const group = getGroup(rec);
      if (rec.length !== this.schemas.length) {
        group.error[ERROR_COLUMN_NOT_MATCHED]++;
        group.badJobs.push(rec);
        continue;
      }

      if (!ensureProjectInProgram(rec)) {
        group.error[ERROR_INVALID_PROJECT]++;
        group.badJobs.push(rec);
        continue;
      }

      let hasError = 0;
      for (let index = 0; index < this.schemas.length; index++) {
        const value = rec[index];
        const element = this.schemas[index];

        if (isEmpty(value)) {
          if (
            element.keyed === 1 ||
            element.groupBy === 1 ||
            element.required === 1
          ) {
            group.error[ERROR_INVALID_EMPTY]++;
            hasError = 1;
          }
          break;
        }

        if (!element.updatable) {
          continue;
        }

        switch (element.dataType) {
          case DATATYPE_DATE:
            if (!checkDate(value)) {
              group.error[ERROR_INVALID_DATE]++;
              hasError = 1;
            }
            break;
          case DATATYPE_TIME:
            if (!checkTime(value)) {
              group.error[ERROR_INVALID_TIME]++;
              hasError = 1;
            }
            break;
          case DATATYPE_NUMBER:
            if (!checkNumber(value)) {
              group.error[ERROR_INVALID_NUMBER]++;
              hasError = 1;
            }
            break;
          case DATATYPE_DATETIME:
            break;
          case DATATYPE_FLOAT:
            if (!checkFloat(value)) {
              group.error[ERROR_INVALID_FLOAT]++;
              hasError = 1;
            }
            break;
          default:
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
  };

  errorOut = message => {
    toast(this, {
      variant: "error",
      title: "Validate Data",
      message
    });
    this.dispatchEvent(
      genCustEvent(EVENT_BUSY_INDICATOR, {
        busy: 0
      })
    );
  };

  messageOut = message => {
    toast(this, {
      variant: "success",
      title: "Validate Data",
      message
    });

    this.dispatchEvent(
      genCustEvent(EVENT_BUSY_INDICATOR, {
        busy: 0
      })
    );
  };

  parseGuides = helps => {
    let id = 1;
    return helps.map(g => {
      return {
        id: id++,
        guide: g
      };
    });
  };
}