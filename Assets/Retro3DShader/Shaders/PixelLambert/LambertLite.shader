Shader "Custom/Lambert Lite"
{
	

	Properties
	{
		_Color ("Tint", Color) = (1.0, 1.0, 1.0)
		_MainTex ("Albedo", 2D) = "white" {}
		_SpecularTint ("Specular", Color) = (0.5, 0.5, 0.5)
		_SpecularMap ("Specular map", 2D) = "black" {}
		_Smoothness ("Smoothness", Range (0.01, 1)) = 0.5
		_Emission ("Emission", Color) = (0.0, 0.0, 0.0)
		_EmissionMap ("Emission map", 2D) = "black" {}
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 100

		Pass
		{
			Tags {
				"LightMode" = "ForwardBase"
			}

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			// make fog work
			#pragma multi_compile_fwdbase
			#pragma multi_compile_fog
			#pragma multi_compile _ LIGHTMAP_ON VERTEXLIGHT_ON
			
			#pragma shader_feature _SPECULAR_MAP
			#pragma shader_feature _EMISSION_MAP
			
			#include "UnityStandardBRDF.cginc"
			#include "AutoLight.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				half3 normal : NORMAL;
				float2 uv : TEXCOORD0;
				
				#if defined(LIGHTMAP_ON)
					float2 uv1 : TEXCOORD1;
				#endif
			};

			struct v2f
			{
				float4 pos : SV_POSITION;
				float2 uv : TEXCOORD0;
				fixed3 diffuse : COLOR0;
				fixed3 indirectLight : COLOR1;
				fixed3 specular : COLOR2;
				half3 normal : TEXCOORD2;
				float3 worldPos : TEXCOORD3;
				UNITY_FOG_COORDS(1)
				SHADOW_COORDS(4)

				#if defined(LIGHTMAP_ON)
					float2 uv1 : TEXCOORD5;
				#endif
			};

			sampler2D _MainTex;
			sampler2D _unity_Lightmap;
			sampler2D _SpecularMap;
			sampler2D _EmissionMap;
			float4 _MainTex_ST;
			float _Smoothness;
			fixed4 _Color;
			fixed4 _SpecularTint;
			fixed3 _Emission;
			
			v2f vert (appdata v)
			{
				v2f o;

				o.pos = UnityObjectToClipPos(v.vertex);
				o.worldPos = mul(unity_ObjectToWorld, v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				o.normal = normalize(UnityObjectToWorldNormal(v.normal));

				#if defined(LIGHTMAP_ON)
					o.uv1 = v.uv1 * unity_LightmapST.xy + unity_LightmapST.zw;
				#endif
				
				//Diffuse reflection
				half3 lightDir = _WorldSpaceLightPos0.xyz;
				fixed3 lightColor = _LightColor0.rgb;
				o.diffuse = lightColor * DotClamped(lightDir, o.normal);

				o.indirectLight = 0;

				#if defined(VERTEXLIGHT_ON)
					o.indirectLight = Shade4PointLights (
						unity_4LightPosX0, unity_4LightPosY0, unity_4LightPosZ0,
						unity_LightColor[0].rgb, unity_LightColor[1].rgb,
						unity_LightColor[2].rgb, unity_LightColor[3].rgb,
						unity_4LightAtten0, o.worldPos, o.normal
					);
				#endif

				#if defined(LIGHTMAP_ON)
					o.indirectLight = 0;
				#else
					o.indirectLight += max(0, ShadeSH9(half4(o.normal, 1)));
				#endif

				//Specular
				half3 viewDir = normalize(_WorldSpaceCameraPos - o.worldPos);
				half3 halfVector = normalize(lightDir + viewDir);
				o.specular = lightColor * _SpecularTint * pow(DotClamped(halfVector, o.normal), _Smoothness * 100);

				//o.diffuse += specular;

				UNITY_TRANSFER_FOG(o,o.pos);
				TRANSFER_SHADOW(o)
					
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				// sample the texture
				half3 albedo = tex2D(_MainTex, i.uv) * _Color;
				fixed shadow = SHADOW_ATTENUATION(i);

				#if defined (LIGHTMAP_ON)
					i.indirectLight = DecodeLightmap(UNITY_SAMPLE_TEX2D(unity_Lightmap, i.uv1));
				#endif

				#if defined (_SPECULAR_MAP)
					fixed3 specular = tex2D(_SpecularMap, i.uv) * i.specular;
				#else
					fixed3 specular = i.specular;
				#endif

				//Emissive light
				#if defined (_EMISSION_MAP)
					fixed3 emission = tex2D(_EmissionMap, i.uv) * _Emission;
				#else
					fixed3 emission = _Emission;
				#endif

				fixed3 lighting = (i.diffuse + specular) * shadow + i.indirectLight + emission;
				fixed4 col = fixed4(albedo * lighting, 1);

				// apply fog
				UNITY_APPLY_FOG(i.fogCoord, col);
				
				return col;

			}
			ENDCG
		}
		
		Pass 
		{
			Tags {
				"LightMode" = "ForwardAdd"
			}

			Blend One One
			Zwrite Off

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			// make fog work
			#pragma multi_compile_fog
			#pragma multi_compile_fwdadd_fullshadows

			#pragma shader_feature _SPECULARMAP

			#include "UnityStandardBRDF.cginc"
			#include "AutoLight.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float4 pos : SV_POSITION;
				fixed3 diffuse : COLOR0;
				fixed3 specular : COLOR1;
				float2 uv : TEXCOORD0;
				half3 normal : TEXCOORD2;
				float3 worldPos : TEXCOORD3;
				UNITY_FOG_COORDS(1)
				SHADOW_COORDS(4)
			};

			sampler2D _MainTex;
			sampler2D _SpecularMap;
			float4 _MainTex_ST;
			float _Smoothness;
			fixed4 _SpecularTint;
			fixed4 _Color;
			
			v2f vert (appdata v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.worldPos = mul(unity_ObjectToWorld, v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);

				o.normal = normalize(UnityObjectToWorldNormal(v.normal));

				//Diffuse light
				//Interpret _WorldSpaceLightPos0 as direction for direction lights and as position for the rest
				#if defined (POINT) || defined(POINT_COOKIE) || defined(SPOT)
					half3 lightDir = normalize(_WorldSpaceLightPos0.xyz - o.worldPos);
				#else
					half3 lightDir = _WorldSpaceLightPos0.xyz;
				#endif
				
				half3 ndotl = DotClamped(o.normal, lightDir);
				fixed3 lightColor = _LightColor0.rgb * ndotl;

				//Specular
				half3 viewDir = normalize(_WorldSpaceCameraPos - o.worldPos);
				half3 halfVector = normalize(lightDir + viewDir);
				o.specular = lightColor * _SpecularTint * pow(DotClamped(halfVector, o.normal), _Smoothness * 100);

				o.diffuse = lightColor;

				UNITY_TRANSFER_FOG(o,o.pos);
				TRANSFER_SHADOW(o)
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				half3 albedo = tex2D(_MainTex, i.uv) * _Color;
				
				
				
				#if defined (_SPECULAR_MAP)
					fixed3 specular = tex2D(_SpecularMap, i.uv) * i.specular;
				#else
					fixed3 specular = i.specular;
				#endif

				UNITY_LIGHT_ATTENUATION(attenuation, i, i.worldPos);
				fixed3 lighting = attenuation * (i.diffuse + specular);
				fixed4 col = fixed4(lighting * albedo, 1);

				// apply fog
				UNITY_APPLY_FOG(i.fogCoord, col);
				return col;
			}
			ENDCG
		}

		Pass 
		{
			Tags {
				"LightMode" = "ShadowCaster"
			}

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_shadowcaster
			#include "UnityCG.cginc"

			struct v2f {
				V2F_SHADOW_CASTER;
			};

			v2f vert (appdata_base v) {
				v2f o;
				TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
				return o;
			}

			float4 frag(v2f i) : SV_Target {
				SHADOW_CASTER_FRAGMENT(i)
			}
			ENDCG
		}

		Pass
		{
			Name "META"
			Tags{ "LightMode" = "Meta" }
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 2.0
			#include "UnityCG.cginc"
			#include "UnityMetaPass.cginc"

			struct v2f
			{
				float4 pos : SV_POSITION;
				float2 uvMain : TEXCOORD0;
				float2 uvIllum : TEXCOORD1;
				UNITY_VERTEX_OUTPUT_STEREO
			};

			float4 _MainTex_ST;
			float4 _Illum_ST;

			v2f vert(appdata_full v)
			{
				v2f o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
				o.pos = UnityMetaVertexPosition(v.vertex, v.texcoord1.xy, v.texcoord2.xy, unity_LightmapST, unity_DynamicLightmapST);
				o.uvMain = TRANSFORM_TEX(v.texcoord, _MainTex);
				o.uvIllum = TRANSFORM_TEX(v.texcoord, _Illum);
				return o;
			}

			sampler2D _MainTex;
			sampler2D _Illum;
			sampler2D _EmissionMap;
			fixed4 _Color;
			fixed3 _Emission;

			half4 frag(v2f i) : SV_Target
			{
				UnityMetaInput metaIN;
				UNITY_INITIALIZE_OUTPUT(UnityMetaInput, metaIN);

				fixed4 tex = tex2D(_MainTex, i.uvMain);
				fixed4 c = tex * _Color;

				//Emissive light
				#if defined (_EMISSION_MAP)
					fixed3 emission = tex2D(_EmissionMap, i.uv) * _Emission;
				#else
					fixed3 emission = _Emission;
				#endif

				metaIN.Albedo = c.rgb;
				metaIN.Emission = c.rgb * tex2D(_Illum, i.uvIllum).a + emission;

				return UnityMetaFragment(metaIN);
			}
			ENDCG
		}

	}
	CustomEditor "LambertLiteInpector"
	Fallback "Diffuse"
}
