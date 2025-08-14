Shader "Unlit/BothEyeVer.2"//アイトラッキング制御前後アリ
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

			float Draw(subpixel sp, float3 leftEye, float3 rightEye, float leftImage, float rightImage)
			{
				float subpixelValue;
				float3 leftEyeOnOVD = CalcEyePosOnOVD(leftEye, sp.pos);
				float3 rightEyeOnOVD = CalcEyePosOnOVD(rightEye, sp.pos);
				float dotL = CalcAccurateDot(leftEyeOnOVD);
				float dotR = CalcAccurateDot(rightEyeOnOVD);
				float dotDistanceL = CalcAccurateDotDistance(sp.num, dotL);
				float dotDistanceR = CalcAccurateDotDistance(sp.num, dotR);

				//float viewingAreaL = CalcViewingArea1to6per25(dotDistanceL);
				//float viewingAreaR = CalcViewingArea1to6per25(dotDistanceR);
				float viewingAreaL = CalcViewingArea1to6per50(dotDistanceL);
				float viewingAreaR = CalcViewingArea1to6per50(dotDistanceR);
				//float viewingAreaL = CalcViewingArea3to23(dotDistanceL);
				//float viewingAreaR = CalcViewingArea3to23(dotDistanceR);
				
				subpixelValue = viewingAreaL / (viewingAreaL + viewingAreaR) * leftImage + viewingAreaR / (viewingAreaL + viewingAreaR) * rightImage;
				subpixelValue *= abs(viewingAreaL - viewingAreaR) / max(viewingAreaL, viewingAreaR); 
				return subpixelValue;
			}

			//main関数のようなもの
			fixed4 frag(v2f i) : SV_Target
			{
				return GenerateImage(_PosL, _PosR, i.uv);
			}
			ENDCG
		}
	}
}

