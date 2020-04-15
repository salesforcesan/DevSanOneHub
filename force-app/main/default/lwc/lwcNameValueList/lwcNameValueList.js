import { LightningElement, api, track} from 'lwc';

export default class nameValueList extends LightningElement {
  @track variant = "horizontal"; //horizontal, inline, stacked
  @api placeholder = "No data to show";
  @api nameValues = []; // array of {name, value}

  @api set variant(value) {
    this.variant = value;
  }

  get className() {
    if (this.variant === "horizontal") {
      return "slds-list_horizontal slds-wrap slds-p-around_xx-small";
    }
    if (this.variant === "stacked") {
      return "slds-list_stacked slds-wrap slds-p-around_xx-small";
    }
    return "slds-list_inline slds-wrap slds-p-around_xx-small";
  }

  get hasNameValues() {
    return this.nameValues.length > 0;
  }
}