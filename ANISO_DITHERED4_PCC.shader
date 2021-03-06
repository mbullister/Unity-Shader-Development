﻿Shader "Teague/Anisotropic PCC with 4-sample Dithering" {
	Properties {
		[NoScaleOffset]_MainTex("CompleteMap (UV2)", 2D) = "gray" {}
		_LightEV("	CompleteMap Strength", Float) = 1.0
		[Toggle]_bReinhard("	Use Reinhard Tone Mapping", Int) = 0
		//_DetailTex("DetailMap (UV1)", 2D) = "gray"{}
		//_DetailUnpack("DetailMap Strength", Float) = 1.0
		//_GlowTex("GlowMap", 2D) = "black" {}
		//_GlowUnpack("GlowMap Strength", Float) = 1.0
		//_ScreenResX
		[NoScaleOffset]_MaskTex("MaskMap(UV2)", 2D) = "white" {}
		//_Samples("Anisotropic Samples", Int) = 4
		//[Toggle]_bUseDithering("Use Dithering", Int) = 1
		_AnisoTex("Anisotropic Direction Map", 2D) = "bump" {}
		_AnisoStrength("AnisotropicStrength", Range(0,1)) = 0
		[Toggle]_bRoughness("Use Roughness From Mask", Int) = 1
		_Roughness("	Roughness", Range (0,1)) = 0.5
		[Toggle]_bMetalness("Use Metalness From Mask", Int) = 1
		_Metalness("	Metalness", Range (0,1)) = 1	
		_MetalF0("	Metal Color", Color) = (0.85,0.85,0.85,1)
		[NoScaleOffset]_Cube("ReflectionMap(CUBE)", Cube) = "" {}
		_CubeEV("	ReflectionMap EV", Float) = 0.0
		_CubeFilter("	ReflectionFilterColor", Color) = (1.0,1.0,1.0,1)
		[Toggle]_bDistanceBased(" Use Contact Hardening (Requires WorldSpaceMap)", Int) = 0
		_DistanceBias("	Contact Bias", Range (1,-1)) = 0
		_DistanceScale("	Contact Scale", Range(0.01,2)) = 1	
		[Toggle]_bReturnDistanceWS("	Visualize Surface Distance", Int) = 0
		[Toggle]_bParallaxCube("Use Parallax Correction", Int) = 1
		_CubeMin("	Reflection Bounds Minimum", vector) = (-20, 5.08, -3, 1.0)
		_CubeMax("	Reflection Bounds Maximum", vector) = (-10, 7.5, 3, 1.0)
		_CubePos("	Reflection Bounds Position", vector) = (-15, 6.5, 0.0, 0.0)
		[NoScaleOffset]_CubeWS("WorldSpaceMap(CUBE)", Cube) = ""
		_CubeScaleWS("WorldSpaceMap Scale(METERS)", vector) = (1,1,1,1)
		_CubeOffsetWS("WorldSpaceMap Offset(METERS)", vector) = (0,0,0,1)
		[NoScaleOffset]_DitherTex("DitherMap(SS)", 2D) = "gray" {}
		_DitherRes("Dither Resolution", Float) = 2
		//[NoScaleOffset]_TexWS("WorldSpaceTexture(UV2)", 2D) = "black" {}
		//[KeywordEnum(Yes, No)]_Awesome("Is this awesome?", Float) = 0
		//[Toggle]_Cool("ToggleTest", Int) = 0
		//_NoiseTex("Noise", 2D) = "black" {}
	}
	SubShader {
		Pass {   
			CGPROGRAM
 
			#pragma vertex vert  
			#pragma fragment frag 

			#include "UnityCG.cginc"

			// User-specified uniforms
			uniform sampler2D _MainTex;
			//uniform float4 _MainTex_ST;
			uniform fixed _LightEV;
			uniform uint _Samples;
			uniform uint _bUseDithering;
			uniform sampler2D _DitherTex;
			uniform fixed _DitherRes;
			//uniform sampler2D _DetailTex;
			//uniform float4 _DetailTex_ST;
			//uniform fixed _DetailUnpack;
			//uniform fixed _RowOffset;
			//uniform sampler2D _GlowTex;
			//uniform float4 _GlowTex_ST;
			//uniform fixed _GlowUnpack;
			uniform sampler2D _MaskTex;
			uniform sampler2D _AnisoTex;
			uniform float4 _AnisoTex_ST;
			uniform fixed _AnisoStrength;
			//uniform float4 _MaskTex_ST;
			//uniform sampler2D _NoiseTex;
			uniform samplerCUBE _Cube;
			uniform fixed _CubeEV;
			uniform fixed4 _CubeFilter;
			uniform uint _bParallaxCube;
			uniform samplerCUBE _CubeWS;
			uniform half4 _CubeScaleWS;
			uniform half4 _CubeOffsetWS;
			uniform uint _bDistanceBased;
			uniform fixed _DistanceBias;
			uniform fixed _DistanceScale;
			uniform uint _bReturnDistanceWS;
			uniform fixed _Roughness;
			uniform fixed _Metalness;
			uniform fixed4 _MetalF0;
			uniform float4 _CubeMin;
			uniform float4 _CubeMax;
			uniform float4 _CubePos;
			uniform uint _bRoughness;
			uniform uint _bMetalness;
			uniform uint _bReinhard;

			
			//base input struct
			struct vertexInput {
				float4 texcoord0 : TEXCOORD0;
				float4 texcoord1 : TEXCOORD1;
				//float4 texcoord2 : TEXCOORD2;
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 tangent : TANGENT;
				
			};
			
			//base output struct
			struct vertexOutput {
				float4 pos : SV_POSITION;
				float4 posWorld : TEXCOORD5;
				float4 uv0 : TEXCOORD0;
				float4 uv1 : TEXCOORD1;
				//float4 uv2 : TEXCOORD2;
				float4 uvSS : TEXCOORD3;
				float3 viewDir : TEXCOORD4;
				float3 tangentWorld : TEXCOORD6;
				float3 normalWorld : TEXCOORD7;
				float3 binormalWorld : TEXCOORD8;
			};
 
			vertexOutput vert(vertexInput i) 
			{
				vertexOutput o;
				
				float4x4 modelMatrix = _Object2World;
				float4x4 modelMatrixInverse = _World2Object;
				
				o.tangentWorld = normalize(mul(modelMatrix, float4(i.tangent.xyz, 0.0)).xyz);
				o.normalWorld = normalize(mul(float4(i.normal, 0.0), modelMatrixInverse).xyz);
				o.binormalWorld = normalize(cross(o.normalWorld, o.tangentWorld) * i.tangent.w);
				
				o.pos = mul(UNITY_MATRIX_MVP, i.vertex);
 				o.posWorld = mul(_Object2World, i.vertex);
				o.uv0 = i.texcoord0;
				o.uv1 = i.texcoord1;
				o.uvSS = o.pos;
 				
				o.viewDir = mul(_Object2World, i.vertex).xyz - _WorldSpaceCameraPos;
								
				return o;
			}
 
			half3 frag(vertexOutput i) : COLOR
			{
				//_AnisoStrength *= 2;
				float2 ScreenCoords = (i.uvSS.xy / i.uvSS.w) + 0;
				ScreenCoords = 0.5 * (ScreenCoords + 1.0);//repack ScreenCoords from -1 to 1 into 0 - 1  
				ScreenCoords *= _ScreenParams.xy / _DitherRes;//multiply the ScreenCoordinates by the number of tiles of dithering
				//return (tex2D(_DitherTex, ScreenCoords) + tex2D(_DitherTex, ScreenCoords + 0.25))/2;
				fixed ditherPattern1 = tex2D(_DitherTex, ScreenCoords).y;
				fixed ditherPattern2 = tex2D(_DitherTex, ScreenCoords + float2(0.5,0.0));
				fixed ditherPattern3 = tex2D(_DitherTex, ScreenCoords + float2(0.0,0.5));
				fixed ditherPattern4 = tex2D(_DitherTex, ScreenCoords + float2(0.5,0.5));
				//return (ditherPattern1 + ditherPattern2 + ditherPattern3 + ditherPattern3)/4;
				
				ditherPattern1 *= 0.8125;
				ditherPattern2 *= 0.8125;
				ditherPattern3 *= 0.8125;
				ditherPattern4 *= 0.8125;
				
				float4 anisoDirection = tex2D(_AnisoTex, i.uv0.xy * _AnisoTex_ST.xy + _AnisoTex_ST.z);
				
				float3 localCoords = float3((anisoDirection.ag - 0.5) * 2 * _AnisoStrength, 0.0);
				localCoords.z = 1.0 - 0.5 * dot(localCoords, localCoords);
				//return localCoords;
				

				
				float3x3 local2WorldTranspose = float3x3(i.tangentWorld, i.binormalWorld, i.normalWorld);
				float3 normalDirection = normalize(mul(localCoords, local2WorldTranspose));
				float3 normalDirectionReverse = normalize(mul(localCoords * float3(-1, -1, 1), local2WorldTranspose));
				//return normalDirection;
								
				half3 viewDirection = normalize(i.posWorld.xyz - _WorldSpaceCameraPos.xyz);
				float3 reverseViewDirection = -1 * viewDirection;
				float reflectionf0 = 0.9;
				float fresnel = reflectionf0 + ((1 - reflectionf0) * pow((1 - dot((reverseViewDirection), i.normalWorld)), 5));
				
				half3 CubeCoords1 = normalize(reflect(viewDirection, lerp(i.normalWorld, normalDirection, ditherPattern1)));
				half3 CubeCoords2 = normalize(reflect(viewDirection, lerp(i.normalWorld, normalDirection, ditherPattern2 + 0.125)));
				half3 CubeCoords3 = normalize(reflect(viewDirection, lerp(i.normalWorld, normalDirectionReverse, ditherPattern3 + 0.125)));
				half3 CubeCoords4 = normalize(reflect(viewDirection, lerp(i.normalWorld, normalDirectionReverse, ditherPattern4 + 0.250)));
				
				//return normalize(i.normalWorld);
				if(_bParallaxCube == 1){//IF using parallax correction...
					//...BEGIN AABB style parallax correction, based on Lagarde2012
					half3 BoxMax = (_CubeMax.xyz - i.posWorld.xyz);
					half3 BoxMin = (_CubeMin.xyz - i.posWorld.xyz);
					//Sample1
					half3 Maxified1 = max((BoxMax / CubeCoords1), (BoxMin / CubeCoords1));
					half Minified1 = min(min(Maxified1.x, Maxified1.y), Maxified1.z);
					CubeCoords1 =(((Minified1 * CubeCoords1) + i.posWorld.xyz) - _CubePos.xyz);
					//Sample2
					half3 Maxified2 = max((BoxMax / CubeCoords2), (BoxMin / CubeCoords2));
					half Minified2 = min(min(Maxified2.x, Maxified2.y), Maxified2.z);
					CubeCoords2 =(((Minified2 * CubeCoords2) + i.posWorld.xyz) - _CubePos.xyz);
					//Sample3
					half3 Maxified3 = max((BoxMax / CubeCoords3), (BoxMin / CubeCoords3));
					half Minified3 = min(min(Maxified3.x, Maxified3.y), Maxified3.z);
					CubeCoords3 =(((Minified3 * CubeCoords3) + i.posWorld.xyz) - _CubePos.xyz);
					//Sample4
					half3 Maxified4 = max((BoxMax / CubeCoords4), (BoxMin / CubeCoords4));
					half Minified4 = min(min(Maxified4.x, Maxified4.y), Maxified4.z);
					CubeCoords4 =(((Minified4 * CubeCoords4) + i.posWorld.xyz) - _CubePos.xyz);
					//END AABB
				}
				
				float3 CubeNormal1 = normalize(lerp(i.normalWorld, normalDirection, ditherPattern1));
				//float3 CubeSample1 = texCUBElod(_Cube, float4(reflect(viewDirection, CubeNormal1), _Roughness * 6));
				float3 CubeSample1 = texCUBElod(_Cube, float4(CubeCoords1, _Roughness * 6));
				//return CubeSample1;
				
				float3 CubeNormal2 = normalize(lerp(i.normalWorld, normalDirection, ditherPattern2 + 0.125));
				//float3 CubeSample2 = texCUBElod(_Cube, float4(reflect(viewDirection, CubeNormal2), _Roughness * 6));
				float3 CubeSample2 = texCUBElod(_Cube, float4(CubeCoords2, _Roughness * 6));
				//return (CubeSample2 + CubeSample1) / 2;
				
				float3 CubeNormal3 = normalize(lerp(i.normalWorld, normalDirectionReverse, ditherPattern3 + 0.125));
				//float3 CubeSample3 = texCUBElod(_Cube, float4(reflect(viewDirection, CubeNormal3), _Roughness * 6));
				float3 CubeSample3 = texCUBElod(_Cube, float4(CubeCoords3, _Roughness * 6));
				//return (CubeSample2 + CubeSample3) / 2;
				
				float3 CubeNormal4 = normalize(lerp(i.normalWorld, normalDirectionReverse, ditherPattern4 + 0.250));
				//float3 CubeSample4 = texCUBElod(_Cube, float4(reflect(viewDirection, CubeNormal4), _Roughness * 6));
				float3 CubeSample4 = texCUBElod(_Cube, float4(CubeCoords4, _Roughness * 6));
				//return (CubeSample3 + CubeSample4)/2;
				
				float3 reflection = (CubeSample1 + CubeSample2 + CubeSample3 + CubeSample4) / 4;
				return pow(reflection * fresnel, 0.4545);
			}
 
			ENDCG
			

			//Offset -.25,-50//hey, don't worry about this.

		}
	}
}