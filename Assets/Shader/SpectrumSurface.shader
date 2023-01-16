Shader "Custom/SpectrumSurface"
{
    Properties
    {
		_Color ("Tint", Color) = (0, 0, 0, 1)
        _MainTex ("Texture", 2D) = "white" {}
        _Smoothness ("Smoothness", Range(0, 1)) = 0
        _Metallic ("Metalness", Range(0, 1)) = 0
        [HDR] _Emission ("Emission", Color) = (0,0,0)
        _Displacement ("Displacement", Float) = 1
        _DispMap ("Displacement Texture", 2D) = "black" 
    }
    SubShader
    {
        //the material is completely non-transparent and is rendered at the same time as the other opaque geometry
        Tags{ "RenderType"="Opaque" "Queue"="Geometry"}
        CGPROGRAM
        // Physically based Standard lighting model, and enable shadows on all light types
         #pragma surface surf Standard fullforwardshadows vertex:vert addshadow

        // Use shader model 3.0 target, to get nicer looking lighting
        #pragma target 3.0
		#pragma glsl


		sampler2D _FullSpectrum;
		sampler2D _DispMap;
		sampler2D _MainTex;

        struct Input
        {
            float2 uv_FullSpectrum;
            float2 uv_MainTex;
        };
		fixed4 _Color;
        half _Smoothness;
        half _Metallic;
        half3 _Emission;
        float _Displacement;

        // Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
        // See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
        // #pragma instancing_options assumeuniformscaling
        UNITY_INSTANCING_BUFFER_START(Props)
            // put more per-instance properties here
        UNITY_INSTANCING_BUFFER_END(Props)

        
        void vert(inout appdata_full data, out Input o){
            UNITY_INITIALIZE_OUTPUT(Input, o);
			fixed height = length(tex2Dlod (_DispMap, float4(data.texcoord.xy, 0, 0)));
            data.vertex.xyz += float3(0, 1, 0) * height * _Displacement;
        }

        //the surface shader function which sets parameters the lighting function then uses
        void surf (Input i, inout SurfaceOutputStandard o) {
            //sample and tint albedo texture
            fixed4 col = tex2D(_DispMap, i.uv_MainTex);
            col *= _Color;
            o.Albedo = col.rgb;
            //just apply the values for metalness, smoothness and emission
            o.Metallic = _Metallic;
            o.Smoothness = _Smoothness;
            o.Emission = _Emission;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
