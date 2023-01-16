using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
[RequireComponent(typeof(AudioListener))]
public class SimpleSpectrumController : MonoBehaviour
{
    [SerializeField] Material material;
    [SerializeField] int sampleSize = 256;
    private float[] samples;
    private Texture2D spectrumTexture;

    private void Start()
    {
        samples = new float[sampleSize];
        spectrumTexture = new Texture2D(sampleSize, 1, TextureFormat.RFloat, false);
    }
    // Start is called before the first frame update
    void Update()
    {
        AudioListener.GetSpectrumData(samples, 0, FFTWindow.Hamming);
        spectrumTexture.SetPixelData(samples, 0);
        spectrumTexture.Apply();
        Shader.SetGlobalTexture("_Spectrum", spectrumTexture);
    }
}
