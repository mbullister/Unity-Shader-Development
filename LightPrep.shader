Shader "LightSource" {
	Properties {
        _Color ("Corona Color", Color) = (1,1,1,0)
        _Opacity("Corona Opacity", Range (0,1)) = 0.25
    }
    SubShader {
        Tags {"Queue"="Opaque + 1"}
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
				o.pos.z = max(0.0, o.pos.z);
                return o;
            }

            half4 frag(v2f i) : COLOR {
                return _Color * _Opacity;
            }
        ENDCG


		Pass {
			Cull off
			Zwrite Off
			ZTest Less
			Blend One One
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			ENDCG
		}


		Pass {
			Cull Front
			Zwrite Off
			ZTest Greater
			ColorMask 0

			Stencil {
				Comp always
				Pass IncrWrap
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

			Stencil {
				Comp always
				Pass DecrSat
			}

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			ENDCG
		}
    } 
}