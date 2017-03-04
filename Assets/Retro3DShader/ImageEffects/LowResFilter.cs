using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class LowResFilter : MonoBehaviour {

	private Shader shader;
	public int verticalResolution = 240;

	private int screenHeight;
	private int screenWidth;

	private Material material;


	void Awake () {
		material = new Material (Shader.Find ("Hidden/LowResFilter"));
	}

	void OnRenderImage (RenderTexture source, RenderTexture destination) {

		source.filterMode = FilterMode.Point;
	
		float screenRatio =  (float)Screen.width / (float)Screen.height;

		material.SetFloat ("_VResolution", verticalResolution);
		material.SetFloat ("_HResolution", (float)verticalResolution * screenRatio);
		Graphics.Blit (source, destination, material);

	}
}
