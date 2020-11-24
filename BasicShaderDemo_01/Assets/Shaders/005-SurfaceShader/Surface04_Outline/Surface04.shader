Shader "Custom/Surface04"
{
   Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _Glossiness ("Smoothness", Range(0,150)) = 120
        _Metallic ("Metallic", Range(0,1)) = 0.0
		_BumpMap("Bumpmap", 2D) = "bump"{}
		_BunmScale("BunmScale",float) = 1
		_ColorTint("Tint", Color) = (1,1,1,1)
		_RimColor("RimColor", Color) = (1,0,0,1)
		_RimPower("RimPower", Range(0.1,8.0)) = 1
		_Steps("Steps", Range(1,30)) = 1
		_ToonEffect("ToonEffect", Range(0,1)) = 0.5
		_Outline("Outline", Range(0,1)) = 0.5
		_OutlineColor("OutlineColor", Color)= (0,0,0,0)
		//Xray
		_XRayColor("XRayColor", Color) =(1,1,1,1)
		_XRayPower("XRayPower", Range(0.0001,3)) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

		Pass
		{
			Blend SrcAlpha One 
			ZWrite Off
			ZTest Greater
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"

			fixed4 _XRayColor;
			float _XRayPower;

			struct v2f
			{
				float4 vertex: SV_POSITION;
				float3  viewDir :TEXCOORD0;
				float3 normal :TEXCOORD1;
			};

			v2f vert(appdata_base v)
			{
				v2f o;
				o.vertex =  UnityObjectToClipPos(v.vertex);
				o.normal = v.normal;
				o.viewDir = ObjSpaceViewDir(v.vertex);
				return o;
			}

			fixed4 frag(v2f i):SV_Target
			{
				float rim = 1 - dot(normalize(i.normal),normalize( i.viewDir));
				return _XRayColor * pow(rim,1/_XRayPower);
			}
				
			ENDCG
		}

		Pass
		{
			Name "Outline"
			Cull Front
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"

			float _Outline;
			fixed4 _OutlineColor;

			struct v2f
			{
				float4 vertex : SV_POSITION;
			};

			v2f vert(appdata_base v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				float3 normal = normalize(mul((float3x3)UNITY_MATRIX_IT_MV, v.normal));
				float2 viewNormal = TransformViewToProjection(normal.xy);
				o.vertex.xy += viewNormal * _Outline;
				return o;
			}

			float4 frag(v2f i) : SV_Target
			{
				return _OutlineColor;
			}

			ENDCG
		}

        CGPROGRAM
        // Physically based Standard lighting model, and enable shadows on all light types
        #pragma surface surf Toon fullforwardshadows nolightmap finalcolor:final

        // Use shader model 3.0 target, to get nicer looking lighting
        #pragma target 3.0

        sampler2D _MainTex;
		sampler2D _BumpMap;
		float _BunmScale;

        struct Input
        {
            float2 uv_MainTex;
			float2 uv_BumpMap;
			float3 viewDir;
        };

        half _Glossiness;
        half _Metallic;
        fixed4 _Color;
		fixed4 _ColorTint;
		fixed4 _RimColor;
		float _RimPower;
		float _Steps;
		float _ToonEffect;

		half4 LightingToon(SurfaceOutput s, half3 lightDir, half3 viewDir, half atten)
		{
			float difLight = dot(lightDir, s.Normal) * 0.5 + 0.5;

			difLight = smoothstep(0,1,difLight);
			float toon = floor(difLight * _Steps)/ _Steps;
			difLight = lerp(difLight, toon, _ToonEffect);

			fixed3 diffuse = _LightColor0 * s.Albedo * difLight;

			fixed3 halfDir = normalize(lightDir + viewDir);
			fixed3 specular = _LightColor0.rgb * _Color.rgb * pow(max(0,dot(s.Normal, halfDir)), s.Gloss );

			return half4(diffuse + specular,1);
		}

        // Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
        // See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
        // #pragma instancing_options assumeuniformscaling
        UNITY_INSTANCING_BUFFER_START(Props)
            // put more per-instance properties here
        UNITY_INSTANCING_BUFFER_END(Props)

        void surf (Input IN, inout SurfaceOutput o)
        {
            // Albedo comes from a texture tinted by color
            fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;
            o.Albedo = c.rgb;
            // Metallic and smoothness come from slider variables
            o.Specular = _Metallic;
            o.Gloss = _Glossiness;
            o.Alpha = c.a;
			float3 normal = UnpackNormal(tex2D(_BumpMap, IN.uv_BumpMap));
			normal.xy *= _BunmScale;
			o.Normal = normal;
			half rim = 1.0 - saturate(dot(normalize(IN.viewDir), o.Normal));
			o.Emission = _RimColor.rgb * pow(rim, _RimPower);
        }

		void final(Input IN, SurfaceOutput o, inout fixed4 color)		{
			color *= _ColorTint;
		}
        ENDCG
    }
    FallBack "Diffuse"
}
