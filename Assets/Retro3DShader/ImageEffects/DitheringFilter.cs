using System.Collections;
using UnityEngine;

[ExecuteInEditMode]
public class DitheringFilter : MonoBehaviour {

	public Shader shader;
	public Texture2D ditheringPattern = null;

	public float verticalResolution = 240;
	public int RColorDepth = 6;
	public int GColorDepth = 6;
	public int BColorDepth = 6;

	private Material material;

	void Awake () {
		material = new Material (Shader.Find("Hidden/Dithering"));
	}

	void OnRenderImage (RenderTexture source, RenderTexture destination) {
		source.filterMode = FilterMode.Point;

		float pixelSize = 1;

		if ( ditheringPattern != null) {
			material.SetTexture ("_DitheringTex", ditheringPattern);
		}
			
		if (verticalResolution != 0) {
			pixelSize = (float)Screen.height / verticalResolution;

			if (pixelSize < 1) {
				pixelSize = 1;
			}
		}
			
		material.SetFloat ("_DitheringWidth", ((float)Screen.width  / (ditheringPattern.width * pixelSize )));
		material.SetFloat ("_DitheringHeight", ((float)Screen.height / (ditheringPattern.height * pixelSize)));
		material.SetFloat ("_RChannelStep", 1 / Mathf.Pow(2, RColorDepth));
		material.SetFloat ("_GChannelStep", 1 / Mathf.Pow(2, GColorDepth));
		material.SetFloat ("_BChannelStep", 1 / Mathf.Pow(2, BColorDepth));

		Graphics.Blit (source, destination, material);
	}


}
