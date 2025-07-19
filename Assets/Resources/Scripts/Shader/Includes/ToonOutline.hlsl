// ToonOutline.hlsl
#ifndef TOON_OUTLINE_INCLUDED
#define TOON_OUTLINE_INCLUDED

struct AppData{
    float4 vertex : POSITION;
    float3 normal : NORMAL;
    float2 uv : TEXCOORD0;
    float4 color : COLOR;
};

struct V2F{
    float4 vertex : SV_POSITION;
    float2 uv : TEXCOORD0;
    float3 normal : TEXCOORD1;
};

CBUFFER_START(UnityPerMaterial)
    float _OutlineThickness;
    float _ThicknessCorrectionMin;
    float _ThicknessCorrectionMax;
    float4 _OutlineColor;
    float4 _OutlineMask_ST;
    float _OutlineAngleWeight;
    float _OutlineBack;
CBUFFER_END

// FOV、距離依存でアウトラインの太さを補正
float OutlineOffsetCorrection(float distance)
{
    float m11 = unity_CameraProjection._m11;

    float corrected = distance / m11;

    return clamp(corrected, _ThicknessCorrectionMin, _ThicknessCorrectionMax);
}

#endif // TOON_OUTLINE_INCLUDED
