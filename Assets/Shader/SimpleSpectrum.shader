Shader "Unlit/SimpleSpectrum"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Pow("Pow", Float) = 2
        _LogScale("LogScale", Float) = 1
        _MaxColor("MaxColor", Color) = (1,1,1,1)
        _MinColor("MinColor", Color) = (0,0,0,1)
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

            #include "UnityCG.cginc"

            float _Pow, _LogScale;
            float4 _MaxColor, _MinColor;

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            sampler2D _Spectrum;
            sampler2D _MainTex;
            float4 _MainTex_ST;

			float3 HUEtoRGB(in float H) {
				float R = abs(H * 6 - 3) - 1;
				float G = 2 - abs(H * 6 - 2);
				float B = 2 - abs(H * 6 - 4);
				return saturate(float3(R,G,B));
			}

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.uv.x = pow(1 - o.uv.x, _LogScale);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float x = i.uv.x;
                float val = 1 - tex2D(_Spectrum, x);
                return pow(i.uv.y,_Pow) >= val ? float4(HUEtoRGB(x), 1): _MinColor;
            }
            ENDCG
        }
    }
}
