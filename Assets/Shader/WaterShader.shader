Shader "Unlit/WaterShader"
{
    Properties { }
     SubShader
     {
        Lighting Off
        Blend One Zero

        Pass
        {
            CGPROGRAM
            #include "UnityCustomRenderTexture.cginc"
            #pragma vertex CustomRenderTextureVertexShader
            #pragma fragment frag
            #pragma target 3.0

            sampler2D _MainTex;

            float4 frag(v2f_customrendertexture IN) : COLOR
            {   
                float2 uv = IN.localTexcoord.xy;
                float n_1 = tex2D(_MainTex, uv).x;
                float n_0 = tex2D(_SelfTexture2D, uv).x;
                float nl = tex2D(_MainTex, uv + float2(1,0)).x;
                float nr = tex2D(_MainTex, uv - float2(1,0)).x;
                float nu = tex2D(_MainTex, uv + float2(0,1)).x;
                float nd = tex2D(_MainTex, uv - float2(0,1)).x;
                float height = n_1 * 2 - n_0 / 4 * (nl + nr + nu + nd - 4 * n_1);
                return distance(uv, float2(.5, .5)) > 0.1f
                    ? float4(height, 1, 1, 1)
                    : float4(1,1,1,1);
            }
            ENDCG
		}
    }
}
