using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class SetObjRotateAction : MonoBehaviour
{
    public float Speed = 5;
    public Vector3 Dir = Vector3.up;
   
    void Update()
    {
        transform.Rotate(Dir * Speed * Time.deltaTime);
    }
}
