import { LightningElement, api, track } from "lwc";
import {
  genCustEvent,
  EVENT_SUBMIT_STEP,
  EVENT_NEXT_STEP,
  EVENT_CANCEL_STEP,
  EVENT_PREVIOUS_STEP,
  EVENT_LAST_STEP
} from "c/lwcImportProgramLibrary";

export default class dialogStepFooter extends LightningElement {
  @api marginGap = ""; //-20px;
  @api hasError = false;
  @track currentStep = 0;
  @track steps = []; // [{id:stirng/number, label: string, flag: 1/0}]
  @track prevDisabled = true;
  @track nextDisabled = false;
  @track hideSteps = false;
  @api nextEnabled = false;

  @api showStepper(value) {
    this.hideSteps = !value;
  }

  /**
   * @param {{ map: (arg0: (val: any) => { id: any; label: any; flag: any; }) => any[]; }} values
   */
  @api
  set stepDefs(values) {
    let stepFlag = false;
    let currentId = 0;

    this.steps = values.map(val => {
      let { id, label, flag } = val;
      return { id, label, flag };
    });

    this.steps.forEach(val => {
      if (val.flag === 1) {
        currentId = val.id;
        stepFlag = true;
      }
    });
    if (!stepFlag) {
      this.currentStep = this.toStep(0).id;
      this.steps[0].flag = 1;
    } else {
      this.currentStep = currentId;
    }

    if (this.isFirstStep) {
      this.prevDisabled = true;
    }
  }

  get isNextDead() {
    if (this.nextEnabled) {
      return this.nextDisabled;
    }
    return true;
  }

  get stepDefs() {
    return this.steps;
  }

  get hasSteps() {
    return this.steps.length > 0;
  }

  get hasGap() {
    return this.marginGap.length > 0;
  }

  get hasOneStep() {
    return this.steps.length === 1;
  }

  get style() {
    return `margin-left: ${this.marginGap}; margin-right: ${this.marginGap};`;
  }

  captureEvent(e) {
    e.preventDefault();
    e.stopPropagation();
  }

  toStep(cursor) {
    let { id, label, flag } = this.steps[cursor];
    return { id, label, flag };
  }

  handleNext(e) {
    this.captureEvent(e);

    if (!this.hasSteps || this.hasOneStep || this.nextDisabled) {
      return;
    }
    this.prevDisabled = false;
    let cursor = this.steps.findIndex(step => step.id === this.currentStep);
    this.currentStep = this.toStep(cursor + 1).id;
    this.resetStep();

    if (this.isLastStep) {
      this.nextDisabled = true;
      this.dispatchEvent(genCustEvent(EVENT_LAST_STEP, this.currentStep));
    } else {
      this.nextDisabled = false;
    }
    this.dispatchEvent(genCustEvent(EVENT_NEXT_STEP, this.currentStep));
  }

  resetStep() {
    let vals = [];
    let currentId = this.currentStep;
    this.steps.forEach(step => {
      let { id, label } = step;
      vals.push({
        id,
        label,
        flag: id === currentId ? 1 : 0
      });
    });
    this.steps = vals;
  }

  get isFirstStep() {
    return this.steps[0].id === this.currentStep;
  }

  get isLastStep() {
    return this.steps[this.steps.length - 1].id === this.currentStep;
  }

  handlePrev(e) {
    this.captureEvent(e);

    if (!this.hasSteps || this.hasOneStep || this.prevDisabled) {
      return;
    }
    let cursor = this.steps.findIndex(step => step.id === this.currentStep);
    this.nextDisabled = false;
    this.currentStep = this.toStep(cursor - 1).id;
    this.resetStep();

    if (this.isFirstStep) {
      this.prevDisabled = true;
    } else {
      this.prevDisabled = false;
    }
    this.dispatchEvent(genCustEvent(EVENT_PREVIOUS_STEP, this.currentStep));
  }

  handleCancel(e) {
    this.captureEvent(e);
    this.dispatchEvent(genCustEvent(EVENT_CANCEL_STEP, 0));
  }

  handleSubmit(e) {
    this.captureEvent(e);
    this.dispatchEvent(genCustEvent(EVENT_SUBMIT_STEP, 0));
  }
}