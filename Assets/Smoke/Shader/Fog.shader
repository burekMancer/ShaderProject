Shader "Custom/FogVolume"
{
    Properties
    {
        _Progress ("Progress", Range(0, 1)) = 0
    }

    SubShader
    {
        Tags
        {
            "RenderType"="Transparent"
            "Queue"="Transparent"
        }

        Blend SrcAlpha OneMinusSrcAlpha
        ZWrite Off

        Pass
        {
            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            float _Progress;

            struct appdata
            {
                float4 vertex : POSITION;
            };

            struct v2f
            {
                float4 position : SV_POSITION;
                float3 worldPos : TEXCOORD0;
            };

            v2f vert(appdata v)
            {
                v2f o;

                o.position =
                    UnityObjectToClipPos(v.vertex);

                o.worldPos =
                    mul(unity_ObjectToWorld, v.vertex).xyz;

                return o;
            }

            bool RayBoxIntersection(
                float3 rayOrigin,
                float3 rayDirection,
                out float tEnter,
                out float tExit)
            {
                float3 boxMin =
                    float3(-0.5, -0.5, -0.5);

                float3 boxMax =
                    float3(0.5, 0.5, 0.5);

                float3 invDir =
                    1.0 / rayDirection;

                float3 t0 =
                    (boxMin - rayOrigin) * invDir;

                float3 t1 =
                    (boxMax - rayOrigin) * invDir;

                float3 tMin =
                    min(t0, t1);

                float3 tMax =
                    max(t0, t1);

                tEnter =
                    max(
                        max(tMin.x, tMin.y),
                        tMin.z
                    );

                tExit =
                    min(
                        min(tMax.x, tMax.y),
                        tMax.z
                    );

                return
                    tExit >= max(tEnter, 0.0);
            }

            float hash(float3 p)
            {
                p =
                    frac(p * 0.3183099 + 0.1);

                p *= 17.0;

                return frac(
                    p.x *
                    p.y *
                    p.z *
                    (p.x + p.y + p.z)
                );
            }

            float noise3D(float3 p)
            {
                float3 cell =
                    floor(p);

                float3 local =
                    frac(p);

                local =
                    local *
                    local *
                    (3.0 - 2.0 * local);

                float n000 =
                    hash(cell + float3(0, 0, 0));

                float n100 =
                    hash(cell + float3(1, 0, 0));

                float n010 =
                    hash(cell + float3(0, 1, 0));

                float n110 =
                    hash(cell + float3(1, 1, 0));

                float n001 =
                    hash(cell + float3(0, 0, 1));

                float n101 =
                    hash(cell + float3(1, 0, 1));

                float n011 =
                    hash(cell + float3(0, 1, 1));

                float n111 =
                    hash(cell + float3(1, 1, 1));

                float nx00 =
                    lerp(n000, n100, local.x);

                float nx10 =
                    lerp(n010, n110, local.x);

                float nx01 =
                    lerp(n001, n101, local.x);

                float nx11 =
                    lerp(n011, n111, local.x);

                float nxy0 =
                    lerp(nx00, nx10, local.y);

                float nxy1 =
                    lerp(nx01, nx11, local.y);

                return
                    lerp(
                        nxy0,
                        nxy1,
                        local.z
                    );
            }

            float fbm(float3 p)
            {
                float value =
                    0.0;

                float amplitude =
                    0.5;

                value +=
                    noise3D(p) * amplitude;

                p *= 2.0;
                amplitude *= 0.5;

                value +=
                    noise3D(p) * amplitude;

                p *= 2.0;
                amplitude *= 0.5;

                value +=
                    noise3D(p) * amplitude;

                p *= 2.0;
                amplitude *= 0.5;

                value +=
                    noise3D(p) * amplitude;

                return value;
            }

            float4 frag(v2f i) : SV_Target
            {
                float3 cameraLocal =
                    mul(
                        unity_WorldToObject,
                        float4(
                            _WorldSpaceCameraPos,
                            1.0
                        )
                    ).xyz;

                float3 fragmentLocal =
                    mul(
                        unity_WorldToObject,
                        float4(
                            i.worldPos,
                            1.0
                        )
                    ).xyz;

                float3 rayDirection =
                    normalize(
                        fragmentLocal -
                        cameraLocal
                    );

                float tEnter;
                float tExit;

                bool hit =
                    RayBoxIntersection(
                        cameraLocal,
                        rayDirection,
                        tEnter,
                        tExit
                    );

                if (!hit)
                {
                    discard;
                }

                tEnter =
                    max(tEnter, 0.0);

                const int SAMPLE_COUNT =
                    32;

                float distanceInsideCube =
                    tExit - tEnter;

                float stepSize =
                    distanceInsideCube /
                    SAMPLE_COUNT;

                float t =
                    tEnter;

                float accumulatedDensity =
                    0.0;

                for (
                    int sample = 0;
                    sample < SAMPLE_COUNT;
                    sample++
                )
                {
                    float3 samplePosition =
                        cameraLocal +
                        rayDirection * t;
                    float3 shapePosition = samplePosition;

                float fall =
                    smoothstep(0.45, 1.0, _Progress);

                shapePosition.y +=
                    fall * 0.24; //fall

                float distanceFromCenter =
                    length(shapePosition);

                float3 animatedPosition =
                    shapePosition;

                animatedPosition.y +=
                    _Time.y * 0.15;

                animatedPosition.x +=
                    _Time.y * 0.05;

                float noise =
                    fbm(animatedPosition * 3.0);

                noise =
                    noise * 2.0 - 1.0;

                float expansion =
                    saturate(_Progress / 0.18);

                expansion =
                    1.0 - pow(1.0 - expansion, 4.0);

                float radius =
                    lerp(0.05, 0.5, expansion);

                float sphere =
                    radius - distanceFromCenter;

                float density =
                    saturate(
                        sphere +
                        noise * 0.35
                    );

                float fade =
                    1.0 - smoothstep(
                        0.72,
                        1.0,
                        _Progress
                    );

                density *= fade;

                                        

                    accumulatedDensity +=
                        density *
                        stepSize *
                        10.0;

                    t += stepSize;
                }

                float alpha =
                    saturate(
                        accumulatedDensity
                    );

                float3 fogColor =
                    float3(
                        0.05,
                        0.05,
                        0.08
                    );

                return float4(
                    fogColor,
                    alpha
                );
            }

            ENDHLSL
        }
    }
}