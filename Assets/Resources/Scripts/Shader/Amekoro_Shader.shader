Shader "Custom/Amekoro_Shader"
{
    Properties
    {
        [Header(Main)]
        [MainTexture] _BaseMap("Base Map", 2D) = "white" {}
        [Normal] _BumpMap("Normal Map", 2D) = "bump" {}

        [Header(Light)]
        _DiffuseIntensity("Diffuse Intensity", Float) = 1.0
        _SpecularIntensity("Specular Intensity", Float) = 1.0
        _LightRimIntensity("Rim Intensity", Range(0, 10)) = 1.0
        _AmbientLight("Ambient Light", Float) = 0.1

        [Header(Toon Lighting)]
        [Toggle(_USETOONLIGHTING)] _UseToonLighting("Use Toon Lighting", Float) = 1.0
        _ToonRamp("Toon Ramp (RGB)", 2D) = "white" {}
        _ToonIntensity("Intensity", Range(0, 1)) = 1.0
        _ToonBorderThreshold("Toon Border Threshold", Range(0, 1)) = 0.5

        [Header(Toon EdgeOverlay)]
        _ToonEdgeOverlayStrength("Strength", Range(0.001, 1)) = 0.5
        _ToonEdgeOverlayThickness("Thickness", Range(0, 1)) = 0.1

        [Header(Emission)]
        [HDR] _EmissionColor("Emission Color", Color) = (1, 1, 1, 1)
        _EmissionIntensity("Intensity", Float) = 1.0

        [Header(Outline)]
        _OutlineThickness ("Thickness", Float) = 1.0
        _ThicknessCorrectionMin ("Correction Min", Float) = 0.2
        _ThicknessCorrectionMax ("Correction Max", Float) = 5.0
        _OutlineColor ("Color", Color) = (0.1, 0.1, 0.1, 1)
        _OutlineMask ("Mask (R = Strength)", 2D) = "white" {}
        _OutlineMask_ST ("Mask ST", Vector) = (1, 1, 0, 0)
        _OutlineBack("Back", Float) = 0.0
        _OutlineAngleWeight("Angle Weight", Float) = 1.0
    }
    SubShader
    {
        Tags
        {
            "Queue" = "Geometry"
            "RenderType"="Opaque"
            "RenderPipeline"="UniversalPipeline"
        }
        LOD 100
        AlphaToMask On

        // ----- Forward Lit Pass -----
        Pass
        {
            Name "FORWARD"
            Tags { "LightMode" = "UniversalForward" }
            Cull Back

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #pragma multi_compile _ _USETOONLIGHTING

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct AppData{
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL0;
                float4 tangent : TANGENT0;
            };

            struct V2F{
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : TEXCOORD1;
                float3 tangent : TEXCOORD2;
                float3 bitangent : TEXCOORD3;
                float3 worldPos : TEXCOORD4;
            };

            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap);

            TEXTURE2D(_BumpMap);
            SAMPLER(sampler_BumpMap);

            TEXTURE2D(_ToonRamp);
            SAMPLER(sampler_ToonRamp);

            CBUFFER_START(UnityPerMaterial)
                float4 _BaseMap_ST;
                float _UseToonLighting;
                float _ToonBorderThreshold;
                float _ToonIntensity;
                float _ToonEdgeOverlayStrength;
                float _ToonEdgeOverlayThickness;
                float _DiffuseIntensity;
                float _SpecularIntensity;
                float _LightRimIntensity;
                float _AmbientLight;
                float4 _EmissionColor;
                float _EmissionIntensity;
            CBUFFER_END

            Light MyGetMainLight(float4 shadowCoord)
            {
                Light light = GetMainLight();

                half4 shadowParams = GetMainLightShadowParams();
                half shadowStrength = shadowParams.x;
                ShadowSamplingData shadowSamplingData = GetMainLightShadowSamplingData();
                
                half attenuation;
                attenuation = SAMPLE_TEXTURE2D_SHADOW(_MainLightShadowmapTexture, sampler_MainLightShadowmapTexture, shadowCoord.xyz);
                attenuation = SampleShadowmapFiltered(TEXTURE2D_SHADOW_ARGS(_MainLightShadowmapTexture, sampler_MainLightShadowmapTexture), shadowCoord, shadowSamplingData);;
                attenuation = LerpWhiteTo(attenuation, shadowStrength);
                
                half shadowAttenuation = BEYOND_SHADOW_FAR(shadowCoord) ? 1.0 : attenuation;
                
                light.shadowAttenuation = shadowAttenuation;
                
                return light;
            }

            float3 CulToonLighting(float3 lightCol, float NdotL)
            {
                // Rampテクスチャでトゥーン調整
                float3 toonRamp = SAMPLE_TEXTURE2D(_ToonRamp, sampler_ToonRamp, float2(NdotL, 0.5));
                float3 toonLightCol = lightCol * toonRamp;

                // 明度ベースで階調制御
                float3 HSV = RgbToHsv(toonLightCol);

                // 境界線オーバーレイ
                float edgeValueDistance = abs(_ToonBorderThreshold - HSV.z);
                float overlay = pow(1 - smoothstep(0, _ToonEdgeOverlayThickness, edgeValueDistance), 5) * _ToonEdgeOverlayStrength;
                HSV.y += lerp(0, overlay, _ToonIntensity);
                
                // Toon処理 & Toon強さ調整
                HSV.z = lerp(HSV.z, step(_ToonBorderThreshold, HSV.z) * _ToonBorderThreshold, _ToonIntensity);

                toonLightCol = HsvToRgb(HSV);
                return toonLightCol;
            }

            V2F vert(AppData v)
            {
                V2F o;

                o.worldPos = TransformObjectToWorld(v.vertex.xyz);
                o.vertex = TransformObjectToHClip(v.vertex.xyz);
                o.uv = TRANSFORM_TEX(v.uv, _BaseMap);
                o.normal = TransformObjectToWorldNormal(v.normal);
                o.tangent = TransformObjectToWorldDir(v.tangent.xyz);
                o.bitangent = cross(o.normal, o.tangent) * v.tangent.w;

                return o;
            }            

            float4 frag(V2F i) : SV_Target
            {
                float3 viewDir = normalize(GetCameraPositionWS() - i.worldPos);
                Light mainLight = MyGetMainLight(TransformWorldToShadowCoord(i.worldPos));
                float4 texCol = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, i.uv);
                float3 normalMap = UnpackNormal(SAMPLE_TEXTURE2D(_BumpMap, sampler_BumpMap, i.uv));
                float3 normalWS = normalize(
                    i.normal * normalMap.z
                    + i.tangent * normalMap.x
                    + i.bitangent * normalMap.y
                );

                // Lighting ---------------------
                // diffuse
                float3 lightDir = normalize(mainLight.direction);
                float NdotL = dot(normalWS, lightDir);
                NdotL = max(0, NdotL);

                float diffuse = pow(NdotL, 2.5) * _DiffuseIntensity * mainLight.color;

                // specular
                float3 refDir = reflect(-lightDir, normalWS);
                float RefDotV = dot(refDir, viewDir);
                RefDotV = max(0, RefDotV);
                float specular = pow(RefDotV, 2.5) * _SpecularIntensity * mainLight.color;

                // ambient light
                float ambient = _AmbientLight * mainLight.color;

                // lightMask Fresnel
                float NdotV = saturate(dot(normalWS, viewDir));
                float fresnel = pow((1.0 - NdotV), _LightRimIntensity);

                // Toon Lighting
                float3 lightCol = (diffuse + specular) * mainLight.shadowAttenuation * fresnel;

                #ifdef _USETOONLIGHTING
                    lightCol = CulToonLighting(lightCol, NdotL);
                #endif

                // Emission
                float4 emission = _EmissionColor * _EmissionIntensity;
                float3 finalColor = texCol.rgb * (lightCol + ambient) * emission.xyz;

                return float4(finalColor, texCol.a);
            }
            ENDHLSL
        }

        // ----- Outline Pass -----
        Pass
        {
            Name "OUTLINE"
            Tags { "LightMode" = "SRPDefaultUnlit" }  // ライト非対応

            Cull Front
            ZWrite On

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            #include "Includes/ToonOutline.hlsl"
            
            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap);

            TEXTURE2D(_OutlineMask);
            SAMPLER(sampler_OutlineMask);

            V2F vert(AppData v)
            {
                V2F o;

                float3 worldPos = TransformObjectToWorld(v.vertex.xyz);
                float3 viewDir = normalize(worldPos - GetCameraPositionWS());
                float3 normal = normalize(TransformObjectToWorldNormal(v.normal));
                float3 normalCS = normalize(TransformWorldToHClipDir(normal));

                float NdotV = abs(dot(normal, viewDir));
                float outlineFactor = saturate(1.0 - NdotV);
                outlineFactor = pow(outlineFactor, 4.0);

                float dist = length(worldPos - GetCameraPositionWS());

                float3 cameraBackDirWS = normalize(mul((float3x3)unity_CameraToWorld, float3(0, 0, 1)));
                float3 cameraBackDirOS = normalize(mul((float3x3)unity_WorldToObject, cameraBackDirWS));

                float angleCorrection = lerp(1.0, v.color.r, _OutlineAngleWeight);

                float3 finalOffsetDir = TransformWorldToObjectDir(normal) * angleCorrection;

                float4 offsetPos = v.vertex
                                + float4(finalOffsetDir * _OutlineThickness * outlineFactor * 1e-3 * OutlineOffsetCorrection(dist), 0)
                                + float4(_OutlineBack * cameraBackDirOS * 0.001, 0);

                o.vertex = TransformObjectToHClip(offsetPos.xyz);
                o.uv = TRANSFORM_TEX(v.uv, _OutlineMask);
                o.normal = normal;

                return o;
            }

            float4 frag(V2F i) : SV_Target
            {
                float mask = SAMPLE_TEXTURE2D(_OutlineMask, sampler_OutlineMask, i.uv).r;
                if (mask < 0.05) discard;

                float3 baseColor = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, i.uv).rgb;

                Light light = GetMainLight();
                float NdotL = saturate(dot(i.normal, light.direction));
                float3 correctedOutline = lerp(_OutlineColor.rgb, baseColor, NdotL * 0.2);

                return float4(correctedOutline, _OutlineColor.a);
            }
            ENDHLSL
        }

        // ----- Shadow Caster Pass -----
        Pass {
            Name "ShadowCaster"
            Tags { "LightMode"="ShadowCaster" }

            ZWrite On
            ZTest LEqual

            HLSLPROGRAM
            #pragma vertex ShadowPassVertex
            #pragma fragment ShadowPassFragment
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/ShadowCasterPass.hlsl"

            ENDHLSL
        }
    }

    FallBack "Diffuse"
}