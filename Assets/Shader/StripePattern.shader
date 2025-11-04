Shader "Unlit/StripePattern"
{
    Properties
	{
		_MainTex("Texture", 2D) = "white" { }
	}
	SubShader
	{
		Tags { "RenderType" = "Opaque" }
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
			#include "viewingArea.cginc"

			struct appdata//デフォルト
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f//デフォルト
			{
				float2 uv : TEXCOORD0;
				UNITY_FOG_COORDS(1)
				float4 vertex : SV_POSITION;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;

			v2f vert(appdata v)//デフォルト
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				UNITY_TRANSFER_FOG(o, o.vertex);
				return o;
			}

			float Draw(subpixel sp, float3 clopeanEye, float leftImage, float rightImage)
			{
				float3 centerOnOVD = CalcEyePosOnOVD(clopeanEye, sp.pos);
				float dot = CalcAccurateDot(centerOnOVD);
				if(dot < (_PatternNum / 2)) return (sp.num <= (dot + _PatternNum / 2) && (sp.num > dot)) ? leftImage : rightImage;	
				else return (sp.num <= dot  && sp.num > (dot - _PatternNum / 2)) ? rightImage : leftImage;
			}

			//main関数のようなもの
			fixed4 frag(v2f i) : SV_Target
		{
			// 画素座標（0..width-1）に正規化
			float2 res = _DisplayResolution;        // float2(width, height) を想定
			float2 px  = floor(i.uv * res);         // 小数切り下げで画素境界にスナップ
			px.x = clamp(px.x, 0.0, res.x - 1.0);   // 右端で越境しないように

			int pix = (int)px.x;        // ピクセルX
			int period = (int)_PatternNum;  // 例: 8（include側で定義済み想定）
			// サブピクセルX = ピクセルX*3 + 色オフセット(R=0,G=1,B=2)
			int subR = pix * 3 + 0;
			int subG = pix * 3 + 1;
			int subB = pix * 3 + 2;

			// 正の剰余（pix>=0なので通常の % でOK）
			int phaseR = subR % period;
			int phaseG = subG % period;
			int phaseB = subB % period;

			// 0..period/2-1 を黒にする（デューティ50%）
			float4 rgba = 1.0;
			rgba.r = (phaseR < period / 2) ? 0.0 : 1.0;
			rgba.g = (phaseG < period / 2) ? 0.0 : 1.0;
			rgba.b = (phaseB < period / 2) ? 0.0 : 1.0;

			return rgba;
		}

			ENDCG
		}
	}
}
