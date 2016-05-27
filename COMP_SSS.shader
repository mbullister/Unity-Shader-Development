Shader "Teague/CompleteMap(UV2) Transmittance(UV2) MaskMap(UV1or2)" {
	Properties{
		[NoScaleOffset]_CompTex("CompleteMap (UV2)", 2D) = "gray" {}
		_LightGamma("    CompleteMap Gamma", Float) = 1.0
		[Toggle]_bReinhard("    Use Reinhard Tone Mapping", Int) = 1
		[NoScaleOffset]_MaskTex("MaskMap", 2D) = "white" {}
		[KeywordEnum(One, Two)]_MaskUV("MaskMap UV", Int) = 1
		[NoScaleOffset]_DepthTex("ThicknessMap(UV2)", 2D) = "black" {}
		_Transmittance("    Scatter Color", Color) = (0.5, 0.5, 0.5, 1)
		_ThickBias("    Thickness Bias", Range(-1,1)) = 0
		_ThickScale("    Thickness Scale", Range(0, 3)) = 0.25
		[Toggle]_bRoughness("Use Roughness From Mask", Int) = 1
		_Roughness("    Roughness", Range (0,1)) = 0.5
		[Toggle]_bMetalness("Use Metalness From Mask", Int) = 1
		_Metalness("    Metalness", Range (0,1)) = 1	
		_Metalf0("    Metal Color", Color) = (0.85,0.85,0.85,1)
		[NoScaleOffset]_Cube("ReflectionMap(CUBE)", Cube) = "" {}
		_CubeFilter("    ReflectionFilterColor", Color) = (1,1,1,1)
		_R0("    Preintegrated IOR", Float) = 0.05325
		[Toggle]_bDistanceBased(" Use Contact Hardening (Requires WorldSpaceMap)", Int) = 0
		_DistanceExp("    Contact Exponent", Float) = 2.0
		_DistanceBias("    Contact Bias", Range (1,-1)) = 0
		[Toggle]_bReturnDistanceWS("    Visualize Surface Distance", Int) = 0
		[Toggle]_bParallaxCube("Use Parallax Correction", Int) = 1
		_CubeMin("    Reflection Bounds Minimum(UNITY)", vector) = (-20, 5.08, -3, 1.0)
		_CubeMax("    Reflection Bounds Maximum(UNITY)", vector) = (-10, 7.5, 3, 1.0)
		_CubePos("    Reflection Bounds Position(UNITY)", vector) = (-15, 6.5, 0.0, 0.0)
		[NoScaleOffset]_CubeWS("WorldSpaceMap(CUBE)", Cube) = ""
		_CubeScaleWS("    WorldSpaceMap Scale(METERS)", vector) = (1,1,1,1)
		_CubeOffsetWS("    WorldSpaceMap Offset(METERS)", vector) = (0,0,0,1)
	}
	SubShader {
		Pass {   
			CGPROGRAM
 
			#pragma vertex vert  
			#pragma fragment frag 

			#include "UnityCG.cginc"
			#include "FUNCTIONS/CommonFunctions.cginc"

			// User-specified uniforms
			uniform sampler2D _CompTex;
			uniform half _LightGamma;
			uniform sampler2D _GlowTex;
			uniform float4 _GlowTex_ST;
			uniform fixed _GlowEV;
			uniform sampler2D _MaskTex;
			uniform uint _MaskUV;
			uniform sampler2D _DepthTex;
			uniform fixed4 _Transmittance;
			uniform float _ThickBias;
			uniform float _ThickScale;
			//uniform float4 _MaskTex_ST;
			//uniform sampler2D _NoiseTex;
			uniform samplerCUBE _Cube;
			uniform half _CubeEV;
			uniform fixed4 _CubeFilter;
			//uniform half _R0;
			uniform uint _bParallaxCube;
			uniform samplerCUBE _CubeWS;
			uniform half4 _CubeScaleWS;
			uniform half4 _CubeOffsetWS;
			uniform uint _bDistanceBased;
			uniform fixed _DistanceExp;
			uniform fixed _DistanceBias;
			//uniform fixed _DistanceScale;
			uniform uint _bReturnDistanceWS;
			uniform fixed _Roughness;
			uniform fixed _Metalness;
			uniform fixed4 _Metalf0;
			//uniform float4 _CubeMin;
			//uniform float4 _CubeMax;
			//uniform float4 _CubePos;
			uniform uint _bRoughness;
			uniform uint _bMetalness;
			//uniform uint _bRoughnessAlpha;
			uniform uint _bReinhard;
			
			/*
			half FRESNEL(float R0, float3 view, float3 normal)
			{
				half fresnelTerm = (R0 + (1 - R0) * pow(1 - (dot(-1 * view, normal), 4)));
				return fresnelTerm;
			}
			*/

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
				
				half3 CubeCoords = normalize(reflect(i.viewDir, i.normalDir));
				half3 viewDirection = normalize(i.posWorld.xyz - _WorldSpaceCameraPos.xyz) * (-1);
				half3 normalDirection = i.normalDir;
				
				float4 totalLighting = pow(tex2D(_CompTex, i.uv1), _LightGamma);//Import TotalLightingMap, converting to Linear
				
				half Thickness = tex2D(_DepthTex, i.uv1).y;
				Thickness = Thickness / (pow(_ThickScale, 2) + 0.01);
				Thickness = saturate(Thickness + _ThickBias);
				//Thickness = 1 - saturate(Thickness);

				fixed4 reflectionMask = tex2D(_MaskTex, i.uv1);//.xy * _MaskTex_ST.xy + _MaskTex_ST.z);
				if(_MaskUV == 0){
					reflectionMask = tex2D(_MaskTex, i.uv0);
				};
				//reflectionMask = Linear(reflectionMask);//Used if MASK gamma is 2.2 on import (should not be the case with good workflow)
				
				_Metalf0 *= saturate(reflectionMask.y + 0.5);//Bias reflection Filtering to avoid overdarkened metals

				half3 selfIllumination = tex2D(_GlowTex, i.uv0.xy * _GlowTex_ST.xy + _GlowTex_ST.z) * _GlowEV;
				
				
				if(_bMetalness == 1){//IF using METALNESS mask...
					_Metalness = reflectionMask.z;
				};
				
				if(_bRoughness == 1){//IF using ROUGHNESS override...
					_Roughness = reflectionMask.x;
				};

				
				half fresnel = Shlick(viewDirection, normalDirection);
				fresnel *= reflectionMask.y;
				//return fresnel;//used for debugging purposes.
				
				_Roughness = _Roughness - (0.125 * fresnel);
				
				fresnel = lerp(fresnel, _Metalf0, _Metalness);
				
				totalLighting *= (1-fresnel);//Apply energy conservation (approx.)
				
				if(_bParallaxCube == 1){//IF using parallax correction...
					CubeCoords = ParallaxCube(CubeCoords, i.posWorld);
				}
				
				
				half3 reflectionWS = texCUBE(_CubeWS, CubeCoords);//sample our textureCUBE with WS coordinates stored...
				half3 positionWS = float3((i.posWorld.x + _CubeOffsetWS.x)/(-1 * _CubeScaleWS.x), ((i.posWorld.y) - _CubeOffsetWS.y)/(_CubeScaleWS.y),1 - ((i.posWorld.z) - _CubeOffsetWS.z)/(1 * _CubeScaleWS.z));//find the current pixel's WS coordinates
				half distanceWS = 0;
				
				
				positionWS *= _CubeScaleWS;
				reflectionWS *= _CubeScaleWS;
																				
				if(_bDistanceBased == 1){//IF Use Contact Hardening is enabled...
					//distanceWS = distance(positionWS, reflectionWS)/3 + 0;//find the distance in WS units between the current pixel and the pixel being reflected
					//distanceWS = 1 - distanceWS;
					//distanceWS *= _DistanceScale;
					distanceWS = distance(positionWS, reflectionWS) + 1;
					distanceWS = 1/pow(distanceWS, _DistanceExp);//inverse square(ish)
					distanceWS += _DistanceBias;//inject a bias
					distanceWS = saturate(distanceWS);//maybe not needed?		
				};
				
				if(_bReturnDistanceWS == 1){//IF distance visualization is enabled...
					//return reflectionWS;
					return distanceWS;//return distance for debugging purposes.
				};
				
				_Roughness = saturate(lerp(_Roughness, 0, distanceWS)+(0.25 * _Metalness * (1-reflectionMask.y)));//reduce roughness near other surfaces(contact hardening)
				//return 1 - _Roughness;
				float4 reflection = texCUBElod(_Cube, half4(CubeCoords, _Roughness * 8));//Use reflection coordinates, step up MIP level based on roughness
				reflection = RGBM(reflection,6);//decode RGBM to Linear HDR.
				//return Gamma(reflection).xyz;//used for debugging

				float4 transmittance = texCUBElod(_Cube, float4(i.viewDir, 4));
				transmittance = RGBM(transmittance, 6);
				transmittance *= reflectionMask.y;
				transmittance *= 1 - Thickness;
				transmittance *= _Transmittance;
				//return pow(transmittance, 1 / 2.2);
				
				reflection *= fresnel;//Angle-dependency
				reflection += transmittance;
				reflection *= _CubeFilter;//User-defined filtering
				totalLighting += reflection;
				//totalLighting += transmittance;
				//return pow(reflection, 1/2.2);//used for debugging

				if(_bReinhard == 1){
					return Reinhard(totalLighting.xyz).xyz;
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