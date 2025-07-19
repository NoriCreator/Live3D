Shader "Custom/PenLightMat"
{
    Properties
    {
        [HDR] _EmissionColor("Emission Color", Color) = (1, 1, 1, 1)
        _EmissionIntensity("Intensity", Float) = 1
    }

    SubShader
    {
        Tags
        {
            "Queue" = "Transparent"
            "RenderType" = "Transparent"
            "RenderPipeline" = "UniversalPipeline"
        }

        Pass
        {
            Name "Emission Material"
            Tags { "LightMode" = "UniversalForward" }
            Blend SrcAlpha OneMinusSrcAlpha
            Cull Back

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_instancing

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            StructuredBuffer<float4x4> matrixBuffer;
            StructuredBuffer<float4> basePositionBuffer;

            CBUFFER_START(UnityPerMaterial)
                float4 _EmissionColor;
                float _EmissionIntensity;
            CBUFFER_END

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                uint instanceID : SV_InstanceID;
            };

            struct V2F
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
                uint instanceID : SV_InstanceID;
            };

            V2F vert(appdata v)
            {
                V2F o;
                o.instanceID = v.instanceID;

                float4x4 modelMatrix = matrixBuffer[o.instanceID];
                float4 worldPos = mul(modelMatrix, float4(v.vertex.xyz, 1.0));

                o.vertex = TransformWorldToHClip(worldPos.xyz);
                o.uv = v.uv;
                o.worldPos = worldPos.xyz;
                return o;
            }

            float4 frag(V2F i) : SV_Target
            {
                uint seed = i.instanceID * 123u + 456u;
                float r1 = frac(sin(seed * 0.123456789) * 43758.5453);

                float wave = distance(i.worldPos.xy, float2(0, 16));
                wave = sin(wave * 0.53 - _Time.y * 2.8) * 0.5 + 0.5;

                float hue = frac(r1 + _Time.y * 0.83);
                float br = wave * wave * 50 + 0.1; 

                float3 color = HsvToRgb(float3(hue, 1, br));

                return float4(color, 1) * _EmissionColor * _EmissionIntensity;
            }

            ENDHLSL
        }
    }
}
