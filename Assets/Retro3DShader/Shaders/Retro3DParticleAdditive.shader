// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Retro3D/Particles/Additive"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_HorizontalRes ("Horizontal res", Int) = 320
		_VerticalRes ("Vertical res", Int) = 240
	}
	SubShader
	{
		Tags { "RenderType"="Transparent" "RenderType" = "Transparent" }
		LOD 100

		Pass
		{

			Cull Back
			ZWrite Off
			Blend One One
				
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma fragmentoption ARB_precision_hint_fastest
			// make fog work
			#pragma multi_compile_fog
			
			#include "UnityCG.cginc"

			struct v2f
			{
				fixed4 diff : COLOR;
				fixed2 uv_MainTex : TEXCOORD0;
				half3 normal : TEXCOORD2;
				UNITY_FOG_COORDS(1)
				fixed4 pos : SV_POSITION;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			uint _HorizontalRes;
			uint _VerticalRes;
			
			v2f vert (appdata_full v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos (v.vertex);

				float4 snapToPixel = o.pos;
				float4 vertex = snapToPixel;
				vertex.xyz = snapToPixel.xyz / snapToPixel.w;
				vertex.x = floor((_HorizontalRes / 2) * vertex.x) / (_HorizontalRes / 2);
				vertex.y = floor((_VerticalRes / 2) * vertex.y) / (_VerticalRes / 2);
				vertex.xyz *= snapToPixel.w;
				o.pos = vertex;

				//Affine Texture Mapping
			    float distance = length(mul(UNITY_MATRIX_MV,v.vertex));
				float4 affinePos = v.vertex; //vertex;				
				o.uv_MainTex = TRANSFORM_TEX(v.texcoord, _MainTex);
				o.uv_MainTex *= distance + (v.vertex.w*(UNITY_LIGHTMODEL_AMBIENT.a * 8)) / distance / 2;
				o.normal = distance + (v.vertex.w*(UNITY_LIGHTMODEL_AMBIENT.a * 8)) / distance / 2;

				o.diff = v.color;

				UNITY_TRANSFER_FOG(o,o.pos);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				// sample the texture
				fixed4 col;
				fixed4 tex = tex2D (_MainTex, i.uv_MainTex / i.normal.x);

				col.rgb = tex.rgb * i.diff.rgb;
				col.a = i.diff.a * tex.a;

				// apply fog
				UNITY_APPLY_FOG(i.fogCoord, col);
				return col;
			}
			ENDCG
		}
	}
}
