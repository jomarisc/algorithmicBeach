using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class cubeRotate : MonoBehaviour
{
    public float xSpeed;
    public float ySpeed;
    // Update is called once per frame
    void Update()
    {
        transform.Rotate(new Vector3(xSpeed, ySpeed, 0) * Time.deltaTime);
    }
}
