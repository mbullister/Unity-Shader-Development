Shader "Teague/Decal Ink(UV1)" {
	Properties {
		[NoScaleOffset]_MainTex("Decal Image (UV1)", 2D) = "white" {}
		_InkIntensity("    Decal Intensity", Range(0,1)) = 1.0
		//[Toggle]_bReinhard("    Use Reinhard Tone Mapping", Int) = 1
	}
	SubShader {
		Tags { "Queue" = "Transparent" }
		Pass {   
			Blend DstColor Zero
			CGPROGRAM
 
			#pragma vertex vert  
			#pragma fragment frag 

			#include "UnityCG.cginc"

			// User-specified uniforms
			uniform sampler2D _MainTex;
			uniform float _InkIntensity;
			//uniform uint _bReinhard;

			
			//base input struct
			struct vertexInput {
				float4 texcoord0 : TEXCOORD0;
				//float4 texcoord1 : TEXCOORD1;
				//float4 texcoord2 : TEXCOORD2;
				float4 vertex : POSITION;
				//float3 normal : NORMAL;
				
			};
			
			//base output struct
			struct vertexOutput {
				float4 pos : SV_POSITION;
				float4 posWorld : TEXCOORD5;
				float4 uv0 : TEXCOORD0;
				//float4 uv1 : TEXCOORD1;
				//float4 uv2 : TEXCOORD2;
				//float3 normalDir : TEXCOORD3;
				//float3 viewDir : TEXCOORD4;
			};
 
			vertexOutput vert(vertexInput i) 
			{
				vertexOutput o;
				
 				o.pos = mul(UNITY_MATRIX_MVP, i.vertex);
 				o.posWorld = mul(_Object2World, i.vertex);
				o.uv0 = i.texcoord0;
				//o.uv1 = i.texcoord1;
				//o.uv2 = i.texcoord2;
				//o.normalDir = normalize(mul( float4(i.normal, 0.0), _World2Object ).xyz);
				//o.viewDir = mul(_Object2World, i.vertex).xyz - _WorldSpaceCameraPos;
								
				return o;
			}
 
			fixed3 frag(vertexOutput i) : COLOR
			{
				return lerp(1.0, tex2D(_MainTex, i.uv0), _InkIntensity);
				
			}
 
			ENDCG
			

			Offset -.25,-50

		}
	}
}