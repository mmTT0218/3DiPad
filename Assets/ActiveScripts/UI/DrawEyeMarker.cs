using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class DrawEyeMarker : MonoBehaviour
{
    private FaceTracking ft;
    private RectTransform leftEyeMarker, rightEyeMarker;
    void Awake()
    {
        ft = GameObject.Find("FaceTracking").GetComponent<FaceTracking>();
        leftEyeMarker = transform.GetChild(0).gameObject.GetComponent<RectTransform>();
        rightEyeMarker = transform.GetChild(1).gameObject.GetComponent<RectTransform>();
    }

    // Update is called once per frame
    void Update()
    {
        leftEyeMarker.position = ft.leftEyeDisplay;
        rightEyeMarker.position = ft.rightEyeDisplay;
    }
}
