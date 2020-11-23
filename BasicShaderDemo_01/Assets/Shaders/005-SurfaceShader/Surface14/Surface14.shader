Shader "Custom/Surface14"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
		_SonwTex("SnowTex",2D) = "white"{}
		_NormalTex("Noraml", 2D) = "bump"{}
		_SnowDir("SnowDir",Vector) = (0,1,0)
		_SnowAmount("_SnowAmount", Range(0,2)) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        CGPROGRAM
        // Physically based Standard lighting model, and enable shadows on all light types
        #pragma surface surf StandardSpecular fullforwardshadows

        // Use shader model 3.0 target, to get nicer looking lighting
        #pragma target 3.0

        sampler2D _MainTex;
		sampler2D _NormalTex;
		sampler2D _SonwTex;

        struct Input
        {
            float2 uv_MainTex;
			float2 uv_NormalTex;
			float2 uv_SonwTex;
			float3 worldNormal; 			INTERNAL_DATA
        };

        half _Glossiness;
        half _Metallic;
        fixed4 _Color;
		float4 _SnowDir;
		half _SnowAmount;

        // Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
        // See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
        // #pragma instancing_options assumeuniformscaling
        UNITY_INSTANCING_BUFFER_START(Props)
            // put more per-instance properties here
        UNITY_INSTANCING_BUFFER_END(Props)

        void surf (Input IN, inout SurfaceOutputStandardSpecular o)
        {
			float3 normalTex = UnpackNormal(tex2D(_NormalTex, IN.uv_NormalTex));
			o.Normal = normalTex;
			fixed3 wNormal = WorldNormalVector(IN, normalTex);

			float lerpVal = saturate(dot(wNormal, _SnowDir.xyz));
            // Albedo comes from a texture tinted by color
            fixed4 c = lerp( tex2D (_MainTex, IN.uv_MainTex), tex2D(_SonwTex, IN.uv_SonwTex), lerpVal * _SnowAmount) * _Color;
            o.Albedo = c.rgb;
            // Metallic and smoothness come from slider variables
            o.Alpha = c.a;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
