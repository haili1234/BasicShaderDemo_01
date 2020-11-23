Shader "Custom/Test_Deferred"
{
    Properties
    {

    }
    SubShader
    {
        Pass
        {
			ZWrite Off
			//LDR Blend DstColor Zero    HDR : Blend One One
			Blend [_SrcBlend] [_DstBlend]
            CGPROGRAM
			#pragma target 3.0
            #pragma vertex vert
            #pragma fragment frag
			#pragma multi_compile_lightpass
			//代表排除不支持MRT的硬件
			//#pragma exclude_renderers norm
			#pragma multi_compile __ UNITY_HDR_ON

			#include "UnityCG.cginc"
			#include "UnityDeferredLibrary.cginc"
			#include "UnityGBuffer.cginc"

			sampler2D _CameraGBufferTexture0;
			sampler2D _CameraGBufferTexture1;
			sampler2D _CameraGBufferTexture2;

			struct a2v
			{
				float4 vertex : POSITION;
				float3 normal :NORMAL;
			};

			//struct v2f
			//{
			//	float4 pos : SV_POSITION;
			//	float4 uv :TEXCOORD0;
			//	float3 ray : TEXCOORD1;
			//};

			unity_v2f_deferred vert(a2v i)
			{
				unity_v2f_deferred o;
				o.pos = UnityObjectToClipPos(i.vertex);
				o.uv = ComputeScreenPos(o.pos);
				o.ray = UnityObjectToViewPos(i.vertex) * float3(-1,-1,1);
				//_LightAsQuad  当在处理四边形时，也就是直射光时返回1，否则返回0
				o.ray = lerp(o.ray, i.normal, _LightAsQuad);
				return o;
			}

			#ifdef	UNITY_HDR_ON
			half4
			#else
			fixed4
			#endif
			frag(unity_v2f_deferred i) : SV_Target
			{
				float3 worldPos;
				float2 uv;
				half3 lightDir;
				float atten;
				float fadeDist;
				UnityDeferredCalculateLightParams(i,worldPos,uv,lightDir, atten,fadeDist);

				//float2 uv = i.uv.xy/i.uv.w;

				////通过深度和方向重新构建世界坐标
				//float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, uv);
				//depth = Linear01Depth(depth);
				////ray 只能表示方向，长度不一定   _ProjectionParams.z是远平面， 因为xyz都是等比例，所以 _ProjectionParams.z/i.ray.z就是 rayToFraPlane向量和ray向量的比值
				//float3 rayToFraPlane = i.ray * (_ProjectionParams.z/i.ray.z);
				//float4 viewPos = float4(rayToFraPlane * depth,1);
				//float3 worldPos = mul(unity_CameraToWorld, viewPos).xyz;

				//float fadeDist = UnityComputeShadowFadeDistance(worldPos, viewPos.z);

				////对不同的光进行光衰减计算 包括阴影计算
				//#if defined(SPOT)
				//	float3 toLight = _LightPos.xyz-worldPos;
				//	half3 lightDir = normalize(toLight);

				//	float4 uvCookie = mul(unity_WorldToLight, float4(worldPos,1));
				//	float atten = tex2Dbias(_LightTexture0, float4(uvCookie.xy/uvCookie.w,0,-8)).w;

				//	atten *= uvCookie < 0;

				//	atten *= tex2D(_LightTextureB0, dot(toLight,toLight) * _LightPos.w).r;

				//	atten *= UnityDeferredComputeShadow(worldPos, fadeDist, uv);
				//#elif defined(DIRECTIONAL) || defined(DIRECTIONAL_COOKIE)
				//	half3 lightDir = -_LightDir.xyz;
				//	float atten = 1.0;

				//	atten *= UnityDeferredComputeShadow(worldPos, fadeDist, uv);

				//	#if defined(DIRECTIONAL_COOKIE)
				//	float4 uvCookie = mul(unity_WorldToLight, float4(worldPos,1));
				//	atten *= tex2Dbias(_LightTexture0, float4(uvCookie.xy,0,-8)).w;
				//	#endif

				//#elif defined(POINT) || defined(POINT_COOKIE)
				//	float3 toLight = _LightPos.xyz-worldPos;
				//	half3 lightDir = normalize(toLight);

				//	float atten = tex2D(_LightTextureB0, dot(toLight,toLight) * _LightPos.w).r;

				//	atten *= UnityDeferredComputeShadow(worldPos, fadeDist, uv);

				//	#if defined(POINT_COOKIE)
				//	float4 uvCookie = mul(unity_WorldToLight, float4(worldPos,1));
				//	atten *= texCUBEbias(_LightTexture0, float4(uvCookie.xyz, -8)).w;
				//	#endif
				//#else
				// half3 lightDir = 0;
				// float atten = 0;
				//#endif

				half3 lightColor = _LightColor.rgb * atten;

				half4 gbuffer0 = tex2D(_CameraGBufferTexture0, uv);
				half4 gbuffer1 = tex2D(_CameraGBufferTexture1, uv);
				half4 gbuffer2 = tex2D(_CameraGBufferTexture2, uv);

				half3 diffuseColor = gbuffer0.rgb;
				half3 specularColor = gbuffer1.rgb;
				float gloss = gbuffer1.a * 50;
				float3 worldNormal = normalize(gbuffer2.xyz * 2 - 1);

				fixed3 viewDir = normalize(_WorldSpaceCameraPos - worldPos);
				fixed3 halfDir = normalize(lightDir + viewDir);

				half3 diffuse = lightColor * diffuseColor * max(0,dot(worldNormal,lightDir));
				half3 specular = lightColor * specularColor * pow(max(0,dot(worldNormal,halfDir)),gloss);

				half4 color = float4(diffuse + specular,1);
				#ifdef UNITY_HDR_ON
				return color;
				#else 
				return exp2(-color);
				#endif
				
			}
            ENDCG
        }

		
		//转码pass，主要是对于LDR转码
		Pass 
		{
			ZTest Always
			Cull Off
			ZWrite Off
			Stencil
			{
				ref[_StencilNonBackground]
				readMask[_StencilNonBackground]

				compback equal
				compfront equal
			}

			CGPROGRAM
			#pragma target 3.0
			#pragma vertex vert
			#pragma fragment frag
			#pragma exclude_renderers nomrt

			#include "UnityCG.cginc"

			sampler2D _LightBuffer;
			struct v2f
			{
				float4 vertex:SV_POSITION;
				float2 texcoord: TEXCOORD0;
			};

			v2f vert(float4 vertex:POSITION,float2 texcoord :TEXCOORD0)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(vertex);
				o.texcoord = texcoord.xy;
				#ifdef UNITY_SINGLE_PASS_STEREO
				o.texcoord = TransformStereoScreenSpaceTex(o.texcoord,1.0);
				#endif
				return o;
			}

			fixed4 frag(v2f i) :SV_Target
			{
				return -log2(tex2D(_LightBuffer,i.texcoord));
			}
			ENDCG
		}
    }
}
