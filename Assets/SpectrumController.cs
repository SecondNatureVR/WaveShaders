using System;
using System.Threading;
using UnityEngine;

using System.Numerics;
using DSPLib;
using Vector4 = UnityEngine.Vector4;
using System.Linq;
using UnityEditor;

[ExecuteInEditMode]

public class SpectrumController : MonoBehaviour
{
    [HideInInspector] [SerializeField] ComputeShader SpectrumCompute;
    [SerializeField] Material spectrumMaterial;
	[SerializeField] AudioSource audioSource;
    private Texture2D spectrumTexture;

	int numChannels;
	int numTotalSamples;
	int sampleRate;
	float clipLength;
	float[] multiChannelSamples;

	private int fftSampleSize;
	private int timeSteps;
	private Vector4[] fftChunks;

    void Start()
    {
		audioSource = GetComponent<AudioSource>();

        // Need all audio samples.  If in stereo, samples will return with left and right channels interweaved
        // [L,R,L,R,L,R]
        multiChannelSamples = new float[audioSource.clip.samples * audioSource.clip.channels];
        numChannels = audioSource.clip.channels;
        numTotalSamples = audioSource.clip.samples;
        clipLength = audioSource.clip.length;

        // We are not evaluating the audio as it is being played by Unity, so we need the clip's sampling rate
        this.sampleRate = audioSource.clip.frequency;

        audioSource.clip.GetData(multiChannelSamples, 0);
        Debug.Log ("GetData done");

        Thread bgThread = new Thread (this.getFullSpectrumThreaded);

        Debug.Log ("Starting Background Thread");
        bgThread.Start ();

		bgThread.Join();

        spectrumTexture = new Texture2D(fftSampleSize, timeSteps, TextureFormat.ARGB32, false);
        spectrumTexture.SetPixelData<Vector4>(fftChunks, 0);
        spectrumTexture.Apply();
        //spectrumMaterial.SetTexture("_FullSpectrum", spectrumTexture);
        AssetDatabase.CreateAsset(spectrumTexture, $"Assets/{audioSource.clip.name}Spectrum.asset");

		Texture2D heightMapTexture = new Texture2D(fftSampleSize, timeSteps, TextureFormat.R16, false);
		var heights = fftChunks.Select(sample => new Color(sample.z, sample.z, sample.z, 1)).ToArray();
		heightMapTexture.SetPixelData(heights, 0);
		heightMapTexture.Apply();
        AssetDatabase.CreateAsset(heightMapTexture, $"Assets/{audioSource.clip.name}HeightMap.asset");

        spectrumMaterial.SetTexture("_FullSpectrum", heightMapTexture);
    }
	public void getFullSpectrumThreaded() {
		try {
			// We only need to retain the samples for combined channels over the time domain
			float[] preProcessedSamples = new float[this.numTotalSamples];

			int numProcessed = 0;
			float combinedChannelAverage = 0f;
			for (int i = 0; i < multiChannelSamples.Length; i++) {
				combinedChannelAverage += multiChannelSamples [i];

				// Each time we have processed all channels samples for a point in time, we will store the average of the channels combined
				if ((i + 1) % this.numChannels == 0) {
					preProcessedSamples[numProcessed] = combinedChannelAverage / this.numChannels;
					numProcessed++;
					combinedChannelAverage = 0f;
				}
			}

			Debug.Log ("Combine Channels done");
			Debug.Log (preProcessedSamples.Length);

			// Once we have our audio sample data prepared, we can execute an FFT to return the spectrum data over the time domain
			int spectrumSampleSize = 1024;
			timeSteps = preProcessedSamples.Length / spectrumSampleSize;

			fftSampleSize = spectrumSampleSize / 2;

			FFT fft = new FFT ();
			fft.Initialize ((UInt32)spectrumSampleSize);

			Debug.Log (string.Format("Processing {0} time domain samples for FFT", timeSteps));
			double[] sampleChunk = new double[spectrumSampleSize];
			fftChunks = new Vector4[fftSampleSize * timeSteps];
			for (int i = 0; i < timeSteps; i++) {
				// Grab the current 1024 chunk of audio sample data
				Array.Copy (preProcessedSamples, i * spectrumSampleSize, sampleChunk, 0, spectrumSampleSize);

				// Apply our chosen FFT Window
				double[] windowCoefs = DSP.Window.Coefficients (DSP.Window.Type.Hanning, (uint)spectrumSampleSize);
				double[] scaledSpectrumChunk = DSP.Math.Multiply (sampleChunk, windowCoefs);
				double scaleFactor = DSP.Window.ScaleFactor.Signal (windowCoefs);

				// Perform the FFT and convert output (complex numbers) to Magnitude
				Complex[] fftSpectrum = fft.Execute(scaledSpectrumChunk);
				double[] scaledFFTSpectrum = DSPLib.DSP.ConvertComplex.ToMagnitude (fftSpectrum);
				scaledFFTSpectrum = DSP.Math.Multiply (scaledFFTSpectrum, scaleFactor);
				// These 1024 magnitude values correspond (roughly) to a single point in the audio timeline
				float curSongTime = getTimeFromIndex(i) * spectrumSampleSize;

				// Copy fft values to a buffer for texture
				Array.Copy(fftSpectrum
					.Zip(scaledFFTSpectrum, (fft, scaled) => new { fft, scaled })
					.Select(x => new Vector4((float) x.fft.Real, (float)x.fft.Imaginary, (float)x.scaled, curSongTime))
					.ToArray(),
				0, fftChunks, i * fftSampleSize, fftSampleSize);
			}
			Debug.Log ("Spectrum Analysis done");
			Debug.Log ("Background Thread Completed");
				
		} catch (Exception e) {
			// Catch exceptions here since the background thread won't always surface the exception to the main thread
			Debug.LogError(e.ToString ());
		}
	}

	public float getTimeFromIndex(int index) {
		return ((1f / (float)this.sampleRate) * index);
	}
}
