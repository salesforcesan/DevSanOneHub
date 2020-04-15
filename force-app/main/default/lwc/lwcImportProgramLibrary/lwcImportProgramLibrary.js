import { ShowToastEvent } from "lightning/platformShowToastEvent";

export const genStep = (id, label, flag) => {
  return { id, label, flag };
};

export const genCustEvent = (type, detail) => {
  if (detail) {
    return new CustomEvent(type, { detail });
  }
  return new CustomEvent(type);
};

export const isEmpty = value => {
  const v = (value + "").trim();
  return v.length === 0;
};

export const toast = (self, options) => {
  const event = new ShowToastEvent(options);
  self.dispatchEvent(event);
};

export const defer = duration => {
  const waitTime = duration || 5;
  return new Promise(resolve => {
    // eslint-disable-next-line @lwc/lwc/no-async-operation
    const id = setTimeout(() => {
      resolve(1);
      window.clearTimeout(id);
    }, waitTime);
  });
};

export const SELECT_DATASOURCE = 1;
export const VALIDATE_DATASOURCE = 2;
export const UPLOAD_FILE_FOR_PROCESS = 3;
export const EVENT_LAST_STEP = "laststep";
export const EVENT_NEXT_STEP = "nextstep";
export const EVENT_PREVIOUS_STEP = "previousstep";
export const EVENT_SUBMIT_STEP = "submit";
export const EVENT_CANCEL_STEP = "cancel";
export const EVENT_CLOSE_DIALOG = "close";
export const EVENT_FILE_UPLOADED = "fileuploaded";
export const EVENT_FILE_CHANGED = "filechanged";
export const EVENT_FILE_INVALID = "invalidfile";
export const EVENT_DATA_VALIDATED = "validated";
export const EVENT_BUSY_INDICATOR = "busy";
export const STAGE_FILE_SELECT = 1;
export const STAGE_FILE_SELECTED = 2;
export const STAGE_FILE_VALIDATE = 3;
export const STAGE_FILE_VALIDATED = 4;
export const STAGE_FILE_UPLOAD = 5;
export const STAGE_FILE_UPLOADED = 6;
export const ERROR_COLUMN_NOT_MATCHED = "1";
export const ERROR_INVALID_DATE = "2";
export const ERROR_INVALID_TIME = "3";
export const ERROR_INVALID_NUMBER = "5";
export const ERROR_INVALID_EMPTY = "4";
export const ERROR_INVALID_FLOAT = "6";
export const ERROR_INVALID_PROJECT = "7";
export const DEFAULT_GROUP_ID = "__default";
export const DEFAULT_GROUP_TITLE = "Default Group";
export const DATATYPE_TEXT = "Text";
export const DATATYPE_NUMBER = "Number";
export const DATATYPE_FLOAT = "Float";
export const DATATYPE_DATE = "Date";
export const DATATYPE_TIME = "Time";
export const DATATYPE_DATETIME = "DateTime";

export const fileHandler = file => {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.onload = () => {
      resolve(reader.result);
    };
    reader.onerror = () => {
      reject(reader.error);
    };
    reader.readAsText(file);
  });
};

export const parseCSVFile = (content, headerOnly = 0) => {
  const data = (content || "").split(/\n|\r|\r\n/g);
  if (!data || data.length === 0) {
    throw new Error("There are no data in the file for importing data.");
  }

  const pattern = new RegExp('"', "g");
  const doubleQuoteRemover = row => {
    return !!row && row.indexOf('"') !== -1 ? row.replace(pattern, "") : row;
  };

  if (headerOnly !== 0) {
    const row = data[0];
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
};

const genMatchResult = (id, order, matched, schema, title) => {
  return { id, order, matched, schema, title };
};

const checkTitleCount = (titles, schemas) => {
  if (titles.length !== schemas.length) {
    return `The import file is invalid. The import file must have ${schemas.length} columns but the selected file has ${titles.length} columns.`;
  }
  return "";
};

const trim = v => {
  return (v + "").trim();
};

export const checkTime = tm => {
  return /(1[0-2]|0?[1-9]):[0-5][0-9] ([AaPp][Mm])/.test(trim(tm));
};

export const checkNumber = number => {
  return /^-?[0-9]+$/.test(trim(number));
};

export const checkFloat = float => {
  const v = trim(float);
  return Number(v) === parseFloat(v) && v % 1 !== 0;
};

export const checkDate = dt => {
  const v = trim(dt);
  return (
    /\d\d\d\d-\d\d?-\d\d?|\d\d?\/\d\d?\/\d\d\d\d/.test(v) &&
    !isNaN(Date.parse(v))
  );
};

export const checkDatetime = () => {
  return false;
};

export const analyzeFileSchema = (titles, schemas) => {
  let results = [];
  let title, schema, matched;
  let error = checkTitleCount(titles, schemas);
  let errColumns = [];

  for (const [index] of schemas.entries()) {
    title = index < titles.length ? titles[index] : "";
    schema = schemas[index].title + "";
    matched = title.toLowerCase() === schema.toLowerCase();
    if (!matched) {
      errColumns.push(title);
    }
    results.push(genMatchResult(index, index, matched, schema, title));
  }

  if (errColumns.length > 0) {
    error = `${error} These columns are not matched: ${errColumns.join(",")}.`;
  }
  return {
    succeeded: error === "",
    error,
    results
  };
};