// 増谷式include
//ドットスペース原点
float _Origin;
//適視距離[mm]
float _OVD;
//ディスプレイ解像度[px x px]
float2 _DisplayResolution;
//バリア傾斜角[subpx]
float _M;
float2 _MRatio;
//ディスプレイの向き
int _ScreenOrientation;
//ピクセルピッチ
float _PixelPitch;
// 眼間距離
float _E;
//両眼の位置[mm]
float3 _PosL;
float3 _PosR;
//開口率
float _ApertureRatio;
//近接ドット
float _ProximityDot;
// Parallax (視差)
float _Parallax;
// ドット数
int _PatternNum;
// ドットスペースの水平幅
float _F;

struct subpixel
{
    float2 pos;
    float num;
};
struct pixel
{
    float2 pos;
    subpixel r, g, b;
};
//画像切替用の変数
sampler2D _LTex;//左眼画像
sampler2D _RTex;//右眼画像
float4 _LTex_ST;
float4 _RTex_ST;
void Swap(inout float a, inout float b)
{
    float t;
    t = a;
    a = b;
    b = t;
}
// 画素番号決定関数_増谷ver (_PatternNum → 8)
float modval(float v, float n)
{
    float m = fmod(v, n);
    return (m < 0.0) ? m + n : m;
}
float3 ma_PixelNumber(int2 pix)
{
    float3 p;
    if (_ScreenOrientation >= 3)
    {
        pix.x *= 3;
        p.r = modval(pix.x - (pix.y * _MRatio.x / _MRatio.y), _PatternNum / abs(_MRatio.y));
        p.g = modval(pix.x + 1.0 - (pix.y * _MRatio.x / _MRatio.y), _PatternNum / abs(_MRatio.y));
        p.b = modval(pix.x + 2.0 - (pix.y * _MRatio.x / _MRatio.y), _PatternNum / abs(_MRatio.y));
    }
    else
    {
        pix.y *= 3;
        p.r = modval(pix.x - (pix.y * _MRatio.x / _MRatio.y), _PatternNum / abs(_MRatio.y));
        p.g = modval(pix.x - ((pix.y + 1) * _MRatio.x / _MRatio.y), _PatternNum / abs(_MRatio.y));
        p.b = modval(pix.x - ((pix.y + 2) * _MRatio.x / _MRatio.y), _PatternNum / abs(_MRatio.y));
    }
    if (_ScreenOrientation % 2 == 0) Swap(p.r, p.b);
    return p;
}
// 今見ているピクセル情報設定
pixel ma_InitPixel(int2 pixelPos)
{
    // ------- pixel coordinate origin is display center  -------
    // -----------------------------------------------------------
    // |                           |                             |
    // |                           |                             |
    // |                           |                             |
    // |     (-3,1) (-2,1)  (-1,1) | (0,1) (1,1) (2,1)           |
    // |     (-3,0) (-2,0)  (-1,0) | (0,0) (1,0) (2,0)           |
    // |---------------------------|-----------------------------|
    // |     (-3,-1)(-2,-1) (-1,-1)| (0,-1)(1,-1) (2,-1)         |
    // |     (-3,-2)(-2,-2) (-1,-2)| (0,-2)(1,-2) (2,-2)         |
    // |                           |                             |
    // |                           |                             |
    // |                           |                             |
    // -----------------------------------------------------------
    // ------------------ RGBsubpixel center pos -----------------
    // ------------------------------------------------------------
    // |                   |                   |                  |
    // |                   |                   |                  |
    // |         R         |         G         |         B        |
    // |<-------->------------------->------------------->        |
    // |    1/6            |   1/2             |   5/6            |
    // ------------------------------------------------------------
    pixel p;
    p.pos = pixelPos + float2(0.5f, 0.5f);
    // r,g,bサブピクセルの2D座標設定[mm]
    // _DisplayResolution * _PixelPitch / 2.0f → ディスプレイの中心2D座標[mm]取得（ここを原点）
    if(_ScreenOrientation >= 3){
        p.r.pos = float2(pixelPos.x + 1.0f / 6.0f, pixelPos.y + 0.5f) * _PixelPitch - _DisplayResolution * _PixelPitch / 2.0f;
        p.g.pos = float2(pixelPos.x + 1.0f / 2.0f, pixelPos.y + 0.5f) * _PixelPitch - _DisplayResolution * _PixelPitch / 2.0f;
        p.b.pos = float2(pixelPos.x + 5.0f / 6.0f, pixelPos.y + 0.5f) * _PixelPitch - _DisplayResolution * _PixelPitch / 2.0f;
        }else{
        p.r.pos = float2(pixelPos.x + 0.5f, pixelPos.y + 5.0f / 6.0f) * _PixelPitch - _DisplayResolution * _PixelPitch / 2.0f;
        p.g.pos = float2(pixelPos.x + 0.5f, pixelPos.y + 1.0f / 2.0f) * _PixelPitch - _DisplayResolution * _PixelPitch / 2.0f;
        p.b.pos = float2(pixelPos.x + 0.5f, pixelPos.y + 1.0f / 6.0f) * _PixelPitch - _DisplayResolution * _PixelPitch / 2.0f;
    }
    if(_ScreenOrientation % 2 == 0) {
        float2 t = p.r.pos;
        p.r.pos = p.b.pos;
        p.b.pos = t;
    }
    // r,g,bサブピクセルの番号設定
    float3 num = ma_PixelNumber(pixelPos);
    p.r.num = num.r;
    p.g.num = num.g;
    p.b.num = num.b;
    return p;
}
// OVD上のサイクロプスの目の座標[mm]推定
float3 ma_CalcEyePosOnOVD(float3 eyePos, float2 subpixelPos)
{
    float t = _OVD / eyePos.z;  // 奥行の比
    // 今見ているサブピクセルの2D座標[mm]
    float x = subpixelPos.x;
    float y = subpixelPos.y;
    return float3((1.0f - t) * x + t * eyePos.x, (1.0f - t) * y + t * eyePos.y, _OVD);
}
// サイクロプスの目が属するドット領域の番号推定
float ma_CalcAccurateDot(float3 eyePos)
{
    float x = eyePos.x - (eyePos.y / _M) + _Origin;
    float shift_f = abs(x) / _F / float(abs(_MRatio.y));        // [0 - 8)の実数倍
    int shift_i = (int)shift_f;                                 // [0 - 7]の整数倍
    float deci = shift_f - shift_i;                             // 0 ~ 0.5 の小数部
    float N = _PatternNum / float(abs(_MRatio.y));              // 正規化区間[0 - 7]
    shift_i %= int(N);                                          // 0 - 7の整数に正規化
    if (x >= 0) return (N - (1.0f / float(abs(_MRatio.y))) - shift_i) + 0.49999f - deci;   // 原点x = 0のときは, 7.99999
    else return shift_i + deci;
}
 
float ma_Draw(subpixel sp, float3 clopeanEye, float leftImage, float rightImage);

// 増谷式GenerateImage
float4 ma_GenerateImage(float3 clopeanEye, float2 uv)
{
    float offset = _Parallax / (_DisplayResolution.x * 3); // 視差量シフト
    float4 leftImage = tex2D(_LTex, uv - float2(offset, 0.0f));
    float4 rightImage = tex2D(_RTex, uv + float2(offset, 0.0f));
    float4 rgba = float4(0, 0, 0, 1);
    // uv * _DisplayResolution → 今見ているピクセル座標[pixel]
    pixel p = ma_InitPixel(uv * _DisplayResolution); // pixel インスタンス化
    // カラーセット
    rgba.r = ma_Draw(p.r, clopeanEye, leftImage.r, rightImage.r);
    rgba.g = ma_Draw(p.g, clopeanEye, leftImage.g, rightImage.g);
    rgba.b = ma_Draw(p.b, clopeanEye, leftImage.b, rightImage.b);
    return rgba;
}