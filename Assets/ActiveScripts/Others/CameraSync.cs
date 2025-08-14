using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class CameraSync : MonoBehaviour
{
    // ディスプレイのサイズ
    private Camera leftCamera, rightCamera;
    private FaceTracking faceTracking;
    private DisplayConfig display;
    private RenderTexture _leftTexture, _rightTexture;
    public RenderTexture leftTexture { get { return _leftTexture; } }
    public RenderTexture rightTexture { get { return _rightTexture; } }

    void Awake()
    {
        Initialize();
    }

    void Start()
    {
        faceTracking = GameObject.Find("FaceTracking").GetComponent<FaceTracking>();
    }

    void LateUpdate()
    {
        ChangeCameraPosition(faceTracking.leftEye, leftCamera);
        ChangeCameraPosition(faceTracking.rightEye, rightCamera);
    }

    void Initialize()
    {
        display = Initializer.display;
        Initialize("left", ref leftCamera, ref _leftTexture);
        Initialize("right", ref rightCamera, ref _rightTexture);
    }
    void Initialize(string lr, ref Camera cam, ref RenderTexture rt)
    {
        //カメラ生成
        var obj = new GameObject(lr + "Camera");
        obj.AddComponent<Camera>();
        obj.transform.parent = this.gameObject.transform;
        //RenderTexture生成
        rt = new RenderTexture((int)display.Resolution.x, (int)display.Resolution.y, 16, RenderTextureFormat.ARGB32);
        rt.name = lr + "Texture";
        rt.Create();
        //カメラセッティング
        cam = obj.GetComponent<Camera>();
        cam.usePhysicalProperties = true;
        cam.sensorSize = display.Resolution;
        cam.nearClipPlane = 0.1f;
        cam.targetTexture = rt;
    }

    void ChangeCameraPosition(Vector3 pos, Camera camera)
    {
        Vector3 objPos;
        objPos = pos / 1000f;
        objPos.z *= -1;
        Vector2 shift = -objPos / display.Size * 1000f;

        //カメラ情報を更新
        camera.transform.localPosition = objPos;
        camera.fieldOfView = 2f * Mathf.Atan(display.Size.y / 1000 / 2f / -objPos.z) / (2f * Mathf.PI) * 360f;
        camera.lensShift = shift;
    }
}
