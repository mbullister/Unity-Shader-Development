Shader "Teague/Sky Box" {
	Properties {
		[Toggle]_bReinhard("    Use Reinhard Tone Mapping", Int) = 1
		[NoScaleOffset]_Cube("EnvironmentMap(CUBE)", Cube) = "" {}
		_CubeFilter("    EnvironmentFilterColor", Color) = (1,1,1,1)
		[Toggle]_bParallaxCube("Use Parallax Correction", Int) = 1
		_CubeMin("    Reflection Bounds Minimum(UNITY)", vector) = (-20, 5.08, -3, 1.0)
		_CubeMax("    Reflection Bounds Maximum(UNITY)", vector) = (-10, 7.5, 3, 1.0)
		_CubePos("    Reflection Bounds Position(UNITY)", vector) = (-15, 6.5, 0.0, 0.0)
	}
	SubShader {
		Pass {   
			CGPROGRAM
 
			#pragma vertex vert  
			#pragma fragment frag 

			#include "UnityCG.cginc"
			#include "FUNCTIONS/CommonFunctions.cginc"
			//#include "shared.cginc"
			uniform samplerCUBE _Cube;
			uniform fixed4 _CubeFilter;
			uniform uint _bParallaxCube;
			//uniform float4 _CubeMin;
			//uniform float4 _CubeMax;
			//uniform float4 _CubePos;
			uniform uint _bReinhard;

			
			//base input struct
			///*
			struct vertexInput {
				float4 texcoord0 : TEXCOORD0;
				float4 texcoord1 : TEXCOORD1;
				//float4 texcoord2 : TEXCOORD2;
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				
			};
			//*/
			///*
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
			//*/
			///*
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
			//*/
			float3 tubular(float3 i) : float3
			{
				return i * 0.5;
			}

			fixed3 frag(vertexOutput i) : COLOR
			{
				
				//half3 CubeCoords = normalize(reflect(i.viewDir, i.normalDir));
				half3 CubeCoords = i.viewDir;
				
				if(_bParallaxCube == 1){//IF using parallax correction...
					CubeCoords = ParallaxCube(i.viewDir, i.posWorld);
				}
				//return pow(texCUBElod(_Cube, float4(CubeCoords, _Roughness)) * pow(2, _CubeEV), 1/2.2);//used for debugging purposes.
								
				
				float4 BackgroundCubeRGBM = texCUBE(_Cube, CubeCoords);//Use reflection coordinates

				float3 BackgroundCube = RGBM(BackgroundCubeRGBM, 6);
				
				if(_bReinhard == 1){
					BackgroundCube = Reinhard(BackgroundCube);
				}

				else{
					BackgroundCube = pow(BackgroundCube, 0.454545);
				}

				return BackgroundCube;//return
			}
 
			ENDCG
			

			//Offset -.25,-50//hey, don't worry about this.

		}
	}
}