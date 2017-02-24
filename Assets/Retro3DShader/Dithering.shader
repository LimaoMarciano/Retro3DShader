Shader "Hidden/Dithering"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}

		_pixelWidth ("Pixel Width", Float) = 1
		_pixelHeight ("Pixel Height", Float) = 1
		_pixelSize ("Pixel Size", Float) = 1

		_DitheringTex("Dithering Pattern (RGB)", 2D) = "white" {}
		_DitheringWidth("Dithering Width", float) = 1.0
		_DitheringHeight("Dithering Height", float) = 1.0

//		_ColorsPerChannel("Colors per channel", float) = 32
		_RChannelColors("Colors per channel", float) = 32
		_GChannelColors("Colors per channel", float) = 32
		_BChannelColors("Colors per channel", float) = 32

	}
	SubShader
	{
		// No culling or depth
		Cull Off ZWrite Off ZTest Always

		Tags { "CanUseSpriteAtlas" = "True" }

		Pass
		{
			CGPROGRAM
			#pragma vertex vert_img
			#pragma fragment frag
			
			#include "UnityCG.cginc"

			uniform sampler2D _MainTex;
			fixed _pixelWidth;
			fixed _pixelHeight;
			fixed _pixelSize;

			sampler2D _DitheringTex;
			fixed _DitheringWidth;
			fixed _DitheringHeight;
//			fixed _ColorsPerChannel;
			fixed _RChannelColors;
			fixed _GChannelColors;
			fixed _BChannelColors;

			fixed4 frag (v2f_img i) : SV_Target
			{
				// Resolution scaling
				half2 tileCount = fixed2((_pixelWidth / (_pixelSize)), (_pixelHeight / (_pixelSize)));
				half2 tile = fixed2(1.0 / tileCount.x, 1.0 / tileCount.y);
				half2 halfTile = tile / 1.0;

				half2 tileUV = floor(i.uv / tile) * tile + halfTile;

				fixed4 output = tex2D(_MainTex, tileUV);

//				fixed4 output = tex2D(_MainTex, i.uv);

				//Dithering
//				fixed nColors = 1.0f / _ColorsPerChannel;
				fixed2 ditherUV = i.uv * fixed2(_DitheringWidth, _DitheringHeight);

				fixed integer;

				fixed ditherTone;
				fixed ditherScale;

				//Red
				ditherTone = modf(output.r / _RChannelColors, integer);
				ditherScale = integer * _RChannelColors;
		
				if (tex2D(_DitheringTex, ditherUV).g < ditherTone)
					output.r = ditherScale + _RChannelColors;
				else
					output.r = ditherScale;


				//Green
				ditherTone = modf(output.g / _GChannelColors, integer);
				ditherScale = integer * _GChannelColors;
		
				if (tex2D(_DitheringTex, ditherUV).g < ditherTone)
					output.g = ditherScale + _GChannelColors;
				else
					output.g = ditherScale;


				//Blue
				ditherTone = modf(output.b / _BChannelColors, integer);
				ditherScale = integer * _BChannelColors;
		
				if (tex2D(_DitheringTex, ditherUV).g < ditherTone)
					output.b = ditherScale + _BChannelColors;
				else
					output.b = ditherScale;

				output.a = 1;

				return output;
			}
			ENDCG
		}
	}
}
