import { LightningElement, api, track } from "lwc";
import { toast } from "c/lwcImportProgramLibrary";

export default class LwcAlert extends LightningElement {
  isConnected = false;

  @api iconName = "";
  @api iconTitle = "";
  @api recordId = "";
  @api objectName = "";
  @api rules = "";
  @api message = "";
  @track showAlert = false;

  connectedCallback() {
    if (!this.message) {
      this.showAlert = false;
      return;
    }
    if (this.rules) {
      // const recordId = this.recordId;
      // const rules = this.rules;
      // const objectName = this.objectName;
      // checkVisible({ recordId, objectName, rules })
      //   .then(data => {
      //     this.showAlert = data === 1;
      //   })
      //   .catch(error => {
      //     toast(self, {
      //       variant: "error",
      //       title: "Failed to check alert visibility",
      //       message: error.body.message
      //     });
      //   });
    } else {
      this.showAlert = true;
    }
  }
}