// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Hidden/LowResFilter"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_HResolution ("Horizontal resolution", Float) = 1
		_VResolution ("Vertical resolution", Float) = 1
	}
	SubShader
	{
		// No culling or depth
		Cull Off ZWrite Off ZTest Always

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
			};

			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv;
				return o;
			}
			
			sampler2D _MainTex;
			fixed _HResolution;
			fixed _VResolution;

			fixed4 frag (v2f i) : SV_Target
			{

				fixed2 UVStep = fixed2 (1.0 / _HResolution, 1.0 / _VResolution);
				fixed2 steppedUV = floor (i.uv / UVStep) * UVStep;

				return tex2D(_MainTex, steppedUV);
			}
			ENDCG
		}
	}
}
