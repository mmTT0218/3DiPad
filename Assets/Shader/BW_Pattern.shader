Shader "Unlit/BW_Pattern"
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
            #include "include.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 svpos : SV_POSITION;
                UNITY_FOG_COORDS(1)
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
                o.svpos = UnityObjectToClipPos(v.vertex);
                UNITY_TRANSFER_FOG(o,o.svpos);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // i.svpos.x は画面のピクセルX座標 (0 から スクリーン幅 まで)
                int pixelX = (int)i.svpos.x;
                
                // 5px周期
                int stripeIndex = (int)(pixelX / 5);

                // インデックスが偶数か奇数かで色を決定
                if (stripeIndex % 2 == 0)
                {
                    // 白
                    return fixed4(1, 1, 1, 1); 
                }
                else
                {
                    // 黒
                    return fixed4(0, 0, 0, 1); 
                }
            }
            ENDCG
        }
    }
}
