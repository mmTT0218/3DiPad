using System.Collections;
using System.Collections.Generic;
using System.Globalization;   // ← 追加：パース安定化
using UnityEngine;
using UnityEngine.UI;
using TMPro;

public class Controller_a : MonoBehaviour
{
    private TextMeshProUGUI objectName;
    private TMP_InputField inputfield;
    private Slider slider;
    private Button button;
    private Toggle toggle;

    // 追加：刻み幅と表示フォーマット
    [Header("Step Settings")]
    [Tooltip("スナップ刻み幅 (例: 0.001)")]
    public float step = 0.001f;
    [Tooltip("表示フォーマット")]
    public string displayFormat = "F3";

    public float init;
    public float min;
    public float max;

    public float value { get { return slider != null ? slider.value : 0f; } }

    void Awake()
    {
        objectName = transform.GetChild(0).GetComponent<TextMeshProUGUI>();
        inputfield = transform.GetChild(1).GetComponent<TMP_InputField>();
        slider     = transform.GetChild(2).GetComponent<Slider>();
        button     = transform.GetChild(3).GetComponent<Button>();
        toggle     = transform.GetChild(4).GetComponent<Toggle>();
    }

    void Start()
    {
        SetValue(name, init, min, max);
    }

    public void SetValue(string name, float init, float min, float max)
    {
        objectName.text = name;

        // min/max 正規化
        slider.minValue = min <= max ? min : max;
        slider.maxValue = max >= min ? max : min;

        // initを範囲＆刻みに合わせる
        float clamped = Mathf.Clamp(init, slider.minValue, slider.maxValue);
        float snapped = toggle != null && toggle.isOn ? Mathf.Round(clamped) : Snap(clamped);

        slider.SetValueWithoutNotify(snapped);
        if (inputfield) inputfield.SetTextWithoutNotify(snapped.ToString(displayFormat, CultureInfo.InvariantCulture));

        this.objectName.text = name;
        this.min  = slider.minValue;
        this.max  = slider.maxValue;
        this.init = snapped;

        IntToggle(); // トグル状態に応じて wholeNumbers を反映
    }

    // Slider → InputField（0.001刻みにスナップ）
    public void SliderChanged()
    {
        if (inputfield == null || slider == null) return;

        float v = slider.value;
        // 整数モードのときは四捨五入、そうでなければstepスナップ
        float snapped = (toggle != null && toggle.isOn) ? Mathf.Round(v) : Snap(v);

        if (!Mathf.Approximately(snapped, v))
            slider.SetValueWithoutNotify(snapped); // 再帰発火防止

        inputfield.SetTextWithoutNotify(snapped.ToString(displayFormat, CultureInfo.InvariantCulture));
    }

    public void InputFieldChanged()
    {
        if (inputfield == null || slider == null) return;

        if (!float.TryParse(inputfield.text, NumberStyles.Float, CultureInfo.InvariantCulture, out float v))
        {
            // パース失敗時は現在値を表示に戻す
            inputfield.SetTextWithoutNotify(slider.value.ToString(displayFormat, CultureInfo.InvariantCulture));
            return;
        }

        v = Mathf.Clamp(v, slider.minValue, slider.maxValue);
        v = (toggle != null && toggle.isOn) ? Mathf.Round(v) : Snap(v);

        slider.SetValueWithoutNotify(v);
        inputfield.SetTextWithoutNotify(v.ToString(displayFormat, CultureInfo.InvariantCulture));
    }

    public void ResetButton()
    {
        if (slider == null) return;
        float v = (toggle != null && toggle.isOn) ? Mathf.Round(init) : Snap(init);
        slider.SetValueWithoutNotify(v);
        if (inputfield) inputfield.SetTextWithoutNotify(v.ToString(displayFormat, CultureInfo.InvariantCulture));
    }

    // 整数モード切替（Toggle）
    public void IntToggle()
    {
        if (slider == null || toggle == null) return;

        slider.wholeNumbers = toggle.isOn; // ONなら整数モード
        // 現在値をモードに合わせて再スナップ
        float v = slider.value;
        v = toggle.isOn ? Mathf.Round(v) : Snap(v);

        slider.SetValueWithoutNotify(v);
        if (inputfield) inputfield.SetTextWithoutNotify(v.ToString(displayFormat, CultureInfo.InvariantCulture));
    }

    // --- ユーティリティ ---
    // minを基準にstepでスナップ（例: min=0.123でも正しく0.001刻み）
    private float Snap(float v)
    {
        if (step <= 0f) step = 0.001f;
        float min = slider.minValue;
        float snapped = Mathf.Round((v - min) / step) * step + min;
        return Mathf.Clamp(snapped, slider.minValue, slider.maxValue);
    }

#if UNITY_EDITOR
    // Inspectorでstepやformatを変えたときも即反映
    void OnValidate()
    {
        if (slider == null) return;
        if (step <= 0f) step = 0.001f;
        float v = (toggle != null && toggle.isOn) ? Mathf.Round(slider.value) : Snap(slider.value);
        slider.SetValueWithoutNotify(v);
        if (inputfield) inputfield.SetTextWithoutNotify(v.ToString(displayFormat, CultureInfo.InvariantCulture));
    }
#endif
}
