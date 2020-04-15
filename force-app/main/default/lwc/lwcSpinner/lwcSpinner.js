import { LightningElement, track, api} from 'lwc';
import { defer } from 'c/lwcImportProgramLibrary';

export default class lwcSpinner extends LightningElement {
  @api alternativeText = "processing...";
  @api size = "medium";
  @api variant = "brand";

  @track isVisible = false;
  
  @api set visible(val) {
    this.isVisible = val;
  }

  get visible() {
    return this.isVisible;
  }
  
  @api show(){
    this.isVisible = true;
  }
  
  @api hide() {
    this.isVisible = false;
  }

  @api deferHide(waitTime) {
    defer(waitTime).then(()=>{
      this.hide();
    })
  }
}