using UnityEngine;
using UnityEngine.UI;
using System.IO;

public class RenderSrc : MonoBehaviour
{
    public Material[] display;
    public Controller material;
    void Start()
    {
        material.SetValue("Material", 0, 0, display.Length - 1);
    }
}
