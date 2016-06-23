Shader "HolePrepare" {
    SubShader {
        Tags { "RenderType"="Opaque" "Queue"="Geometry+1"}
        ColorMask 0
        ZWrite off


        CGINCLUDE
            struct appdata {
                float4 vertex : POSITION;
            };
            struct v2f {
                float4 pos : SV_POSITION;
            };
            v2f vert(appdata v) {
                v2f o;
                o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
                return o;
            }
            half4 frag(v2f i) : SV_Target {
                return half4(1,1,0,1);
            }
        ENDCG

        Pass {
            Cull Back
            ZTest Less

            Stencil {
            	Ref 1
            	Comp always
            	Pass IncrSat
       		}

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            ENDCG
        }

        Pass {
            Cull Front
            ZTest Less

            Stencil {
            	Ref 1
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