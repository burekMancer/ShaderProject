using System.Collections;
using UnityEngine;
using UnityEngine.InputSystem;

public class TeleportSmoke : MonoBehaviour
{
    public float duration = 2.0f;

    private Material material;
    private bool isPlaying = false;

    private void Awake()
    {
        material = GetComponent<Renderer>().material;

        // Start invisible
        material.SetFloat("_Progress", 1.0f);
    }

    private void Update()
    {
        if (Keyboard.current != null &&
            Keyboard.current.spaceKey.wasPressedThisFrame)
        {
            Debug.Log("SPACE PRESSED!");

            if (!isPlaying)
            {
                StartCoroutine(PlayFog());
            }
        }
    }

    private IEnumerator PlayFog()
    {
        isPlaying = true;

        float time = 0.0f;

        material.SetFloat("_Progress", 0.0f);

        while (time < duration)
        {
            time += Time.deltaTime;

            float progress =
                Mathf.Clamp01(time / duration);

            material.SetFloat("_Progress", progress);

            yield return null;
        }

        material.SetFloat("_Progress", 1.0f);

        isPlaying = false;
    }
}