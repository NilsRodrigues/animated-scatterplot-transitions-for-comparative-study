// workaround for local modules without webserver
{
const d3 = window.d3;
const st = d3.scatterTrans;

// my clusters
const myClusterConfig = {
    epsMin: 0.1,
    epsMax: 0.1,
    ptsMin: 5,
    ptsMax: 5
}
// autoMPG
const autoMpgConfig = {
    epsMin: 0.1,
    epsMax: 0.1,
    ptsMin: 5,
    ptsMax: 5
}

const TransitionTypes = {
    straight: {
        transtype: st.StraightTransition,
        params: {},
        speed: 1,
        displayName: "Straight Lines"
    },
    bundledPoints: {
        transtype: st.SplineTransition,
        params: {
            clustering: autoMpgConfig,
            retime: st.retimeIdentity,
            bundlingStrength: 3
        },
        speed: 1,
        displayName: "Bundled Lines"
    },
    bundledClusters: {
        transtype: st.SplineTransition,
        params: {
            clustering: myClusterConfig,
            retime: st.retimeIdentity,
            bundlingStrength: 3
        },
        speed: 1,
        displayName: "Bundled Lines"
    },
    timeoffsetPoints: {
        transtype: st.SplineTransition,
        params: {
            clustering: autoMpgConfig,
            retime: st.retimeEqualNonOverlappingCascade,
            bundlingStrength: 0
        },
        speed: 0.5,
        displayName: "Time-offset Lines"
    },
    timeoffsetClusters: {
        transtype: st.SplineTransition,
        params: {
            clustering: myClusterConfig,
            retime: st.retimeEqualNonOverlappingCascade,
            bundlingStrength: 0
        },
        speed: 0.5,
        displayName: "Time-offset Lines"
    },
    rotstaged: {
        transtype: st.RotationTransition,
        params: { perspective: 1, staged: true, ease: d3.easeCubicInOut },
        speed: (1.0/2.5),
        displayName: "Staged Rotation"
    },
    rotpersp: {
        transtype: st.RotationTransition,
        params: { perspective: 1 },
        speed: 1,
        displayName: "Perspective Rotation"
    },
    rotortho: {
        transtype: st.RotationTransition,
        params: {},
        speed: 1,
        displayName: "Orthographic Rotation"
    }
};

window.tt = {TransitionTypes: TransitionTypes};
}