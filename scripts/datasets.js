{
// workaround for local modules without webserver
const tools = window.tools;
const data = window.data;

const LoadedDataSets = {};

class DataSet {
    name;
    data;
    numericDims;
    constructor(name, data, numericDims) {
        this.name = name;
        this.data = data;
        this.numericDims = numericDims;
    }

    /**
     * @param {DataSet} dataset
     * @param {String} datasetName 
     */
    saveAs(datasetName) {
        // update dataset name
        let newName = datasetName || this.name;

        // ensure there is only numeric data
        let croppedData = tools.cropDataDimensions(this.data, this.numericDims);

        // compile dataset for storage
        let saveSet = new DataSet(newName, croppedData, this.numericDims);
        LoadedDataSets[newName] = saveSet;

        // convert data to json
        let dataJson = JSON.stringify(saveSet, undefined, "\t");

        // create js file
        let script = `
const ${newName} = ${dataJson};
export default ${newName};
`;

        let link = document.createElement("a");
        link.textContent = "Download dataset";
        link.href = `data:,${encodeURI(script)}`;
        link.download = `${newName}.js`;

        document.body.appendChild(link);
        link.click();
        link.remove();
    }

    static async load(datasetName) {
        // use existing dataset
        let dataset = LoadedDataSets[datasetName];

        // load fresh dataset
        if (!dataset) {
            // import the data
            let imported;
            try {
                // workaround to not require web server
                imported = data[datasetName];
                if (imported === undefined) throw new Error(`Local data '${datasetName}' is undefined.`);
                //imported = await import(`../data/${datasetName}.js`);
                //imported = imported.default;
            } catch (error) {
                throw new Error(`Error loading dataset '${datasetName}'`, {cause: error});
            }

            // wrap it in a dataset
            dataset = new DataSet(imported.name, imported.data, imported.numericDims);
            LoadedDataSets[datasetName] = dataset;
        }

        // return a deep copy to avoid changes to the original
        return dataset.deepCopy();
    }

    deepCopy() {
        let copied = JSON.parse(JSON.stringify(this));
        return new DataSet(copied.name, copied.data, copied.numericDims);
    }
}

class LoadedData extends DataSet {
    idDim;
    constructor(name, data, numericDims, idDim) {
        super(name, data, numericDims);
        this.idDim = idDim;
    }

    /**
     * @param {String} idDim 
     */
    addIdDim(idDim) {
        // get all dimensions
        let allDims = Object.keys(this.data[0]);

        // get name of new ID dim (after this function is complete)
        let newIdDim = idDim || this.idDim;
        if (!newIdDim) {
            newIdDim = "_ID";
            while (allDims.indexOf(newIdDim) >= 0) {
                newIdDim = "_" + newIdDim;
            }
        }

        // ID already exists and no change of name => nothing to do
        if (newIdDim === this.idDim && allDims.indexOf(newIdDim) >= 0)
            return;
        // remove old ID dim
        else if (allDims.indexOf(this.idDim) >= 0) {
            for (let p of this.data) {
                delete p[this.idDim];
            }
        }

        // add unique IDs
        let id = 0;
        for (let p of this.data) {
            p[newIdDim] = id++;
        }

        // remember current ID dim name
        this.idDim = newIdDim;
    }

    /**
     * @param {DataSet} dataset 
     */
    static fromDataSet(dataset) {
        if (!(dataset instanceof DataSet))
            throw "Expected an instance of DataSet.";

        // just wrap dataset in loaded data class
        let loaded = (dataset instanceof LoadedData) ? dataset : new LoadedData(dataset.name, dataset.data, dataset.numericDims);
        
        // ensure there is an ID dim
        loaded.addIdDim();

        return loaded;
    }

    static async fromDataSetName(datasetName) {
        // get dataset
        let dataset = await DataSet.load(datasetName);
        // wrap in loaded data
        return LoadedData.fromDataSet(dataset);
    }

    deepCopy() {
        let copied = JSON.parse(JSON.stringify(this));
        return new LoadedData(copied.name, copied.data, copied.numericDims, copied.idDim);
    }
}

const ds = { DataSet: DataSet, LoadedData: LoadedData}

window.LoadedDataSets = LoadedDataSets;
window.ds = ds;
}