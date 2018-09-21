#if !defined(MY_LIGHTING_INCLUDED)
#define MY_LIGHTING_INCLUDED


#include "UnityStandardBRDF.cginc"
#include "AutoLight.cginc"

float4 _Tint;
sampler2D _MainTex;
float4 _MainTex_ST;
sampler2D _EmissionMap;
float4 _Emission;
float4 _SpecularTint;
float _Smoothness;
float _AlphaCutoff;
samplerCUBE _ReflectionMap;
float4 _ReflectionTint;

struct VertexData {
	float4 vertex : POSITION;
	float3 normal : NORMAL;
	float2 uv : TEXCOORD0;
};

struct Interpolators {
	float4 pos : SV_POSITION;
	float2 uv : TEXCOORD0;
	float3 normal : TEXCOORD1;
	float3 worldPos : TEXCOORD2;

	SHADOW_COORDS(5)

	#if defined (VERTEXLIGHT_ON)
		float3 vertexLightColor : TEXCOORD6;
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
	i.pos = UnityObjectToClipPos(v.vertex);
	i.worldPos = mul(unity_ObjectToWorld, v.vertex);
	i.normal = UnityObjectToWorldNormal(v.normal);
	i.uv = TRANSFORM_TEX(v.uv, _MainTex);
	
	TRANSFER_SHADOW(i);

	ComputeVertexLightColor(i);
	return i;
}

float3 GetIndirectLight (inout Interpolators i) {
	float3 indirectLight = 0;
	#if defined(VERTEXLIGHT_ON)
		indirectLight = i.vertexLightColor;
	#endif

	#if defined (FORWARD_BASE_PASS)
		indirectLight += max(0, ShadeSH9(float4(i.normal, 1)));
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
	float alpha = _Tint.a * tex2D(_MainTex, i.uv.xy).a;
	return alpha;
}

//Fragment program
float4 MyFragmentProgram (Interpolators i) : SV_TARGET {
	float alpha = GetAlpha(i);
	
	#if defined(_RENDERING_CUTOUT)
		clip(alpha - _AlphaCutoff);
	#endif
	
	//Normals cans be normalized on vertex program for better performance
	i.normal = normalize(i.normal);
	
	#if defined(POINT) || defined(POINT_COOKIE) || defined(SPOT)
		float3 lightDir = normalize(_WorldSpaceLightPos0.xyz - i.worldPos);
	#else
		float3 lightDir = _WorldSpaceLightPos0.xyz;
	#endif

	UNITY_LIGHT_ATTENUATION(attenuation, i, i.worldPos);
	
	float3 lightColor = _LightColor0.rgb * attenuation;
	float3 albedo = tex2D(_MainTex, i.uv).rgb * _Tint.rgb;
	float3 diffuse = lightColor * DotClamped(lightDir, i.normal);

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

	color.rgb = albedo * (diffuse + GetIndirectLight(i)) + specular + emission;
	color.a = 1;

	#if defined(_RENDERING_FADE) || (_RENDERING_TRANSPARENT)
		color.a = alpha;
	#endif

	return color;
}

#endif