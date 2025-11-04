Shader "Unlit/Mashitani_Rev3"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"
            #include "include_ma_rev3.cginc"
			#include "viewingArea.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            float ma_Draw(subpixel sp, float3 clopeanEye, float leftImage, float rightImage)
            {
                float3 centerOnOVD = ma_CalcEyePosOnOVD(clopeanEye, sp.pos);
                float dot = ma_CalcAccurateDot(centerOnOVD);
                if(dot < (_PatternNum / abs(_MRatio.y) / 2)) return (sp.num <= (dot + _PatternNum / abs(_MRatio.y) / 2) && (sp.num > dot)) ? leftImage : rightImage;	
                else return (sp.num <= dot  && sp.num > (dot - _PatternNum / abs(_MRatio.y) / 2)) ? rightImage : leftImage;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                return ma_GenerateImage((_PosL + _PosR) / 2.0f, i.uv);
            }
            ENDCG
        }
    }
}
