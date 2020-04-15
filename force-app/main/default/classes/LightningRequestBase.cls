public abstract class LightningRequestBase implements ILightningRequest {
  public virtual Object get(Object parameters){
    throw new AuraHandledException('The get method is not implemented.');
  }

  public virtual Object filter(Object parameters) {
    throw new AuraHandledException('The find method is not implemented.');
  }

  public virtual Object search(Object parameters){
    throw new AuraHandledException('The search method is not implemented.');
  }
  
  public virtual Object add(Object parameters) {
    throw new AuraHandledException('The add method is not implemented.');
  }

  public virtual Object remove(Object parameters) {
    throw new AuraHandledException('The remove method is not implemented.');
  }

  public virtual Object modify(Object parameters) {
    throw new AuraHandledException('The modify method is not implemented.');
  }
 
}