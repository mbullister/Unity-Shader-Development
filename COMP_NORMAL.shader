Shader "Teague/CompleteMap(UV2) NormalMap(UV1) GlowMap(UV1) MaskMap(UV1or2)" {
	Properties {
		[NoScaleOffset]_TotalLightingMap("TotalLightingMap", 2D) = "gray" {}
		[KeywordEnum(One, Two)]_TLMUV("TotalLightingMap UV", Int) = 1
		[Toggle]_bLightmapGamma("    Use Gamma Color", Int) = 0
		_RGBMRange("    RGBM Color Range", Int) = 5
		[Toggle]_bReinhard("    Use Reinhard Tone Mapping", Int) = 1
		//_AlbedoTex("AlbedoMap (UV1)", 2D) = "white" {}
		//_AlbedoGamma("    AlbedoMap Gamma", Float) = 2.2
		_GlowTex("GlowMap (UV1)", 2D) = "black" {}
		_GlowEV("    GlowMap EV", Float) = 0.0
		//_DetailTex("DetailMap (UV1)", 2D) = "gray"{}
		//_DetailUnpack("DetailMap Strength", Float) = 1.0
		[NoScaleOffset]_BumpTex("NormalMap (UV1)", 2D) = "bump" {}
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
		//_CubeEV("    ReflectionMap EV", Float) = 1.0
		_CubeFilter("    ReflectionFilterColor", Color) = (1,1,1,1)
		_R0("    Preintegrated IOR", Float) = 0.05325
		[Toggle]_bDistanceBased(" Use Contact Hardening (Requires WorldSpaceMap)", Int) = 0
		_DistanceExp("    Contact Exponent", Float) = 2.0
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
		Pass {   
			CGPROGRAM
 
			#pragma vertex vert  
			#pragma fragment frag 

			#include "UnityCG.cginc"
			#include "FUNCTIONS/CommonFunctions.cginc"

			// User-specified uniforms
			uniform sampler2D _TotalLightingMap;
			uniform uint _TLMUV;
			uniform uint _bLightmapGamma;
			//uniform float4 _MainTex_ST;
			uniform fixed _RGBMRange;
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
			uniform sampler2D _BumpTex;
			uniform sampler2D _MaskTex;
			uniform uint _MaskUV;
			//uniform float4 _MaskTex_ST;
			//uniform sampler2D _NoiseTex;
			uniform samplerCUBE _Cube;
			//uniform half _CubeEV;
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
				float3 tangentWorld : TEXCOORD2;
				float3 normalDir : TEXCOORD3;
				float3 binormalWorld : TEXCOORD6;
				float3 viewDir : TEXCOORD4;
			};
 
			vertexOutput vert(vertexInput i) 
			{
				vertexOutput o;
				
				float4x4 modelMatrix = _Object2World;
				float4x4 modelMatrixInverse = _World2Object;
				
				o.tangentWorld = normalize(mul(modelMatrix, float4(i.tangent.xyz, 0.0)).xyz);
				o.normalDir = normalize(mul(float4(i.normal, 0.0), modelMatrixInverse).xyz);
				o.binormalWorld = normalize(cross(o.normalDir, o.tangentWorld) * i.tangent.w);
				
 				o.pos = mul(UNITY_MATRIX_MVP, i.vertex);
 				o.posWorld = mul(_Object2World, i.vertex);
				o.uv0 = i.texcoord0;
				o.uv1 = i.texcoord1;
				//o.uv2 = i.texcoord2;
				//o.normalDir = normalize(mul( float4(i.normal, 0.0), _World2Object ).xyz);
				o.viewDir = mul(_Object2World, i.vertex).xyz - _WorldSpaceCameraPos;
								
				return o;
			}
 
			fixed3 frag(vertexOutput i) : COLOR
			{
				float4 encodedNormal = tex2D(_BumpTex, i.uv0);
				float3 localCoords = float3(2.0 * encodedNormal.a - 1.0, 2.0 * encodedNormal.g - 1.0, 0.0);
				localCoords.z = sqrt(1.0 - dot(localCoords, localCoords));

				float3x3 local2WorldTranspose = float3x3(i.tangentWorld, i.binormalWorld, i.normalDir);
				float3 normalDirection = normalize(mul(localCoords, local2WorldTranspose));

				half3 CubeCoords = normalize(reflect(i.viewDir, normalDirection));
				half3 viewDirection = normalize(i.posWorld.xyz - _WorldSpaceCameraPos.xyz) * (-1);
				//half3 normalDirection = i.normalDir;
				
				float4 totalLighting = tex2D(_TotalLightingMap, i.uv1);//Import TotalLightingMap, converting to Linear
				if(_TLMUV == 0){
					totalLighting = tex2D(_TotalLightingMap, i.uv0);
				};

				totalLighting = totalLighting * totalLighting.a * _RGBMRange;

				if (_bLightmapGamma == 1){
						totalLighting = Linear(totalLighting);
				};


				float4 detailTexture = tex2D(_DetailTex, i.uv0.xy * _DetailTex_ST.xy + _DetailTex_ST.z);
				
				fixed4 reflectionMask = tex2D(_MaskTex, i.uv1);//.xy * _MaskTex_ST.xy + _MaskTex_ST.z);
				if(_MaskUV == 0){
					reflectionMask = tex2D(_MaskTex, i.uv0);
				};

				//reflectionMask = Linear(reflectionMask);//Used if MASK gamma is 2.2 on import (should not be the case with good workflow)
				_Metalf0 *= saturate(reflectionMask.y + 0.5);//Bias reflection Filtering to avoid overdarkened metals

				float4 selfIllumination = tex2D(_GlowTex, i.uv1.xy * _GlowTex_ST.xy + _GlowTex_ST.z);
				selfIllumination = RGBM(selfIllumination, 5);
				
				
				if(_bMetalness == 1){//IF using METALNESS mask...
					_Metalness = reflectionMask.z;
				};

				totalLighting *= 1 - _Metalness;

				if(_bRoughness == 1){//IF using ROUGHNESS override...
					_Roughness = reflectionMask.x;
				};

				//_Roughness *= detailTexture.y;
				_Roughness = Overlay(_Roughness, detailTexture.y);
				//return _Roughness;

				half fresnel = Shlick(viewDirection, normalDirection);
				fresnel *= Linear(reflectionMask.y);

				//return fresnel;//used for debugging purposes.
				
				//_Roughness = _Roughness - (0.1 * fresnel);//Angle based roughness

				if (fresnel >= 0.90f){
					//return float3(0.5,0.5,0);
					fresnel = 0.90;
				};

				fresnel = lerp(fresnel, _Metalf0, _Metalness);
				
				totalLighting *= (1-fresnel);//Apply energy conservation (approx.)
				
				if(_bParallaxCube == 1){//IF using parallax correction...
					CubeCoords = ParallaxCube(CubeCoords, i.posWorld);
				}
				
				
				half3 reflectionWS = texCUBE(_CubeWS, CubeCoords);//sample our textureCUBE with WS coordinates stored...
				half3 positionWS = float3((i.posWorld.x + _CubeOffsetWS.x)/(-1 * _CubeScaleWS.x), ((i.posWorld.y) - _CubeOffsetWS.y)/(_CubeScaleWS.y),1 - ((i.posWorld.z) - _CubeOffsetWS.z)/(1 * _CubeScaleWS.z));//find the current pixel's WS coordinates
				half distanceWS = 0;
				
				//return _Roughness + saturate(1 - abs(i.posWorld.x - _CubePos.x) / 10);

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

				//_Roughness += (1 - abs(i.posWorld.x - _CubePos.x) / 10);

				//return 1 - _Roughness;//returns Glossiness, used for debugging
				float4 reflection = texCUBElod(_Cube, half4(CubeCoords, _Roughness * 10));//Use reflection coordinates, step up MIP level based on roughness

				//return reflection.a;

				reflection = RGBM(reflection,5);//decode RGBM to Linear HDR.
				
				//return Gamma(reflection).xyz;//used for debugging

				reflection *= fresnel;//Angle-dependency
				reflection *= _CubeFilter;//User-defined filtering

				totalLighting += reflection;
				totalLighting += selfIllumination;

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