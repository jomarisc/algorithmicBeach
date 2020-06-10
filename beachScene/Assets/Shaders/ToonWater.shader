Shader "Roystan/Toon/Water"
{
    Properties
    {	
        //Gradient for shallow and deep water
        _DepthGradientShallow("Depth Gradient Shallow", Color) = (0.325, 0.807, 0.971, 0.725)
        _DepthGradientDeep("Depth Gradient Deep", Color) = (0.086, 0.407, 1, 0.749)
        _DepthMaxDistance("Depth Maximum Distance", Float) = 1
        //For our noise texture property
        _SurfaceNoise("Surface Noise", 2D) = "white" {}
        //Make waves binary, for more toony look
        _SurfaceNoiseCutoff("Surface Noise Cutoff", Range(0, 1)) = 0.777
        //Contrl for what Depth the shoreline is visible.
        _FoamMaxDistance("Foam Maximum Distance", Float) = 0.4
        _FoamMinDistance("Foam Minimum Distance", Float) = 0.04
        //Property to control scroll speed, in UVs per second.
        _SurfaceNoiseScroll("Surface Noise Scroll Amount", Vector) = (0.03, 0.03, 0, 0)

        //Two channel distortion texture
        _SurfaceDistortion("Surface Distortion", 2D) = "white" {}
        //Control to multiply the strength of the distortion
        _SurfaceDistortionAmount("Surface Distortion Amount", Range(0, 1)) = 0.27

        _FoamColor("Foam Color", Color) = (1,1,1,1)
    }
    SubShader
    {
        Tags
        {
            "Queue" = "Transparent"
		}
        
        Pass
        {
            Blend SrcAlpha OneMinusSrcAlpha
            ZWrite Off

			CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #define SMOOTHSTEP_AA 0.01

            #include "UnityCG.cginc"

            float4 alphaBlend(float4 top, float4 bottom) 
            {
                float3 color = (top.rgb * top.a) + (bottom.rgb * (1 - top.a));
                float alpha = top.a + bottom.a * (1 - top.a);


                return float4(color,alpha);
            }


            struct appdata
            {
                float4 uv : TEXCOORD0;
                float4 vertex : POSITION;

                float3 normal : NORMAL;
            };

            struct v2f
            {
                
                //Getting position of vertices to sample the texture.
                float4 screenPosition : TEXCOORD2;
                float4 vertex : SV_POSITION;

                float3 viewNormal : NORMAL;
                
                float2 distortUV : TEXCOORD1;
                float2 noiseUV : TEXCOORD0;
            };

            //Matching sampler to property.
            sampler2D _SurfaceNoise;
            //Unity automatically populates this with tiling and offset data.
            float4 _SurfaceNoise_ST;
            //Matching property variable.
            float _SurfaceNoiseCutoff;
            float _FoamMaxDistance;
            float _FoamMinDistance;
            float2 _SurfaceNoiseScroll;
            
            sampler2D _SurfaceDistortion;
            float4 _SurfaceDistortion_ST;

            float _SurfaceDistortionAmount;

            sampler2D _CameraNormalsTexture;

            float4 _FoamColor;

            v2f vert (appdata v)
            {
                v2f o;
                
                o.vertex = UnityObjectToClipPos(v.vertex);
                //Getting position of vertices to sample the texture.
                o.screenPosition = ComputeScreenPos(o.vertex);
                //UV data is declared here, then passed to fragment shader.
                o.noiseUV = TRANSFORM_TEX(v.uv, _SurfaceNoise);
                o.distortUV = TRANSFORM_TEX(v.uv, _SurfaceDistortion);
                return o;
            }

            //Declaring Properties
            float4 _DepthGradientShallow;
            float4 _DepthGradientDeep;
            
            float _DepthMaxDistance;

            sampler2D _CameraDepthTexture;

            float4 frag (v2f i) : SV_Target
            {
                //Screen position of verts now available.
                //Sample the depth texture using tex2Dproj and screenPosition
                float existingDepth01 = tex2Dproj(_CameraDepthTexture, UNITY_PROJ_COORD(i.screenPosition)).r;
                //Convert the non-linear depth to be linear.
                float existingDepthLinear = LinearEyeDepth(existingDepth01);
                float depthDifference = existingDepthLinear - i.screenPosition.w;

                //Calculate color of water based on depth, compared to our maximum depth.
                float waterDepthDifference01 = saturate(depthDifference/_DepthMaxDistance);
                float4 waterColor = lerp(_DepthGradientShallow, _DepthGradientDeep, waterDepthDifference01);

                float3 existingNormal = tex2Dproj(_CameraNormalsTexture, UNITY_PROJ_COORD(i.screenPosition));
                float3 normalDot = saturate(dot(existingNormal, i.viewNormal));

                float foamDistance = lerp (_FoamMaxDistance, _FoamMinDistance, normalDot);
                float foamDepthDifference01 = saturate(depthDifference / foamDistance);
                float surfaceNoiseCutoff = foamDepthDifference01 * _SurfaceNoiseCutoff;

                float2 distortSample = (tex2D(_SurfaceDistortion, i.distortUV).xy * 2 - 1) * _SurfaceDistortionAmount;

                float2 noiseUV = float2( (i.noiseUV.x + _Time.y * _SurfaceNoiseScroll.x) + distortSample.x, (i.noiseUV.y + _Time.y * _SurfaceNoiseScroll.y) + distortSample.y);
         
                //Sample the noise texture.
                float surfaceNoiseSample = tex2D(_SurfaceNoise, noiseUV).r;
                //Adjust the noise.
                //float surfaceNoise = surfaceNoiseSample > surfaceNoiseCutoff ? 1 : 0;
                float surfaceNoise = smoothstep(surfaceNoiseCutoff - SMOOTHSTEP_AA, surfaceNoiseCutoff + SMOOTHSTEP_AA, surfaceNoiseSample);
                float4 surfaceNoiseColor = _FoamColor;
                surfaceNoiseColor.a *= surfaceNoise;

				return alphaBlend(surfaceNoiseColor, waterColor);
            }
            ENDCG
        }
    }
}