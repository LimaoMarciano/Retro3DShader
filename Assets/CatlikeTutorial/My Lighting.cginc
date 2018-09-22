// Upgrade NOTE: replaced 'defined SUBTRACTIVE_LIGHTING' with 'defined (SUBTRACTIVE_LIGHTING)'

#if !defined(MY_LIGHTING_INCLUDED)
#define MY_LIGHTING_INCLUDED


#include "UnityStandardBRDF.cginc"
#include "AutoLight.cginc"

#if defined(LIGHTMAP_ON) && defined(SHADOWS_SCREEN)
	#if defined(LIGHTMAP_SHADOW_MIXING) && !defined(SHADOWS_SHADOWMASK)
		#define SUBTRACTIVE_LIGHTING 1
	#endif
#endif

float4 _Color;
sampler2D _MainTex;
float4 _MainTex_ST;
sampler2D _EmissionMap;
float4 _Emission;
float4 _SpecularTint;
float _Smoothness;
float _Cutoff;
samplerCUBE _ReflectionMap;
float4 _ReflectionTint;
float _GeoRes;

struct VertexData {
	float4 vertex : POSITION;
	float3 normal : NORMAL;
	float2 uv : TEXCOORD0;
	float2 uv1 : TEXCOORD1;
};

struct Interpolators {
	float4 pos : SV_POSITION;
	float2 uv : TEXCOORD0;
	float3 normal : TEXCOORD1;
	float3 worldPos : TEXCOORD2;
	UNITY_FOG_COORDS(4)
	UNITY_SHADOW_COORDS(5)

	#if defined (VERTEXLIGHT_ON)
		float3 vertexLightColor : TEXCOORD6;
	#endif

	#if defined (LIGHTMAP_ON)
		float2 lightmapUV : TEXCOORD7;
	#endif

};

void ComputeVertexLightColor (inout Interpolators i) {
	#if defined (VERTEXLIGHT_ON)
		i.vertexLightColor = Shade4PointLights(
			unity_4LightPosX0, unity_4LightPosY0, unity_4LightPosZ0,
			unity_LightColor[0].rgb, unity_LightColor[1].rgb,
			unity_LightColor[2].rgb, unity_LightColor[3].rgb,
			unity_4LightAtten0, i.worldPos, i.normal);
	#endif
}

//Vertex program
Interpolators MyVertexProgram (VertexData v) {
	Interpolators i;
	UNITY_INITIALIZE_OUTPUT(Interpolators, i);
	//i.pos = UnityObjectToClipPos(v.vertex);

	float4 viewPos = mul(UNITY_MATRIX_MV, v.vertex);
	viewPos.xyz = floor(viewPos.xyz * _GeoRes) / _GeoRes;

	float4 clipPos = mul(UNITY_MATRIX_P, viewPos);
	i.pos = clipPos;

	i.worldPos = mul(unity_ObjectToWorld, v.vertex);
	i.normal = UnityObjectToWorldNormal(v.normal);
	i.uv = TRANSFORM_TEX(v.uv, _MainTex);
	
	#if defined (LIGHTMAP_ON)
		i.lightmapUV = v.uv1 * unity_LightmapST.xy + unity_LightmapST.zw;
	#endif
	
	UNITY_TRANSFER_SHADOW(i, v.uv1);
	UNITY_TRANSFER_FOG(i, i.pos);

	ComputeVertexLightColor(i);
	return i;
}


float FadeShadows(Interpolators i, float attenuation) {
	#if HANDLE_SHADOWS_BLENDING_IN_GI
		// UNITY_LIGHT_ATTENUATION doesn't fade shadows for us.
		float viewZ = dot(_WorldSpaceCameraPos - i.worldPos, UNITY_MATRIX_V[2].xyz);
		float shadowFadeDistance = UnityComputeShadowFadeDistance(i.worldPos, viewZ);
		float shadowFade = UnityComputeShadowFade(shadowFadeDistance);

		float bakedAttenuation = UnitySampleBakedOcclusion(i.lightmapUV, i.worldPos);
		attenuation = UnityMixRealtimeAndBakedShadows(attenuation, bakedAttenuation, shadowFade);
	#endif
	return attenuation;
}

float3 ApplySubtractiveLighting(Interpolators i, float3 diffuse) {

	UNITY_LIGHT_ATTENUATION(attenuation, i, i.worldPos.xyz);
	attenuation = FadeShadows(i, attenuation);

	float ndotl = saturate(dot(i.normal, _WorldSpaceLightPos0.xyz));
	float3 shadowedLightEstimate = ndotl * (1 - attenuation) * _LightColor0.rgb;

	float3 subtractedLight = diffuse - shadowedLightEstimate;
	subtractedLight = max(subtractedLight, unity_ShadowColor.rgb);
	subtractedLight = lerp(subtractedLight, diffuse, _LightShadowData.x);
	float3 correctDiffuse = min(subtractedLight, diffuse);

	return correctDiffuse;
}

float3 GetIndirectLight (inout Interpolators i) {
	float3 indirectLight = 0;
	#if defined(VERTEXLIGHT_ON)
		indirectLight = i.vertexLightColor;
	#endif

	#if defined (FORWARD_BASE_PASS)
		#if defined (LIGHTMAP_ON)
			indirectLight = DecodeLightmap(UNITY_SAMPLE_TEX2D(unity_Lightmap, i.lightmapUV));

			#if defined (DIRLIGHTMAP_COMBINED)
				float4 lightmapDirection = UNITY_SAMPLE_TEX2D_SAMPLER(unity_LightmapInd, unity_Lightmap, i.lightmapUV);
				indirectLight = DecodeDirectionalLightmap(indirectLight, lightmapDirection, i.normal);
			#endif
			
			#if SUBTRACTIVE_LIGHTING
				indirectLight = ApplySubtractiveLighting(i, indirectLight);
			#endif

		#else
			indirectLight += max(0, ShadeSH9(float4(i.normal, 1)));
		#endif
	#endif

	return indirectLight;
}

float3 GetEmission(Interpolators i) {
	#if defined(FORWARD_BASE_PASS)
		#if defined(_EMISSION_MAP)
			return tex2D(_EmissionMap, i.uv.xy) * _Emission;
		#else
			return _Emission;
		#endif
	#else
		return 0;
	#endif
}

float GetAlpha(Interpolators i) {
	float alpha = _Color.a * tex2D(_MainTex, i.uv.xy).a;
	return alpha;
}



//Fragment program
float4 MyFragmentProgram (Interpolators i) : SV_TARGET {
	float alpha = GetAlpha(i);
	
	#if defined(_RENDERING_CUTOUT)
		clip(alpha - _Cutoff);
	#endif
	
	//Normals cans be normalized on vertex program for better performance
	i.normal = normalize(i.normal);
	
	float3 lightDir;
	float3 lightColor;

	#if SUBTRACTIVE_LIGHTING
		lightDir = float3 (0, 1, 0);
		lightColor = 0;
	#else
		#if defined(POINT) || defined(POINT_COOKIE) || defined(SPOT)
			lightDir = normalize(_WorldSpaceLightPos0.xyz - i.worldPos);
		#else
			lightDir = _WorldSpaceLightPos0.xyz;
		#endif

		UNITY_LIGHT_ATTENUATION(attenuation, i, i.worldPos);
		attenuation = FadeShadows(i, attenuation);

		lightColor = _LightColor0.rgb * attenuation;

	#endif

	float3 diffuse = GetIndirectLight(i) + lightColor * DotClamped(lightDir, i.normal);
	float3 albedo = tex2D(_MainTex, i.uv).rgb * _Color.rgb;

	float3 viewDir = normalize(_WorldSpaceCameraPos - i.worldPos);
	float3 halfVector = normalize(lightDir + viewDir);
	float3 specular = _SpecularTint.rgb * lightColor * pow(DotClamped(halfVector, i.normal), _Smoothness * 100);
	float3 emission = GetEmission(i);

	float4 color;
	
	#if defined (FORWARD_BASE_PASS)
		#if defined (_REFLECTIVE)
			float3 reflectionDir = reflect(-viewDir, i.normal);
			float3 reflection = texCUBE(_ReflectionMap, reflectionDir);
			diffuse += reflection * _ReflectionTint;
			
			//half4 reflectionData = UNITY_SAMPLE_TEXCUBE(unity_SpecCube0, reflectionDir);
            //half3 reflection = DecodeHDR (reflectionData, unity_SpecCube0_HDR);
			//diffuse += reflection;

		#endif
	#endif
			
	#if defined (_RENDERING_TRANSPARENT)
		albedo *= alpha;
	#endif

	color.rgb = albedo * diffuse + specular + emission;
	color.a = 1;
	
	#if defined(_RENDERING_FADE) || (_RENDERING_TRANSPARENT)
		color.a = alpha;
	#endif

	UNITY_APPLY_FOG(i.fogCoord, color);

	return color;
}

#endif