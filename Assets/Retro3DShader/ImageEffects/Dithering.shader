Shader "Hidden/Dithering"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}

		_DitheringTex("Dithering Pattern (RGB)", 2D) = "white" {}
		_DitheringWidth("Dithering Width", float) = 1.0
		_DitheringHeight("Dithering Height", float) = 1.0

		_RChannelStep("Colors per channel", float) = 32
		_GChannelStep("Colors per channel", float) = 32
		_BChannelStep("Colors per channel", float) = 32

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

			sampler2D _DitheringTex;
			fixed _DitheringWidth;
			fixed _DitheringHeight;
			fixed _RChannelStep;
			fixed _GChannelStep;
			fixed _BChannelStep;

			fixed4 frag (v2f_img i) : SV_Target
			{

				fixed4 output = tex2D(_MainTex, i.uv);

				fixed2 ditherUV = i.uv * fixed2(_DitheringWidth, _DitheringHeight);

				fixed colorSteps;
				fixed colorError;
				fixed reducedColor;

				//RED CHANNEL
				//Reduces color precision to specified steps in _RChannelStep
				//and stores color deviation from original color

				colorError = modf(output.r / _RChannelStep, colorSteps);
				reducedColor = colorSteps * _RChannelStep;

				//Compare dithering texture with color error after reduction. 
				//If dither color is smaller than color error, use the next color step
				if (tex2D(_DitheringTex, ditherUV).g < colorError)
					output.r = reducedColor + _RChannelStep;
				else
					output.r = reducedColor;


				//GREEN CHANNEL
				colorError = modf(output.g / _GChannelStep, colorSteps);
				reducedColor = colorSteps * _GChannelStep;
		
				if (tex2D(_DitheringTex, ditherUV).g < colorError)
					output.g = reducedColor + _GChannelStep;
				else
					output.g = reducedColor;


				//BLUE CHANNEL
				colorError = modf(output.b / _BChannelStep, colorSteps);
				reducedColor = colorSteps * _BChannelStep;
		
				if (tex2D(_DitheringTex, ditherUV).g < colorError)
					output.b = reducedColor + _BChannelStep;
				else
					output.b = reducedColor;

				output.a = 1;

				return output;
			}
			ENDCG
		}
	}
}
