// 増谷式include
//ドットスペース原点
float _Origin;
//適視距離[mm]
float _OVD;
//ディスプレイ解像度[px x px]
float2 _DisplayResolution;
//バリア傾斜角[subpx]
float _M;
int2 _MRatio;
//パターン数(増谷式)
int _PatternNum_Ma;
//ディスプレイの向き
int _ScreenOrientation;
//ピクセルピッチ
float _PixelPitch;
// ドットスペース幅
float _F;
//両眼の位置[mm]
float3 _PosL;
float3 _PosR;
//開口率
float _ApertureRatio;
//近接ドット
float _ProximityDot;
// Parallax (視差)
float _Parallax;
struct subpixel
{
    float2 pos;
    float num;
};
struct pixel
{
    int2 pos;
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
        p.r = modval(pix.x - (pix.y * _MRatio.x / _MRatio.y), _PatternNum_Ma);
        p.g = modval(pix.x + 1.0 - (pix.y * _MRatio.x / _MRatio.y), _PatternNum_Ma);
        p.b = modval(pix.x + 2.0 - (pix.y * _MRatio.x / _MRatio.y), _PatternNum_Ma);
    }
    else
    {
        pix.y *= 3;
        p.r = modval(pix.x - (pix.y * _MRatio.x / _MRatio.y), _PatternNum_Ma);
        p.g = modval(pix.x - ((pix.y + 1) * _MRatio.x / _MRatio.y), _PatternNum_Ma);
        p.b = modval(pix.x - ((pix.y + 2) * _MRatio.x / _MRatio.y), _PatternNum_Ma);
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
    //ドット領域
    float _Fh = _F;      // 水平幅[mm]
    float _Fv = _Fh * 6; // 垂直幅[mm]
    float x = eyePos.x + _Origin;
    float y = eyePos.y;

    // センターラインのドット領域を超えてるかCheck
    if (y  >= _Fv / 2)
    {
        x = x + floor ((abs(y) + _Fv / 2) / _Fv) * _Fh / 2; // ドット領域の水平幅/2 の整数倍シフト
    }
    // センターラインのドット領域を下回ってるかCheck
    else if (y <= -_Fv / 2)
    {
        x = x - floor ((abs(y) + _Fv / 2) / _Fv) * _Fh / 2; // ドット領域の水平幅/2 の整数倍シフト
    }
    
    // 暫定的なドット領域の番号推定（x座標のみ考慮）
    float shift_f = abs(x) / _Fh;
    // 微調整
    int shift_i = (int)shift_f;      // 整数部
    float deci = shift_f - shift_i;  // 小数部
    shift_i %= _PatternNum_Ma;                    // 正規化
    if (x >= 0) return (_PatternNum_Ma - 1 - shift_i) % _PatternNum_Ma + 0.99999f - deci;
    // 最終的なドット領域の番号
    else return shift_i + deci;
}
// 描画
float ma_Draw(subpixel sp, float3 clopeanEye, float leftImage, float rightImage)
{
    // OVD上のサイクロプスの目の座標[mm]推定
    float3 centerOnOVD = ma_CalcEyePosOnOVD(clopeanEye, sp.pos);
    // OVD上のサイクロプスの目の座標[mm]からドット領域の番号推定
    float dot = ma_CalcAccurateDot(centerOnOVD);
    // LR割り当て
    if (dot < 4.0)
        return (sp.num > dot && sp.num <= dot + 4.0 + 1.0) ? leftImage : rightImage;
    else
        return (sp.num > dot - 4.0 && sp.num <= dot + 1.0) ? rightImage : leftImage;
}
// 増谷式GenerateImage
float4 ma_GenerateImage(float3 clopeanEye, float2 uv)
{
    float offset = _Parallax / _DisplayResolution.x; // 視差量シフト
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