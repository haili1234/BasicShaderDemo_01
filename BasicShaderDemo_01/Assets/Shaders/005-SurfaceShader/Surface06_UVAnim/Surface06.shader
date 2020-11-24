Shader "Custom/Surface06"
{
    Properties
    {
        [HDR]_Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
		_DistortTexture("Distort Texture", 2D) = "bump"{}
		_Speed ("_Speed", float) = 0
		_UVDisIntensity("UVDisIntensity", Range(0,1)) = 0
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue"="Geometry"}
        LOD 200

        CGPROGRAM
        // Physically based Standard lighting model, and enable shadows on all light types
        #pragma surface surf Standard fullforwardshadows

        // Use shader model 3.0 target, to get nicer looking lighting
        #pragma target 3.0

        sampler2D _MainTex;
		sampler2D _DistortTexture;

        struct Input
        {
            float2 uv_MainTex;
        };

        half _Glossiness;
        half _Metallic;
		half _Speed;
		half _UVDisIntensity;
        fixed4 _Color;

        // Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
        // See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
        // #pragma instancing_options assumeuniformscaling
        UNITY_INSTANCING_BUFFER_START(Props)
            // put more per-instance properties here
        UNITY_INSTANCING_BUFFER_END(Props)

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
			float2 uv1 = IN.uv_MainTex + _Time.y * _Speed * float2(-1,-1);
			float2 uv2 = IN.uv_MainTex + _Time.y * _Speed * float2(1,1);
			float3 Distort = UnpackScaleNormal(tex2D(_DistortTexture,IN.uv_MainTex),_UVDisIntensity);
			float4 mainTex1 = tex2D(_MainTex, (float3(uv1,0) + Distort).xy);
			float4 mainTex2 = tex2D(_MainTex, (float3(uv2,0) + Distort).xy);
			float4 color = _Color * mainTex1 * mainTex2;
            // Albedo comes from a texture tinted by color
            //fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;
            o.Albedo = color;
			o.Emission = color;
            // Metallic and smoothness come from slider variables
            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
            o.Alpha = 1;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
