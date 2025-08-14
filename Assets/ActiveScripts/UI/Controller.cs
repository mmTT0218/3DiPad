using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
using TMPro;

public class Controller : MonoBehaviour
{
    private TextMeshProUGUI objectName;
    private TMP_InputField inputfield;
    private Slider slider;
    private Button button;
    private Toggle toggle;
    public float init;
    public float min;
    public float max;
    public float value { get { return slider.value; } }     // content number

    void Awake()
    {
        objectName = transform.GetChild(0).gameObject.GetComponent<TextMeshProUGUI>();
        inputfield = transform.GetChild(1).gameObject.GetComponent<TMP_InputField>();
        slider = transform.GetChild(2).gameObject.GetComponent<Slider>();
        button = transform.GetChild(3).gameObject.GetComponent<Button>();
        toggle = transform.GetChild(4).gameObject.GetComponent<Toggle>();
    }

    void Start()
    {
        SetValue(name, init, min, max);
    }

    public void SetValue(string name, float init, float min, float max)
    {
        objectName.text = name;
        slider.minValue = min <= max ? min : max;
        slider.maxValue = max >= min ? max : min;
        if (init < slider.minValue) init = min;
        else if (init > slider.maxValue) init = max;
        slider.value = init;
        inputfield.text = init.ToString();
        this.objectName.text = name;
        this.min = slider.minValue;
        this.max = slider.maxValue;
        this.init = init;
        IntToggle();
    }

    public void SliderChanged()
    {
        if (inputfield != null & slider != null) inputfield.text = slider.value.ToString();
    }

    public void InputFieldChanged()
    {
        float value = float.Parse(inputfield.text);
        if (value > slider.maxValue) value = slider.maxValue;
        else if (value < slider.minValue) value = slider.minValue;
        slider.value = value;
    }

    public void ResetButton()
    {
        if (slider != null) slider.value = init;
    }

    public void IntToggle()
    {
        if (slider != null) slider.wholeNumbers = toggle.isOn;
    }
}
