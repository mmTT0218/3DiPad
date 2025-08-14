using System.Collections;
using System.Collections.Generic;
using System.Collections.Specialized;
using UnityEngine;
using UnityEngine.UI;

public class ObjectController : MonoBehaviour
{
    public ControllerMaster objectController;
    private Vector3 startPos, startRot;

    // Start is called before the first frame update
    void Start()
    {
        startPos = gameObject.transform.localPosition;
        startRot = gameObject.transform.eulerAngles;
    }

    // Update is called once per frame
    void Update()
    {
        UpdatePos();
    }

    public void UpdatePos()
    {
        Vector3 objPos;
        objPos.x = startPos.x + objectController.x / 1000f;
        objPos.y = startPos.y + objectController.y / 1000f;
        objPos.z = startPos.z - objectController.z / 1000f;
        
        Vector3 objRot;
        objRot = startRot + objectController.rot;

        gameObject.transform.localPosition = objPos;
        gameObject.transform.eulerAngles = objRot;
    }

}
