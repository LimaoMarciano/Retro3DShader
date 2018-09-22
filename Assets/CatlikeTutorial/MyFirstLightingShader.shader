Shader "Unlit/MyFirstLightingShader"
{
	
	Properties {
		_Color ("Tint", Color) = (1, 1, 1, 1)
		_MainTex ("Albedo", 2D) = "white" {}
		_SpecularTint ("Specular", Color) = (0.5, 0.5, 0.5)
		_Smoothness ("Smoothness", Range(0.01, 1)) = 0.1
		[NoScaleOffset] _EmissionMap ("Emission", 2D) = "black" {}
		_Emission("Emission", Color) = (0, 0, 0)
		_Cutoff("Alpha Cutoff", Range(0, 1)) = 0.5
		_ReflectionMap("Reflection Map", Cube) = "" {}
		_ReflectionTint ("Reflection Tint", Color) = (0.5, 0.5, 0.5)
		_GeoRes ("Geometric Resolution", Float) = 50
		[HideInInspector] _SrcBlend("_SrcBlend", Float) = 1
		[HideInInspector] _DstBlend("_DstBlend", Float) = 0
		[HideInInspector] _ZWrite ("_ZWrite", Float) = 1
	}

	CustomEditor "MyLightingShaderGUI"

	SubShader {
	
		Pass {

			Tags {
				"LightMode" = "ForwardBase"
			}
			
			Blend [_SrcBlend] [_DstBlend]
			ZWrite [_ZWrite]

			CGPROGRAM

			#pragma target 3.0

			#pragma multi_compile_fwdbase
			#pragma multi_compile _ VERTEXLIGHT_ON
			#pragma multi_compile_fog
			#pragma shader_feature _EMISSION_MAP
			#pragma shader_feature _ _RENDERING_CUTOUT _RENDERING_FADE _RENDERING_TRANSPARENT
			#pragma shader_feature _ _REFLECTIVE

			#pragma vertex MyVertexProgram
			#pragma fragment MyFragmentProgram

			#define FORWARD_BASE_PASS

			#include "My Lighting.cginc"

			ENDCG
		}

		Pass {
			
			Tags {
				"LightMode" = "ForwardAdd"
			}

			Blend [_SrcBlend] One
			ZWrite Off

			CGPROGRAM

			#pragma target 3.0

			#pragma multi_compile_fwdadd_fullshadows
			#pragma multi_compile_fog
			#pragma shader_feature _ _RENDERING_CUTOUT _RENDERING_FADE _RENDERING_TRANSPARENT

			#pragma vertex MyVertexProgram
			#pragma fragment MyFragmentProgram

			#include "My Lighting.cginc"

			ENDCG

		}

		Pass {

			Tags {
				"LightMode" = "ShadowCaster"
			}

			CGPROGRAM

			#pragma target 3.0

			#pragma multi_compile_shadowcaster
			#pragma shader_feature _ _RENDERING_CUTOUT _RENDERING_FADE _RENDERING_TRANSPARENT
			#pragma shader_feature _SEMITRANSPARENT_SHADOWS

			#pragma vertex MyShadowVertexProgram
			#pragma fragment MyShadowFragmentProgram

			#include "My Shadows.cginc"

			ENDCG

		}

	}

	Fallback "Diffuse"

}
