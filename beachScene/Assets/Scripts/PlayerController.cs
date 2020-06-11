using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
using UnityOSC;

public class PlayerController : MonoBehaviour
{
    public float speed;
    public Transform Player;
    public Transform Ocean;
    public float safeMeter;
    public double safeMeterD;
    public bool wet;
    public float sandTempo;

    public Text countText;
    private int count;


    private Rigidbody rb;
    

    private void Start()
    {
        Application.runInBackground = true; //allows unity to update when not in focus

        //************* Instantiate the OSC Handler...
        OSCHandler.Instance.Init();
       // OSCHandler.Instance.SendMessageToClient("pd", "/unity/trigger", "ready");
        OSCHandler.Instance.SendMessageToClient("pd", "/unity/playseq", 1);
        OSCHandler.Instance.SendMessageToClient("pd", "/unity/water", 0);

        //*************

        rb = GetComponent<Rigidbody>();
        count = 0;
        setCountText();
        safeMeterD = 0.75;
        Debug.Log(safeMeter); // ocean volume
        wet = false;
    }

    private void FixedUpdate()
    {
        float moveHorizontal = Input.GetAxis("Horizontal");
        float moveVertical = Input.GetAxis("Vertical");

        Vector3 movement = new Vector3(moveHorizontal, 0.0f, moveVertical);

        rb.AddForce(movement * speed);
    }
    private void Update()
    {
        safeMeter = (((Player.position.x -Ocean.position.x + 29) * 4)/100);
        if(safeMeter > .75)
        {
            float safeMeter = (float)safeMeterD;
        }
        //Debug.Log(safeMeter); // ocean volume
        OSCHandler.Instance.SendMessageToClient("pd", "/unity/water", safeMeter);
        sandTempo = (800 - (rb.velocity.magnitude * 55));
        if(sandTempo < 200)
        {
            sandTempo = 200;
        }

        OSCHandler.Instance.SendMessageToClient("pd", "/unity/speed", sandTempo);
        Debug.Log(wet);
    }

    private void OnTriggerEnter(Collider other)
    {
        if (other.gameObject.CompareTag("Pick Up"))
        {
            other.gameObject.SetActive(false);
            count = count + 1;
            setCountText();
            Debug.Log(count);
            // layer music here
        }
        if(other.tag == "Ocean")
        {


            if (wet)
            {
                Debug.Log("splashing");
                OSCHandler.Instance.SendMessageToClient("pd", "/unity/sand2", 1);
                OSCHandler.Instance.SendMessageToClient("pd", "/unity/swim", ((float)0.2));
                OSCHandler.Instance.SendMessageToClient("pd", "/unity/paddle", 2);

                wet = false;
            }
            //wet = true;
            // if(wet)
            //   {
            //     Debug.Log("splashing");
            //       wet = false;
            //   }
            //    else
            //    {
            //      Debug.Log("swim");
            //   }
        }
        if(other.tag == "deepocean")
        {
            Debug.Log("muffled sound"); //ocean volume half
        }
        if(other.tag == "towel")
        {
            Debug.Log("slow sound"); // ocean volume 1/4
        }
        if (other.tag == "sand")
        {
            if (!wet)
            {
                Debug.Log("splashing");
                OSCHandler.Instance.SendMessageToClient("pd", "/unity/sand", 1);
                OSCHandler.Instance.SendMessageToClient("pd", "/unity/swim", 0);
                OSCHandler.Instance.SendMessageToClient("pd", "/unity/paddle", 1);

                wet = true;
            }


        }
        if (other.tag == "hard")
        {
            OSCHandler.Instance.SendMessageToClient("pd", "/unity/hard", 3);


        }
        if (other.tag == "sand")
        {

            OSCHandler.Instance.SendMessageToClient("pd", "/unity/hard", 4);

        }


    }

    private void OnTriggerStay(Collider other)
    {
        if (other.tag == "deepocean")
        {

            OSCHandler.Instance.SendMessageToClient("pd", "/unity/deep", ((float)0.2));
            OSCHandler.Instance.SendMessageToClient("pd", "/unity/deeper", ((float)0.01));
            OSCHandler.Instance.SendMessageToClient("pd", "/unity/deepest", ((float)0.1));
            Debug.Log("underwater");

        }
        if (other.tag == "Ocean")
        {
            OSCHandler.Instance.SendMessageToClient("pd", "/unity/deep", 1);
            OSCHandler.Instance.SendMessageToClient("pd", "/unity/deeper", ((float)0.03));
            OSCHandler.Instance.SendMessageToClient("pd", "/unity/deepest", ((float)0.6));
            Debug.Log("justwater");

        }
    }


    void setCountText()
    {
        countText.text = "Count: " + count.ToString();

        //************* Send the message to the client...
        OSCHandler.Instance.SendMessageToClient("pd", "/unity/trigger", count);
        //*************
    }

}
