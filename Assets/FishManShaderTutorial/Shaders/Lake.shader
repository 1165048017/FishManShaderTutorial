﻿// create by JiepengTan 2018-04-16  email: jiepengtan@gmail.com
Shader "FishManShaderTutorial/Lake" {
    Properties{
        _MainTex("Base (RGB)", 2D) = "white" {}
		_LoopNum ("_LoopNum", Vector) = (40.,128., 1, 1)
		_BaseWaterColor ("_BaseWaterColor", COLOR) = (.025, .2, .125,0.)
		_LightWaterColor ("_LightWaterColor", COLOR) = (.025, .2, .125,0.)
		waterHeight ("waterHeight", float) =1.0
		lightDir ("lightDir", Vector) =(-0.8,0.4,-0.3,0.)
    }
    SubShader{ 
        Pass {
            ZTest Always Cull Off ZWrite Off
            CGPROGRAM
            float4 _LoopNum = float4(40.,128.,0.,0.);
			//#define USING_PERLIN_NOISE
#pragma vertex vert  
#pragma fragment frag  
#include "ShaderLibs/Framework3D.cginc" 
			
			float3 _BaseWaterColor;
			float3 _LightWaterColor;
			
			float waterHeight = 4.;
			const float2x2 m2 = float2x2( 0.60, -0.80, 0.80, 0.60 );
			const float3x3 m3 = float3x3( 0.00,  0.80,  0.60,
										 -0.80,  0.36, -0.48,
										 -0.60, -0.48,  0.64 );



			//#define lightDir _WorldSpaceLightPos0 
			

			float3 lightDir ;
			float FBM( in float3 p ) {
				float f = 0.0;
				f += 0.5000*Noise( p ); p = mul(m3,p)*2.02;
				f += 0.2500*Noise( p ); p = mul(m3,p)*2.03;
				f += 0.1250*Noise( p ); p = mul(m3,p)*2.01; 
				f += 0.0625*Noise( p );
				return f/0.9375;
			}
			float WaterMap( fixed3 pos ) {
				return fbm( fixed3( pos.xz, ftime )) * 1;
			}

			float3 WaterNormal(float3 pos,float rz){
				float EPSILON = 0.01;
				float3 dx = float3( EPSILON, 0.,0. );
				float3 dz = float3( 0.,0., EPSILON );
					
				float3	normal = float3( 0., 1., 0. );
				float bumpfactor = 0.2 * (1. - smoothstep( 0., 500, rz) );//根据距离所见Bump幅度
				
				normal.x = -bumpfactor * (WaterMap(pos + dx) - WaterMap(pos-dx) ) / (2. * EPSILON);
				normal.z = -bumpfactor * (WaterMap(pos + dz) - WaterMap(pos-dz) ) / (2. * EPSILON);
				return normalize( normal );	
			}


			float3 RayMarchCloud(float3 ro,float3 rd){
				fixed3 col = fixed3(0.0,0.0,0.0);  
				float sundot = clamp(dot(rd,lightDir),0.0,1.0);
               
                 // sky      
                col = float3(0.2,0.5,0.85)*1.1 - rd.y*rd.y*0.5;
                col = lerp( col, 0.85*float3(0.7,0.75,0.85), pow( 1.0-max(rd.y,0.0), 4.0 ) );
                // sun
                col += 0.25*float3(1.0,0.7,0.4)*pow( sundot,5.0 );
                col += 0.25*float3(1.0,0.8,0.6)*pow( sundot,64.0 );
                col += 0.2*float3(1.0,0.8,0.6)*pow( sundot,512.0 );
                // clouds
				col = Cloud(col,ro,rd,float3(1.0,0.95,1.0),1,1);
                // .
                col = lerp( col, 0.68*float3(0.4,0.65,1.0), pow( 1.0-max(rd.y,0.0), 16.0 ) );
				return col;
			}

            float4 ProcessRayMarch(float2 uv,float3 ro,float3 rd,inout float sceneDep,float4 sceneCol){ 
				fixed3 col = RayMarchCloud(ro,rd);
				if(rd.y < -0.01 ) {
					float rz = (-ro.y)/rd.y;
					float3 pos = ro + rd * rz; 
					float3 normal = WaterNormal(pos,rz);
					float ndotr = dot(normal,-rd);
					float fresnel = pow(1.0-abs(ndotr),6.);//计算 
					float3 reflectRd = reflect( rd, normal);
					float3 reflectCol = RayMarchCloud( ro, reflectRd);
  
					float3 diff = pow(dot(normal,lightDir) * 0.4 + 0.6,3.);
					float3 refractCol = _BaseWaterColor + diff * _LightWaterColor * 0.12; 
    
					col = lerp(refractCol,reflectCol,fresnel);
    
					float nrm = (60. + 8.0) / (PI * 8.0);
					float spec=  pow(max(dot(reflectRd,lightDir),0.0),128.) * nrm;
					col += float3(spec,spec,spec);
				}
				col = pow(col,float3(0.8,0.8,0.8));
				
                sceneCol.xyz = col;
                return sceneCol;
            }
            ENDCG
        }//end pass 
    }//end SubShader
    FallBack Off
}



