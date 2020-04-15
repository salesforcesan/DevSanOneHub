public interface ILightningRequest {
  Object get(Object parameters);
  Object search(Object parameters);
  Object filter(Object parameters);
  Object add(Object parameters);
  Object remove(Object parameters);
  Object modify(Object parameters);
}