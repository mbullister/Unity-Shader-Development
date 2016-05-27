Shader "Teague/LightMap(UV2) AlbedoMap(UV1) NormalMap(UV1) GlowMap(UV1) MaskMap(UV1or2)" {
	Properties {
		[KeywordEnum(Filmic, Reinhard, None)]_bToneMap("Tone Mapping Style", Int) = 0
		_EV("    ExposureValue", Float) = 1
		[NoScaleOffset]_LightTex("RawTotalLightingMap (UV2)", 2D) = "gray" {}
		_RGBMRange("    RGBM Encoding(0 to Disable)", Int) = 5

		_AlbedoTex("DiffuseMap (UV1)", 2D) = "white" {}//Used with RawTotalLight Mapping
		_AlbedoGamma("    DiffuseMap Gamma", Float) = 2.2//Used with RawTotalLight Mapping

		_GlowTex("SelfIlluminationMap (UV1)", 2D) = "black" {}
		_GlowRGBM("    RGBM Encoding(0 to Disable)", Int) = 5
		//_DetailTex("DetailMap (UV1)", 2D) = "gray"{}
		//_DetailUnpack("DetailMap Strength", Float) = 1.0

		[Normal]_BumpTex("NormalMap (UV1)", 2D) = "bump" {}//Used with Normal Mapping
		[Normal]_BumpTexDetail("DetailNormal (UV1)", 2D) = "bump" {}//Used with Normal Mapping
		_BumpTexDetailStrength("DetailNormalStrength", Float) = 1//Used with Normal Mapping

		_MaskTex("MaskMap", 2D) = "white" {}
		[KeywordEnum(One, Two)]_MaskUV("MaskMap UV", Int) = 1
		//[NoScaleOffset]_OcclusionMap("Atlased Occlusion(UV2)", 2D) = "white" {}
		_Roughness("Roughness", Range (0,1)) = 0.5
		[Toggle]_bRoughness("    Use Roughness From Mask", Int) = 1
		[Toggle]_bRoughnessAlpha("    Use Roughness From Diffuse Alpha", Int) = 0 
		_Metalness("Metalness", Range (0,1)) = 1	
		[Toggle]_bMetalness("    Use Metalness From Mask", Int) = 1
		_MetalR0("    Metal Color", Color) = (0.85,0.85,0.85,1)
		[NoScaleOffset]_Cube("ReflectionMap(CUBE)", Cube) = "" {}
		_RGBMCube("    RGBM Encoding(0 to Disable)", Int) = 5
		_CubeFilter("    ReflectionFilterColor", Color) = (1,1,1,1)
		_R0("    Preintegrated IOR", Float) = 0.05325
		[Toggle]_bDistanceBased(" Use Contact Hardening (Requires WorldSpaceMap)", Int) = 0
		_DistanceScale("    Contact Scale", Float) = 0.5
		[Toggle]_bReturnDistanceWS("    Visualize Surface Distance", Int) = 0
		[Toggle]_bParallaxCube("Use Parallax Correction", Int) = 0
		_CubeMin("    Reflection Bounds Minimum(UNITY)", vector) = (-35, 5.08, -3, 1.0)
		_CubeMax("    Reflection Bounds Maximum(UNITY)", vector) = (-10, 7.5, 3, 1.0)
		_CubePos("    Reflection Bounds Position(UNITY)", vector) = (-22.0, 6.5, 0.0, 0.0)
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
			uniform sampler2D _AlbedoTex;//Used with RawTotalLight Mapping
			uniform float4 _AlbedoTex_ST;//Used with RawTotalLight Mapping
			uniform float _AlbedoGamma;//Used with RawTotalLight Mapping
			//uniform sampler2D _OcclusionMap;
			uniform samplerCUBE _Cube;
			uniform float _RGBMCube;
			uniform fixed4 _CubeFilter;
			uniform uint _bParallaxCube;
			uniform fixed _Roughness;
			uniform fixed _Metalness;
			uniform fixed4 _MetalR0;
			uniform uint _bRoughness;
			uniform uint _bRoughnessAlpha;
			uniform uint _bMetalness;
			uniform uint _bToneMap;

			fixed3 frag(vertexOutput i) : COLOR
			{
				//return boop;

				_EV -= 7;
				float3 viewDirection = normalize(i.posWorld.xyz - _WorldSpaceCameraPos.xyz);
				float3 normalDirection = Tex2Normal(i);//Used with Normal Mapping
				float normalDeviation = saturate(dot(normalDirection, i.normalDir));//Used with Normal Mapping
				//float3 normalDirection = normalize(i.normalDir);//Used without Normal Mapping
				//return float3((normalDirection.xyz * 0.5) + float3(0.5, 0.5, 0.5));//used for Debugging

				float3 CubeCoords = reflect(viewDirection, normalDirection);
				if(_bParallaxCube == 1){//IF using parallax correction...
					CubeCoords = ParallaxCube(CubeCoords, i.posWorld);
				}

				half4 diffuseFilter = pow(tex2D(_AlbedoTex, i.uv0.xy * _AlbedoTex_ST.xy + _AlbedoTex_ST.z), _AlbedoGamma);//convert albedo to linear color

				fixed3 reflectionMask = tex2D(_MaskTex, i.uv1.xy * _MaskTex_ST.xy + _MaskTex_ST.z);
				if(_MaskUV == 0){
					reflectionMask = tex2D(_MaskTex, i.uv0.xy * _MaskTex_ST.xy + _MaskTex_ST.z);
				};
				//reflectionMask.y *= tex2D(_OcclusionMap, i.uv1).y;
				if(_bMetalness == 1){//IF using METALNESS mask...
					_Metalness = reflectionMask.z;
				};
				if(_bRoughness == 1){//IF using ROUGHNESS override...
					_Roughness = reflectionMask.x;
				};
				if(_bRoughnessAlpha == 1){
					_Roughness = pow(diffuseFilter.a, 0.454545);
				};

				half4 selfIllumination = tex2D(_GlowTex, i.uv0.xy * _GlowTex_ST.xy + _GlowTex_ST.z);
				if(_GlowRGBM > 0){
					selfIllumination = RGBM(selfIllumination, _RGBMRange);
				}
				else{
					selfIllumination = Linear(selfIllumination);
				}

				float fresnel = Shlick(-1 * viewDirection, normalDirection);
				fresnel *= reflectionMask.y;//large-scale occlusion from baked map
				float4 fresnelColor = float4(fresnel, fresnel, fresnel, 1);
				_MetalR0 = Linear(_MetalR0) * (reflectionMask.y / 2 + 0.5);
				//fresnel *= (_CubeFilter.x + _CubeFilter.y + _CubeFilter.z)/3;//Gray-scale Filter
				fresnelColor = lerp(fresnelColor, _MetalR0, _Metalness);
				fresnelColor *= Linear(_CubeFilter);

				float4 rawTotalLighting = tex2D(_LightTex, i.uv1);
				//float4 CubeLighting = texCUBElod(_Cube, float4(normalDirection, 5)) * reflectionMask.y;//Used with Normal Mapping
				//rawTotalLighting = lerp(CubeLighting, rawTotalLighting, normalDeviation);//Used with Normal Mapping
				if(_RGBMRange > 0){
					rawTotalLighting = RGBM(rawTotalLighting, _RGBMRange);
				}
				else{
					rawTotalLighting = Linear(rawTotalLighting);
				}

				float4 totalLighting = diffuseFilter * rawTotalLighting;//Used with RawTotalLight Mapping
				//float4 totalLighting = rawTotalLighting;//Used with TotalLight Mapping
				totalLighting *= (1-fresnelColor);//Apply energy conservation (approx.)
				totalLighting *= (1-_Metalness);
				totalLighting += selfIllumination;

				float distanceWS = DistanceWS(i, CubeCoords, _DistanceScale);
				if(_bReturnDistanceWS == 1){
					return distanceWS;
				};
				_Roughness *= 1 - 0.33 * fresnel;//reduce roughness by angle(view dependent roughness)
				_Roughness += 0.75 * (1 - reflectionMask.y);
				_Roughness = lerp(0, _Roughness, distanceWS);//reduce roughness near other surfaces(contact hardening)

				float4 reflection = texCUBElod(_Cube, half4(CubeCoords,_Roughness * 8));//Use reflection coordinates, step up MIP level based on roughness
				if(_RGBMCube > 0){
					reflection = RGBM(reflection, _RGBMCube);
				}
				else{
					reflection = Linear(reflection);
				}
				reflection *= fresnelColor * _CubeFilter;//Angle-dependency & User-Defined Filtering

				totalLighting += reflection;
				totalLighting *= pow(2, _EV);
				if(_bToneMap == 0){
					return Filmic(totalLighting);
				}
				else if(_bToneMap == 1){
					return Reinhard(totalLighting);
				}
				else{
					return Gamma(totalLighting);
				}
				return float4(0.0, 1.0, 1.0, 1.0);//return Error Color
			}
			ENDCG
		}
	}
}