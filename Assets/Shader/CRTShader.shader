// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unlit/CRTShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Pow("Pow", Float) = 2
        _LogScale("LogScale", Float) = 1
        _MaxColor("MaxColor", Color) = (1,1,1,1)
        _MinColor("MinColor", Color) = (0,0,0,1)
        _Displacement("Displacement Factor", Range(0, 1.0)) = 0.1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
			#define UNITY_PASS_FORWARDBASE
			#include "UnityCG.cginc"
			#include "AutoLight.cginc"
			#include "Lighting.cginc"
			#pragma multi_compile_fwdbase_fullshadows


            float _Pow, _LogScale;
            float4 _MaxColor, _MinColor;
            float _Displacement;

            struct appdata
            {
                float4 vertex : POSITION;       //local vertex position
				float3 normal : NORMAL;         //normal direction
				float4 tangent : TANGENT;       //tangent direction    
				float2 texcoord0 : TEXCOORD0;   //uv coordinates
				float2 texcoord1 : TEXCOORD1;   //lightmap uv coordinates
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
                float2 lightmap_uv : TEXCOORD1;
                float3 normalDir : TEXCOORD3;
                float3 posWorld : TEXCOORD4;
            };

            sampler2D _FullSpectrum;
            float4 _FullSpectrum_ST;
            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
                o.uv = v.texcoord0;
                o.lightmap_uv = v.texcoord1;
                o.normalDir = UnityObjectToWorldNormal(v.normal);
                TRANSFER_VERTEX_TO_FRAGMENT(o);
                float3 dcolor = tex2Dlod (_FullSpectrum, float4(o.uv * _FullSpectrum_ST.xy, 0, 0));
                float height = length(dcolor);
                v.vertex.xyz += v.normal * height * _Displacement;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.posWorld = mul(unity_ObjectToWorld, v.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float4 t = tex2D(_FullSpectrum, i.uv.xy);
                return t;
            }
            ENDCG
        }
    }
}
