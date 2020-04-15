public without sharing class QueryResultAnalyzer {
    private integer noneOverrideCursor;
    private integer overrideCursor;
    private boolean hasMoreFlag;

    public boolean getHasMoreFlag() {
        return this.hasMoreFlag;
    }

    public integer getNoneOverrideCursor() {
        return this.noneOverrideCursor;
    }

    public integer getOverrideCursor(){
        return this.overrideCursor;
    }

    private QueryResultAnalyzer(integer currentNoneOverrideCursor, integer currentOverrideCursor){
        this.noneOverrideCursor = currentNoneOverrideCursor;
        this.overrideCursor = currentOverrideCursor;
        this.hasMoreFlag = false;
    }

    public static QueryResultAnalyzer create(integer currentNoneOverrideCursor, integer currentOverrideCursor){
        return new QueryResultAnalyzer(currentNoneOverrideCursor, currentOverrideCursor);
    }

    public List<SObject> execute(List<SObject> noneOverrideResults, List<SObject> overrideResults){
        List<SObject> results = new List<SObject>();
        integer pageSize = AppUtil.PhotoViewerPageSize;
        integer halfSize = pageSize / 2;
        integer noneOverrideSize = noneOverrideResults.size();
        integer overrideSize = overrideResults.size();

        if(noneOverrideSize >= pageSize){
            this.hasMoreFlag = true;
            if (overrideSize >= pageSize){
                results.addAll(subList(noneOverrideResults, 0, halfSize));
                results.addAll(subList(overrideResults, 0, pageSize - halfSize));
                this.noneOverrideCursor += halfSize;
                this.overrideCursor += (pageSize - halfSize);
                return results;
            }

            if(overrideSize > 0){
                results.addAll(subList(noneOverrideResults, 0, pageSize - overrideSize));
                results.addAll(overrideResults);
                this.noneOverrideCursor += (pageSize - overrideSize);
                this.overrideCursor = -1;
                return results;
            }
            
            results.addAll(noneOverrideResults);
            this.noneOverrideCursor += noneOverrideSize;
            this.overrideCursor = -1;
            return results;
        }

        if (noneOverrideSize > 0){
            if(overrideSize >= pageSize){
                results.addAll(noneOverrideResults);
                results.addAll(subList(overrideResults, 0, pageSize - noneOverrideSize));
                this.noneOverrideCursor = -1;
                this.overrideCursor += (pageSize - noneOverrideSize);
                this.hasMoreFlag = true;
                return results;
            }

            if(overrideSize > 0){
                results.addAll(noneOverrideResults);
                results.addAll(overrideResults);
                this.noneOverrideCursor = -1;
                this.overrideCursor = -1;
                return results;
            }

            results.addAll(noneOverrideResults);
            this.noneOverrideCursor = -1;
            this.overrideCursor = -1;
            return results;
        }

        this.noneOverrideCursor = -1;

        if(overrideSize >= pageSize){
            results.addAll(subList(overrideResults, 0, pageSize));
            this.overrideCursor += pageSize;
            this.hasMoreFlag = true;
        } 
        else if (overrideSize > 0){
            results.addAll(overrideResults);
            this.overrideCursor = -1;
        } 
        else 
        {
            this.overrideCursor = -1;
        }

        return results;
    }

    public static List<SObject> subList(List<SObject> sources, Integer fromIndex, Integer count){
        List<SObject> items = new List<SObject>();
        for(integer i= fromIndex; i < count; i++){
            items.add(sources[i]);
        }
        return items;
    }

}