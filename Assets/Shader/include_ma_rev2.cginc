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
//------- 2025/08/13 追加 -------
int _PatternNum_Ma;
float _Fh;
float _Fv;
float _OriginY;
float _dtheta;
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
    // 眼の位置(x, y)
    float x = eyePos.x + _Origin;
    float y = eyePos.y + _OriginY;
    // 行推定
    int row = 0;
    if (y >= 0){   // 0行目以上
        row = (int)(y / _Fv);
    }
    else {         // 0行目より下
        row = (int)((y - _Fv) / _Fv);
    }
    // 行分のシフト（_M < 0 のため "- row * (_Fv / _M)" は + 側に寄ります）
    x = x - row * (_Fv / _M);
    // 暫定番号（xのみ）
    float shift_f = x / _Fh;
    int   shift_i = (int)shift_f;     // 整数部
    float deci    = shift_f - shift_i;// 小数部
    shift_i %= _PatternNum_Ma;        // 正規化
    // ★ 修正点: x>=0 分岐を +0.99999f - deci に（境界の取り方を整数中心に合わせる）
    if (x >= 0) return (_PatternNum_Ma - 1 - shift_i) % _PatternNum_Ma + 0.99999f - deci;
    else        return  abs(shift_i + deci);
}
// 描画
// (-N/2, N/2] に正規化した円周差
float normalizeDiff(float d, float N)
{
    float half = N * 0.5;
    float x = fmod(d + half, N);
    if (x < 0.0) x += N;   // ここが重要：負のとき補正して [0, N) に
    return x - half;
}
float ma_Draw(subpixel sp, float3 clopeanEye, float leftImage, float rightImage)
{
    const float N = _PatternNum_Ma; // 例: 8
    // 1) 視点位置から dot 番号
    float3 centerOnOVD = ma_CalcEyePosOnOVD(clopeanEye, sp.pos);
    float  dot         = ma_CalcAccurateDot(centerOnOVD);
    // 2) R領域: d ∈ [u-W, u] を固定
    const float u = 0.5;
    // ★ 修正点: W = N/2
    const float W = N * 0.5;     // N=8 → 4.0
    const float l = u - W;       // N=8 → -3.5
    // 3) 判定
    float d = normalizeDiff(sp.num - dot, N);
    bool isRight = (d > l) && (d <= u);
    return isRight ? rightImage : leftImage;
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