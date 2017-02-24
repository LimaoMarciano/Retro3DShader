using System.Collections;
using UnityEngine;

[ExecuteInEditMode]
public class Dithering : FilterBehavior {

	public Texture2D ditheringPattern = null;
	private float pixelSize = 1.0f;

	public int verticalResolution = 300;
	public int RColorDepth = 6;
	public int GColorDepth = 6;
	public int BColorDepth = 6;

	void OnRenderImage (RenderTexture source, RenderTexture destination) {
		source.filterMode = FilterMode.Point;

		if ( ditheringPattern != null) {
			this.material.SetTexture ("_DitheringTex", ditheringPattern);
		}
			
		if (verticalResolution != 0) {
			pixelSize = Screen.height / (float)verticalResolution;
		}

		if (pixelSize < 1) {
			pixelSize = 1;
		}

		this.material.SetFloat( "_pixelSize", (float)( pixelSize ) );
		this.material.SetFloat( "_pixelWidth", (float)( source.width ) );
		this.material.SetFloat( "_pixelHeight", (float)( source.height ) );
		this.material.SetFloat ("_DitheringWidth", (float)(source.width / (ditheringPattern.width * pixelSize)));
		this.material.SetFloat ("_DitheringHeight", (float)(source.height / (ditheringPattern.height * pixelSize)));
		this.material.SetFloat ("_RChannelColors", 1 / Mathf.Pow(2, RColorDepth));
		this.material.SetFloat ("_GChannelColors", 1 / Mathf.Pow(2, GColorDepth));
		this.material.SetFloat ("_BChannelColors", 1 / Mathf.Pow(2, BColorDepth));

		Graphics.Blit (source, destination, this.material);
	}


}
