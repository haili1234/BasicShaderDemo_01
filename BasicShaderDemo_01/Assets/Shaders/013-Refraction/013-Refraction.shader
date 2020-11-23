Shader "Custom/013-Refraction"
{
	Properties
	{
		_MainTex("Texture", 2D) = "white" {}
		_CubeMap("Cubemap", Cube) = "_Skybox"{}
		_RefractColor("ReflectionColor",Color) = (1,1,1,1)
		_RefractAmount("ReflectionAmount", Range(0,1)) = 1
		_RefracRotio("RefracRotio",Range(0,1)) = 0.5
	}
		SubShader
		{
			Tags { "RenderType" = "Opaque" }
			LOD 100

			Pass
			{
				CGPROGRAM
				#pragma vertex vert
				#pragma fragment frag
				// make fog work
				#pragma multi_compile_fog

				#include "UnityCG.cginc"
				#include "Lighting.cginc"

				struct appdata
				{
					float4 vertex : POSITION;
					float2 uv : TEXCOORD0;
					float3 normal: NORMAL;
				};

				struct v2f
				{
					float2 uv : TEXCOORD0;
					UNITY_FOG_COORDS(1)
					float4 vertex : SV_POSITION;
					float3 worldPos : TEXCOORD02;
					float3 worldNormal : TEXCOORD03;
					float3 worldViewDir : TEXCOORD04;
					float3 worldRefr : TEXCOORD05;
				};

				fixed4 _RefractColor;
				samplerCUBE _CubeMap;
				half _RefractAmount;
				sampler2D _MainTex;
				float4 _MainTex_ST;
				fixed _RefracRotio;

				v2f vert(appdata v)
				{
					v2f o;
					o.vertex = UnityObjectToClipPos(v.vertex);
					o.uv = TRANSFORM_TEX(v.uv, _MainTex);
					o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
					o.worldNormal = UnityObjectToWorldNormal(v.normal);
					o.worldViewDir = UnityWorldSpaceViewDir(o.worldPos);
					o.worldRefr = refract(-normalize(o.worldViewDir), normalize(o.worldNormal), _RefracRotio);
					UNITY_TRANSFER_FOG(o,o.vertex);
					return o;
				}

				fixed4 frag(v2f i) : SV_Target
				{
					fixed3 worldNormal = normalize(i.worldNormal);
					fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
					fixed3 worldViewDir = normalize(i.worldViewDir);

					fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;

					// sample the texture
					fixed3 diffuse = tex2D(_MainTex, i.uv).rgb * _LightColor0.rgb * max(0,dot(worldNormal,worldLightDir));

					fixed3 refection = texCUBE(_CubeMap, i.worldRefr).rgb * _RefractColor;

					fixed3 col = ambient + lerp(diffuse, refection, _RefractAmount);
					// apply fog
					UNITY_APPLY_FOG(i.fogCoord, col);
					return fixed4(col,1);
				}
				ENDCG
			}
		}
}
