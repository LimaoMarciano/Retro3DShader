// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Custom/Retro3DSurface" {
	Properties {
		_Color ("Color", Color) = (1,1,1,1)
		_MainTex ("Albedo (RGB)", 2D) = "white" {}
//		_Glossiness ("Smoothness", Range(0,1)) = 0.5
//		_Metallic ("Metallic", Range(0,1)) = 0.0
		_HorizontalRes ("Horizontal res", Int) = 320
		_VerticalRes ("Vertical res", Int) = 240
	}
	SubShader {
		Tags { "RenderType"="Opaque" }
		LOD 200
		
		CGPROGRAM
		// Physically based Standard lighting model, and enable shadows on all light types
		#pragma surface surf Lambert fullforwardshadows addshadow vertex:vert

		// Use shader model 3.0 target, to get nicer looking lighting
		#pragma target 3.0

		sampler2D _MainTex;


		struct Input {
			float2 uv_MainTex;
			fixed3 Normal;
		};

		half _Glossiness;
		half _Metallic;
		fixed4 _Color;
		uint _HorizontalRes;
		uint _VerticalRes;


		// Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
		// See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
		// #pragma instancing_options assumeuniformscaling
//		UNITY_INSTANCING_CBUFFER_START(Props)
			// put more per-instance properties here
//		UNITY_INSTANCING_CBUFFER_END

		float4x4 inverse(float4x4 input)
 		{
     #define minor(a,b,c) determinant(float3x3(input.a, input.b, input.c))
     //determinant(float3x3(input._22_23_23, input._32_33_34, input._42_43_44))
     
	     float4x4 cofactors = float4x4(
	          minor(_22_23_24, _32_33_34, _42_43_44), 
	         -minor(_21_23_24, _31_33_34, _41_43_44),
	          minor(_21_22_24, _31_32_34, _41_42_44),
	         -minor(_21_22_23, _31_32_33, _41_42_43),
	         
	         -minor(_12_13_14, _32_33_34, _42_43_44),
	          minor(_11_13_14, _31_33_34, _41_43_44),
	         -minor(_11_12_14, _31_32_34, _41_42_44),
	          minor(_11_12_13, _31_32_33, _41_42_43),
	         
	          minor(_12_13_14, _22_23_24, _42_43_44),
	         -minor(_11_13_14, _21_23_24, _41_43_44),
	          minor(_11_12_14, _21_22_24, _41_42_44),
	         -minor(_11_12_13, _21_22_23, _41_42_43),
	         
	         -minor(_12_13_14, _22_23_24, _32_33_34),
	          minor(_11_13_14, _21_23_24, _31_33_34),
	         -minor(_11_12_14, _21_22_24, _31_32_34),
	          minor(_11_12_13, _21_22_23, _31_32_33)
	     );
	     #undef minor
	     return transpose(cofactors) / determinant(input);
 		}

		void vert (inout appdata_full v, out Input o) {

//			v2f o;
//		    o.pos = UnityObjectToClipPos (v.vertex);

			float4 viewPos = v.vertex;
//			viewPos.xyz = UnityObjectToViewPos (viewPos);
			viewPos.xyz = UnityObjectToClipPos (v.vertex);

			//Vertex snapping
			float4 snapToPixel = viewPos;
			float4 vertex = snapToPixel;
			vertex.xyz = snapToPixel.xyz / snapToPixel.w;
			vertex.x = floor((_HorizontalRes / 2) * vertex.x) / (_HorizontalRes / 2);
			vertex.y = floor((_VerticalRes / 2) * vertex.y) / (_VerticalRes / 2);
			vertex.xyz *= snapToPixel.w;


			//Affine Texture Mapping
		    float distance = length(UnityObjectToClipPos(v.vertex));
			float4 affinePos = vertex; //vertex;				

			v.texcoord *= distance + (vertex.w*(1 * 8)) / distance / 2;
			o.Normal = distance + (vertex.w*(1 * 8)) / distance / 2;

			o.uv_MainTex = TRANSFORM_UV(0);
			float4x4 inv = inverse(mul (UNITY_MATRIX_P, UNITY_MATRIX_V));
			v.vertex = mul(inv, vertex);
			
		}

		void surf (Input IN, inout SurfaceOutput o) {
			

			// Albedo comes from a texture tinted by color
			fixed4 c = tex2D (_MainTex, IN.uv_MainTex / IN.Normal.x) * _Color;
			o.Albedo = c.rgb;
			// Metallic and smoothness come from slider variables
//			o.Metallic = _Metallic;
//			o.Smoothness = _Glossiness;
			o.Alpha = c.a;
		}
		ENDCG
	}
	FallBack "Diffuse"
}
