#if !defined(MY_LIGHTING_INCLUDED)
#define MY_LIGHTING_INCLUDED

#include "AutoLight.cginc"
#include "UnityStandardBRDF.cginc"

float4 _Tint;
sampler2D _MainTex;
float4 _MainTex_ST;
float4 _SpecularTint;
float _Smoothness;

struct VertexData {
	float4 position : POSITION;
	float3 normal : NORMAL;
	float2 uv : TEXCOORD0;
};

struct Interpolators {
	float4 position : SV_POSITION;
	float2 uv : TEXCOORD0;
	float3 normal : TEXCOORD1;
	float3 worldPos : TEXCOORD2;

	#if defined (VERTEXLIGHT_ON)
		float3 vertexLightColor : TEXCOORD3;
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
	i.position = UnityObjectToClipPos(v.position);
	i.worldPos = mul(unity_ObjectToWorld, v.position);
	i.normal = UnityObjectToWorldNormal(v.normal);
	i.uv = TRANSFORM_TEX(v.uv, _MainTex);
	ComputeVertexLightColor(i);
	return i;
}

float3 ComputeIndirectLight (inout Interpolators i) {
	float3 indirectLight = 0;
	#if defined(VERTEXLIGHT_ON)
		indirectLight = i.vertexLightColor;
	#endif

	#if defined (FORWARD_BASE_PASS)
		indirectLight += max(0, ShadeSH9(float4(i.normal, 1)));
	#endif

	return indirectLight;
}

//Fragment program
float4 MyFragmentProgram (Interpolators i) : SV_TARGET {
	//Normals cans be normalized on vertex program for better performance
	i.normal = normalize(i.normal);
	
	#if defined(POINT) || defined(POINT_COOKIE) || defined(SPOT)
		float3 lightDir = normalize(_WorldSpaceLightPos0.xyz - i.worldPos);
	#else
		float3 lightDir = _WorldSpaceLightPos0.xyz;
	#endif

	UNITY_LIGHT_ATTENUATION(attenuation, 0, i.worldPos);
	float3 lightColor = _LightColor0.rgb * attenuation;
	float3 albedo = tex2D(_MainTex, i.uv).rgb * _Tint.rgb;
	float3 diffuse = lightColor * DotClamped(lightDir, i.normal);
	
	float3 viewDir = normalize(_WorldSpaceCameraPos - i.worldPos);
	float3 halfVector = normalize(lightDir + viewDir);
	float3 specular = _SpecularTint.rgb * lightColor * pow(DotClamped(halfVector, i.normal), _Smoothness * 100);
				
	return float4(albedo * (diffuse + specular + ComputeIndirectLight(i)), 1);
}

#endif