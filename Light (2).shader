Shader "LightRender" {
    Properties {
        _Color ("Light Color", Color) = (1,1,1,0)
    }
    SubShader {
        Tags {"Queue"="Opaque + 3"}
        zwrite off

		CGINCLUDE
		uniform float4 _Color;
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



        ENDCG

        Pass{
			Blend One One

			ColorMask RGB
			Cull Front
			ZTest Always
			Stencil {
			    Ref 1
			    Comp equal
			}

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			half4 frag(v2f i) : SV_Target {
		    return _Color;
		}
			ENDCG
		}

		Pass{
			Blend One One

			ColorMask RGB
			Cull Front
			ZTest Always
			Stencil {
			    Ref 2
			    Comp LEqual
			}

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			half4 frag(v2f i) : SV_Target {
		    return _Color * 2;
		}
			ENDCG

		}
    } 
}