using UnityEngine;
using UnityEngine.InputSystem;

public class TeleportObject : MonoBehaviour
{
    private Renderer capsuleRenderer;

    private void Awake()
    {
        capsuleRenderer = GetComponent<Renderer>();
    }

    private void Update()
    {
        if (Keyboard.current != null &&
            Keyboard.current.spaceKey.wasPressedThisFrame)
        {
            capsuleRenderer.enabled = false;
        }
    }
}