// workaround for local modules without webserver
{
const d3 = window.d3;
const st = d3.scatterTrans;

const opt = window.opt;
const tools = window.tools;
const ds = window.ds;
const sp = window.sp;
const tt = window.tt.TransitionTypes;


class PointTracing {
    #options;
    /**
     * @param {opt.TracingOptions} options 
     */
    constructor(options) {
        // check whether options have been set in limesurvey
        this.#options = options;
        if (!this.#options || !(this.#options instanceof opt.TracingOptions))
            throw `Failed to provide ${opt.TracingOptions.name} for ${PointTracing.name}.`;

        this.#initCssVars();
        this.#initUIElementVars();
        this.#applyOptions();
    }
    
    #isTraining
    #transitionType;
    #isOneD;
    #task;
    #datasetName;
    #datapointId;
    #views;
    /**
     * Get task info from options and study protocol.
     */
    #applyOptions() {
        const options = this.#options;
        this.#isTraining = options.IsTraining;
        this.#transitionType = tt[options.Transition];
        this.#isOneD = options.IsOneD;

        this.#task = sp.Tasks[options.Task];
        const experiment = this.#task[`Experiments${(this.#isOneD ? "1" : "2")}D`][options.Step];
        this.#datasetName = experiment.datasetName;
        this.#datapointId = experiment.datapointId;
        if (this.#isOneD) {
            this.#views = experiment.dims;
        } else {
            this.#views = this.#transitionType.transtype.requiresCommonDimensions ? experiment.commonDims : experiment.directDims;
        }
    }

    #isSinglePlot;
    #questionContainerId;
    #questionArea;
    #answerArea;
    #animateBtn;
    #continueBtn;
    #submitBtn;
    #initUIElementVars() {
        this.#isSinglePlot = document.querySelectorAll(".PlotContainer").length <= 1;
        const questionContainerId = this.#questionContainerId = `question${this.#options.QuestionId}`;
        this.#questionArea = tools.RequireUIElement(`#${CSS.escape(questionContainerId)} .PlotContainer`, HTMLDivElement);
        this.#answerArea = tools.RequireUIElement(`#${CSS.escape("answer".concat(this.#options.SurveyGroupQuestionId))}`, HTMLTextAreaElement);
        this.#animateBtn = tools.RequireUIElement(`#${CSS.escape(questionContainerId)} .Point .AnimateBtn`, HTMLButtonElement);
        this.#continueBtn = tools.RequireUIElement(`#${CSS.escape(questionContainerId)} .Point .ContinueBtn`, HTMLButtonElement);
        this.#submitBtn = tools.RequireUIElement("#ls-button-submit", HTMLButtonElement, true);
    }

    #plotSize;
    #dotRadius;
    #adornerLayerClass;
    #adornerThickness;
    #adornerPadding;
    #selectedDotClass;
    #selectedDotDuration;
    #selectedPositionClass;
    #selectedPositionDuration;
    #initCssVars() {
        const computedStyle = getComputedStyle(document.body);

        this.#plotSize = parseFloat(computedStyle.getPropertyValue("--plot-size-px"));
        this.#dotRadius = parseFloat(computedStyle.getPropertyValue("--dot-radius-px"));
        this.#adornerLayerClass = computedStyle.getPropertyValue("--adorner-layer-class");
        this.#adornerThickness = parseFloat(computedStyle.getPropertyValue("--adorner-thickness-px"));
        this.#adornerPadding = parseFloat(computedStyle.getPropertyValue("--adorner-padding-px"));

        this.#selectedDotClass = computedStyle.getPropertyValue("--selectDot-class");
        this.#selectedDotDuration = parseFloat(computedStyle.getPropertyValue("--selectDot-animation-duration-ms"));
        this.#selectedPositionClass = computedStyle.getPropertyValue("--selectPos-class");
        this.#selectedPositionDuration = parseFloat(computedStyle.getPropertyValue("--selectDot-animation-duration-ms"));
    }

    #dataSet;
    #dimNames;
    #dims;
    #svg;
    #dotContainer;
    #adornerContainer;
    #plot;
    #circles;
    #circleNodes;
    /** set up plotting, study, and experiment variables */
    async #initPlot() {
        // load data
        this.#dataSet = await ds.LoadedData.fromDataSetName(this.#datasetName);

        // get numerical dimensions
        this.#dimNames = this.#dataSet.numericDims;
        this.#dims = this.#dimNames.map((dimName) => st.Dimension.fromData(dimName, this.#dataSet.data));

        // create svg element for plotting
        const svg = this.#svg = d3.select(`#${CSS.escape(this.#questionContainerId)} svg`);
        svg.attr("width", this.#plotSize);
        svg.attr("height", this.#plotSize);

        // create separate svg groups for dots and adorners
        this.#dotContainer = svg.append("g");
        const adornerContainer = this.#adornerContainer = svg.append("g");
        adornerContainer.classed(this.#adornerLayerClass, true);

        // create scatterplot
        const plot = this.#plot = st.scatterplot();
        plot.data(this.#dataSet.data);
        plot.size(this.#plotSize, this.#plotSize);
        plot.speed(this.#transitionType.speed);
        plot.view(this.#dims[this.#views[0].x], this.#dims[this.#views[0].y]);

        // render scatterplot to svg
        const circles = this.#circles = plot.createCircles(this.#dotContainer);
        circles.attr("r", null); // remove attribute, radius is handled in CSS
        circles.attr("fill", null); // remove attributes
        circles.style("fill", null); // remove style
        this.#circleNodes = circles.nodes();

        //console.info("Setup done.");
    }

    #readyForAnimation = false;
    async #prepareForAnimation() {
        // show play button for animation but keep it disabled until the tracking target is visible
        this.#animateBtn.setAttribute("disabled", "");
        this.#animateBtn.classList.add("enabled");

        // highlight tracking target and enable animation button
        await this.#selectDotIdx(this.#datapointId);
        this.#animateBtn.addEventListener("click", this.#playAnimationHandler);
        this.#animateBtn.removeAttribute("disabled");

        // disable submitting the answer
        if (this.#isSinglePlot && this.#submitBtn)
            this.#submitBtn.setAttribute("disabled", "");

        this.#readyForAnimation = true;
    }

    async initialize() {
        if (!this.#readyForAnimation) {
            await this.#initPlot();
            await this.#prepareForAnimation();
        }
    }


    #clearHighlights() {
        this.#adornerContainer.selectChildren().remove();
    }

    /**
     * 'Selects' a dot by creating an adorner to hightlight it.
     * @param {d3.Selection} dotSelection - Selection containing a single dot from the scatter plot.
     */
    async #selectDot(dotSelection) {
        // remove previous adorners
        this.#clearHighlights();

        // get info from selected dot
        let dotX = dotSelection.attr("cx");
        let dotY = dotSelection.attr("cy");

        // add new adorner
        let adorner = this.#adornerContainer.append("circle");
        adorner.attr("cx", dotX);
        adorner.attr("cy", dotY);
        adorner.classed(this.#selectedDotClass, true);
        await tools.sleep(this.#selectedDotDuration);
    }

    /**
     * 
     * @param {Number} dotIdx index of dot in data set 
     */
    async #selectDotIdx(dotIdx) {
        const dotNode = this.#circleNodes[dotIdx];
        const selection = d3.select(dotNode);
        await this.#selectDot(selection);
    }

    #playAnimationHandler = (evt) => { this.playAnimation(evt); }

    /**
     * @param {MouseEvent} evt - Click event.
     */
    async playAnimation(evt) {
        if (!this.#readyForAnimation)
            throw "Not ready for animation, yet.";

        const button = evt.target;
        if (!button || !(button instanceof HTMLButtonElement))
            throw "Attempted animation without click on button.";

        // hide button and ensure we don't handle this multiple times
        button.removeEventListener("click", this.#playAnimationHandler);
        button.classList.remove("enabled");
        button.setAttribute("disabled", "");

        // remove highlights to not interfere with viewing the data
        this.#clearHighlights();

        // transition to other views
        /*for (let view of this.#views.slice(1)) {
            await tools.play(this.#plot, this.#transitionType.transtype, this.#transitionType.params, this.#dims[view.x], this.#dims[view.y]);
        }*/
        const viewSequence = this.#views.slice(1).map(v => ({x: this.#dims[v.x], y: this.#dims[v.y]}));
        let transitionParams = this.#transitionType.params;
        // override params to make bot questions simpler
        if (this.#datasetName.endsWith("Bot")) {
            if (transitionParams.bundlingStrength > 0)
                transitionParams.bundlingStrength = 1;
            if (transitionParams.clustering)
                transitionParams.clustering = {
                    epsMin: 0.29,
                    epsMax: 0.29,
                    ptsMin: 5,
                    ptsMax: 5
                }
        }
        await tools.playMulti(this.#plot, this.#transitionType.transtype, transitionParams, viewSequence);
        this.#plot.finishTransition();
        
        // enable giving and answer by clicking a position on the page
        this.#questionArea.addEventListener("click", this.#selectClickPositionHandler);

        // mark event as handled
        evt.preventDefault();
        evt.stopPropagation();

        //console.info("View change animation done.");
    }

    /**
     * 'Selects' a position on the scatter plot by creating an adorner to hightlight it.
     * @param {Object} drawingPos - The click position relative to the drawing of the scatter plot (same as coordinate system of dot circles).
     * @param {number} drawingPos.x - The x position in pixels.
     * @param {number} drawingPos.y - The y position in pixels.
     * @returns {number} The selected position in normalized plot coordinates.
     */
    async #selectPosition(drawingPos) {
        // get info from selected position
        let normalizedPos = this.#plot.drawingToNormalized(drawingPos);
        //console.info(`Selected position {x: ${drawingPos.x.toFixed(4)}, y: ${drawingPos.y.toFixed(4)}} on drawing and normalized to {x: ${normalizedPos.x.toFixed(4)}, y: ${normalizedPos.y.toFixed(4)}}.`);

        // write selected position into answer
        const actual = this.#composeAnswer(normalizedPos);
        
        // ensure the participant can continue to the next question
        if (this.#isSinglePlot && this.#submitBtn) {
            this.#submitBtn.removeAttribute("disabled");
            this.#continueBtn.addEventListener("click", this.#nextQuestionHandler);
            this.#continueBtn.removeAttribute("disabled");
            this.#continueBtn.classList.add("enabled");
        }

        // remove previous adorners
        this.#clearHighlights();

        if (this.#isTraining) {
            // stop changing the answer
            this.#questionArea.removeEventListener("click", this.#selectClickPositionHandler);

            // connecting line between actual and selected position
	        let connection = this.#adornerContainer.append("line");
	        connection.attr("x1", `${actual.x * 100}%`);
	        connection.attr("y1", `${(1-actual.y) * 100}%`);
	        connection.attr("x2", `${normalizedPos.x * 100}%`);
	        connection.attr("y2", `${(1-normalizedPos.y) * 100}%`);

            // actual position
	        let actualAdorner = this.#adornerContainer.append("circle");
	        actualAdorner.attr("cx", `${actual.x * 100}%`);
	        actualAdorner.attr("cy", `${(1-actual.y) * 100}%`);
	        actualAdorner.classed(this.#selectedDotClass, true);
        }
        
        // selected position
        let selectedAdorner = this.#adornerContainer.append("circle");
        selectedAdorner.attr("cx", `${normalizedPos.x * 100}%`);
        selectedAdorner.attr("cy", `${(1-normalizedPos.y) * 100}%`);
        selectedAdorner.classed(this.#selectedPositionClass, true);
        
        // wait for animation to finish
        await tools.sleep(this.#selectedPositionDuration);
        
        return normalizedPos;
    }


    #nextQuestionHandler = (evt) => { this.#nextQuestion(evt);}

    /**
     * @param {MouseEvent} evt - Click event.
     */
    #nextQuestion(evt) {
        // stop changing the answer
        this.#questionArea.removeEventListener("click", this.#selectClickPositionHandler);

        // mark this click as handled
        evt.preventDefault();
        evt.stopPropagation();

        // submit the form, if there are no other questions
        if (this.#isSinglePlot && this.#submitBtn) {
            // disable our "next" button
            this.#animateBtn.setAttribute("disabled", "");
            this.#animateBtn.classList.remove("enabled");
            this.#continueBtn.setAttribute("disabled", "");
            this.#continueBtn.classList.remove("enabled");
            // click limesurvey's submit button
            this.#submitBtn.click();
        }

        return true;
    }


    #composeAnswer(normalizedPos) {
        // get normalized position of correct answer and error
        const datapoint = this.#dataSet.data[this.#datapointId];
        const actualX = this.#plot.dataPointX(datapoint);
        const actualY = this.#plot.dataPointY(datapoint);
        const error = Math.hypot(normalizedPos.x - actualX, normalizedPos.y - actualY);

        // compose answer to limesurvey question for the records
        const answer = {
            //actualX: actualX,
            //actualY: actualY,
            x: normalizedPos.x,
            y: normalizedPos.y,
            //error: error
        };
        this.#answerArea.textContent = JSON.stringify(answer);
        //console.dir(answer);

        return {
            x: actualX,
            y: actualY,
            error: error
        }
    }

    #selectClickPositionHandler = async (evt) => { await this.#selectClickPosition(evt); }

    /**
     * @param {MouseEvent} evt 
     */
    async #selectClickPosition(evt) {
        const drawingPos = tools.clientPosToDrawingPos(this.#dotContainer, evt);
        const normalizedPos = await this.#selectPosition(drawingPos);
    }
}


window.pt = { PointTracing: PointTracing, TracingOptions: opt.TracingOptions };

}