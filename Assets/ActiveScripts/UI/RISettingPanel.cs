using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class RISettingPanel : MonoBehaviour
{
    // Start is called before the first frame update
    [SerializeField] GameObject displaySettingPanel;

    void Start()
    {
        
    }

    // Update is called once per frame
    void Update()
    {
        
    }

    public void Event() {
//        GameObject displaySettingPanel = GameObject.Find("UI").GetComponent<Toggle>();
//        Debug.Log("イベント発生！");
        Debug.Log(displaySettingPanel.activeSelf);
        if (displaySettingPanel.activeSelf == true) {
            GameObject.Find("UIManager").SendMessage("DisableDisplaySetteingPanel");
//            displaySettingPanel.SetActive(!displaySettingPanel.activeSelf);
        }
    }
}
