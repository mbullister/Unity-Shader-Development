Shader "Teague/Glass" {
	Properties{
		[NoScaleOffset]_MainTex("CompleteMap (UV2)", 2D) = "gray" {}
		_LightGamma("	CompleteMap Gamma", Float) = 1.0
		[Toggle]_bReinhard("	Use Reinhard Tone Mapping", Int) = 0
		_GlassColor("Glass Color", Color) = (1.0,1.0,1.0,1)
		//_DetailTex("DetailMap (UV1)", 2D) = "gray"{}
		//_DetailUnpack("DetailMap Strength", Float) = 1.0
		//_GlowTex("GlowMap", 2D) = "black" {}
		//_GlowUnpack("GlowMap Strength", Float) = 1.0
		//_ScreenResX
		[NoScaleOffset]_MaskTex("MaskMap(UV2)", 2D) = "white" {}
		//_Samples("Anisotropic Samples", Int) = 4
		//[Toggle]_bUseDithering("Use Dithering", Int) = 1
		//	[NoScaleOffset]_DitherTex("DitherMap(SS)", 2D) = "bump" {}
		//_DitherRes("Dither Resolution", Float) = 2
		//_AnisoTex("Anisotropic Direction Map", 2D) = "black" {}
		//_FrostedStrength("FrostedStrength", Range(0,1)) = 0
		_DepthTex("ThicknessMap(UV2)", 2D) = "black" {}
		[Toggle]_bRoughness("Use Roughness From Mask", Int) = 1
		_Roughness("	Roughness", Range(0,1)) = 0.5
		[Toggle]_bMetalness("Use Metalness From Mask", Int) = 1
		_Metalness("	Metalness", Range(0,1)) = 1
		_MetalF0("	Metal Color", Color) = (0.85,0.85,0.85,1)
		[NoScaleOffset]_Cube("ReflectionMap(CUBE)", Cube) = "" {}
		_CubeFilter("	ReflectionFilterColor", Color) = (1.0,1.0,1.0,1)
		_R0("    Preintegrated IOR", Float) = 0.05325
		_RefractionScale("    Refraction Scale", Float) = 2.0
		[Toggle]_bDistanceBased(" Use Contact Hardening (Requires WorldSpaceMap)", Int) = 0
		_DistanceBias("	Contact Bias", Range(1,-1)) = 0
		_DistanceScale("	Contact Scale", Range(0.01,2)) = 1
		[Toggle]_bReturnDistanceWS("	Visualize Surface Distance", Int) = 0
		[Toggle]_bParallaxCube("Use Parallax Correction", Int) = 1
		_CubeMin("	Reflection Bounds Minimum", vector) = (-20, 5.08, -3, 1.0)
		_CubeMax("	Reflection Bounds Maximum", vector) = (-10, 7.5, 3, 1.0)
		_CubePos("	Reflection Bounds Position", vector) = (-15, 6.5, 0.0, 0.0)
		[NoScaleOffset]_CubeWS("WorldSpaceMap(CUBE)", Cube) = ""
		_CubeScaleWS("WorldSpaceMap Scale(METERS)", vector) = (1,1,1,1)
		_CubeOffsetWS("WorldSpaceMap Offset(METERS)", vector) = (0,0,0,1)
		//[NoScaleOffset]_TexWS("WorldSpaceTexture(UV2)", 2D) = "black" {}
		//[KeywordEnum(Yes, No)]_Awesome("Is this awesome?", Float) = 0
		//[Toggle]_Cool("ToggleTest", Int) = 0
		//_NoiseTex("Noise", 2D) = "black" {}
	}

		SubShader{
		Tags{ "Queue" = "Transparent" }
		GrabPass{ "_ScreenTex" }

		Pass{
		CGPROGRAM

#pragma vertex vert  
#pragma fragment frag 

#include "UnityCG.cginc"

		// User-specified uniforms
		uniform float4 _GlassColor;
	uniform sampler2D _ScreenTex;
	uniform sampler2D _MainTex;
	uniform fixed _LightGamma;
	//uniform uint _Samples;
	//uniform uint _bUseDithering;
	//uniform sampler2D _DitherTex;
	//uniform fixed _DitherRes;
	uniform sampler2D _MaskTex;
	uniform samplerCUBE _Cube;
	uniform fixed4 _CubeFilter;
	uniform float _R0;
	uniform fixed _RefractionScale;
	uniform fixed _FrostedStrength;
	uniform sampler2D _DepthTex;
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
		half Thickness = tex2D(_DepthTex, i.uv1).y;
	Thickness = (Thickness + 3) / 4;//thickness bias
	_GlassColor = pow(lerp(1.0, _GlassColor, Thickness),2.2);
	_GlassColor = pow(_GlassColor, Thickness + 1);
	//return pow(_GlassColor, 1 / 2.2);
	float3 rawTotalLighting = pow(tex2D(_MainTex, i.uv1), _LightGamma);//Import TotalLightingMap, converting to Gamma 1.0

																	   //return pow(rawTotalLighting, 1/2.2);

	fixed3 reflectionMask = tex2D(_MaskTex, i.uv1);

	float ScreenDepth = saturate(distance(_WorldSpaceCameraPos, i.posWorld) / 5);
	//return ScreenDepth;
	//return Thickness;
	//_FrostedStrength /= ScreenDepth + 0.01;
	float ScreenCoordStrength = (_FrostedStrength * 0.1 *  (1 / (ScreenDepth + 1))) * Thickness;

	//return _FrostedStrength * ((Thickness + 1) / 2) * ScreenDepth;

	float2 ScreenCoords = (i.uvSS.xy / i.uvSS.w) + (i.normalWorld * _R0 * _RefractionScale);
	ScreenCoords = 0.5 * (ScreenCoords + 1.0);//repack ScreenCoords from -1 to 1 into 0 - 1  
	ScreenCoords = float2(ScreenCoords.x, 1 - ScreenCoords.y);//right ScreenCoords Y axis
	/*
	float2 DitherCoords = (0.5 * ((i.uvSS.xy / i.uvSS.w) + 1)) * _ScreenParams.xy / _DitherRes;
	fixed2 ditherPattern = tex2D(_DitherTex, DitherCoords).xy;
	//return float3(ditherPattern2.xy, 0.0);
	//fixed2 ditherPattern2 = float2(tex2D(_DitherTex, DitherCoords).x, tex2D(_DitherTex, DitherCoords * float2(1,(-1))).y);
	//fixed2 ditherPattern3 = float2(tex2D(_DitherTex, DitherCoords).x, tex2D(_DitherTex, ScreenCoords).y);
	//fixed2 ditherPattern4 = ;

	ditherPattern = 2.0 * (ditherPattern - 0.5);
	

	float3 GrabbedPass1 = pow(tex2D(_ScreenTex, ScreenCoords + (ScreenCoordStrength * ditherPattern)), 2.2);
	//return pow(GrabbedPass1, 1 / 2.2);
	
	float3 GrabbedPass2 = pow(tex2D(_ScreenTex, ScreenCoords + ScreenCoordStrength * (ditherPattern * float2(1,-1))), 2.2);
	//return pow(GrabbedPass2, 1 / 2.2);
	float3 GrabbedPass3 = pow(tex2D(_ScreenTex, ScreenCoords + ScreenCoordStrength * (ditherPattern * float2(0.5, 1.41))), 2.2);
	//return pow(GrabbedPass3, 1 / 2.2);
	float3 GrabbedPass4 = pow(tex2D(_ScreenTex, ScreenCoords + ScreenCoordStrength * (ditherPattern * float2(1.41, 0.5))), 2.2);
	//return pow(GrabbedPass4, 1 / 2.2);
	*/
	float3 screenRefraction = pow(tex2D(_ScreenTex, ScreenCoords), 2.2);

	half3 CubeCoords = normalize(reflect(i.viewDir, i.normalWorld));
	half3 viewDirection = normalize(i.posWorld.xyz - _WorldSpaceCameraPos.xyz);
	half falloff = dot(viewDirection * (-1), i.normalWorld);
	half fresnel = (_R0 + (1 - _R0) * pow(1 - falloff, 4));//Fresnel term based on Shlick's approximation

														   //float3 CubeNormal1 = normalize(lerp(i.normalWorld, normalDirection, ditherPattern1 + 0.125));
	float4 reflectionCube = texCUBElod(_Cube, float4(CubeCoords, _Roughness * 6));
	float3 reflection = pow((reflectionCube.xyz * reflectionCube.a * 6),2.2);
	/*
	float4 refractionCube = texCUBElod(_Cube, float4(i.viewDir + (i.normalWorld * _R0 * _RefractionScale), 4 * _FrostedStrength));
	float3 refraction = pow((refractionCube.xyz * refractionCube.a * 6), 2.2);
	refraction *= _GlassColor;
	*/
	//return pow(refraction, 1/2.2); 

	//float3 screenRefraction = 0.25 * (GrabbedPass1 + GrabbedPass2 + GrabbedPass3 + GrabbedPass4);//average 4 dithered refraction samples
	screenRefraction *= _GlassColor;
	//screenRefraction *= pow(_GlassColor, Thickness + 1);
	//return pow(0.5, Thickness + 1);
	/*
	half refractionCubeStrength = 1;
	if (_bUseDithering == 1) {
		refractionCubeStrength = lerp(_FrostedStrength * ScreenDepth, 1, _FrostedStrength);
	}
	*/
	//return refractionCubeStrength;
	//totalLighting = lerp(refraction, totalLighting, saturate(_FrostedStrength - 0.125));
	//float3 totalLighting = lerp(screenRefraction, refraction, refractionCubeStrength);
	float3 totalLighting = screenRefraction;
	//totalLighting = lerp(totalLighting, totalLighting * rawTotalLighting, saturate(_FrostedStrength + 0.25));//Import TotalLightingMap, converting to Gamma 1.0
	totalLighting *= (1 - fresnel);
	reflection *= reflectionMask.y * fresnel;
	totalLighting += reflection;

	if (_bReinhard == 1) {
		return totalLighting = pow((totalLighting / (1 + totalLighting)), 0.454545);//..Apply a Reinhard tonemap, then convert to Gamma 2.2
	}
	//else
	return pow(totalLighting, 0.454545);
	}

		ENDCG


		//Offset -.25,-50//hey, don't worry about this.

	}
	}
}