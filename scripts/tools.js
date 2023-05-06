// workaround for local modules without webserver
const d3 = window.d3;
const st = d3.scatterTrans;

class tools {
    // Gets multiple necessary GUI elements from the HTML DOM.
    /**
     * 
     * @param {String} elementSelector - CSS Selector of the elements to search for.
     * @param {*} elementType - A subtype of HTMLElement. If provided, will ensure all selected elements are of this type.
     * @param {boolean} [ignoreMissing=false] - How to handle missing elements. False to throw an error. True to log a warning.
     * @returns An array of HTML elements with the given ID and type.
     */
    static RequireUIElements(elementSelector, elementType, ignoreMissing = false) {
        // get all matches.
        let matches = document.querySelectorAll(elementSelector);
        if (matches === null || matches === undefined)
            matches = [];
        
        // error if no match at all.
        if (matches.length <= 0) {
            const message = `HTML incompatible with code behind. Couldn't find elements with selector '${elementSelector}'.`;
            if (ignoreMissing) {
                console.warn(message);
            } else {
                throw message;
            }
        }

        // error if wrong element type
        if (elementType) {
            for (let elem of matches) {
                if (!(elem instanceof elementType)) {
                    throw `Not all elements selected with '${elementSelector}' where of type ${elementType.name}.`;
                }
            }
        }

        // return an array of all matches
        return [...matches];
    }
        
    // Gets a unique GUI element from the HTML DOM.
    /**
     * 
     * @param {String} elementSelector - CSS Selector of the element to search for.
     * @param {*} elementType - A subtype of HTMLElement. If provided, will ensure that the selected element is of this type.
     * @param {boolean} [ignoreMissing=false] - How to handle a missing element. False to throw an error. True to log a warning.
     * @returns An HTML element with the given ID and type.
     */
    static RequireUIElement(elementSelector, elementType, ignoreMissing = false) {
        // get matches. error if it's not unique (multiple matches).
        const matches = tools.RequireUIElements(elementSelector, elementType, ignoreMissing);
        if (matches.length > 1) {
            const message = `HTML incompatible with code behind. Found more than one elements with selector '${elementSelector}'.`;
            if (ignoreMissing) {
                console.warn(message);
            } else {
                throw message;
            }
        }

        // return the single match
        return matches[0];
    }


    static sleep(delay) {
        return new Promise((resolve, reject) => {
            try {
                setTimeout(resolve, delay);
            } catch (error) {
                reject(error);
            }
        });
    }

    /**
     * Creates a shallow copy of the given objects. Only keeps the listed properties of the source objects.
     * @param {Object[]} data 
     * @param {String[]} dimsToKeep
     */
    static cropDataDimensions(data, dimsToKeep) {
        return data.map((point) => {
            let filtered = {};
            for (let dim of dimsToKeep) {
                filtered[dim] = point[dim];
            }
            return filtered;
        });
    }


    static clientPosToDrawingPos(container, clientPos) {
        let containerNode = container.node();
        let positionRoot = containerNode.viewportElement || containerNode;
        let clientBounds = positionRoot.getBoundingClientRect();
        return {
            x:  clientPos.x - clientBounds.x,
            y: clientPos.y - clientBounds.y
        };
    }

    static #playStopped(plot) {
        const playDurationEnd = performance.now();
        if (this.playDurationStart) {
            const duration = playDurationEnd - this.playDurationStart;
            //console.info(`Transition played for ${Math.round(duration)} milliseconds.`)
        }
        this.removeListener("pause", tools.#playStopped);
        if (this.playResolve === undefined)
            return;
        let resolve = this.playResolve;
        delete this.playResolve;
        resolve();
    }
    static #play2End(plot, resolve, reject) {
        try {
            plot.playDurationStart = performance.now();
            plot.playResolve = resolve;
            plot.addListener("pause", tools.#playStopped);
            plot.playing(true);
        } catch (error) {
            reject(error);
        }
    }
    static play2End(plot) {
        return new Promise((resolve, reject) => { tools.#play2End(plot, resolve, reject); });
    }
    static play(plot, transition, transitionParams, viewX, viewY) {
        return new Promise((resolve, reject) => {
            // keep the current view if undefined/null
            let xUnset = viewX === undefined || viewX === null;
            let yUnset = viewY === undefined || viewY === null;
            if (xUnset || yUnset) {
                let currentView = plot.getCurrentTransitionView();
                if (xUnset)
                    viewX = currentView.x;
                if (yUnset)
                    viewY = currentView.y;
            }
            
            // create the new transition
            plot
            .transition(transition, transitionParams)
            .toView(viewX, viewY)
            .build()
            .then(() => { tools.#play2End(plot, resolve, reject); });
        });
    }
    static playMulti(plot, transition, transitionParams, views) {
        return new Promise((resolve, reject) => {
            // create the new transition
            let animation = plot.transition(transition, transitionParams);
            for (let view of views) {
                animation = animation.toView(view.x, view.y);
            }
            animation
                .build()
                .then(() => { tools.#play2End(plot, resolve, reject); });
        });
    }

    static getVisibleData(plot) {
        let view = plot.getCurrentTransitionView();
        let data = plot.data();
        let x = data.map(p => p[view.x.name]);
        let y = data.map(p => p[view.y.name]);
        return {x: x, y: y};
    }
    static getClosestDataPoint(plot, position) {
        // get info about the current plot view
        let view = plot.getCurrentTransitionView();
        let data = plot.data();
        let xDim = view.x.name;
        let yDim = view.y.name;

        // get the position in the original data domain
        let pos = plot.screenToDomain(position);

        // loop over all data points to get the closest one
        let closestPoint = data[0];
        let smallestDistance = Math.hypot(closestPoint[xDim] - pos.x, closestPoint[yDim] - pos.y);
        for (let point of data) {
            let distance = Math.hypot(point[xDim] - pos.x, point[yDim] - pos.y);
            if (distance <= smallestDistance) {
                closestPoint = point;
                smallestDistance = distance;
            }
        }

        return {
            point: closestPoint,
            distance: smallestDistance
        };
    }
}

window.tools = tools;