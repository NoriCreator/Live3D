Shader "Custom/Monitor"
{
    Properties
    {
        [Header(Main)]
        [MainTexture] _BaseMap("Monitor Render Texture", 2D) = "white" {}
        _BaseMapResolution("解像度 = Monitor Mask Tilling", Vector) = (144, 81, 1, 1)
        _MonitorMask("Monitor Mask", 2D) = "white" {}

        [HDR] _EmissionColor("Emission Color", Color) = (1, 1, 1, 1)
        _EmissionIntensity("Intensity", Float) = 1
    }

    SubShader
    {
        Tags
        {
            "RenderType" = "Opaque"
            "RenderPipeline" = "UniversalPipeline"
        }

        Pass
        {
            Tags { "LightMode" = "UniversalForward" }
            LOD 100
            Cull Back

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap);

            TEXTURE2D(_MonitorMask);
            SAMPLER(sampler_MonitorMask);

            CBUFFER_START(UnityPerMaterial)
                float4 _BaseMap_ST;
                float2 _BaseMapResolution;
                float4 _MonitorMask_ST;
                float4 _EmissionColor;
                float _EmissionIntensity;
            CBUFFER_END

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct V2F
            {
                float4 vertex : SV_POSITION;
                float2 uvBase : TEXCOORD0;
                float2 uvMask : TEXCOORD1;
                float3 worldPos : TEXCOORD2;
            };

            float _TimeY;

            V2F vert(appdata v)
            {
                V2F o;
                o.worldPos = TransformObjectToWorld(v.vertex.xyz);
                o.vertex = TransformObjectToHClip(v.vertex.xyz);
                o.uvBase = TRANSFORM_TEX(v.uv, _BaseMap);
                o.uvMask = TRANSFORM_TEX(v.uv, _MonitorMask);
                return o;
            }

            float4 frag(V2F i) : SV_Target
            {
                float2 pixelUV = floor(i.uvBase * _BaseMapResolution) / _BaseMapResolution;
                float4 baseColor = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, pixelUV);
                float4 mask = SAMPLE_TEXTURE2D(_MonitorMask, sampler_MonitorMask, i.uvMask);
                return baseColor * mask * _EmissionColor * _EmissionIntensity;
            }

            ENDHLSL
        }
    }
}
