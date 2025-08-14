using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
using UnityEngine.XR.ARFoundation;
using UnityEngine.XR.ARSubsystems;


public class Initializer : MonoBehaviour
{
    [SerializeField] private DisplayConfig _display;
    public static DisplayConfig display;
    void Awake()
    {
        display = _display;
        display.SendToShader();
        //両眼検出器生成
        var obj = new GameObject("FaceManager");
#if DEVELOPMENT_BUILD || UNITY_EDITOR
        obj.AddComponent<TrackingManual>();
#else
        obj.AddComponent<Tracking>();
#endif
        //仮想カメラ同期オブジェクト生成
        obj = new GameObject("StereoCamera");
        obj.AddComponent<CameraSync>();

        //CanvasのRawImage (視差画像表示用)を初期化
        obj = GameObject.Find("Canvas/RIRendered3DImage");
        obj.AddComponent<ShowImage>();

    }
}

