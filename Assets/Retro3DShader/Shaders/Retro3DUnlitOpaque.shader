// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Retro3D/Unlit/Opaque (No ambient)" {
Properties {
	_Color ("Main Color", Color) = (1,1,1,1)
	_MainTex ("Base (RGB) Trans (A)", 2D) = "white" {}
	_HorizontalRes ("Horizontal res", Int) = 320
	_VerticalRes ("Vertical res", Int) = 240

}
 
SubShader {
	Tags {"Queue"="Geometry" "RenderType" = "Opaque" "IgnoreProjector"="True"}
	LOD 100

	ZWrite On
 
	Pass {
		Tags { LightMode = Vertex } 
		CGPROGRAM
		#pragma vertex vert  
		#pragma fragment frag
		#pragma multi_compile_fog
 
		#include "UnityCG.cginc"
 
		fixed4 _Color;
		uint _HorizontalRes;
		uint _VerticalRes;
 
		half _Shininess;
 
		sampler2D _MainTex;
		float4 _MainTex_ST;
 
		struct v2f {
			fixed3 diff : COLOR;
			float4 pos : SV_POSITION;
			float2 uv_MainTex : TEXCOORD0;
			half3 normal : TEXCOORD1;
 
			UNITY_FOG_COORDS(2)
		};
 
		v2f vert (appdata_full v)
		{
		    v2f o;
		    o.pos = UnityObjectToClipPos (v.vertex);

		    //Vertex snapping
			float4 snapToPixel = o.pos;
			float4 vertex = snapToPixel;
			vertex.xyz = snapToPixel.xyz / snapToPixel.w;
			vertex.x = floor((_HorizontalRes / 2) * vertex.x) / (_HorizontalRes / 2);
			vertex.y = floor((_VerticalRes / 2) * vertex.y) / (_VerticalRes / 2);
			vertex.xyz *= snapToPixel.w;
			o.pos = vertex;

		    //Affine Texture Mapping
		    float distance = length(mul(UNITY_MATRIX_MV,v.vertex));
			float4 affinePos = vertex; //vertex;				
			o.uv_MainTex = TRANSFORM_TEX(v.texcoord, _MainTex);
			o.uv_MainTex *= distance + (vertex.w*(UNITY_LIGHTMODEL_AMBIENT.a * 8)) / distance / 2;
			o.normal = distance + (vertex.w*(UNITY_LIGHTMODEL_AMBIENT.a * 8)) / distance / 2;

			UNITY_TRANSFER_FOG (o, o.pos);

			o.diff = _Color;

			return o;
		}
 
		fixed4 frag (v2f i) : COLOR {
			fixed4 c;
 
			c = tex2D (_MainTex, i.uv_MainTex / i.normal.x);
			c.rgb *= i.diff;

			UNITY_APPLY_FOG (i.fogCoord, c);
			UNITY_OPAQUE_ALPHA (c.a);

			return c;
		}
 
		ENDCG
	}

	Pass {
		Tags { LightMode = VertexLM } 
		CGPROGRAM
		#pragma vertex vert  
		#pragma fragment frag
		#pragma multi_compile_fog
 
		#include "UnityCG.cginc"
 
		fixed4 _Color;
		uint _HorizontalRes;
		uint _VerticalRes;
 
		half _Shininess;
 
		sampler2D _MainTex;
		float4 _MainTex_ST;
 
		struct v2f {
			fixed3 diff : COLOR;
			float4 pos : SV_POSITION;
			float2 uv_MainTex : TEXCOORD0;
			half3 normal : TEXCOORD1;
 
			UNITY_FOG_COORDS(2)
		};
 
		v2f vert (appdata_full v)
		{
		    v2f o;
		    o.pos = UnityObjectToClipPos (v.vertex);

		    //Vertex snapping
			float4 snapToPixel = o.pos;
			float4 vertex = snapToPixel;
			vertex.xyz = snapToPixel.xyz / snapToPixel.w;
			vertex.x = floor((_HorizontalRes / 2) * vertex.x) / (_HorizontalRes / 2);
			vertex.y = floor((_VerticalRes / 2) * vertex.y) / (_VerticalRes / 2);
			vertex.xyz *= snapToPixel.w;
			o.pos = vertex;

		    //Affine Texture Mapping
		    float distance = length(mul(UNITY_MATRIX_MV,v.vertex));
			float4 affinePos = vertex; //vertex;				
			o.uv_MainTex = TRANSFORM_TEX(v.texcoord, _MainTex);
			o.uv_MainTex *= distance + (vertex.w*(UNITY_LIGHTMODEL_AMBIENT.a * 8)) / distance / 2;
			o.normal = distance + (vertex.w*(UNITY_LIGHTMODEL_AMBIENT.a * 8)) / distance / 2;

			UNITY_TRANSFER_FOG (o, o.pos);

			o.diff = _Color;
 
			return o;
		}
 
		fixed4 frag (v2f i) : COLOR {
			fixed4 c;
 
			c = tex2D (_MainTex, i.uv_MainTex / i.normal.x);
			c.rgb *= i.diff;

			UNITY_APPLY_FOG (i.fogCoord, c);
			UNITY_OPAQUE_ALPHA (c.a);

			return c;
		}
 
		ENDCG
	}

	Pass {
		Tags { LightMode = VertexLMRGBM } 
		CGPROGRAM
		#pragma vertex vert  
		#pragma fragment frag
		#pragma multi_compile_fog
 
		#include "UnityCG.cginc"
 
		fixed4 _Color;
		uint _HorizontalRes;
		uint _VerticalRes;
 
		half _Shininess;
 
		sampler2D _MainTex;
		float4 _MainTex_ST;
 
		struct v2f {
			fixed3 diff : COLOR;
			float4 pos : SV_POSITION;
			float2 uv_MainTex : TEXCOORD0;
			half3 normal : TEXCOORD1;
 
			UNITY_FOG_COORDS(2)
		};
 
		v2f vert (appdata_full v)
		{
		    v2f o;
		    o.pos = UnityObjectToClipPos (v.vertex);

		    //Vertex snapping
			float4 snapToPixel = o.pos;
			float4 vertex = snapToPixel;
			vertex.xyz = snapToPixel.xyz / snapToPixel.w;
			vertex.x = floor((_HorizontalRes / 2) * vertex.x) / (_HorizontalRes / 2);
			vertex.y = floor((_VerticalRes / 2) * vertex.y) / (_VerticalRes / 2);
			vertex.xyz *= snapToPixel.w;
			o.pos = vertex;

		    //Affine Texture Mapping
		    float distance = length(mul(UNITY_MATRIX_MV,v.vertex));
			float4 affinePos = vertex; //vertex;				
			o.uv_MainTex = TRANSFORM_TEX(v.texcoord, _MainTex);
			o.uv_MainTex *= distance + (vertex.w*(UNITY_LIGHTMODEL_AMBIENT.a * 8)) / distance / 2;
			o.normal = distance + (vertex.w*(UNITY_LIGHTMODEL_AMBIENT.a * 8)) / distance / 2;

			UNITY_TRANSFER_FOG (o, o.pos);

			o.diff = _Color;
 
			return o;
		}
 
		fixed4 frag (v2f i) : COLOR {
			fixed4 c;
 
			c = tex2D (_MainTex, i.uv_MainTex / i.normal.x);
			c.rgb *= i.diff;

			UNITY_APPLY_FOG (i.fogCoord, c);
			UNITY_OPAQUE_ALPHA (c.a);

			return c;
		}
 
		ENDCG
	}
 
}
 
//Fallback "VertexLit"
}