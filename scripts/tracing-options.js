{
class TracingOptions {
    constructor({
        IsTraining = false,
        SurveyGroupQuestionId = "{SGQ}",
        QuestionId = "{QID}",
        Transition = "rotortho",
        IsOneD = false,
        Task = "ClusterStudy",
        Step = 1
    }) {
        this.IsTraining = IsTraining;
        this.SurveyGroupQuestionId = SurveyGroupQuestionId;
        this.QuestionId = QuestionId;
        this.Transition = Transition;
        this.IsOneD = IsOneD;
        this.Task = Task;
        this.Step = Step;
    }
}

const opt = { TracingOptions: TracingOptions };
window.opt = opt;
}
