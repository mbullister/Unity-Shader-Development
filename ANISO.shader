Shader "Teague/Anisotropic Brute-Force"{
	Properties{
		//_Roughness("Roughness", Range(0,1)) = 0
		_MaskTex("MaskMap", 2D) = "white"
		_Cube("Reflection Cube", Cube) = "" {}
		_AnisoTex("AnisotropicDirectionMap", 2D) = "bump" {}
		_AnisoStrength("AnisotropicStrength", Range(0,1)) = 0
		//_AnisoX("AnisotropicComponentX", Range(0,1)) = 0
		//_AnisoY("AnisotropicComponentY", Range(0,1)) = 0
		_Samples("AnisotropicSampleCount(/2)", Int) = 16
	}
	SubShader {
		Pass {
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#pragma target 4.0
			
			//uniform float _Roughness;
			uniform sampler2D _MaskTex;
			uniform samplerCUBE _Cube;
			uniform float _AnisoX;
			uniform float _AnisoY;
			uniform int _Samples;
			uniform sampler2D _AnisoTex;
			uniform float4 _AnisoTex_ST;
			uniform float _AnisoStrength;
			//uniform samplerCUBE _Contrast;
			
			struct vertexInput {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 tangent : TANGENT;
				float4 texcoord0 : TEXCOORD0;
				float4 texcoord1 : TEXCOORD1;
			};
			
			struct vertexOutput {
				float4 uv0 : TEXCOORD0;
				float4 uv1 : TEXCOORD1;
				float4 uvSS : TEXCOORD8;
				float4 pos : SV_POSITION;
				float4 posWorld : TEXCOORD2;
				float3 normalDir : TEXCOORD3;
				float3 viewDir : TEXCOORD4;
				float3 normalWorld : TEXCOORD5;
				float3 tangentWorld : TEXCOORD6;
				float3 binormalWorld : TEXCOORD7;
			};
			
			vertexOutput vert(vertexInput i){
				vertexOutput o;
				o.uv0 = i.texcoord0;
				o.uv1 = i.texcoord1;
				o.pos = mul(UNITY_MATRIX_MVP, i.vertex);
				o.uvSS = o.pos;
				o.posWorld = mul(_Object2World, i.vertex);
				o.normalDir = normalize(mul(float4(i.normal, 0.0), _World2Object ).xyz);
				o.viewDir = mul(_Object2World, i.vertex).xyz - _WorldSpaceCameraPos;
				o.normalWorld = normalize(mul(float4(i.normal.xyz, 0.0), _World2Object).xyz);
				o.tangentWorld = normalize(float3(mul(_Object2World, float4(float3(i.tangent.xyz),0.0)).xyz));
				o.binormalWorld = normalize(cross(o.normalWorld, o.tangentWorld).xyz * i.tangent.w);
				return o;
				
			};
			
			float4 frag (vertexOutput i) : COLOR{
				
				float3 reflectionMask = tex2D(_MaskTex, i.uv1);
				//return ReflectionMask;
				half3 reflectVector = normalize(reflect(i.viewDir, i.normalDir));
				//half2 anisoOffset = half2(_AnisoX, _AnisoY);
				half2 anisoOffset = tex2D(_AnisoTex, (i.uv0).xy * _AnisoTex_ST.xy + _AnisoTex_ST.z).ag;
				
				//return tex2D(_AnisoTex, (i.uv0).xy * _AnisoTex_ST.xy + _AnisoTex_ST.z);
				
				float3 localCoords = float3((anisoOffset - 0.5) * 2, 0.0);
				localCoords.z = 1.0 - 0.5 * dot(localCoords, localCoords); 
				//return localCoords;
				float3x3 local2WorldTranspose = float3x3(i.tangentWorld, i.binormalWorld, i.normalWorld);
				
				

				
				half3 normalDirection = normalize(mul(localCoords, local2WorldTranspose));
				half3 viewDirection = normalize(i.posWorld.xyz - _WorldSpaceCameraPos.xyz);
				//return texCUBE(_Cube, reflect(normalDirection, viewDirection));
				float3 reverseViewDirection = -1 * viewDirection;
				float reflectionf0 = 0.9;
				float fresnel = reflectionf0 + ((1 - reflectionf0) * pow((1 - dot((reverseViewDirection), i.normalDir)), 5));
				
				reflectVector = reflect(viewDirection, normalDirection);
				//fixed ContrastMap = texCUBE(_Contrast, reflect(i.viewDir, i.normalDir)).x;
				//return ContrastMap;
				uint sampleCount = _Samples;// * ContrastMap;
				//return (half)sampleCount/16;

				half4 reflectionColor = half4(0,0,0,1);

				if(frac((float)sampleCount/2) == 0.5){//IF using an ODD number of samples...
					reflectionColor = texCUBE(_Cube, reflect(viewDirection, i.normalDir));//Start with one sample in the middle
					//return reflectionColor;
				};
				//return frac((float)sampleCount / 2);
				//reflectionColor = half4(0,0,0,1);
				
				//return (dot(i.viewDir, i.tangentWorld));
				
				//reflectionColor = texCUBE(_Cube, (reflect(viewDirection, (normalize(mul(localCoords, local2WorldTranspose))))));
				
				//localCoords = float3(anisoOffset * 0.5, 0.0);
				//localCoords.z = 1.0 - 0.5 * dot(localCoords, localCoords); 
				
				//reflectionColor += texCUBE(_Cube, (reflect(viewDirection, (normalize(mul(localCoords * float3(0.5,0.5,1), local2WorldTranspose))))));
				//reflectionColor *= 0.5;
				//return reflectionColor;
				
				
				//float3 bullshitReflect = (reflectVector + (tangentWorld * float3(_AnisoX * 0, 0.0, _AnisoY * 0)));
				
				for (uint i = 1; i<(sampleCount + 2)/2; i++){ 
					reflectionColor += (texCUBE(_Cube, (reflect(viewDirection, (normalize(mul(localCoords * float3(i * ((float)_AnisoStrength / sampleCount),i * ((float)_AnisoStrength / sampleCount) ,1), local2WorldTranspose))))))) + (texCUBE(_Cube, (reflect(viewDirection, (normalize(mul(localCoords * float3(i * ((float)_AnisoStrength / sampleCount) * (-1),i * ((float)_AnisoStrength / sampleCount) * (-1) ,1), local2WorldTranspose)))))));
				};
				
				reflectionColor /= sampleCount;
				
				
				//float3 bullshitReflect = (reflectVector + (i.tangentWorld * float3(_AnisoX, 0.0, _AnisoY)));
				//reflectionColor = texCUBElod(_Cube, float4(bullshitReflect, 0));
				return pow(reflectionColor * fresnel * reflectionMask.y, 0.4545);
			};
			ENDCG
			
		}
		
	}
}