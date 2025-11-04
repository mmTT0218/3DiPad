Shader "Unlit/OVDCheck"
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

            float4 ParallaxImage(subpixel sp, float2 uv, float leftImage, float rightImage)
            {
                // R : 0 ~ 7
                if (0 <= sp.num && sp.num >= 7){
                    return rightImage;
                }
                // L : 0 ~ 7
                else {
                    return leftImage;
                }
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // LR 初期化
                float4 leftImage = tex2D(_LTex, i.uv);
	            float4 rightImage = tex2D(_RTex, i.uv);

                // rgba 初期化
                float4 rgba = float4(0, 0, 0, 1);

                pixel p = InitPixel(i.uv * _DisplayResolution);
                rgba.r = ParallaxImage(p.r, i.uv, leftImage.r, rightImage.r);
                rgba.g = ParallaxImage(p.g, i.uv, leftImage.g, rightImage.g);
                rgba.b = ParallaxImage(p.b, i.uv, leftImage.b, rightImage.b);
                return rgba;
            }
            ENDCG
        }
    }
}
