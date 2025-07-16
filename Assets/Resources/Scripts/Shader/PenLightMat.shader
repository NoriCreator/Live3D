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
            };

            float _TimeY;

            V2F vert(appdata v)
            {
                uint id = v.instanceID;

                float4x4 modelMatrix = matrixBuffer[id];
                float4 worldPos = mul(modelMatrix, float4(v.vertex.xyz, 1.0));

                V2F o;
                o.vertex = TransformWorldToHClip(worldPos.xyz);
                o.uv = v.uv;
                o.worldPos = worldPos.xyz;
                return o;
            }

            float4 frag(V2F i) : SV_Target
            {
                return _EmissionColor * _EmissionIntensity;
            }

            ENDHLSL
        }
    }
}
