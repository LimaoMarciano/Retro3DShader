Shader "Unlit/MyFirstLightingShader"
{
	
	Properties {
		_Tint ("Tint", Color) = (1, 1, 1, 1)
		_MainTex ("Albedo", 2D) = "white" {}
		_SpecularTint ("Specular", Color) = (0.5, 0.5, 0.5)
		_Smoothness ("Smoothness", Range(0.01, 1)) = 0.1
		[NoScaleOffset] _EmissionMap ("Emission", 2D) = "black" {}
		_Emission("Emission", Color) = (0, 0, 0)
		_AlphaCutoff("Alpha Cutoff", Range(0, 1)) = 0.5
	}

	CustomEditor "MyLightingShaderGUI"

	SubShader {
	
		Pass {

			Tags {
				"LightMode" = "ForwardBase"
			}

			CGPROGRAM

			#pragma target 3.0

			#pragma multi_compile _ VERTEXLIGHT_ON
			#pragma multi_compile _ SHADOWS_SCREEN
			#pragma shader_feature _EMISSION_MAP
			#pragma shader_feature _RENDERING_CUTOUT

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

			Blend One One
			ZWrite Off

			CGPROGRAM

			#pragma target 3.0

			#pragma multi_compile_fwdadd_fullshadows
			#pragma shader_feature _RENDERING_CUTOUT

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

			#pragma vertex MyShadowVertexProgram
			#pragma fragment MyShadowFragmentProgram

			#include "My Shadows.cginc"

			ENDCG

		}

	}

}
