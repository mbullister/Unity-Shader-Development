﻿Shader "Teague/Decal Blend(UV1)" {
	Properties {
		[NoScaleOffset]_MainTex("Decal Image (UV1)", 2D) = "gray" {}
		_BlendIntensity("    Decal Intensity", Range(0,1)) = 0.0
		//[Toggle]_bReinhard("    Use Reinhard Tone Mapping", Int) = 1
		//_AlbedoTex("AlbedoMap (UV1)", 2D) = "white" {}
		//_AlbedoGamma("    AlbedoMap Gamma", Float) = 2.2
		_GlowTex("GlowMap (UV1)", 2D) = "black" {}
		_GlowEV("    GlowMap EV", Float) = 0.0
		//_DetailTex("DetailMap (UV1)", 2D) = "gray"{}
		//_DetailUnpack("DetailMap Strength", Float) = 1.0
		[NoScaleOffset]_MaskTex("MaskMap", 2D) = "white" {}
		[KeywordEnum(One, Two)]_MaskUV("MaskMap UV", Int) = 1
		//[KeywordEnum(1,2)] _MaskUV("MaskMap UVs", Float) = 1
		[Toggle]_bRoughness("Use Roughness From Mask", Int) = 1
		//[Toggle]_bRoughnessAlpha("    Use Roughness From Albedo Alpha", Int) = 0 
		_Roughness("    Roughness", Range (0,1)) = 0.5
		[Toggle]_bMetalness("Use Metalness From Mask", Int) = 1
		_Metalness("    Metalness", Range (0,1)) = 1	
		_Metalf0("    Metal Color", Color) = (0.85,0.85,0.85,1)
		[NoScaleOffset]_Cube("ReflectionMap(CUBE)", Cube) = "" {}
		_CubeEV("    ReflectionMap EV", Float) = 1.0
		_CubeFilter("    ReflectionFilterColor", Color) = (1,1,1,1)
		_R0("    Preintegrated IOR", Float) = 0.05325
		[Toggle]_bDistanceBased(" Use Contact Hardening (Requires WorldSpaceMap)", Int) = 0
		_DistanceBias("    Contact Bias", Range (1,-1)) = 0
		//_DistanceScale("    Contact Scale", Range(0,10)) = 1
		[Toggle]_bReturnDistanceWS("    Visualize Surface Distance", Int) = 0
		[Toggle]_bParallaxCube("Use Parallax Correction", Int) = 1
		_CubeMin("    Reflection Bounds Minimum(UNITY)", vector) = (-20, 5.08, -3, 1.0)
		_CubeMax("    Reflection Bounds Maximum(UNITY)", vector) = (-10, 7.5, 3, 1.0)
		_CubePos("    Reflection Bounds Position(UNITY)", vector) = (-15, 6.5, 0.0, 0.0)
		[NoScaleOffset]_CubeWS("WorldSpaceMap(CUBE)", Cube) = ""
		_CubeScaleWS("    WorldSpaceMap Scale(METERS)", vector) = (1,1,1,1)
		_CubeOffsetWS("    WorldSpaceMap Offset(METERS)", vector) = (0,0,0,1)
		//[NoScaleOffset]_TexWS("WorldSpaceTexture(UV2)", 2D) = "black" {}
		//[Toggle]_Cool("ToggleTest", Int) = 0
		//_NoiseTex("Noise", 2D) = "black" {}
	}
	SubShader {
		Tags { "Queue" = "Transparent" }
		Pass {  
			Blend SrcAlpha OneMinusSrcAlpha 
			CGPROGRAM
 
			#pragma vertex vert  
			#pragma fragment frag 

			#include "UnityCG.cginc"

			// User-specified uniforms
			uniform sampler2D _MainTex;
			//uniform float4 _MainTex_ST;
			uniform float _BlendIntensity;
			//uniform sampler2D _AlbedoTex;
			//uniform float4 _AlbedoTex_ST;
			//uniform float _AlbedoGamma;
			//uniform uint _bSRGBAlbedo;
			//uniform sampler2D _DetailTex;
			//uniform float4 _DetailTex_ST;
			//uniform fixed _DetailUnpack;
			//uniform fixed _RowOffset;
			uniform sampler2D _GlowTex;
			uniform float4 _GlowTex_ST;
			uniform fixed _GlowEV;
			uniform sampler2D _MaskTex;
			uniform uint _MaskUV;
			//uniform float4 _MaskTex_ST;
			//uniform sampler2D _NoiseTex;
			uniform samplerCUBE _Cube;
			uniform half _CubeEV;
			uniform fixed4 _CubeFilter;
			uniform half _R0;
			uniform uint _bParallaxCube;
			uniform samplerCUBE _CubeWS;
			uniform half4 _CubeScaleWS;
			uniform half4 _CubeOffsetWS;
			uniform uint _bDistanceBased;
			uniform fixed _DistanceBias;
			//uniform fixed _DistanceScale;
			uniform uint _bReturnDistanceWS;
			uniform fixed _Roughness;
			uniform fixed _Metalness;
			uniform fixed4 _Metalf0;
			uniform float4 _CubeMin;
			uniform float4 _CubeMax;
			uniform float4 _CubePos;
			uniform uint _bRoughness;
			uniform uint _bMetalness;
			//uniform uint _bRoughnessAlpha;
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
 
			fixed4 frag(vertexOutput i) : COLOR
			{
				//float _RowOffset = mul(_Object2World, float4(0,0,0,1)).x;
				//float2 uvRandomize = float2(tex2D(_NoiseTex, i.uv2 + float2(0, _RowOffset)).xy);
				//half4 diffuseFilter = pow(tex2D(_AlbedoTex, i.uv0.xy * _AlbedoTex_ST.xy + _AlbedoTex_ST.z), _AlbedoGamma);//convert albedo to linear color
				//return pow(diffuseFilter, 1/2.2);
				
				//float3 rawTotalLighting = pow(tex2D(_MainTex, i.uv1), 2.2);
				//rawTotalLighting *= pow(2, _LightEV);//Apply exposure correction
				//return pow(rawTotalLighting, 1/2.2);
				//float4 overlayColor = tex2D(_DetailTex, ((i.uv0.xy * _DetailTex_ST.xy + _DetailTex_ST.z) + uvRandomize));//overlayColor using tiling/offset and randomized UVs on Channel 1
				float3 totalLighting = pow(tex2D(_MainTex, i.uv0), 2.2);
				float DecalAlpha = tex2D(_MainTex, i.uv0).a;
				DecalAlpha *= _BlendIntensity;
				//totalLighting *= pow(2, _LightEV);
				//return pow(totalLighting, 1/2.2);//used for debugging purposes.
				//return float4(totalLighting, DecalAlpha);
				
				fixed3 reflectionMask = tex2D(_MaskTex, i.uv1);//.xy * _MaskTex_ST.xy + _MaskTex_ST.z);
				if(_MaskUV == 0){
					reflectionMask = tex2D(_MaskTex, i.uv0);
				};
				reflectionMask = pow(reflectionMask, 2.2);
				
				half3 selfIllumination = tex2D(_GlowTex, i.uv0.xy * _GlowTex_ST.xy + _GlowTex_ST.z) * pow(2, _GlowEV);
				
				
				if(_bMetalness == 1){//IF using METALNESS mask...
					_Metalness = reflectionMask.z;
					_Metalf0.xyz = totalLighting;
				};
				
				if(_bRoughness == 1){//IF using ROUGHNESS override...
					_Roughness = reflectionMask.x;
				};
				/*
				if(_bRoughnessAlpha == 1){//IF using Roughness from Albedo Alpha...
					_Roughness = diffuseFilter.a;//set roughness from DiffuseFilter.Alpha
				};
				*/
				//return _Roughness;//used for debugging purposes.
				fixed3 reflectionR0 = _R0;//use METALNESS to determine if our f0 reflectivity is a dielectric constant (~1.6 IOR) or stored in the COMP map
				
				half3 CubeCoords = normalize(reflect(i.viewDir, i.normalDir));
				half3 viewDirection = normalize(i.posWorld.xyz - _WorldSpaceCameraPos.xyz);
				half fresnel = (reflectionR0 + (1 - reflectionR0) * pow(1 - dot(viewDirection * (-1), i.normalDir), 6));//Fresnel term based on Shlick's approximation
				//fresnel = pow(fresnel, 2.2);//convert fresnel to linear space
				fresnel *= (_CubeFilter.x + _CubeFilter.y + _CubeFilter.z)/3;
				fresnel *= reflectionMask.y;//apply large-scale occlusion from baked map
				//fresnel *= (1-_Roughness * 0.75);//apply small-scale occlusion from Roughness
				//return fresnel;//used for debugging purposes.
				
				totalLighting *= (1-fresnel) * (1-_Metalness);//Apply energy conservation (approx.)
				
				fresnel = lerp(fresnel, _Metalf0, _Metalness);
				
				if(_bParallaxCube == 1){//IF using parallax correction...
					//...BEGIN AABB style parallax correction, based on Lagarde2012
					half3 BoxMax = (_CubeMax.xyz - i.posWorld.xyz);
					half3 BoxMin = (_CubeMin.xyz - i.posWorld.xyz);
					half3 Maxified = max((BoxMax / CubeCoords), (BoxMin / CubeCoords));
					half Minified = min(min(Maxified.x, Maxified.y), Maxified.z);
					CubeCoords =(((Minified * CubeCoords) + i.posWorld.xyz) - _CubePos.xyz);
					//END AABB
				}
				//return pow(texCUBElod(_Cube, float4(CubeCoords, _Roughness)) * pow(2, _CubeEV), 1/2.2);//used for debugging purposes.
				
			
				
				half3 reflectionWS = texCUBE(_CubeWS, CubeCoords);//sample our textureCUBE with WS coordinates stored...
				reflectionWS = half3((reflectionWS.x * _CubeScaleWS.x) + _CubeOffsetWS.x, (reflectionWS.y * _CubeScaleWS.y) + _CubeOffsetWS.y, (reflectionWS.z * _CubeScaleWS.z) + _CubeOffsetWS.z);//transform to Unity's space
				half3 positionWS = i.posWorld.xyz;//find the current pixel's WS coordinates
				half distanceWS = 0;
				
				if(_bDistanceBased == 1){//IF Use Contact Hardening is enabled...
					distanceWS = distance(positionWS, reflectionWS) + 1;//find the distance in WS units between the current pixel and the pixel being reflected
					//distanceWS *= _DistanceScale;
					distanceWS = 1/pow(distanceWS, 2);//inverse square
					distanceWS += _DistanceBias;//inject a bias
					clamp(distanceWS,0,1);//maybe not needed?		
				};
				
				if(_bReturnDistanceWS == 1){//IF distance visualization is enabled...
					return distanceWS;//return distance for debugging purposes.
				};
				
				//return _Roughness;
				_Roughness = lerp(_Roughness, 0, distanceWS);
				//_Roughness *= (1 - pow(1 - dot(viewDirection * (-1), i.normalDir), 5));//reduce roughness near other surfaces(contact hardening), reduce roughness by angle(view dependent roughness)
				//return _Roughness;
				float3 reflection = pow(texCUBElod(_Cube, half4(CubeCoords,_Roughness * 6)), 2.2) * pow(2, _CubeEV);//Convert to Linear color.  Use reflection coordinates, step up MIP level based on roughness
				reflection *= fresnel;//Angle-dependency
				//return 1 - _Roughness;
				//return fresnel;
				//return pow(reflection, 1/2.2);
				reflection *= _CubeFilter;//User-defined filtering
				totalLighting += reflection;
				totalLighting += selfIllumination;
				//return pow(reflection, 1/2.2);
				if(_bReinhard == 1){
					totalLighting = pow((totalLighting/(1+totalLighting)), 0.454545);//..Apply a Reinhard tonemap, then convert to Gamma 2.2
				}
				else{
					totalLighting = pow(totalLighting, 0.454545);
				}
				//return fresnel;
				return float4(totalLighting, DecalAlpha);//return
			}
 
			ENDCG
			

			Offset -.25,-50

		}
	}
}