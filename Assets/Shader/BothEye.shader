Shader "Unlit/BothEye"//アイトラッキング制御前後アリ
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
			#include "Refraction.cginc"

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

			//観察しているかどうかを判定する関数
			bool isObserved(float dotDistance)
			{
				return (dotDistance < (_PatternNum * _ApertureRatio + _ProximityDot) / 2.0);
			}

			float Draw(subpixel sp, float3 leftEye, float3 rightEye, float leftImage, float rightImage)
			{
				float subpixelValue;
				float3 leftEyeOnOVD = CalcEyePosOnOVD(leftEye, sp.pos);
				float3 rightEyeOnOVD = CalcEyePosOnOVD(rightEye, sp.pos);
				float dotL = CalcAccurateDot(leftEyeOnOVD);
				float dotR = CalcAccurateDot(rightEyeOnOVD);
				float dotDistanceL = CalcDotDistance(sp.num, dotL);
				float dotDistanceR = CalcDotDistance(sp.num, dotR);
				
				if (isObserved(dotDistanceL) ^ isObserved(dotDistanceR))
				{
					subpixelValue = isObserved(dotDistanceL) ? leftImage : rightImage;
					return subpixelValue;
				}
				else return 0;
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