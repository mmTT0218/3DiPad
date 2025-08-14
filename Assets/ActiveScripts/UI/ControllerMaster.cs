using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class ControllerMaster : MonoBehaviour
{
    public List<Controller> controllerList { get; private set; }
    private int childCount;
    public float x { get { return childCount > 0 ? controllerList[0].value : 0; } }
    public float y { get { return childCount > 1 ? controllerList[1].value : 0; } }
    public float z { get { return childCount > 2 ? controllerList[2].value : 0; } }
    public float rotX { get { return childCount > 3 ? controllerList[3].value : 0; } }
    public float rotY { get { return childCount > 4 ? controllerList[4].value : 0; } }
    public float rotZ { get { return childCount > 5 ? controllerList[5].value : 0; } }
    public Vector3 xyz { get { return new Vector3(x, y, z); } }
    public Vector3 rot { get { return new Vector3(rotX, rotY, rotZ); } }

    void Awake()
    {
        controllerList = new List<Controller>();
        childCount = this.transform.childCount;
        if (childCount == 0 || childCount > 6) return;
        for (int i = 0; i < childCount; i++)
        {
            controllerList.Add(transform.GetChild(i).gameObject.GetComponent<Controller>());
        }
    }

    public void SetValue(int controllerNum, string name, float init, float min, float max)
    {
        controllerList[controllerNum].SetValue(name, init, min, max);
    }

    public void SetValue(int controllerNum, string[] name, float[] init, float[] min, float[] max)
    {
        if (controllerNum < 0 || controllerNum > childCount) return;
        for (int i = 0; i < controllerNum; i++)
        {
            SetValue(i, name[i], init[i], min[i], max[i]);
        }
    }
}
