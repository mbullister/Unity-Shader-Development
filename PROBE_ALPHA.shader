Shader "Teague/Probe Lighting with Alpha" {
	Properties{
		[NoScaleOffset]_LightProbe("Light Probe(CUBE)", cube) = "" {}
		_RGBM("    RGBM factor", Int) = 5
		[NoScaleOffset]_ShadingRamp("ShadingRamp (1D)", 2D) = "gray" {}
		_SubSurface("SubSurface Color", Color) = (0,0,0,0)
		[Toggle]_bReinhard("    Use Tone Mapping", Int) = 1
		_AlbedoTex("DiffuseMap (UV1)", 2D) = "gray" {}
		[KeywordEnum(One, Two)]_DiffUV("    DiffuseMap UV", Int) = 1
		_AlbedoGamma("    DiffuseMap Gamma", Float) = 2.2
		_FuzzColor("Peach Fuzz Color", Color) = (0.957, 0.894, 0.859, 1)
		_FuzzStrength("    Peach Fuzz Strength", Float) = 0.5
		//_DetailTex("DetailMap (UV1)", 2D) = "gray"{}
		//_DetailUnpack("DetailMap Strength", Float) = 1.0
		[NoScaleOffset]_BumpTex("NormalMap (UV1)", 2D) = "bump" {}
		_BumpDetail("SkinDetailNormal (UV1)", 2D) = "bump" {}
		_BumpDetailStrength("SkinDetailStrength", Float) = 1
		[NoScaleOffset]_MaskTex("MaskMap", 2D) = "white" {}
		[KeywordEnum(One, Two)]_MaskUV("    MaskMap UV", Int) = 1
		//[KeywordEnum(1,2)] _MaskUV("MaskMap UVs", Float) = 1
		[Toggle]_bRoughness("Use Roughness From Mask", Int) = 1
		[Toggle]_bRoughnessAlpha("    Use Roughness From Diffuse Alpha", Int) = 0
		_Roughness("    Roughness", Range(0,1)) = 0.5
		[Toggle]_bMetalness("Use Metalness From Mask", Int) = 1
		_Metalness("    Metalness", Range(0,1)) = 1
		_Metalf0("    Metal Color", Color) = (0.85,0.85,0.85,1)
		_DetailTex("DetailMap", 2D) = "gray" {}
		[NoScaleOffset]_Cube("ReflectionMap(CUBE)", Cube) = "" {}
		_CubeFilter("    ReflectionFilterColor", Color) = (1,1,1,1)
		_R0("    Preintegrated IOR", Float) = 0.05325
		_AnisoTex("AnisotropicDirectionMap(UV1)", 2D) = "bump" {}
		_AnisoStrength("Anisotropic Strength", Range (0,1)) = 0.5
		[Toggle]_bUseDithering("Use Dithering", Int) = 1
		[NoScaleOffset]_DitherTex("DitherMap(SS)", 2D) = "bump" {}
		_DitherRes("Dither Resolution", Float) = 2
		//[Toggle]_bDistanceBased(" Use Contact Hardening (Requires WorldSpaceMap)", Int) = 0
		//_DistanceExp("    Contact Exponent", Float) = 2.0
		//_DistanceBias("    Contact Bias", Range(1,-1)) = 0
		//_DistanceScale("    Contact Scale", Range(0,10)) = 1
		//[Toggle]_bReturnDistanceWS("    Visualize Surface Distance", Int) = 0
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
		SubShader{
			Tags {"Queue" = "AlphaTest" "RenderType" = "TransparentCutout" "IgnoreProjector" = "True"}
			Pass{
				Blend SrcAlpha OneMinusSrcAlpha
				AlphaToMask On

				CGPROGRAM

			#pragma vertex vert  
			#pragma fragment frag 

			#include "UnityCG.cginc"
			#include "FUNCTIONS/CommonFunctions.cginc"

			// User-specified uniforms
			uniform samplerCUBE _LightProbe;
			//uniform float4 _MainTex_ST;
			uniform uint _RGBM;
			uniform sampler2D _ShadingRamp;
			uniform fixed4 _SubSurface;
			uniform sampler2D _AlbedoTex;
			uniform float4 _AlbedoTex_ST;
			uniform float _AlbedoGamma;
			uniform uint _DiffUV;
			uniform float4 _FuzzColor;
			uniform fixed _FuzzStrength;
			//uniform uint _bSRGBAlbedo;
			//uniform sampler2D _DetailTex;
			//uniform float4 _DetailTex_ST;
			//uniform fixed _DetailUnpack;
			//uniform fixed _RowOffset;

			uniform sampler2D _AnisoTex;
			uniform float4 _AnisoTex_ST;
			uniform fixed _AnisoStrength;
			uniform sampler2D _DitherTex;
			uniform fixed _DitherRes;

			uniform sampler2D _BumpTex;
			uniform sampler2D _BumpDetail;
			uniform float4 _BumpDetail_ST;
			uniform fixed _BumpDetailStrength;
			uniform sampler2D _MaskTex;
			uniform uint _MaskUV;
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
			uniform uint _bRoughnessAlpha;
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
		float4 uvSS : TEXCOORD7;
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
		o.uvSS = o.pos;
		//o.uv2 = i.texcoord2;
		//o.normalDir = normalize(mul( float4(i.normal, 0.0), _World2Object ).xyz);
		o.viewDir = mul(_Object2World, i.vertex).xyz - _WorldSpaceCameraPos;

		return o;
	}

	fixed4 frag(vertexOutput i) : COLOR
	{
		//return i.pos;

		//BEGIN ANISOTROPIC FILTERING
		float2 ScreenCoords = (i.uvSS.xy / i.uvSS.w) + 0;
		ScreenCoords = 0.5 * (ScreenCoords + 1.0);//repack ScreenCoords from -1 to 1 into 0 - 1  
		ScreenCoords *= _ScreenParams.xy / _DitherRes;//multiply the ScreenCoordinates by the number of tiles of dithering

		float2 DitherCoords = (0.5 * ((i.uvSS.xy / i.uvSS.w) + 1)) * _ScreenParams.xy / _DitherRes;
		fixed ditherPattern = tex2D(_DitherTex, ScreenCoords).x;
		//ditherPattern = pow(ditherPattern, 2.2);
		ditherPattern = (ditherPattern - 0.5) * 2;
		ditherPattern *= _AnisoStrength;

		float4 anisoDirection = tex2D(_AnisoTex, i.uv0.xy * _AnisoTex_ST.xy + _AnisoTex_ST.z);
								
		half3 viewDirection = normalize(i.posWorld.xyz - _WorldSpaceCameraPos.xyz);
				

		float4 encodedNormal = tex2D(_AnisoTex, i.uv0.xy * _AnisoTex_ST.xy + _AnisoTex_ST.z);
		float3 localCoords1 = float3(2.0 * encodedNormal.a - 1.0, 2.0 * encodedNormal.g - 1.0, 0.0);
		float3 localCoords2 = localCoords1;
		float3 localCoords3 = localCoords1;
		float3 localCoords4 = localCoords1;
		localCoords1 *= ditherPattern;
		localCoords1.z = sqrt(1.0 - dot(localCoords1, localCoords1));
		//localCoords2 *= ditherPattern + 0.125;
		localCoords2 *= ditherPattern + 0.0625;
		localCoords2.z = sqrt(1.0 - dot(localCoords2, localCoords2));
		localCoords3 *= ditherPattern + 0.125;
		localCoords3.z = sqrt(1.0 - dot(localCoords3, localCoords3));
		localCoords4 *= ditherPattern + 0.1875;
		localCoords4.z = sqrt(1.0 - dot(localCoords4, localCoords4));

		float3x3 local2WorldTranspose = float3x3(i.tangentWorld, i.binormalWorld, i.normalDir);
		float3 normalDirection1 = normalize(mul(localCoords1, local2WorldTranspose));
		float3 normalDirection2 = normalize(mul(localCoords2, local2WorldTranspose));
		float3 normalDirection3 = normalize(mul(localCoords3, local2WorldTranspose));
		float3 normalDirection4 = normalize(mul(localCoords4, local2WorldTranspose));


		half3 CubeCoords1 = normalize(reflect(i.viewDir, normalDirection1));
		half3 CubeCoords2 = normalize(reflect(i.viewDir, normalDirection2));
		half3 CubeCoords3 = normalize(reflect(i.viewDir, normalDirection3));
		half3 CubeCoords4 = normalize(reflect(i.viewDir, normalDirection4));
		//half3 viewDirection = normalize(i.posWorld.xyz - _WorldSpaceCameraPos.xyz) * (-1);
		_SubSurface = Linear(_SubSurface);
		half3 ScatterCoords = normalize(i.viewDir);


		//half fresnel = Shlick(viewDirection, normalDirection);
		half fresnel = 1 - abs(dot(viewDirection, normalDirection1));

		fresnel = _R0 + (1 - _R0) * pow(fresnel, 3);

		//return float4(fresnel, fresnel, fresnel, 1);

		if (_bParallaxCube == 1) {//IF using parallax correction...
			CubeCoords1 = ParallaxCube(CubeCoords1, i.posWorld);
			CubeCoords2 = ParallaxCube(CubeCoords2, i.posWorld);
			CubeCoords3 = ParallaxCube(CubeCoords3, i.posWorld);
			CubeCoords4 = ParallaxCube(CubeCoords4, i.posWorld);
			ScatterCoords = ParallaxCube(i.viewDir, i.posWorld);
		}


		//half3 normalDirection = i.normalDir;

		half4 diffuseFilter = pow(tex2D(_AlbedoTex, i.uv1.xy * _AlbedoTex_ST.xy + _AlbedoTex_ST.z), _AlbedoGamma);//convert albedo to linear color
		
		float4 detailTexture = tex2D(_DetailTex, i.uv0.xy * _DetailTex_ST.xy + _DetailTex_ST.z);

		fixed4 reflectionMask = tex2D(_MaskTex, i.uv1);//.xy * _MaskTex_ST.xy + _MaskTex_ST.z);
		if (_MaskUV == 0) {
			reflectionMask = tex2D(_MaskTex, i.uv0);
		};
																												  //return pow(diffuseFilter, 1/2.2);
		if (_DiffUV == 0) {
			diffuseFilter = pow(tex2D(_AlbedoTex, i.uv0.xy * _AlbedoTex_ST.xy + _AlbedoTex_ST.z), _AlbedoGamma);
		};

		float Opacity = pow(diffuseFilter.a, 1/2.2);

		fresnel *= Opacity;

		//return float4(reflectionMask.y,reflectionMask.y,reflectionMask.y,saturate(Opacity * 2));

		float4 skinOcclusion = float4(float3(reflectionMask.y, reflectionMask.y, reflectionMask.y) + float3(_SubSurface.xyz * 0.25), 1);

		skinOcclusion = float4(saturate(skinOcclusion.r), saturate(skinOcclusion.g), saturate(skinOcclusion.b), skinOcclusion.a);

		//return skinOcclusion;//used for debugging

		float4 rawTotalLightingTex = texCUBE(_LightProbe, normalDirection1);
		float4 rawTotalLightingBlur = texCUBE(_LightProbe, i.normalDir);

		rawTotalLightingTex = lerp(rawTotalLightingTex, rawTotalLightingBlur, 0.45);
		
		//return rawTotalLightingTexR;

		//rawTotalLightingTex = float4(rawTotalLightingTexR, rawTotalLightingTex.gba);
		float4 rawTotalLighting;

		if(_RGBM >= 0){
			rawTotalLighting = RGBM(rawTotalLightingTex, _RGBM);//RGBM decode
		}
		else {
			rawTotalLighting = Linear(rawTotalLightingTex);
		}
		//return Gamma(rawTotalLighting * 0.25);
		
		rawTotalLighting = float4(tex2D(_ShadingRamp, float2(rawTotalLightingTex.x + (_SubSurface.x * 0.25), 0.5)).x, tex2D(_ShadingRamp, float2(rawTotalLightingTex.y + (_SubSurface.y * 0.25), 0.5)).y, tex2D(_ShadingRamp, float2(rawTotalLightingTex.z + (_SubSurface.z * 0.25), 0.5)).z, 1) + float4(saturate(rawTotalLighting.x - 1), saturate(rawTotalLighting.y - 1), saturate(rawTotalLighting.z - 1), 0);
		

		//return rampedShading;

		rawTotalLighting *= skinOcclusion;

		rawTotalLighting = Linear(rawTotalLighting);

		//rawTotalLighting *= float4(saturate(normalDirection.y + 1 +(0.3 * reflectionMask.y)), saturate(normalDirection.y + 1.05), saturate(normalDirection.y + 1), 1);

		float4 rimLighting = fresnel * _FuzzColor * _FuzzStrength;

		rimLighting *= reflectionMask.y;
		rimLighting *= rawTotalLightingTex;
		rimLighting *= (normalDirection1.y + 3) / 4;

		//return float4(rimLighting.xyz, Opacity);

		float4 backScatter = texCUBElod(_Cube, float4(ScatterCoords, (reflectionMask.z * 6) + 2));
		//float4 backScatter = texCUBE(_LightProbe, ScatterCoords);
		
		if (_RGBM >= 0) {
			backScatter = RGBM(backScatter, _RGBM);//RGBM decode
		}
		else {
			backScatter = Linear(backScatter);
		}
		backScatter *= (1 - Linear(reflectionMask.z)) + fresnel;//pow(1 - dot(i.normalDir, -1 * viewDirection), 3);
		backScatter *= _SubSurface; 

		//return Gamma(backScatter);

		//rawTotalLighting += rimLighting;

																   //return Gamma(rawTotalLighting);

		float4 totalLighting = diffuseFilter * rawTotalLighting;
		//return pow(totalLighting, 1/2.2);//used for debugging purposes.

		//reflectionMask = Linear(reflectionMask);//Used if MASK gamma is 2.2 on import (should not be the case with good workflow)

		_Metalf0 *= saturate(reflectionMask.y + 0.5);//Bias reflection Filtering to avoid overdarkened metals

		if (_bMetalness == 1) {//IF using METALNESS mask...
			_Metalness = reflectionMask.z;
		};

		totalLighting *= 1 - _Metalness;

		if (_bRoughness == 1) {//IF using ROUGHNESS override...
			_Roughness = reflectionMask.x;
		};

		//_Roughness *= detailTexture.y;
		_Roughness = Overlay(_Roughness, detailTexture.y);
		//return _Roughness;

		fresnel *= reflectionMask.y;
		//return float4(fresnel, fresnel, fresnel, Opacity);//used for debugging purposes.
		//return reflectionMask.y;
		
		_Roughness = _Roughness - (0.2 * fresnel);//Angle based roughness

		fresnel = lerp(fresnel, _Metalf0, _Metalness);

		//totalLighting *= (1 - fresnel);//Apply energy conservation (approx.)

		rimLighting *= reflectionMask.y;


		totalLighting += rimLighting;
		totalLighting += backScatter;

		//return _Roughness + saturate(1 - abs(i.posWorld.x - _CubePos.x) / 10);


		//_Roughness = saturate(0.25 * _Metalness * (1 - reflectionMask.y));//reduce roughness near other surfaces(contact hardening)

		//_Roughness += (1 - abs(i.posWorld.x - _CubePos.x) / 10);

		//return 1 - _Roughness;//returns Glossiness, used for debugging
		float4 reflection1 = texCUBElod(_Cube, half4(CubeCoords1, _Roughness * 8));//Use reflection coordinates, step up MIP level based on roughness
		float4 reflection2 = texCUBElod(_Cube, half4(CubeCoords2, _Roughness * 8));
		float4 reflection3 = texCUBElod(_Cube, half4(CubeCoords3, _Roughness * 8));
		float4 reflection4 = texCUBElod(_Cube, half4(CubeCoords4, _Roughness * 8));

		//return reflection2;

		//float4 reflection = (reflection1 + reflection2) /  2;
		float4 reflection = (reflection1 + reflection2 + reflection3 + reflection4) / 4;
		reflection = RGBM(reflection,5);//decode RGBM to Linear HDR.

		//return Gamma(reflection);

		reflection *= fresnel;//Angle-dependency
		reflection *= reflectionMask.y;
		//reflection *= D;

		//return reflectionMask;

		reflection *= _CubeFilter;//User-defined filtering

		//return float4(Gamma(reflection).xyz, Opacity);//used for debugging
		//return Gamma(rawTotalLighting * 0.25) + Gamma(reflection);//used for debugging
		//return Filmic(totalLighting);

		totalLighting += reflection;

		//Opacity = saturate(Opacity * 2);
		//return float4(Opacity, Opacity, Opacity, 1);

		if (_bReinhard == 1) {
			//return float4(rawTotalLighting.xyz * 0.25, 1);
			return float4(Filmic(totalLighting).xyz, Opacity);
			//return float4(Filmic(diffuseFilter * rawTotalLighting).xyz, Opacity);
		}
		else {
			//return float4(Gamma(totalLighting).xyz, diffuseFilterGamma.a);
			return float4(Gamma(totalLighting).xyz, Opacity);
		}
		return fixed4(1,0.5,0.5, 1);//return error color
	}

		ENDCG

		Cull Off
		//Offset -.25,-50//hey, don't worry about this.

	}
	}
}