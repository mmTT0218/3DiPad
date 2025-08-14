//バリアギャップ
float _Gap;
//屈折率
float _N;
//屈折考慮フラグ
int _RefractionFlag;

float f(float x, float d, float z)
{
	return _N * x / sqrt(_Gap * _Gap + x * x) - (d - x) / sqrt(z * z + (d - x) * (d - x));
}

float fPrime(float x, float d, float z)
{
	return -(d - x) * (d - x) / ((d - x) * (d - x) + z * z) / sqrt((d - x) * (d - x) + z * z) + 1 / sqrt((d - x) * (d - x) + z * z) + _N / sqrt(_Gap * _Gap + x * x) - _N * x * x / (_Gap * _Gap + x * x) / sqrt(_Gap * _Gap + x * x);
}

float NewtonMethod(float init, float d, float z)
{
	float x = init;
	for (int i = 0; i < 5; i++)
	{
		x -= f(x, d, z) / fPrime(x, d, z);
	}
	return x;
}

float _ShiftRefraction(float2 processingPixelPos, float3 eyePos)
{
	float2 pp = (processingPixelPos + float2(1.0 / 6.0, 1.0 / 2.0) - _DisplayResolution / 2.0) * _PixelPitch;
	float d = sqrt((eyePos.x - pp.x) * (eyePos.x - pp.x) + (eyePos.y - pp.y) * (eyePos.y - pp.y));
	float x = NewtonMethod(0, d, eyePos.z);
	float theta1 = atan((d - x) / eyePos.z);
	float theta2 = asin(sin(theta1) / _N);
	//theta2 = atan(x / _Gap);
	float delta = _Gap * tan(theta1) * (cos(theta1) - cos(theta2)) / cos(theta2);
	float deltaX, deltaY;
	deltaX = delta * (pp.x - eyePos.x) / d;
	deltaY = delta * (pp.y - eyePos.y) / d;
	float threshX, threshY;
	threshX = _PixelPitch / 3.0;
	threshY = _PixelPitch;
	if (_ScreenOrientation < 3) Swap(threshX, threshY);
	float shift = -_MRatio.y * deltaX / threshX + _MRatio.x * deltaY / threshY;
	shift %= _PatternNum;
	shift += shift < 0 ? _PatternNum : 0;
	return shift;
}

float3 ShiftRefraction(int2 processingPixelPos, float3 eyePos)
{
	float3 shift;
	if (_ScreenOrientation >= 3)
	{
		shift.r = _ShiftRefraction(processingPixelPos + float2(0.0, 0.0), eyePos);
		shift.g = _ShiftRefraction(processingPixelPos + float2(1.0 / 3.0, 0.0), eyePos);
		shift.b = _ShiftRefraction(processingPixelPos + float2(2.0 / 3.0, 0.0), eyePos);
	}
	else if (_ScreenOrientation < 3)
	{
		shift.r = _ShiftRefraction(processingPixelPos + float2(0.0, 2.0 / 3.0), eyePos);
		shift.g = _ShiftRefraction(processingPixelPos + float2(0.0, 1.0 / 3.0), eyePos);
		shift.b = _ShiftRefraction(processingPixelPos + float2(0.0, 0.0), eyePos);
	}
	if (_ScreenOrientation % 2 == 0) Swap(shift.r, shift.b);
	return shift;
}