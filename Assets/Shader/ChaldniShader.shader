// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'


Shader "Unlit/ChaldniShader" {
    Properties {
        _N ("N", Integer) = 3
        _M ("M", Integer) = 5
        _C ("Contrast", Float) = 1.0
        _Steepness ("Steepness", Float) = 1.0
        _MaxTone ("MaxTone", Color) = (1, 0, 0, 1)
        _MinTone ("MinTone", Color) = (0, 0, 0, 1)
        _MidTone ("MidTone", Color) = (1, 1, 1, 1)
        _MaxLevel ("MaxLevel", Range(0,1)) = 1
        _MidLevel ("MidLevel", Range(0,1)) = 0.5
        _MinLevel ("MinLevel", Range(0,1)) = 0
    }
    SubShader {
        LOD 100
        Pass {
            CGPROGRAM
            #pragma vertex vert_img
            #pragma fragment frag
			#define PI 3.14159265358979323846
            #define TAU 6.283185307179586
            
            #include "UnityCG.cginc"

            float _N, _M, _C;
            float _Steepness, _StepSize, _Alpha;
            float4 _MinTone, _MaxTone, _MidTone;
            float _MinLevel, _MaxLevel, _MidLevel;

            
            struct vertexInput {
                float4 vertex : POSITION;
                float4 uv: TEXCOORD0;
            };

            struct fragmentInput{
                float4 position : SV_POSITION;
                float4 uv: TEXCOORD0;
            };

            fragmentInput vert(vertexInput i){
                fragmentInput o;
                o.position = UnityObjectToClipPos (i.vertex);
                o.uv = i.uv;
                return o;
            }

            float theta(float p) {
                return 2*PI * p;
            }

            float chaldni(float n, float m, float x, float y) {
                return sin(n * PI * theta(x))
                     * sin(m * PI * theta(y))
                     - sin(m * PI * theta(x))
                     * sin(n * PI * theta(y));
            }

            float chaldni3D(float u, float v, float w, float x, float y, float z) {
                float t_x = PI * theta(x);
                float t_y = PI * theta(y);
                float t_z = PI * theta(z);
                return sin(u * t_x) * sin(v * t_y) * sin(w * t_z)
                     + sin(u * t_x) * sin(v * t_z) * sin(w * t_y)
                     + sin(u * t_y) * sin(v * t_x) * sin(w * t_z)
                     + sin(u * t_y) * sin(v * t_z) * sin(w * t_x)
                     + sin(u * t_z) * sin(v * t_y) * sin(w * t_x)
                     + sin(u * t_z) * sin(v * t_x) * sin(w * t_y);
            }

			float3 HUEtoRGB(in float H) {
				float R = abs(H * 6 - 3) - 1;
				float G = 2 - abs(H * 6 - 2);
				float B = 2 - abs(H * 6 - 4);
				return saturate(float3(R,G,B));
			}

            float contrast(float val) {
                float C = _C;
                float F = (259 * (C + 255)) / (255 * (259 - C));
                return F * (val - (128/255)) + 128/255;
            }

            float InverseLerp(float a, float b, float v) {
                return (v - a) / (b - a);
            }

            float Remap(float2 i, float2 o, float v) {
                float t = InverseLerp(i.x, i.y, v);
                return lerp(o.x, o.y, t);
            }

            float4 frag(fragmentInput i) : COLOR {
				float x = i.uv.x;
				float y = i.uv.y;
				float t = abs(pow(_CosTime.y / 2, 2));
				float c2d = abs(chaldni(abs(.5 - t / 3) + _N, t * _M, x, y));
				float v = contrast(sqrt(_Steepness / 50 * c2d));

                float w = saturate(InverseLerp(_MinLevel, _MidLevel, v));
                float z = saturate(InverseLerp(_MidLevel, _MaxLevel, w));
                float4 color = lerp(_MinTone, lerp(_MidTone, _MaxTone, z), w);
                return color;
            }
            ENDCG
        }
    }
}
