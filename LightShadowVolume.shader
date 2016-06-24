Shader "LightShadowVolume" {
	Properties {
        _Color ("Shadow Color", Color) = (0,0,0,0)
        _Opacity("Shadow Opacity", Range (0,1)) = 0.1
    }
    SubShader {
        Tags {"Queue"="Opaque + 3"}
        ZWrite off


        CGINCLUDE
        	uniform float4 _Color;
        	uniform half _Opacity;

            struct appdata {
                float4 vertex : POSITION;
            };
            struct v2f {
                float4 pos : SV_POSITION;
            };
            v2f vert(appdata v) {
                v2f o;
                o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
                //o.pos.z = max(0.0f, o.pos.z);
                return o;
            }

            half4 frag(v2f i) : SV_Target {
                return lerp(float4(1,1,1,0), _Color, _Opacity);
            }

        ENDCG

        Pass {
			Cull Front
			Zwrite Off
			ZTest Greater
			ColorMask 0

			Stencil {
				Ref 1
				Comp always
				Pass Invert
				//Pass IncrWrap
			}

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			ENDCG
		}

		Pass {
			Cull Back
			Zwrite Off
			ZTest Greater
			ColorMask 0
			//Blend One One

			Stencil {
				Ref 255
				Comp Greater
				Pass Invert
				Fail Zero
			}

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			ENDCG
		}

	} 
}