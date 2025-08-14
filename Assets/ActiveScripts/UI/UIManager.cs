using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class UIManager : MonoBehaviour
{
    private Toggle eyeMarkerToggle;
    private int _refractionFlag = 1;

    [SerializeField] GameObject displaySettingPanel;

    void Update()
    {/*
        if (Input.GetMouseButtonDown(0)) {
            if (displaySettingPanel.activeSelf == false) {
                displaySettingPanel.SetActive(!displaySettingPanel.activeSelf);
            }
        }
        /**/
        /*
        if (Input.GetMouseButtonUp(0)) {
            if (displaySettingPanel.activeSelf == true) {
                displaySettingPanel.SetActive(!displaySettingPanel.activeSelf);
            }
        }
        /**/
    }

    void Awake()
    {
        eyeMarkerToggle = GameObject.Find("EyeMarkerToggle").GetComponent<Toggle>();
    }

    void Start()
    {
        eyeMarkerToggle.isOn ^= true;
        eyeMarkerToggle.isOn ^= true;
    }

    public void OnClick(GameObject go)
    {
        go.SetActive(!go.activeSelf);
    }

    public void EyeMarkerToggleChanged()
    {
        this.gameObject.SetActive(eyeMarkerToggle.isOn);
    }

    public void Refraction()
    {
        _refractionFlag++;
        _refractionFlag %= 2;
        Shader.SetGlobalInt("_RefractionFlag", _refractionFlag);
    }

    public void DisableDisplaySetteingPanel()
    {
        Debug.Log("DisableDisplaySetteingPanel！");
        if (displaySettingPanel.activeSelf == true) {
                    Debug.Log("DisableDisplaySetteingPanel！True!!");
            displaySettingPanel.SetActive(!displaySettingPanel.activeSelf);
        }
    }
}

