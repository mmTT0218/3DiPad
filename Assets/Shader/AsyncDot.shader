Shader "Unlit/AsyncDot"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Diameter ("Diameter", Float) = 150
        _Spacing ("Spacing", Vector) = (150, 250, 0, 0)
        _Offset ("Offset", Vector) = (0, 0, 0, 0)
        _Row ("Row", Float) = 4
        _Col ("Col", Float) = 11
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

            // 変数
            float _Diameter;
            float4 _Spacing;
            float4 _Offset;
            float _Row;
            float _Col;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                int2 res = int2(2360, 1640);
                int2 pixel = i.uv * res;

                float2 startPos = _Offset.xy + float2(_Diameter / 2.0, _Diameter / 2.0);
                float Circle = 0.0;

                for (int col = 0; col < _Col; col++) {
                    // 各列の開始点
                    float2 colStart = startPos + float2(col * _Spacing.x, 0.0);

                    // 偶数列目は縦に半ピッチシフト
                    if (col % 2 != 0) {
                        colStart += float2(0.0, _Spacing.y / 2.0);
                    }

                    for (int row = 0; row < _Row; row++) {
                        float2 center = colStart + float2(0.0, row * _Spacing.y);
                        float dist = distance(pixel, center);
                        Circle += smoothstep(_Diameter * 0.5 + 1.0, _Diameter * 0.5 - 1.0, dist);
                    }
                }

                return float4(1.0 - Circle, 1.0 - Circle, 1.0 - Circle, 1.0);
            }

            ENDCG
        }
    }
}
