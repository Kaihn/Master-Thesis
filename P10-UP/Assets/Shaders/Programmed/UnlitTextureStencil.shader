﻿Shader "Stencils/UnlitTexture"
{
    Properties
    {
        _MainColor("Color", Color) = (0,0,0,1)
        _MainTex ("Texture", 2D) = "black" {}
		_StencilValue("Stencil Value", Range(0,255)) = 0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque"  "Queue"="Geometry" }
		Stencil
		{
			Ref [_StencilValue]
			Comp Equal
		}

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct vertexInput
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
				float3 worldPos : TEXCOORD1;
            };

            sampler2D _MainTex;
			int _StencilValue;
            fixed4 _MainColor;
            float4 _MainTex_ST;
			float4x4 _WorldToPortal;

            v2f vert (vertexInput v)
            {
                v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f IN) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, IN.uv);
                col.rgb += _MainColor.rgb;
                // apply fog
                UNITY_APPLY_FOG(IN.fogCoord, col);

				// Discard geometry based on z axis proximity, but not when camera is close enough to the portal
				if (_StencilValue > 0) {
					if (mul(_WorldToPortal, float4(_WorldSpaceCameraPos, 1.0)).z > 0.1)
					{
						if (mul(_WorldToPortal, float4(IN.worldPos, 1.0)).z > 0.11)
							discard;
					}
					else if (mul(_WorldToPortal, float4(_WorldSpaceCameraPos, 1.0)).z < -0.1)
					{
						if (mul(_WorldToPortal, float4(IN.worldPos, 1.0)).z < -0.11)
							discard;
					}
				}

                return col;
            }
            ENDCG
        }
    }
}
