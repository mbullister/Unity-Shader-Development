Shader "Teague/CompleteMap(UV2) REFLECTION GEOMETRY" {
	Properties {
		[NoScaleOffset]_MainTex("CompleteMap (UV2)", 2D) = "gray" {}
		_LightEV("	CompleteMap Strength", Float) = 1.0
		[Toggle]_bReinhard("	Use Reinhard Tone Mapping", Int) = 0
		//_DetailTex("DetailMap (UV1)", 2D) = "gray"{}
		//_DetailUnpack("DetailMap Strength", Float) = 1.0
		//_GlowTex("GlowMap", 2D) = "black" {}
		//_GlowUnpack("GlowMap Strength", Float) = 1.0
		//[NoScaleOffset]_MaskTex("MaskMap(UV2)", 2D) = "white" {}
		//[Toggle]_bRoughness("Use Roughness From Mask", Int) = 1
		_Roughness("	Roughness", Range (0,1)) = 0.5
		//[Toggle]_bMetalness("Use Metalness From Mask", Int) = 1
		_Metalness("	Metalness", Range (0,1)) = 1	
		_MetalF0("	Metal Color", Color) = (0.85,0.85,0.85,1)
		_FloorWS("Floor Height(METERS)", Float) = 5.08
		[NoScaleOffset]_Cube("ReflectionMap(CUBE)", Cube) = "" {}
		_CubeEV("	ReflectionMap EV", Float) = 0.0
		_CubeFilter("	ReflectionFilterColor", Color) = (1.0,1.0,1.0,1)
		
		//[Toggle]_bDistanceBased(" Use Contact Hardening (Requires WorldSpaceMap)", Int) = 0
		//_DistanceBias("	Contact Bias", Range (1,-1)) = 0
		//_DistanceScale("	Contact Scale", Range(0.01,2)) = 1	
		//[Toggle]_bReturnDistanceWS("	Visualize Surface Distance", Int) = 0
		[Toggle]_bParallaxCube("Use Parallax Correction", Int) = 1
		_CubeMin("	Reflection Bounds Minimum", vector) = (-20, 5.08, -3, 1.0)
		_CubeMax("	Reflection Bounds Maximum", vector) = (-10, 7.5, 3, 1.0)
		_CubePos("	Reflection Bounds Position", vector) = (-15, 6.5, 0.0, 0.0)
		//[NoScaleOffset]_CubeWS("WorldSpaceMap(CUBE)", Cube) = ""
		//_CubeScaleWS("WorldSpaceMap Scale(METERS)", vector) = (1,1,1,1)
		//_CubeOffsetWS("WorldSpaceMap Offset(METERS)", vector) = (0,0,0,1)
		
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

			uniform sampler2D _MainTex;
			uniform fixed _LightEV;
			uniform uint _bReinhard;
			uniform fixed _Roughness;
			uniform fixed _Metalness;
			uniform half _FloorWS;
			uniform uint _bParallaxCube;
			uniform samplerCUBE _Cube;
			uniform half _CubeEV;
			uniform float4 _CubeFilter;
			uniform float4 _CubeMax;
			uniform float4 _CubeMin;
			uniform float4 _CubePos;

			
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
				_CubeMax.y = _FloorWS - distance(_CubeMin.y, _CubeMax.y);
				_CubePos.y = _FloorWS - distance(_CubeMin.y, _CubePos.y);
				half floorDistance = distance(i.posWorld.y, _FloorWS);
				half floorDistanceINSQ = 1/pow(floorDistance + 1, 2);
				floorDistance = pow(clamp(floorDistance/1.5, 0, 1),2);
				half3 CubeCoords = normalize(i.viewDir);
				half3 viewDirection = normalize(i.posWorld.xyz - _WorldSpaceCameraPos.xyz);
				_Roughness = lerp(_Roughness, 0, floorDistanceINSQ * 0.20) * (1 - pow(1 - dot(viewDirection * (-1), half3(0,1,0)), 5));
				half reflectionf0 = 0.052;
				half fresnel = (reflectionf0 + (1 - reflectionf0) * pow(1 - dot(viewDirection * (-1), half3(0,1,0)), 5));//Fresnel term based on Shlick's approximation
				fresnel *= (_CubeFilter.x + _CubeFilter.y + _CubeFilter.z)/3;
				fresnel *= (1-_Roughness * 0.75);
				//return fresnel;//used for debugging purposes.
				
				
				if(_bParallaxCube == 1){//IF using parallax correction...
					//...BEGIN AABB style parallax correction, based on Lagarde2012
					half3 BoxMax = (_CubeMax.xyz - i.posWorld.xyz);
					half3 BoxMin = (_CubeMin.xyz - i.posWorld.xyz);
					half3 Maxified = max((BoxMax / CubeCoords), (BoxMin / CubeCoords));
					half Minified = min(min(Maxified.x, Maxified.y), Maxified.z);
					CubeCoords =(((Minified * CubeCoords) + i.posWorld.xyz) - _CubePos.xyz);
					CubeCoords *= float3(1, -1, 1);
					//END AABB
				}
				
				half4 reflection = texCUBElod(_Cube, float4(CubeCoords, _Roughness * 8)) * pow(2, _CubeEV);
				reflection *= _CubeFilter;
				//fixed4 totalLighting = tex2D(_MainTex, i.uv1);
				float4 MipLookup = float4(i.uv1.xy, 0, _Roughness * 8);
				fixed4 totalLighting = tex2Dlod(_MainTex, MipLookup);//.xy * _MainTex_ST.xy + _MainTex_ST.z);//Convert COMP map to linear color
				totalLighting = lerp(totalLighting, reflection, floorDistance);
				totalLighting *= fresnel;
				
				if(_bReinhard == 1){
					totalLighting = pow((totalLighting/(1+totalLighting)), 0.454545);//..Apply a Reinhard tonemap, then convert to Gamma 2.2
				}
				else{
					totalLighting = pow(totalLighting, 0.454545);
				}
				return fixed4(totalLighting.xyz, floorDistance);//return
			}
 
			ENDCG
			

		}
	}
}