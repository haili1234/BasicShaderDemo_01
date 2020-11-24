Shader "Custom/Surface07"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
		_MainMix("MainMix", Range(0,1)) = 0.5
		_Nomral("Normal", 2D) = "bump"{}
		//此贴图属于正常，不是normal map, alpha通道另有它用
		_BurnNormal("BurnNormal", 2D) = "white" {}
		_NormalTill("NormalTill", Range(0,5)) = 1

		_Mask("Mask", 2D) = "white"{}
		_BurnTill("BurnTill", float) = 1
		_BurnOffset("BurnOffset", float) = 1
		_BurnRange("BurnRange",  Range(0,1)) = 0.5

		_BurnColor("BurnColor", Color) = (0,0,0,0)

		//Glow参数
		_GlowColor("GlowColor", Color) = (1,1,1,1)
		_GlowIntensity("GlowIntensity",Range(0,2)) = 0.5
		_GlowFrequency("GlowFrequency",Range(0,5)) = 0.5
		_GlowOverride("GlowOverride", Range(0,2)) = 0.5
		_GlowEmission("GlowEmission",  Range(0,2)) = 0.5

		_Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue" ="Geometry"}
        LOD 200

        CGPROGRAM
        // Physically based Standard lighting model, and enable shadows on all light types
        #pragma surface surf Standard fullforwardshadows

        // Use shader model 3.0 target, to get nicer looking lighting
        #pragma target 3.0

        sampler2D _MainTex;
		sampler2D _Nomral;
		sampler2D _BurnNormal;
		half _NormalTill;
		sampler2D _Mask;
		half _BurnTill;
		half _BurnOffset;
		half _BurnRange;
		half _MainMix;
		fixed4 _BurnColor;
		fixed4 _GlowColor;
		half _GlowIntensity;
		half _GlowFrequency;
		half _GlowOverride;
		half _GlowEmission;

        struct Input
        {
            float2 uv_MainTex;
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
			float3 normal1 = UnpackNormal(tex2D(_Nomral, IN.uv_MainTex));
			fixed4 burnTexture = tex2D(_BurnNormal, IN.uv_MainTex * _NormalTill);
			fixed4 burnNormal = fixed4(1, burnTexture.g, 0, burnTexture.r);
			float3 normal2 = UnpackNormal(burnNormal);
			float2 maskUv = IN.uv_MainTex * _BurnTill + _BurnOffset * float2(1,1);
			fixed3 maskColor = tex2D(_Mask, maskUv);
			float maskR = _BurnRange + maskColor.r;
			o.Normal = lerp(normal1,normal2, maskR);
            // Albedo comes from a texture tinted by color

            fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;
			fixed4 diffuse = lerp(c * _MainMix, _BurnColor ,maskR);
            o.Albedo = diffuse.rgb;

			float4 glow = _GlowColor * _GlowIntensity * ( 0.5f * sin(_Time.y * _GlowFrequency) + _GlowOverride * burnTexture.a);
			//maskColor.r 确定了那部分烧着 ，然后 burnTexture.a 确定了烧着部分哪些地方有火焰
			o.Emission = glow * maskColor.r * burnTexture.a  *  _GlowEmission;
            // Metallic and smoothness come from slider variables
            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
            o.Alpha = diffuse.a;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
