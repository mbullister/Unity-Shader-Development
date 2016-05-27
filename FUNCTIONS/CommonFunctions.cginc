#ifndef COMMON_FUCNTIONS
#define COMMON_FUNCTIONS

uniform sampler2D _LightTex;
uniform uint _RGBMRange;
uniform sampler2D _GlowTex;
uniform float4 _GlowTex_ST;
uniform uint _GlowRGBM;
uniform sampler2D _MaskTex;
uniform float4 _MaskTex_ST;
uniform uint _MaskUV;
						
uniform float _EV;
uniform float4 _CubeMax;
uniform float4 _CubeMin;
uniform float4 _CubePos;
uniform float _R0;

uniform sampler2D _DetailTex;
uniform float4 _DetailTex_ST;
uniform float _DetailStrength;

uniform sampler2D _BumpTex;
uniform float4 _BumpTex_ST;
uniform sampler2D _BumpTexDetail;
uniform float4 _BumpTexDetail_ST;
uniform float _BumpTexDetailStrength;

uniform samplerCUBE _CubeWS;
uniform half4 _CubeScaleWS;
uniform half4 _CubeOffsetWS;
uniform uint _bDistanceBased;
uniform float _DistanceScale;
uniform uint _bReturnDistanceWS;

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
	//float3 viewDir : TEXCOORD4;
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
	//o.viewDir = normalize(o.posWorld.xyz - _WorldSpaceCameraPos);
					
	return o;
}

//uniform float3 tangentWorld vertexOutput.tangentWorld;

half4 Linear(float4 i) : half4//Gamma Decode Function
{
	i = pow(i, 2.2);
	return i;
}

fixed4 Gamma(float4 i) : fixed4//Gamma Encode Function
{
	i = pow(i, 0.454545);
return i;
}

float3 Tex2Normal(vertexOutput i) : float3//Normal Mapping Function
{
	half4 encodedNormal = tex2D(_BumpTex, i.uv0.xy * _BumpTex_ST.xy + _BumpTex_ST.z);
	half4 encodedNormalDetail = tex2D(_BumpTexDetail, i.uv0.xy * _BumpTexDetail_ST.xy + _BumpTexDetail_ST.z);
	float3 localCoords = float3(2.0f * encodedNormal.a - 1.0f, 2.0f * encodedNormal.g - 1.0f, 1.0);
	float2 localCoordsDetail = float2(2.0f * encodedNormalDetail.a - 1.0f, 2.0f * encodedNormalDetail.g - 1.0f);

	localCoords = float3(localCoords.xy + localCoordsDetail * _BumpTexDetailStrength, localCoords.z);
	localCoords.z = sqrt(1 - pow(localCoords.x, 2) - pow(localCoords.y, 2));
	localCoords = normalize(localCoords);

	//float3x3 local2WorldTranspose = float3x3(normalize(i.tangentWorld), normalize(i.binormalWorld),normalize(i.normalDir));
	float3x3 local2WorldTranspose = float3x3(i.tangentWorld, i.binormalWorld, i.normalDir);
	float3 normalDirection = normalize(mul(localCoords, local2WorldTranspose));

	return normalDirection;
}

float Overlay(float i, float i2) : float//Overlay Function
{
	float baseColor = i;
	float overlayColor = lerp(0.5, i2, _DetailStrength);
	float finalColor = 0.0;
	if (baseColor < 0.5) {
		finalColor = 2 * baseColor * overlayColor;
	}
	else {
		finalColor = 1 - 2 * (1 - baseColor) * (1 - overlayColor);
	}
	return finalColor;
}

float Shlick(float3 viewDir, float3 normalDir) : float//Fresnel Function
{
	float fresnel = abs(dot(viewDir, normalDir));
	//fresnel = saturate(fresnel);
	//fresnel = 0;
	fresnel = _R0 + ((1 - _R0) * pow(1 - fresnel, 5));
	//return 0;
	return fresnel;
}

float4 RGBM(float4 i, float scalar) : float4 //Gamma RGBM -> Linear HDR Function
{
	float4 texColor = i * i.a * scalar;
	texColor = Linear(texColor);
	return texColor;
}


float3 ParallaxCube(float3 CubeCoords, float4 posWorld) : float3 //AABB Box Correction Function
{
	half3 BoxMax = (_CubeMax.xyz - posWorld.xyz);
	half3 BoxMin = (_CubeMin.xyz - posWorld.xyz);
	half3 Maxified = max((BoxMax / CubeCoords), (BoxMin / CubeCoords));
	half Minified = min(min(Maxified.x, Maxified.y), Maxified.z);
	CubeCoords = (((Minified * CubeCoords) + posWorld.xyz) - _CubePos.xyz);
	return CubeCoords;
}

float DistanceWS(vertexOutput i, float3 CubeCoords, float DistanceScale) : float
{
	half distanceWS = 1;
	DistanceScale = max(DistanceScale, 0.00001);
	if(_bDistanceBased == 1){//IF Use Contact Hardening is enabled...
		half3 reflectionWS = texCUBE(_CubeWS, CubeCoords);//sample our textureCUBE with WS coordinates stored...
		half3 positionWS = float3((i.posWorld.x + _CubeOffsetWS.x)/(-1 * _CubeScaleWS.x), ((i.posWorld.y) - _CubeOffsetWS.y)/(_CubeScaleWS.y),1 - ((i.posWorld.z) - _CubeOffsetWS.z)/(1 * _CubeScaleWS.z));//find the current pixel's WS coordinates
		distanceWS = distance(positionWS, reflectionWS);//find the distance in WS units between the current pixel and the pixel being reflected
		distanceWS /= DistanceScale;
		distanceWS =1 - 1 / pow(distanceWS + 1, 2);//Inverse Squared falloff
	};
	return distanceWS;
}

float4 Reinhard(float4 i) : float4 //Reinhard Tonemap Function
{
	float3 texColor = i.xyz / (1 + i.xyz);//apply Reinhard tonemap to linear input
										  //texColor = Gamma(float4(texColor,1));//convert to gamma
	texColor = pow(texColor, 1 / 2.2);
	return float4(texColor, 1);//return
}


float3 Uncharted2Tonemap(float3 x)
{
	float _A = 0.15;
	float _B = 0.50;
	float _C = 0.10;
	float _D = 0.20;
	float _E = 0.02;
	float _F = 0.30;
	//float _W = 11.2;
	return ((x*(_A*x + _C*_B) + _D*_E) / (x*(_A*x + _B) + _D*_F)) - _E / _F;
}


float4 Filmic(float4 i) : float4 //Uncharted2 Tonemap Function
{
	float3 texColor = i.xyz;
	//texColor *= 16;

	float ExposureBias = 2.0f;
	float3 curr = Uncharted2Tonemap(texColor * ExposureBias);
	float3 whiteScale = 1.0f / Uncharted2Tonemap(11.2);
	float3 _color = curr*whiteScale;

	float3 retColor = pow(_color, 1 / 2.2);
	//return float4(0.5,0.5,1,0);
	return float4(retColor, 1);

}


#endif // COMMON_FUNCTIONS