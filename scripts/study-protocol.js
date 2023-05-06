// workaround for local modules without webserver
{
const sp = window.sp;

const StudyProtocol = {
    Tasks: {
        PointTrain:     sp.PointTrain,
        PointStudy:     sp.PointStudy,
        PointBot:       sp.PointBot,
        ClusterTrain:   sp.ClusterTrain,
        ClusterStudy:   sp.ClusterStudy,
        ClusterBot:     sp.ClusterBot
    },
};

window.sp = StudyProtocol;
}
