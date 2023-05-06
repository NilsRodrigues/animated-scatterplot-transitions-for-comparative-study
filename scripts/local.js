{
    const opt = window.opt;
    const tt = window.tt;

    function simulateLimesurveyAnswers() {
        function assignAnswer(evt) {
            const radio = this.querySelector("input");
            radio.checked = true;
            // change event only fires when the user clicks on the input. so we have to do it ourselves.
            answerField.value = radio.value;
        }
        const answerField = document.getElementById("java{SGQ}");
        function copyAnswer(evt) {
            const radio = this;
            answerField.value = radio.value;
        }

        const radios = document.querySelectorAll("[name='{SGQ}']");
        for (const radio of radios) {
            radio.addEventListener("change", copyAnswer);
            radio.parentElement.parentElement.addEventListener("click", assignAnswer)
        }
    }
    window.addEventListener("load", simulateLimesurveyAnswers);


    const sp = window.sp;
    const anims = Object.keys(tt.TransitionTypes);
    const animNames = anims.map((key) => tt.TransitionTypes[key].displayName);
    const tasks = ["Point", "Cluster"];
    const taskNames = ["Point Tracing", "Cluster Tracing"];
    const modes = ["Study", "Train", "Bot"];
    const modeNames = ["Analysis in Study", "Participant Training", "Attention Checks"];

    class LocalState {
        static intBetween(aNumber, min, max) {
            return Math.trunc(Math.max(min, Math.min(max, aNumber)));
        }

        #task = tasks[0];
        get task() {
            return this.#task;
        }
        set task(newValue) {
            // validate
            if (newValue === null || newValue === undefined) {
                newValue = tasks[0];
            } else if (!tasks.includes(newValue)) {
                throw new Error("Selected task is unknown.");
            }
            // set
            this.#task = newValue;
            this.#updateAnims();
            this.#updateProtocol();
        }

        #availableAnims = [];
        get availableAnims() {
            return this.#availableAnims;
        }
        #hiddenAnims = [];
        get hiddenAnims() {
            return this.#hiddenAnims;
        }
        #updateAnims() {
            const available = new Set(anims);
            const hidden = new Set();
            const otherTasks = tasks.filter((t) => t !== this.task);
            for (let otherTask of otherTasks) {
                const suffix = otherTask + "s";
                for (let currentAnim of available) {
                    if (currentAnim.endsWith(suffix)) {
                        hidden.add(currentAnim);
                        available.delete(currentAnim);
                    }
                }
            }
            this.#availableAnims = [...available];
            this.#hiddenAnims = [...hidden];
        }

        #mode = modes[0];
        get mode() {
            return this.#mode;
        }
        set mode(newValue) {
            // validate
            if (newValue === null || newValue === undefined) {
                newValue = modes[0];
            } else if (!modes.includes(newValue)) {
                throw new Error("Selected mode is unknown.");
            }
            // set
            this.#mode = newValue;
            this.#updateProtocol();
        }

        #protocol;
        get protocol() {
            // validate
            if (this.#protocol === undefined) {
                throw new Error("Unknown study protocol.");
            }
            return this.#protocol;
        }
        #updateProtocol() {
            // get the current study protocol
            this.#protocol = sp.Tasks[this.task + this.mode];
        }

        #anim = anims[0];
        get anim() {
            return this.#anim;
        }
        set anim(newValue) {
            // validate
            if (newValue === null || newValue === undefined) {
                newValue = anims[0];
            } else if (!anims.includes(newValue)) {
                throw new Error("Selected animation is unknown.");
            } else if (this.hiddenAnims.includes(newValue)) {
                // select variant of animation that is not hidden
                const otherTask = new RegExp("[A-Z].*$");
                newValue = newValue.replace(otherTask, this.task + "s");
                // check if it's available now
                if (!this.availableAnims.includes(newValue)) {
                    throw new Error("The animation is not available for the current task.");
                }
            }
            // set
            this.#anim = newValue;
        }

        #dims = 1;
        get dims() {
            return this.#dims;
        }
        set dims(newValue) {
            // validate dimension count
            if (Number.isNaN(newValue)) {
                newValue = 1;
            } else {
                // ensure it is exactly 1 or 2
                newValue = LocalState.intBetween(newValue, 1, 2);
            }
            // set
            this.#dims = newValue;
            this.#updateExperiments();
        }

        #experiments;
        get experiments() {
            // validate
            if (this.#experiments === undefined) {
                throw new Error("Unknown dimension count for experiments.");
            }
            return this.#experiments;
        }
        #updateExperiments() {
            const protocol = this.protocol;
            this.#experiments = protocol[`Experiments${this.dims}D`];
            this.#updateMaxStep();
        }

        #maxStep = -1;
        get maxStep() {
            return this.#maxStep;
        };
        #updateMaxStep() {
            let experiments = this.#experiments;
            if (experiments === undefined) {
                this.#maxStep = -1;
            } else {
                this.#maxStep = experiments.length - 1;
            }
        }

        #currentStep = 0;
        get step() {
            return this.#currentStep;
        }
        set step(newValue) {
            if (Number.isNaN(newValue)) {
                newValue = 0;
            } else {
                // ensure it corresponds to an experiment
                newValue = LocalState.intBetween(newValue, 0, this.maxStep);
            }
            this.#currentStep = newValue;
        }

        #feedback = false;
        get feedback() {
            return this.#feedback;
        }
        set feedback(newValue) {
            this.#feedback = newValue;
        }

        load() {
            this.task = window.sessionStorage.getItem("task");
            this.anim = window.sessionStorage.getItem("anim");
            this.mode = window.sessionStorage.getItem("mode");
            this.dims = parseInt(window.sessionStorage.getItem("dims"));
            this.step = parseInt(window.sessionStorage.getItem("step"));
            this.feedback = window.sessionStorage.getItem("feedback") === "true";
        }
        save() {
            window.sessionStorage.setItem("task", this.task);
            window.sessionStorage.setItem("anim", this.anim);
            window.sessionStorage.setItem("mode", this.mode);
            window.sessionStorage.setItem("dims", this.dims);
            window.sessionStorage.setItem("step", this.step);
            window.sessionStorage.setItem("feedback", this.feedback);
        }
    }
    const localState = new LocalState();

    function reloadPage() {
        window.location.reload();
    }

    function navSelectionHandler(evt) {
        const selector = evt.currentTarget;
        localState[selector.name] = selector.value;
        localState.save();
        reloadPage();
    }

    function addSelector(container, options, value, name, label = undefined, displayTexts = undefined) {
        // add label
        if (label !== undefined) {
            const theLabel = document.createElement("label");
            theLabel.htmlFor = name;
            theLabel.innerHTML = label;
            container.appendChild(theLabel);
        }
        
        // check display texts
        if (displayTexts !== undefined) {
            if (!Array.isArray(displayTexts))
                throw new Error("Need array of strings.");
            if (displayTexts.length !== options.length)
                throw new Error("Need same number of options and display strings.");
        }

        // create select
        const optionContainer = document.createElement("select");
        // add options
        for (let idx in options) {
            const option = document.createElement("option");
            option.value = options[idx];
            option.innerHTML = (displayTexts !== undefined) ? displayTexts[idx] : options[idx];
            optionContainer.appendChild(option);
        }
        // add select to document
        optionContainer.id = name;
        optionContainer.name = name;
        optionContainer.value = value;
        optionContainer.setAttribute("required", "");
        container.appendChild(optionContainer);
        
        optionContainer.addEventListener("change", navSelectionHandler);

        return optionContainer;
    }

    function navToggleHandler(evt) {
        const toggle = evt.currentTarget;
        localState[toggle.name] = toggle.checked;
        localState.save();
        reloadPage();
    }

    function addToggle(container, value, name, label = undefined) {
        // create checkbox
        const toggle = document.createElement("input");
        toggle.id = name;
        toggle.name = name;
        toggle.type = "checkbox";
        toggle.checked = value;
        toggle.addEventListener("change", navToggleHandler);
        container.appendChild(toggle);

        // add label
        if (label === undefined || label === null) {
            label = name;
        }
        const theLabel = document.createElement("label");
        theLabel.htmlFor = name;
        theLabel.innerHTML = label;
        container.appendChild(theLabel);
    }

    function navStepHandler(evt) {
        const stepBtn = evt.target;
        let deltaStep = 0;
        switch(stepBtn.value) {
            case "moveprev":
                deltaStep = -1;
                break;
            case "movenext":
                deltaStep = 1;
                break;
            default:
                throw new Error("Unknown step direction.");
        }
        navigateStep(deltaStep);
    }

    function navigateStep(deltaStep) {
        // navigate through tests. loop around at beginning and end
        if (deltaStep > 0 && localState.maxStep === localState.step) {
            localState.step = 0;
        } else if (deltaStep < 0 && localState.step === 0) {
            localState.step = localState.maxStep;
        } else {
            localState.step += deltaStep;
        }
        localState.save();
        reloadPage();
    }

    function initNavigation() {
        const navbar = document.getElementById("navbar");
        if (!(navbar instanceof HTMLElement))
            throw new Error("No HTML element with the id=\"navbar\".");

        // create selectors for settings
        const steps = [...Array(localState.maxStep+1).keys()];
        const stepNames = steps.map((e) => e+1);
        const animSelector = addSelector(navbar, anims, localState.anim, "anim", "Animation: ", animNames);
        const taskSelector = addSelector(navbar, tasks, localState.task, "task", "Task: ", taskNames);
        const modeSelector = addSelector(navbar, modes, localState.mode, "mode", "Used for: ", modeNames);
        const feedbackToggle = addToggle(navbar, localState.feedback, "feedback", "Always Show Feedback for Training");
        const dimsSelector = addSelector(navbar, [1,2], localState.dims, "dims", "Dimensionality: ", ["1D", "2D"]);
        const stepSelector = addSelector(navbar, steps, localState.step, "step", "Experiment: ", stepNames);

        // we have different settings for point/cluster tasks => hide settings that don't fit the current task
        for(let option of animSelector.children) {
            if (localState.hiddenAnims.includes(option.value)) {
                option.remove();
            }
        }

        // add next/prev buttons
        const prevBtn = document.createElement("button");
        prevBtn.value = "moveprev";
        prevBtn.innerHTML = "-";
        prevBtn.addEventListener("click", navStepHandler);
        navbar.appendChild(prevBtn);
        const nextBtn = document.createElement("button");
        nextBtn.value = "movenext";
        nextBtn.innerHTML = "+";
        nextBtn.addEventListener("click", navStepHandler);
        navbar.appendChild(nextBtn);

        // hook up next button
        const submitResponseBtn = document.getElementById("ls-button-submit");
        submitResponseBtn.addEventListener("click", navStepHandler);
    }

    async function initPage() {
        // load state between page reloads
        localState.load();
        // save state to preserve it between page reloads
        localState.save();

        // apply restored settings
        initNavigation();
        window.tracingOptions = {
            SurveyGroupQuestionId: "{SGQ}",
            QuestionId: "{QID}",
            IsTraining: localState.mode === "Train" || localState.feedback,
            IsOneD: localState.dims === 1,
            Task: localState.task + localState.mode,
            Transition: localState.anim,
            Step: localState.step,
        };
        const options = new opt.TracingOptions(window.tracingOptions);

        // show training indicator
        if (options.IsTraining) {
            const elem = document.querySelector(".training-indicator");
            elem.classList.add("enabled");
        }

        // show task buttons
        const taskBtnContainers = document.querySelectorAll(`div.ButtonContainer.${localState.task}`);
        for (let btnContainer of taskBtnContainers) {
            btnContainer.classList.remove("hidden");
        }

        // init plot and animation
        let tracing;
        switch (localState.task) {
            case "Point":
                const pt = window.pt;
                tracing = new pt.PointTracing(options);
                break;
            case "Cluster":
                const ct = window.ct;
                tracing = new ct.ClusterTracing(options);
                break;
            default:
                throw new Error("Demo page logic error 1680262786.");
        }
        await tracing.initialize();
    }
    window.addEventListener("load", initPage);


}