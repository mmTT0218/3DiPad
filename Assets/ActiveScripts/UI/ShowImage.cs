using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class ShowImage : MonoBehaviour
{
    private RectTransform rectTransform;
    private RawImage rawImage;
    private RenderSrc renderSrc;

    // Start is called before the first frame update
    void Start()
    {
        rectTransform = this.gameObject.GetComponent<RectTransform>();
        rectTransform.sizeDelta = Initializer.display.Resolution;
        rawImage = this.gameObject.GetComponent<RawImage>();
        rawImage.color = new Color(0, 0, 0, 1);
        renderSrc = GameObject.Find("Initializer").GetComponent<RenderSrc>();
    }

    // Update is called once per frame
    void Update()
    {
        rawImage.material = renderSrc.display[(int)renderSrc.material.value];
    }
}
