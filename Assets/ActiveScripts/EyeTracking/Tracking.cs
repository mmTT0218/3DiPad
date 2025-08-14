using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.XR.ARFoundation;
using UnityEngine.XR.ARSubsystems;

public class Tracking : FaceManager
{
    private Camera arCamera;
    private ARFaceManager arFaceManager;
    private ControllerMaster leftCameraController, rightCameraController;
    private DisplayConfig display;

    private void Awake()
    {
        var obj = GameObject.Find("AR Session Origin");
        arFaceManager = obj.GetComponent<ARFaceManager>();
        arCamera = obj.transform.Find("AR Camera").GetComponent<Camera>();
        display = Initializer.display;
    }

    private void Start()
    {
        leftCameraController = GameObject.Find("LeftCameraController").GetComponent<ControllerMaster>();
        rightCameraController = GameObject.Find("RightCameraController").GetComponent<ControllerMaster>();
        string[] name = { "X", "Y", "Z" };
        float[] init = { 0, 0, 0 };
        float[] min = { -50, -50, -50 };
        float[] max = { 50, 50, 50 };
        leftCameraController.SetValue(3, name, init, min, max);
        rightCameraController.SetValue(3, name, init, min, max);
    }

    private void OnEnable() { arFaceManager.facesChanged += OnFaceChanged; }

    private void OnDisable() { arFaceManager.facesChanged -= OnFaceChanged; }

    private void OnFaceChanged(ARFacesChangedEventArgs eventArgs)
    {
        if (eventArgs.updated.Count != 0)
        {
            var arFace = eventArgs.updated[0];
            if ((arFace.trackingState == TrackingState.Tracking) && (ARSession.state > ARSessionState.Ready))
            {
                //カメラの左右が反転するので代入先が逆になる。内カメラだけ？
                //ディスプレイ中心を原点とする座標系に変換
                leftEye = ConvertToDisplayOrigin(WorldToCamera(arFace.rightEye.position)) + leftCameraController.xyz;
                rightEye = ConvertToDisplayOrigin(WorldToCamera(arFace.leftEye.position)) + rightCameraController.xyz;
            }
        }
    }

    //ワールド座標系を内蔵カメラを原点とする座標系に変換（右手座標系：単位[mm]）
    Vector3 WorldToCamera(Vector3 worldPos)
    {
        var v = arCamera.worldToCameraMatrix.MultiplyVector(worldPos);
        v *= 1000f;
        v.z *= -1f;
        return v;
    }

    Vector3 ConvertToDisplayOrigin(Vector3 cameraPos)
    {
        var v = cameraPos;
        //ディスプレイの中心を原点とする座標系に変換
        //iPadのカメラの位置がディスプレイの左側の時(iPadの向きの話)
        if (display.Orientation == ScreenOrientation.LandscapeLeft) v.x -= display.Size.x / 2f;
        //iPadのカメラの位置がディスプレイの右側の時(iPadの向きの話)
        else if (display.Orientation == ScreenOrientation.LandscapeRight) v.x += display.Size.x / 2f;
        //iPadのカメラの位置がディスプレイの上側の時(iPadの向きの話)
        else if (display.Orientation == ScreenOrientation.Portrait) v.y += display.Size.y / 2f;
        //iPadのカメラの位置がディスプレイの下側の時(iPadの向きの話)
        else if (display.Orientation == ScreenOrientation.PortraitUpsideDown) v.y -= display.Size.y / 2f;
        return v;
    }
}
