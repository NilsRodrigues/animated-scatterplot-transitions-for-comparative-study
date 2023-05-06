// workaround for local modules without webserver
{
const d3 = window.d3;
const st = d3.scatterTrans;

const opt = window.opt;
const tools = window.tools;
const ds = window.ds;
const sp = window.sp;
const tt = window.tt.TransitionTypes;

class ClusterTracing {

    #options;
    /**
     * @param {opt.TracingOptions} options 
     */
    constructor(options) {
        // check whether options have been set in limesurvey
        this.#options = options;
        if (!this.#options || !(this.#options instanceof opt.TracingOptions))
            throw `Failed to provide ${opt.TracingOptions.name} for ${ClusterTracing.name}.`;

        this.#applyOptions();
        this.#initCssVars();
        this.#initUIElementVars();
    }

    #isTraining;
    #transitionType;
    #isOneD;
    #task;
    #datasetName;
    #datapointIds;
    #views;
    #correctAnswer;
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
        this.#datapointIds = experiment.datapointIds;
        if (this.#isOneD) {
            this.#views = experiment.dims;
        } else {
            this.#views = this.#transitionType.transtype.requiresCommonDimensions ? experiment.commonDims : experiment.directDims;
        }
        this.#correctAnswer = experiment.actual;
    }

    #isSinglePlot;
    #questionContainerId;
    #animateBtn;
    #myAnswerBtns;
    #assessmentRight;
    #assessmentWrong;
    //#answerArea;
    #answerBtns;
    #answerField;
    #submitBtn;
    #initUIElementVars() {
        this.#isSinglePlot = document.querySelectorAll(".PlotContainer").length <= 1;
        const questionContainerId = this.#questionContainerId = `question${this.#options.QuestionId}`;
        this.#animateBtn = tools.RequireUIElement(`#${CSS.escape(questionContainerId)} .Cluster .AnimateBtn`, HTMLButtonElement);
        this.#myAnswerBtns = tools.RequireUIElements(`#${CSS.escape(questionContainerId)} .myAnswerBtns`, HTMLButtonElement);
        this.#assessmentRight = tools.RequireUIElement(`#${CSS.escape(questionContainerId)} .assessment-container .right`, undefined, !this.#isTraining);
        this.#assessmentWrong = tools.RequireUIElement(`#${CSS.escape(questionContainerId)} .assessment-container .wrong`, undefined, !this.#isTraining);
        //this.#answerArea = tools.RequireUIElement(`#${CSS.escape(questionContainerId)} .answer-container`, HTMLDivElement, this.#isTraining);
        this.#answerBtns = tools.RequireUIElements(`#${CSS.escape(questionContainerId)} .bootstrap-radio`, HTMLInputElement, true);
        this.#answerField = tools.RequireUIElement(`#${CSS.escape(`java${this.#options.SurveyGroupQuestionId}`)}`, HTMLInputElement, this.#isTraining);
        this.#submitBtn = tools.RequireUIElement("#ls-button-submit", HTMLButtonElement, true);
    }

    #plotSize;
    #dotRadius;
    #selectedClusterClass;
    #initCssVars() {
        const computedStyle = getComputedStyle(document.body);
        this.#plotSize = parseFloat(computedStyle.getPropertyValue("--plot-size-px"));
        this.#dotRadius = parseFloat(computedStyle.getPropertyValue("--dot-radius-px"));
        this.#selectedClusterClass = computedStyle.getPropertyValue("--selected-cluster-class");
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
        //dataSet = window.dataSet = await ds.LoadedData.fromCsv("./data/mtcars.csv");
        this.#dataSet = await ds.LoadedData.fromDataSetName(this.#datasetName); //await ds.LoadedData.fromCsv("./data/mtcars.csv");

        // get numerical dimensions
        this.#dimNames = this.#dataSet.numericDims;
        this.#dims = this.#dimNames.map((dimName) => st.Dimension.fromData(dimName, this.#dataSet.data));

        // create svg element for plotting
        const svg = this.#svg = d3.select(`#${CSS.escape(this.#questionContainerId)} svg`);
        svg.attr("width", this.#plotSize);
        svg.attr("height", this.#plotSize);

        // create separate svg group for dots and adorners
        this.#dotContainer = svg.append("g");
        this.#adornerContainer = svg.append("g");
        this.#adornerContainer.classed(this.#selectedClusterClass, true);

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

    #prepareForAnswering() {
        // enable and hook up my answer buttons
        const handler = this.#provideStudyAnswerHandler;//this.#isTraining ? this.#provideTrainingAnswerHandler : this.#provideStudyAnswerHandler;
        for (const btn of this.#myAnswerBtns) {
            btn.addEventListener("click", handler);
            btn.removeAttribute("disabled");
            btn.classList.add("enabled");
        }
        
        // enable limesurvey's answer buttons. somehow, they are still necessary.
        for (const btn of this.#answerBtns) {
            btn.removeAttribute("disabled");
        }
        
        // enable limesurvey's submit button, if this is the only plot on the page.
        if (this.#isSinglePlot && this.#submitBtn) {
            this.#submitBtn.removeAttribute("disabled");
        }

        // ensure all answer buttons are the same size
        let maxWidth = Number.NEGATIVE_INFINITY;
        for (const btn of this.#myAnswerBtns) {
            const btnStyle = window.getComputedStyle(btn);
            const borderWidth = parseFloat(btnStyle["border-left-width"]) + parseFloat(btnStyle["border-right-width"]);
            const width = btn.scrollWidth + borderWidth;
            if (width > maxWidth)
                maxWidth = width;
        }
        for (const btn of this.#myAnswerBtns) {
            btn.style.width = btn.style["min-width"] = btn.style["max-width"] = `${maxWidth}px`;
        }
    }

    async #highlightCluster() {
        await this.#selectDotIdx(this.#datapointIds);
    }

    #readyForAnimation = false;
    async #prepareForAnimation() {
        // show play button for animation but keep it disabled until the tracking target is visible
        this.#animateBtn.setAttribute("disabled", "");
        this.#animateBtn.classList.add("enabled");

        // highlight tracking target and enable animation button
        await this.#highlightCluster();
        this.#animateBtn.addEventListener("click", this.#playAnimationHandler);
        this.#animateBtn.removeAttribute("disabled");

        // disable answer buttons before running the animation
        for (const btn of this.#myAnswerBtns) {
            btn.setAttribute("disabled", "");
        }
        for (const btn of this.#answerBtns) {
            btn.setAttribute("disabled", "");
        }
        if (this.#isSinglePlot && this.#submitBtn) {
            this.#submitBtn.setAttribute("disabled", "");
        }

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
    async #selectDots(dotSelection) {
        // remove previous adorners
        this.#clearHighlights();

        // clone selected dots
        let newDots = dotSelection.clone(true);

        // put them in the adorner layer
        newDots.remove();
        const container = this.#adornerContainer.node();
        newDots.nodes().map(d => container.append(d));
    }

    /**
     * 
     * @param {Number} dotIdx index of dot in data set 
     */
    async #selectDotIdx(dotIdx) {
        const dotNodes = this.#datapointIds.map(i => this.#circleNodes[i]);
        const selection = d3.selectAll(dotNodes);
        await this.#selectDots(selection);
    }

    #playAnimationHandler = async (evt) => { await this.playAnimation(evt); }

    /**
     * @param {MouseEvent} evt - Click event.
     */
    async playAnimation(evt) {
        if (!this.#readyForAnimation)
            throw "Not ready for animation, yet.";

        // hide button and ensure we don't handle this multiple times
        this.#animateBtn.removeEventListener("click", this.#playAnimationHandler);
        this.#animateBtn.classList.remove("enabled");
        this.#animateBtn.setAttribute("disabled", "");

        // remove highlights to not interfere with viewing the data
        this.#clearHighlights();

        // transition to other views
        /*for (const view of this.#views.slice(1)) {
            await tools.play(this.#plot, this.#transitionType.transtype, this.#transitionType.params, this.#dims[view.x], this.#dims[view.y]);
        }*/
        const viewSequence = this.#views.slice(1).map(v => ({x: this.#dims[v.x], y: this.#dims[v.y]}));
        await tools.playMulti(this.#plot, this.#transitionType.transtype, this.#transitionType.params, viewSequence);
        this.#plot.finishTransition();
        
        // enable giving an answer
        this.#prepareForAnswering();

        // mark event as handled
        evt?.preventDefault();
        evt?.stopPropagation();

        //console.info("View change animation done.");
    }


    #provideStudyAnswerHandler = async (evt) => { return this.#provideStudyAnswer(evt); }

    #isAnswerGiven = false;
    async #provideStudyAnswer(evt) {
        // ignore subsequent answers when not training
        if (this.#isAnswerGiven) {
            return;
        }
        this.#isAnswerGiven = true;

        // check whether we really aren't training
        //if (this.#isTraining)
        //    throw "Study handler hooked up to training task.";

        // check whether the user gave the correct answer
        const clickedBtn = evt.currentTarget;
        const isCorrect = clickedBtn.value === this.#correctAnswer;

        // hide the answer options and prevent future clicks
        for (const btn of this.#myAnswerBtns) {
            // hide the buttons (but keep the clicked one during training)
            btn.classList.remove("enabled");
            btn.setAttribute("disabled", "");
            btn.removeEventListener("click", this.#provideStudyAnswerHandler);
        }

        // do virtual click on limesurvey's answer buttons
        for (const limebtn of this.#answerBtns) {
            if (limebtn.value === clickedBtn.value) {
                limebtn.click();
                break;
            }
        }

        if (this.#isTraining) {
            // show whether the user was right
            if (isCorrect) {
                this.#assessmentWrong.classList.remove("enabled");
                this.#assessmentRight.classList.add("enabled");
            } else {
                this.#assessmentRight.classList.remove("enabled");
                this.#assessmentWrong.classList.add("enabled");
            }
            // show the correct answer
            for (const btn of this.#myAnswerBtns) {
                if (btn.value == this.#correctAnswer)
                    btn.classList.add("enabled");
                else
                    btn.classList.remove("enabled");
            }
            // show the cluster, again
            await this.#highlightCluster();
        }

        // wait for the limesurvey scripts to fill the answer field
        while(this.#answerField.value === "") {
            await tools.sleep(100);
        }

        // submit answer or show the button for the user to click on
        if (this.#submitBtn) {
            if (this.#isTraining) {
                this.#submitBtn.removeAttribute("disabled");
                this.#submitBtn.classList.add("enabled");
            } else if (this.#isSinglePlot) {
                this.#submitBtn.click();
            }
        }
    }
}


window.ct = { ClusterTracing: ClusterTracing, TracingOptions: opt.TracingOptions };

}