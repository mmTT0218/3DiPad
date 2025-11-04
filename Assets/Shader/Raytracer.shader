Shader "Unlit/Raytracer"
{
	Properties
	{
		_MainTex("Texture", 2D) = "white" { }
		_Scale("Scale", float) = 1.0
		_Width("Width", float) = 1.77777
		_Height("Height", float) = 1.0
		_IsSBS("IsSBS", Range(0, 1)) = 1
		_Shift("Shift", float) = 1.0
		_PupilRadiusMM("PupilRadius", float) = 4.0
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
			#include "include_yanagida.cginc"

			//����̈ʒu[mm]
			float3 _PosL;
			float3 _PosR;

			//�J����
			float _ApertureRatio;

			//�ߐڃh�b�g
			float _ProximityDot;

			//�P�x�l����
			int _BrightnessIndex;

			struct appdata//�f�t�H���g
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f//�f�t�H���g
			{
				float2 uv : TEXCOORD0;
				UNITY_FOG_COORDS(1)
				float4 vertex : SV_POSITION;
			};

			sampler2D _MainTex;
			float _Scale;
			float _Width;
			float _Height;
			int _IsSBS;
			float4 _MainTex_ST;
			float _Shift;
			float _PupilRadiusMM;
			static const int VIS_MODE = 2;

			v2f vert(appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				UNITY_TRANSFER_FOG(o, o.vertex);
				return o;
			}

			struct subpixel
			{
				float2 pos;
				int num;
			};

			struct pixel
			{
				int2 pos;
				subpixel r, g, b;
			};
			float CheckDotFloat(float dot)
			{
				dot %= _PatternNum;
				float ret = dot < 0 ? dot + _PatternNum : dot;
				return ret;
			}
			float2 RefractionUV(float3 eyePos, float2 pos)
			{
				//���܍l��UV�ʒu
				float2 pixPos = (pos - 0.5f) * _DisplayResolution * _PixelPitch;
				float sub;//��������s�N�Z�������܂ł̐�������[mm]
				float theta1;//���܊p[rad]
				float theta2;//���ˊp[rad]
				float delta_p;//���ܗ��l�������ꍇ�̂����[mm]
				//delta_p�̓��o�Adelta_p�͕K�����ƂȂ�
				sub = sqrt((eyePos.x - pixPos.x) * (eyePos.x - pixPos.x) + (eyePos.y - pixPos.y) * (eyePos.y - pixPos.y));
				float x = NewtonMethod(0, sub, eyePos.z);
				theta2 = atan((sub - x) / eyePos.z);
				theta1 = asin(sin(theta2) / _N);
				delta_p = _Gap * tan(theta1) * ((cos(theta1) - cos(theta2)) / cos(theta2));
				float deltaX, deltaY;
				deltaX = delta_p * (pixPos.x - eyePos.x) / sub;
				deltaY = delta_p * (pixPos.y - eyePos.y) / sub;
				float2 RefPos;
				RefPos.x = pixPos.x + deltaX;
				RefPos.y = pixPos.y + deltaY;
				float2 RefPosUV;
				RefPosUV = RefPos / _DisplayResolution / _PixelPitch + 0.5f;
				return RefPosUV;
			}

			float shiftRefractionDot(float3 eyePos, float2 pos)
			{
				//�c���V�t�g��
				float2 pixPos = (pos - 0.5f) * _DisplayResolution * _PixelPitch;
				float sub;//��������s�N�Z�������܂ł̐�������[mm]
				float theta1;//���܊p[rad]
				float theta2;//���ˊp[rad]
				float delta_p;//���ܗ��l�������ꍇ�̂����[mm]
				//delta_p�̓��o�Adelta_p�͕K�����ƂȂ�
				sub = sqrt((eyePos.x - pixPos.x) * (eyePos.x - pixPos.x) + (eyePos.y - pixPos.y) * (eyePos.y - pixPos.y));
				float x = NewtonMethod(0, sub, eyePos.z);
				theta2 = atan((sub - x) / eyePos.z);
				theta1 = asin(sin(theta2) / _N);
				delta_p = _Gap * tan(theta1) * ((cos(theta1) - cos(theta2)) / cos(theta2));
				float deltaX, deltaY;
				deltaX = delta_p * (pixPos.x - eyePos.x) / sub;
				deltaY = delta_p * (pixPos.y - eyePos.y) / sub;
				float threshX, threshY;
				threshX = _PixelPitch / 3.0f;
				threshY = _PixelPitch;
				float shift = 2 * (deltaX / threshX) + (deltaY / threshY);
				shift %= _PatternNum;
				shift += shift < 0 ? _PatternNum : 0;
				return shift;
			}

			pixel InitPixel(int2 pixelPos)
			{
				pixel p;
				p.pos = pixelPos + float2(0.5f, 0.5f);
				if (_ScreenOrientation >= 3) {
					p.r.pos = float2(pixelPos.x + 1.0f / 6.0f, pixelPos.y ) * _PixelPitch - _DisplayResolution * _PixelPitch / 2.0f;
					p.g.pos = float2(pixelPos.x + 1.0f / 2.0f, pixelPos.y ) * _PixelPitch - _DisplayResolution * _PixelPitch / 2.0f;
					p.b.pos = float2(pixelPos.x + 5.0f / 6.0f, pixelPos.y ) * _PixelPitch - _DisplayResolution * _PixelPitch / 2.0f;
				}
				else {
					p.r.pos = float2(pixelPos.x + 0.5f, pixelPos.y + 1.0f / 6.0f) * _PixelPitch - _DisplayResolution * _PixelPitch / 2.0f;
					p.g.pos = float2(pixelPos.x + 0.5f, pixelPos.y + 1.0f / 2.0f) * _PixelPitch - _DisplayResolution * _PixelPitch / 2.0f;
					p.b.pos = float2(pixelPos.x + 0.5f, pixelPos.y + 5.0f / 6.0f) * _PixelPitch - _DisplayResolution * _PixelPitch / 2.0f;
				}
				if (_ScreenOrientation % 2 == 0) {
					float2 t = p.r.pos;
					p.r.pos = p.b.pos;
					p.b.pos = t;
				}
				int3 num = PixelNumber(pixelPos);
				p.r.num = num.r;
				p.g.num = num.g;
				p.b.num = num.b;
				return p;
			}

			float CalcAccurateDotDistance(int subpixelNum, float accurateDot)
			{
				float diff = abs(subpixelNum + 0.5f - accurateDot);
				return (diff <= _PatternNum / 2) ? diff : _PatternNum - diff;
			}

			float2 N_from_dir(float2 dirTangent) {
				float2 d = normalize(dirTangent);         
				float2 n = normalize(float2(-d.y, d.x));
				return n;
			}
			float overlapLen(float m, float a, float delta) {
				float ell = 0.5*a + delta - abs(m);
				float ellMax = min(a, 2.0*delta);
				return clamp(ell, 0.0, ellMax);
			}

			// 可視率 r(m)（0..1）
			float vis_ratio(float m, float a, float delta, int mode /*0/1/2*/) {
				float ell = overlapLen(m, a, delta);
				if (mode == 0)       return ell / max(2.0*delta, 1e-8);                
				else if (mode == 1)  return ell / max(a,          1e-8);               
				else                 return ell / max(max(a,2.0*delta), 1e-8);          
			}

			// “半分以上見えたら通す”
			bool pass_half_visible(float m, float a, float delta, int mode /*0/1/2*/) {
				return vis_ratio(m, a, delta, mode) >= 0.3;
			}

			float wrap_pm_half(float u, float p) {
				float m = fmod(u, p);
				if (m < 0) m += p;
				return m - 0.5 * p;
			}

			float Raytracer(subpixel sp, float3 EyePos)
			{
				float3 P = float3(sp.pos.x, sp.pos.y, 0);
				float3 E = EyePos;
				float3 B = P + (_Gap / max(E.z, 1e-8)) * (E - P);

				float X_LT =  - _PixelPitch * _DisplayResolution.x / 2.0f;
				float Y_LT = _PixelPitch * _DisplayResolution.y / 2.0f;
				
				float2 d = normalize(float2(1, -6));
				float2 n = normalize(float2(-d.y, d.x));

				float phi = -dot(n, float2(X_LT, Y_LT));
				float u = dot(n, B.xy) + phi;
				float m = wrap_pm_half(u, 0.2551);
				return m;
			}

			float chooseEyeByVisibility(float mL, float mR, float a, float deltaL, float deltaR, int mode)
			{
				float rL = vis_ratio(mL, a, deltaL, mode);
				float rR = vis_ratio(mR, a, deltaR, mode);
				const float T = 0.5;      // 半分以上見えている条件
				const float eps = 1e-6;

				if (rL >= T && rR < T) return -1.0;
				if (rR >= T && rL < T) return +1.0;

				
				if (abs(rL - rR) > eps)
					return (rL > rR) ? -1.0 : +1.0; 

				return (abs(mL) <= abs(mR)) ? -1.0 : +1.0; 
			}

			float Draw(subpixel sp, subpixel rsp,  float3 EyePos, float leftImage, float rightImage, float2 uv)
			{
				float3 EL = _PosL;//float3(-30, 0, 975);
				float3 ER = _PosR;//float3(30, 0, 975);

				float mL = Raytracer(sp, EL);
				float mR = Raytracer(sp, ER);

				float a = 0.2551 * 0.25; // 0.48228 for 32 inch 4K
				float h = 0.5 * a; 

				// if (abs(mL) < h && abs(mR) >= h) {
				// 	return leftImage;  
				// } else if (abs(mR) < h && abs(mL) >= h) {
				// 	return rightImage; 
				// } else {
				// 	return 0.0;
				// }

				float deltaL = _PupilRadiusMM * (_Gap / max(EL.z, 1e-6));
    			float deltaR = _PupilRadiusMM * (_Gap / max(ER.z, 1e-6));

				bool passL = pass_half_visible(mL, a, deltaL, VIS_MODE); 
    			bool passR = pass_half_visible(mR, a, deltaR, VIS_MODE);

				if (abs(mL) < h && abs(mR) >= h) {
					return leftImage;  
				} else if (abs(mR) < h && abs(mL) >= h) {
					return rightImage; 
				} else {
					return 0.0;
				}
			}

			float2 DisplayPos(float3 eyePos) {
				float2 temp = float2(eyePos.x, eyePos.y);
				float2 displayPos = temp / _DisplayResolution / _PixelPitch + 0.5f;
				return displayPos;
			}

			float4 GenerateImage(float3 leftEye, float3 rightEye, float2 uv)
			{
				float3 InterocularPos = (leftEye + rightEye) / 2.0f;

				//ズーム
				float inverse = 1.0f / _Scale;
				float2 scaledUV = uv * inverse;
				float offset = ((1.0f - inverse) - 0.5f) + (inverse / 2.0f);
				scaledUV += float2(offset, offset);

				//アスペクト比
				float2 modifiedUV = float2(scaledUV.x * 1, scaledUV.y * 1);
				float2 UVoffset = float2(abs(1 - 1) / 2, 0);
				modifiedUV -= UVoffset;

				//シフト
				float horizontalShift = _Shift / 2732.0f * 3;
				
				float4 leftImage;
				float4 rightImage;
				float BlackOffset;

				if (_IsSBS == 0)
				{
					float2 L = float2(modifiedUV.x / 2, modifiedUV.y);
					float2 R = float2(modifiedUV.x / 2 + 0.5, modifiedUV.y);
					L.x += horizontalShift;
					R.x -= horizontalShift;

					leftImage = tex2D(_LTex, L);
					rightImage = tex2D(_RTex, R);
					BlackOffset = float(abs(horizontalShift) + (1 - (1.0 / _Width)) / 2) * 2;
				}
				else
				{
					float2 L = float2(modifiedUV.x, modifiedUV.y);
					float2 R = float2(modifiedUV.x, modifiedUV.y);
					
					L.x += horizontalShift;
					R.x -= horizontalShift;
					
					if(_Reversal == 0)
					{
						leftImage = tex2D(_LTex, L);
						rightImage = tex2D(_RTex, R);
					}
					else
					{
						leftImage = tex2D(_RTex, float2(1.0 - L.x, L.y));
						rightImage = tex2D(_LTex, float2(1.0 - R.x, L.y));
					}

					BlackOffset = float(abs(horizontalShift) + (1 - (1.0 / _Width)) / 2);
				}


				float4 rgba = float4(0, 0, 0, 1);
				pixel p = InitPixel(uv * _DisplayResolution);
				pixel rp = InitPixel(RefractionUV(InterocularPos,uv) * _DisplayResolution);
				rgba.r = Draw(p.r, rp.r, InterocularPos, leftImage.r, rightImage.r, uv);
				rgba.g = Draw(p.g, rp.g, InterocularPos, leftImage.g, rightImage.g, uv);
				rgba.b = Draw(p.b, rp.b, InterocularPos, leftImage.b, rightImage.b, uv);
				if (_MarkerFlag == 0) {
					if (sqrt((DisplayPos(leftEye).x - uv.x) * (DisplayPos(leftEye).x - uv.x) + (DisplayPos(leftEye).y - uv.y) * (DisplayPos(leftEye).y - uv.y)) < 0.01f) {
						return float4(0, 0, 1, 1);
					}
					else if (sqrt((DisplayPos(rightEye).x - uv.x) * (DisplayPos(rightEye).x - uv.x) + (DisplayPos(rightEye).y - uv.y) * (DisplayPos(rightEye).y - uv.y)) < 0.01f) {
						return float4(1, 0, 0, 1);
					}
					else {
						return rgba;
					}
				}
				else {
					return rgba;
				}
			}

			fixed4 frag(v2f i) : SV_Target
			{
				return GenerateImage(_PosL, _PosR, i.uv);
			}
			ENDCG
		}
	}
}