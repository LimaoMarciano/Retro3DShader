Shader "Retro3D/Lit/Opaque" {
Properties {
	_Color ("Main Color", Color) = (1,1,1,1)
	_SpecColor ("Spec Color", Color) = (1,1,1,0)
	_Emission ("Emissive Color", Color) = (0,0,0,0)
	_Shininess ("Shininess", Range (0.1, 1)) = 0.7
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
 
		#define ADD_SPECULAR
 
		fixed4 _Color;
		fixed4 _SpecColor;
		fixed4 _Emission;
		uint _HorizontalRes;
		uint _VerticalRes;
 
		half _Shininess;
 
		sampler2D _MainTex;
		float4 _MainTex_ST;
 
		struct v2f {
			float4 pos : SV_POSITION;
			float2 uv_MainTex : TEXCOORD0;
			fixed3 diff : COLOR;
			half3 normal : TEXCOORD2;
 
			#ifdef ADD_SPECULAR
			fixed3 spec : TEXCOORD1;
			#endif
			UNITY_FOG_COORDS(3)
		};
 
		v2f vert (appdata_full v)
		{
		    v2f o;
		    o.pos = mul (UNITY_MATRIX_MVP, v.vertex);

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
 
			float3 viewpos = mul (UNITY_MATRIX_MV, v.vertex).xyz;
 
			o.diff = UNITY_LIGHTMODEL_AMBIENT.xyz;
 
			#ifdef ADD_SPECULAR
			o.spec = 0;
			fixed3 viewDirObj = normalize( ObjSpaceViewDir(v.vertex) );
			#endif

			//All calculations are in object space
			for (int i = 0; i < 4; i++) {
				half3 toLight = unity_LightPosition[i].xyz - viewpos.xyz * unity_LightPosition[i].w;
				half lengthSq = dot(toLight, toLight);
				toLight *= rsqrt(lengthSq);
				half atten = 1.0 / (1.0 + lengthSq * unity_LightAtten[i].z );

				//Spotlights
				float rho = max (0, dot(toLight, unity_SpotDirection[i].xyz));
				float spotAtt = (rho - unity_LightAtten[i].x) * unity_LightAtten[i].y;
				atten *= saturate(spotAtt);

				fixed3 lightDirObj = normalize (mul( (float3x3)UNITY_MATRIX_T_MV, toLight));	//View => model
 
				lightDirObj = normalize(lightDirObj);
 
				fixed diff = max ( 0, dot (v.normal, lightDirObj) );
				o.diff += unity_LightColor[i].rgb * (diff * atten);
 
				#ifdef ADD_SPECULAR
				fixed3 h = normalize (viewDirObj + lightDirObj);
				fixed nh = max (0, dot (v.normal, h));
 
				fixed spec = pow (nh, _Shininess * 128.0);
				o.spec += spec * unity_LightColor[i].rgb * atten;
				#endif
			}
 
			o.diff = (o.diff * _Color + _Emission.rgb) ;
			#ifdef ADD_SPECULAR
			o.spec *= _SpecColor;
			#endif

			UNITY_TRANSFER_FOG (o, o.pos);
 
			return o;
		}
 
		fixed4 frag (v2f i) : COLOR {
			fixed4 c;
 
			fixed4 mainTex = tex2D (_MainTex, i.uv_MainTex / i.normal.x);
 
			#ifdef ADD_SPECULAR
			c.rgb = (mainTex.rgb * i.diff + i.spec);
			#else
			c.rgb = (mainTex.rgb * i.diff);
			#endif

			UNITY_APPLY_FOG (i.fogCoord, c);
			UNITY_OPAQUE_ALPHA (c.a);

 
			return c;
		}
 
		ENDCG
	}
 
	//Lightmap pass, dLDR;
	Pass {
		Tags { "LightMode" = "VertexLM" }
 
		CGPROGRAM
		#pragma vertex vert  
		#pragma fragment frag
		#pragma multi_compile_fog
 
		#include "UnityCG.cginc"

 		fixed4 _Color;
 		fixed4 _Emission;
		uint _HorizontalRes;
		uint _VerticalRes;
		sampler2D _MainTex;
		float4 _MainTex_ST;
 
		struct v2f {
			float4 pos : SV_POSITION;
			fixed3 diff : COLOR;
			float2 uv_MainTex : TEXCOORD0;
			float2 uv_Lightmap : TEXCOORD1;
			half3 normal : TEXCOORD2;
			UNITY_FOG_COORDS(3)
		};
 
		v2f vert (appdata_full v)
		{
		    v2f o;
		    o.pos = mul (UNITY_MATRIX_MVP, v.vertex);

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
			o.uv_Lightmap = v.texcoord1.xy * unity_LightmapST.xy + unity_LightmapST.zw;
			o.uv_Lightmap *= distance + (vertex.w*(UNITY_LIGHTMODEL_AMBIENT.a * 8)) / distance / 2;

			float3 viewpos = mul (UNITY_MATRIX_MV, v.vertex).xyz;
 
			o.diff = UNITY_LIGHTMODEL_AMBIENT.xyz;

			//All calculations are in object space
			for (int i = 0; i < 4; i++) {
				half3 toLight = unity_LightPosition[i].xyz - viewpos.xyz * unity_LightPosition[i].w;
				half lengthSq = dot(toLight, toLight);
				toLight *= rsqrt(lengthSq);
				half atten = 1.0 / (1.0 + lengthSq * unity_LightAtten[i].z );

				//Spotlights
				float rho = max (0, dot(toLight, unity_SpotDirection[i].xyz));
				float spotAtt = (rho - unity_LightAtten[i].x) * unity_LightAtten[i].y;
				atten *= saturate(spotAtt);

				fixed3 lightDirObj = normalize (mul( (float3x3)UNITY_MATRIX_T_MV, toLight));	//View => model
 
				lightDirObj = normalize(lightDirObj);
 
				fixed diff = max ( 0, dot (v.normal, lightDirObj) );
				o.diff += unity_LightColor[i].rgb * (diff * atten);
 
			}

			o.diff = (o.diff * _Color + _Emission.rgb) ;
			UNITY_TRANSFER_FOG (o, o.pos);

		    return o;
		 }

 
		fixed4 frag (v2f i) : COLOR {

			fixed4 c = tex2D(_MainTex, i.uv_MainTex / i.normal.x);
			fixed3 lightmap = DecodeLightmap(UNITY_SAMPLE_TEX2D(unity_Lightmap, i.uv_Lightmap / i.normal.r));

			c.rgb *= i.diff.rgb + lightmap;

			UNITY_APPLY_FOG (i.fogCoord, c);
			UNITY_OPAQUE_ALPHA (c.a);

			return c;
		}
 
		ENDCG
	}
 
	//Lightmap pass, RGBM;
	Pass {
		Tags { "LightMode" = "VertexLMRGBM" }
 
		CGPROGRAM
		#pragma vertex vert  
		#pragma fragment frag
		#pragma multi_compile_fog
 
		#include "UnityCG.cginc"

		fixed4 _Color;
		fixed4 _Emission;
		uint _HorizontalRes;
		uint _VerticalRes;
		sampler2D _MainTex;
		float4 _MainTex_ST;
 
		struct v2f {
			float4 pos : SV_POSITION;
			fixed3 diff : COLOR;
			float2 uv_MainTex : TEXCOORD0;
			float2 uv_Lightmap : TEXCOORD1;
			half3 normal : TEXCOORD2;
			UNITY_FOG_COORDS(3)
		};
 
		v2f vert (appdata_full v)
		{
		    v2f o;
		    o.pos = mul (UNITY_MATRIX_MVP, v.vertex);

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
			o.uv_Lightmap = v.texcoord1.xy * unity_LightmapST.xy + unity_LightmapST.zw;
			o.uv_Lightmap *= distance + (vertex.w*(UNITY_LIGHTMODEL_AMBIENT.a * 8)) / distance / 2;

			float3 viewpos = mul (UNITY_MATRIX_MV, v.vertex).xyz;
 
			o.diff = UNITY_LIGHTMODEL_AMBIENT.xyz;

			//All calculations are in object space
			for (int i = 0; i < 4; i++) {
				half3 toLight = unity_LightPosition[i].xyz - viewpos.xyz * unity_LightPosition[i].w;
				half lengthSq = dot(toLight, toLight);
				toLight *= rsqrt(lengthSq);
				half atten = 1.0 / (1.0 + lengthSq * unity_LightAtten[i].z );

				//Spotlights
				float rho = max (0, dot(toLight, unity_SpotDirection[i].xyz));
				float spotAtt = (rho - unity_LightAtten[i].x) * unity_LightAtten[i].y;
				atten *= saturate(spotAtt);

				fixed3 lightDirObj = normalize (mul( (float3x3)UNITY_MATRIX_T_MV, toLight));	//View => model
 
				lightDirObj = normalize(lightDirObj);
 
				fixed diff = max ( 0, dot (v.normal, lightDirObj) );
				o.diff += unity_LightColor[i].rgb * (diff * atten);
 
			}

			o.diff = o.diff + _Emission.rgb;
			UNITY_TRANSFER_FOG (o, o.pos);

		    return o;
		 }

 
		fixed4 frag (v2f i) : COLOR {

			fixed4 c = tex2D(_MainTex, i.uv_MainTex / i.normal.x) * _Color;
			fixed3 lightmap = DecodeLightmap(UNITY_SAMPLE_TEX2D(unity_Lightmap, i.uv_Lightmap / i.normal.r));

			c.rgb *= i.diff.rgb + lightmap;

			UNITY_APPLY_FOG (i.fogCoord, c);
			UNITY_OPAQUE_ALPHA (c.a);

			return c;
		}
 
		ENDCG
	}
}
 
Fallback "VertexLit"
}