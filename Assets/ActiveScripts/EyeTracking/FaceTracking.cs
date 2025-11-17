using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
using Unity.Collections;
public class FaceTracking : MonoBehaviour
{
    private DisplayConfig display;
    public Information information;
    public Controller origin;
    public Controller parallax;
    public Vector3 leftEye { get; private set; }
    public Vector3 rightEye { get; private set; }
    public Vector3 leftEyeDisplay { get; private set; }
    public Vector3 rightEyeDisplay { get; private set; }
    private FaceManager faceManager;
    public Controller Lx, Ly, Lz, Rx, Ry, Rz;

    // 2025/08/30 追加
    public Controller OnDotNum;
    public Controller MratioY;

    // 2025/10/06 追加
    public Controller_a MratioX;

    private void Start()
    {
        //faceManager = GameObject.Find("FaceManager").GetComponent<FaceManager>();
        display = Initializer.display;
    }
    void Update()
    {
        //leftEye = faceManager.leftEye;
        //rightEye = faceManager.rightEye;
        //leftEyeDisplay = CameraToDisplay(leftEye);
        //rightEyeDisplay = CameraToDisplay(rightEye);
        ToShaderVariables();

        // Debug.Log("Game View Resolution: " + Screen.width + "x" + Screen.height);
    }
    void ToShaderVariables()
    {
        leftEye = new Vector3(Lx.value, Ly.value, Lz.value);
        rightEye = new Vector3(Rx.value, Ry.value, Rz.value);
        Shader.SetGlobalVector("_PosL", leftEye);
        Shader.SetGlobalVector("_PosR", rightEye);
        Shader.SetGlobalFloat("_Origin", origin.value);
        Shader.SetGlobalFloat("_Parallax", parallax.value);

        // 2025/08/30 追加
        Shader.SetGlobalFloat("_dotNum", OnDotNum.value);
        // とりあえずScreenOrientaitonは無視
        Shader.SetGlobalFloat("_MRatio_X", MratioX.value);
        Debug.Log("MratioX: "+  MratioX.value);
        Shader.SetGlobalFloat("_M", 3.0f * MratioY.value * (-1) / MratioX.value);
        Debug.Log("_M: "+  3.0f * MratioY.value * (-1) / MratioX.value);
    }
    //カメラ座標系をディスプレイ座標に変換（左下原点：単位[px]）
    Vector2 CameraToDisplay(Vector3 cameraPos)
    {
        Vector2 v;
        v.x = cameraPos.x + display.Size.x / 2;
        v.y = cameraPos.y + display.Size.y / 2;
        v /= display.PixelPitch;
        return v;
    }
}