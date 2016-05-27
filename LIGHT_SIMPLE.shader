Shader "Teague/LightMap(UV2) AlbedoMap(UV1)" {
	Properties {
		[NoScaleOffset]_MainTex("RawTotalLightingMap (UV2)", 2D) = "gray" {}
		//_RGBM("    RGBM factor", Int) = 6
		//[Toggle]_bReinhard("    Use Reinhard Tone Mapping", Int) = 1
		_AlbedoTex("DiffuseMap (UV1)", 2D) = "gray" {}
		[KeywordEnum(One, Two)]_DiffUV("    DiffuseMap UV", Int) = 1
		_AlbedoGamma("    DiffuseMap Gamma", Float) = 2.2
		//_GlowTex("SelfIlluminationMap (UV1)", 2D) = "black" {}
		//_GlowEV("    SelfIlluminationMap EV", Float) = 0.0
		//_DetailTex("DetailMap (UV1)", 2D) = "gray"{}
		//_DetailUnpack("DetailMap Strength", Float) = 1.0
		//[NoScaleOffset]_TexWS("WorldSpaceTexture(UV2)", 2D) = "black" {}
		//[Toggle]_Cool("ToggleTest", Int) = 0
		//_NoiseTex("Noise", 2D) = "black" {}
	}
	SubShader {
		Pass {   
			CGPROGRAM
 
			#pragma vertex vert  
			#pragma fragment frag 

			#include "UnityCG.cginc"
			#include "FUNCTIONS/CommonFunctions.cginc"

			// User-specified uniforms
			uniform sampler2D _MainTex;
			//uniform float4 _MainTex_ST;
			uniform uint _RGBM;
			uniform sampler2D _AlbedoTex;
			uniform float4 _AlbedoTex_ST;
			uniform float _AlbedoGamma;
			uniform uint _DiffUV;
			//uniform uint _bSRGBAlbedo;
			//uniform sampler2D _DetailTex;
			//uniform float4 _DetailTex_ST;
			//uniform fixed _DetailUnpack;
			//uniform fixed _RowOffset;

			uniform uint _bReinhard;

			
			//base input struct
			struct vertexInput {
				float4 texcoord0 : TEXCOORD0;
				float4 texcoord1 : TEXCOORD1;
				//float4 texcoord2 : TEXCOORD2;
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				
			};
			
			//base output struct
			struct vertexOutput {
				float4 pos : SV_POSITION;
				float4 posWorld : TEXCOORD5;
				float4 uv0 : TEXCOORD0;
				float4 uv1 : TEXCOORD1;
				//float4 uv2 : TEXCOORD2;
				float3 normalDir : TEXCOORD3;
				float3 viewDir : TEXCOORD4;
			};
 
			vertexOutput vert(vertexInput i) 
			{
				vertexOutput o;
				
 				o.pos = mul(UNITY_MATRIX_MVP, i.vertex);
 				o.posWorld = mul(_Object2World, i.vertex);
				o.uv0 = i.texcoord0;
				o.uv1 = i.texcoord1;
				//o.uv2 = i.texcoord2;
				o.normalDir = normalize(mul( float4(i.normal, 0.0), _World2Object ).xyz);
				o.viewDir = mul(_Object2World, i.vertex).xyz - _WorldSpaceCameraPos;
								
				return o;
			}
 
			fixed3 frag(vertexOutput i) : COLOR
			{
				half4 diffuseFilter = pow(tex2D(_AlbedoTex, i.uv1.xy * _AlbedoTex_ST.xy + _AlbedoTex_ST.z), _AlbedoGamma);//convert albedo to linear color
				//return pow(diffuseFilter, 1/2.2);
				if(_DiffUV == 0){
					diffuseFilter = pow(tex2D(_AlbedoTex, i.uv0.xy * _AlbedoTex_ST.xy + _AlbedoTex_ST.z), _AlbedoGamma);
				};
				
				//return diffuseFilter;

				float4 rawTotalLightingTex = tex2D(_MainTex, i.uv1);

																
				//float4 rawTotalLighting = RGBM(rawTotalLightingTex, _RGBM);//RGBM decode

				float4 totalLighting = diffuseFilter * rawTotalLightingTex;
				//return pow(totalLighting, 1/2.2);//used for debugging purposes.
				
				if(_bReinhard == 1){
					return Reinhard(totalLighting).xyz;
				}
				else{
					return Gamma(totalLighting).xyz;
				}
				return fixed3(1,0.5,0.5);//return error color
			}

				ENDCG
			

			//Offset -.25,-50//hey, don't worry about this.

		}
	}
}