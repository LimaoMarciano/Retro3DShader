#if !defined(MY_LIGHTMAPPING_INCLUDED)
#define MY_LIGHTMAPPING_INCLUDED

#include "UnityPBSLighting.cginc"
#include "UnityMetaPass.cginc"

float4 _Color;
sampler2D _MainTex;
float4 _MainTex_ST;
sampler2D _EmissionMap;
float3 _Emission;

struct VertexData {
	float4 vertex : POSITION;
	float2 uv : TEXCOORD0;
	float2 uv1 : TEXCOORD1;
};

struct Interpolators {
	float4 pos : SV_POSITION;
	float2 uv : TEXCOORD0;
};

float3 GetEmission(Interpolators i) {

	#if defined(_EMISSION_MAP)
		return tex2D(_EmissionMap, i.uv.xy) * _Emission;
	#else
		return _Emission;
	#endif

}

Interpolators MyLightmappingVertexProgram (VertexData v) {
	Interpolators i;

	i.pos = UnityMetaVertexPosition(v.vertex, v.uv.xy, v.uv1.xy, unity_LightmapST, unity_DynamicLightmapST);

	//v.vertex.xy = v.uv1 * unity_LightmapST.xy + unity_LightmapST.zw;
	//v.vertex.z = v.vertex.z > 0 ? 0.0001 : 0;

	//i.pos = UnityObjectToClipPos(v.vertex);
	i.uv = TRANSFORM_TEX(v.uv, _MainTex);
	return i;
}

float4 MyLightmappingFragmentProgram (Interpolators i) : SV_TARGET {
	UnityMetaInput surfaceData;
	UNITY_INITIALIZE_OUTPUT(UnityMetaInput, surfaceData);

	surfaceData.Emission = GetEmission(i);
	surfaceData.Albedo = tex2D(_MainTex, i.uv).rgb * _Color.rgb;
	surfaceData.SpecularColor = 0;
	return UnityMetaFragment(surfaceData);
}

#endif