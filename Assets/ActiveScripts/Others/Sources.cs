using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using UnityEngine.UI;
using UnityEngine.Video;
using Unity.VisualScripting;

public class Sources : MonoBehaviour
{
    public Controller picture; 
    private RenderTexture leftCamera, rightCamera;
    public List<Texture> leftImage, rightImage;
    public List<VideoClip> leftMovie, rightMovie;
    private VideoPlayer leftPlayer, rightPlayer;

    public void Start()
    {
        var cameraSync = GameObject.Find("StereoCamera").GetComponent<CameraSync>();
        leftCamera = cameraSync.leftTexture;
        rightCamera = cameraSync.rightTexture;
        leftPlayer = this.AddComponent<VideoPlayer>();
        rightPlayer = this.AddComponent<VideoPlayer>();
        leftPlayer.isLooping = true;
        rightPlayer.isLooping = true;
        leftPlayer.aspectRatio = VideoAspectRatio.FitInside;
        rightPlayer.aspectRatio = VideoAspectRatio.FitInside;
        picture.SetValue("Picture", 0, 0, leftImage.Count + leftMovie.Count);
    }

    public void Update()
    {
        if ((int)picture.value == 0)
        {
            leftCamera.wrapMode = TextureWrapMode.Clamp;
            rightCamera.wrapMode = TextureWrapMode.Clamp;
            Shader.SetGlobalTexture("_LTex", leftCamera);
            Shader.SetGlobalTexture("_RTex", rightCamera);
        }
        else if ((int)picture.value <= leftImage.Count)
        {
            leftPlayer.Stop();
            rightPlayer.Stop();
            leftImage[(int)picture.value - 1].wrapMode = TextureWrapMode.Clamp;
            rightImage[(int)picture.value - 1].wrapMode = TextureWrapMode.Clamp;
            Shader.SetGlobalTexture("_LTex", leftImage[(int)picture.value - 1]);
            Shader.SetGlobalTexture("_RTex", rightImage[(int)picture.value - 1]);
        }
        else
        {
            leftPlayer.clip = leftMovie[(int)picture.value - 1 - rightImage.Count];
            rightPlayer.clip = rightMovie[(int)picture.value - 1 - rightImage.Count];
            leftPlayer.Play();
            rightPlayer.Play();
            Shader.SetGlobalTexture("_LTex", leftPlayer.texture);
            Shader.SetGlobalTexture("_RTex", rightPlayer.texture);
        }
    }

}
