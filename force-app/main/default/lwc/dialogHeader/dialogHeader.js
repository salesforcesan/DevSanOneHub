import { LightningElement, api } from "lwc";

export default class dialogHeader extends LightningElement {
  @api title;
  @api marginGap = "";

  get style() {
    return `margin-left: ${this.marginGap}; margin-right: ${this.marginGap};`;
  }

  get hasGap() {
    return this.marginGap.length > 0;
  }
}