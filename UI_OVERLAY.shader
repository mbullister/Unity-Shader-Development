Shader "Teague/UI Always in front" {
	Properties {
		_MainTex("UI texture (UV1)", 2D) = "gray" {}
		_Color("Tint Color", Color) = (1,1,1,1)
		_Opacity("Xray intensity", Range(0,1)) = 0.25
		
	}
	SubShader {
		Tags {"Queue" = "Transparent" }

		Pass {   
			Blend SrcAlpha OneMinusSrcAlpha
			ZTest On
			
			CGPROGRAM
 
			#pragma vertex vert  
			#pragma fragment frag 

			//#include "UnityCG.cginc"

			// User-specified uniforms
			uniform sampler2D _MainTex;
			uniform float4 _Color;
			
			//base input struct
			struct vertexInput {
				float4 texcoord0 : TEXCOORD0;
				float4 vertex : POSITION;
				
			};
			
			//base output struct
			struct vertexOutput {
				float4 pos : SV_POSITION;
				float4 posWorld : TEXCOORD5;
				float4 uv0 : TEXCOORD0;
			};
 
			vertexOutput vert(vertexInput i) 
			{
				vertexOutput o;
				
 				o.pos = mul(UNITY_MATRIX_MVP, i.vertex);
 				o.posWorld = mul(_Object2World, i.vertex);
				o.uv0 = i.texcoord0;								
				return o;
			}
 
			float4 frag(vertexOutput i) : COLOR
			{
				
				half4 totalLighting = tex2D(_MainTex, i.uv0);//.xy * _MainTex_ST.xy + _MainTex_ST.z);
				totalLighting = float4((totalLighting * _Color).xyz, totalLighting.a);
		
				return totalLighting;
			}
 
			ENDCG
			

			

		}
		
		Pass {   
			Blend SrcAlpha OneMinusSrcAlpha
			ZTest Off
			Cull Off
			
			CGPROGRAM
 
			#pragma vertex vert  
			#pragma fragment frag 

			//#include "UnityCG.cginc"

			// User-specified uniforms
			uniform sampler2D _MainTex;
			uniform half _Opacity;
			uniform float4 _Color;
			
			//base input struct
			struct vertexInput {
				float4 texcoord0 : TEXCOORD0;
				float4 vertex : POSITION;
				
			};
			
			//base output struct
			struct vertexOutput {
				float4 pos : SV_POSITION;
				float4 posWorld : TEXCOORD5;
				float4 uv0 : TEXCOORD0;
			};
 
			vertexOutput vert(vertexInput i) 
			{
				vertexOutput o;
				
 				o.pos = mul(UNITY_MATRIX_MVP, i.vertex);
 				o.posWorld = mul(_Object2World, i.vertex);
				o.uv0 = i.texcoord0;								
				return o;
			}
 
			float4 frag(vertexOutput i) : COLOR
			{
				
				fixed4 totalLighting = tex2D(_MainTex, i.uv0);//.xy * _MainTex_ST.xy + _MainTex_ST.z);
				totalLighting = float4((totalLighting * _Color).xyz, totalLighting.a);
		
				return fixed4(totalLighting.xyz, (totalLighting.a * _Opacity));
			}
 
			ENDCG
			
			Offset -5000,-10

		}
		
	}
}