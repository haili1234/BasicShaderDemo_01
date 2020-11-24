Shader "Custom/Surface10"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
		_Normal("Normal", 2D) = "bump" {}
		_NormalScale("NormalScale", Range(0,5)) = 1
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0
		_DisolveTex("DisolveTex",2D) = "white"{}
		_Threshold("Threshold",Range(0,1)) = 0
		_EdgeLength("EdgeLength", Range(0,0.2)) = 0.1
		_BurnTex("BurnTex", 2D) = "white"{}
		_BurnInstensity("BurnInstensity", Range(0,5)) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        CGPROGRAM
        // Physically based Standard lighting model, and enable shadows on all light types
        #pragma surface surf Standard fullforwardshadows

        // Use shader model 3.0 target, to get nicer looking lighting
        #pragma target 3.0

        sampler2D _MainTex;
		sampler2D _Normal;
		half _NormalScale;
		sampler2D _DisolveTex;
		half _Threshold;
		sampler2D _BurnTex;
		half _EdgeLength;
		half _BurnInstensity;

        struct Input
        {
            float2 uv_MainTex;
			float2 uv_Normal;
			float2 uv_DisolveTex;
        };

        half _Glossiness;
        half _Metallic;
        fixed4 _Color;

        // Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
        // See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
        // #pragma instancing_options assumeuniformscaling
        UNITY_INSTANCING_BUFFER_START(Props)
            // put more per-instance properties here
        UNITY_INSTANCING_BUFFER_END(Props)

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            // Albedo comes from a texture tinted by color
            fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;
			o.Normal = UnpackScaleNormal(tex2D(_Normal, IN.uv_Normal),_NormalScale);
            o.Albedo = c.rgb;

			float cutout = tex2D(_DisolveTex, IN.uv_DisolveTex).r;
			clip(cutout - _Threshold);
			float temp = saturate((cutout - _Threshold) / _EdgeLength);
			fixed4 edgeColor = tex2D(_BurnTex,float2(temp,temp));
			fixed4 finalColor = _BurnInstensity * lerp(edgeColor, fixed4(0,0,0,0), temp);
			o.Emission = finalColor.rgb;
            // Metallic and smoothness come from slider variables
            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
            o.Alpha = c.a;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
