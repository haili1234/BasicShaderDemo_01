Shader "Custom/004-Shadow3"
{
      Properties
    {
		_MainTex("MainTex", 2D) = "white" {}
		_Color("Diffuse",Color) = (1,1,1,1)
		_Specular("Specular", Color) = (1,1,1,1)
		_Gloss("Gloss", Range(8.0, 256)) = 20
		_AlphaScale("Alpha", Range(0,1)) = 0.5
    }
    SubShader
    {
        Tags { "RenderType" = "Transparent" "Queue"="Transparent" "IgnoreProjector" = "True"}
		LOD 100

		Pass
		{
			Tags{"LightMode" = "ForwardBase"}

			ZWrite off
			Blend SrcAlpha OneMinusSrcAlpha

			CGPROGRAM
			#pragma multi_compile_fwdbase
			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "AutoLight.cginc"

			fixed4 _Color;
			fixed4 _Specular;
			float _Gloss;
			fixed _AlphaScale;
			sampler2D _MainTex;
			float4 _MainTex_ST;

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
				float3 normal:NORMAL;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
				float3 worldNormal : TEXCOORD0;
				float3 worldPos:TEXCOORD1;
				float3 vertexLight : TEXCOORD2;
				SHADOW_COORDS(3) //仅仅是阴影
				float2 uv : TEXCOORD4;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
				o.worldNormal = UnityObjectToWorldNormal(v.normal);
				o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				//仅仅是阴影
				TRANSFER_SHADOW(o);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
				fixed3 worldNormal = normalize(i.worldNormal);
				fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;

				fixed4 texColor = tex2D(_MainTex, i.uv);

				fixed3 diffuse = texColor * _LightColor0.rgb * _Color.rgb * max(0, dot(worldNormal,worldLightDir));

				fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz);
				fixed3 halfDir = normalize(worldLightDir + viewDir);
				fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0,dot(worldNormal,halfDir)),_Gloss);

				//fixed shadow = SHADOW_ATTENUATION(i);

				//这个函数计算包含了光照衰减已经阴影,因为ForwardBase逐像素光源一般是方向光，衰减为1，atten在这里实际是阴影值
				UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);

                return fixed4((ambient + (diffuse + specular) * atten + i.vertexLight), texColor.a * _AlphaScale);
            }
            ENDCG
        }

		//Pass
		//{
		//	Tags{"LightMode" = "ForwardAdd"}

		//	Blend One One

		//	CGPROGRAM
		//	#pragma multi_compile_fwdadd_fullshadows
		//	#pragma vertex vert
		//	#pragma fragment frag

		//	#include "Lighting.cginc"
		//	#include "AutoLight.cginc"

		//	fixed4 _Color;
		//	fixed4 _Specular;
		//	float _Gloss;

		//	struct a2v
		//	{
		//		float4 vertex:POSITION;
		//		float3 normal :NORMAL;
		//	};

		//	struct v2f
		//	{
		//		float4 pos :SV_POSITION;
		//		float3 worldNormal : TEXCOORD0;
		//		float3 worldPos : TEXCOORD1;
		//		LIGHTING_COORDS(2,3) //包含光照衰减以及阴影
		//	};

		//	v2f vert(a2v v)
		//	{
		//		v2f o;
		//		o.pos = UnityObjectToClipPos(v.vertex);
		//		o.worldNormal = UnityObjectToWorldNormal(v.normal);
		//		o.worldPos = mul(unity_ObjectToWorld,v.vertex).xyz;
		//		//包含光照衰减以及阴影
		//		TRANSFER_VERTEX_TO_FRAGMENT(o);
		//		return o;
		//	}

		//	fixed4 frag(v2f i):SV_Target
		//	{
		//		fixed3 worldNormal = normalize(i.worldNormal);
		//		fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));

		//		fixed3 diffuse = _LightColor0.rgb * _Color.rgb * max(0,dot(worldNormal,worldLightDir));

		//		fixed3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
		//		fixed3 halfDir = normalize(worldLightDir + viewDir);
		//		fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0,dot(viewDir,halfDir)),_Gloss);

		//		//fixed atten = LIGHT_ATTENUATION(i);
		//		////包含光照衰减以及阴影
		//		UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);

		//		return fixed4((diffuse+ specular)*atten,1.0);
		//	}

		//	ENDCG
		//}
    }
	FallBack "Diffuse"
	//FallBack "Transparent/Cutout/VertexLit"
}
