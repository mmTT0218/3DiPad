using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
using TMPro;

public class Information : MonoBehaviour
{
    private FaceTracking faceTracking;
    private Vector3 leftEyePos, rightEyePos;
    private float fps;
    private TextMeshProUGUI tmp;
    private Text text;

    void Start()
    {
        faceTracking = GameObject.Find("FaceTracking").GetComponent<FaceTracking>();
        tmp = this.GetComponent<TextMeshProUGUI>();
        if (tmp == null) text = this.GetComponent<Text>();
    }
    // Update is called once per frame
    void LateUpdate()
    {
        GetInformation();
        if (tmp != null) tmp.text = Texting();
        else if (text != null) text.text = Texting();
        else return;
    }

    void GetInformation()
    {
        leftEyePos = faceTracking.leftEye;
        rightEyePos = faceTracking.rightEye;
        fps = 1 / Time.deltaTime;
    }

    string Texting()
    {
        string s;
        s = "Pos (L) : " + leftEyePos.ToString() + System.Environment.NewLine +
            "Pos (R) : " + rightEyePos.ToString() + System.Environment.NewLine +
            "IPD: " + Vector3.Distance(leftEyePos, rightEyePos) + System.Environment.NewLine +
            "FPS : " + fps.ToString();
        return s;
    }
}
