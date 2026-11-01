shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled, specular_disabled;
uniform vec4 dust_color : source_color = vec4(0.72,0.47,0.29,1.0);
uniform vec4 compact_color : source_color = vec4(0.36,0.19,0.12,1.0);
varying vec3 contact_world;
float hash21(vec2 p) {
	uvec2 q = uvec2(ivec2(p));
	uint h = (q.x*1597334677u)^(q.y*3812015801u);
	h = (h^(h>>16u))*2246822519u;
	return float(h&16777215u)/16777215.0;
}
float noise2(vec2 p) {
	vec2 i=floor(p), f=fract(p); f=f*f*(3.0-2.0*f);
	return mix(mix(hash21(i),hash21(i+vec2(1,0)),f.x),mix(hash21(i+vec2(0,1)),hash21(i+vec2(1,1)),f.x),f.y);
}
float box_distance(vec2 p,vec2 center,vec2 half_size) {
	vec2 q=abs(p-center)-half_size;
	return length(max(q,0.0))+min(max(q.x,q.y),0.0);
}
float bank(vec2 p,vec2 center,vec2 half_size,float warp) {
	float d=box_distance(p,center,half_size)+warp;
	return (1.0-smoothstep(0.05,0.92,d))*smoothstep(-0.16,0.0,d);
}
float track(vec2 p,vec2 a,vec2 b,float width) {
	vec2 ab=b-a;
	float t=clamp(dot(p-a,ab)/dot(ab,ab),0.0,1.0);
	return 1.0-smoothstep(width,width+0.16,length(p-a-ab*t));
}
void vertex(){contact_world=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;}
void fragment(){
	vec2 p=contact_world.xz;
	float broad=noise2(p*2.7);
	float flow=noise2(vec2(p.x*0.65+p.y*0.38,p.y*3.8-p.x*0.7));
	float warp=(broad-0.5)*0.28+(flow-0.5)*0.13;
	float dust=bank(p,vec2(8.3,6.2),vec2(1.23,1.25),warp);
	dust=max(dust,bank(p,vec2(13.2,6.2),vec2(1.86,1.24),warp));
	dust=max(dust,bank(p,vec2(16.1,8.2),vec2(0.84,0.58),warp));
	dust=max(dust,bank(p,vec2(6.5,10.9),vec2(2.50,2.20),warp)*0.70);
	dust=max(dust,bank(p,vec2(19.2,11.8),vec2(2.10,2.05),warp)*0.70);
	// Compacted foot approaches and paired wheel ruts in the loading/service area.
	float worn=track(p,vec2(8.3,7.5),vec2(10.6,9.5),0.13);
	worn=max(worn,track(p,vec2(14.8,7.0),vec2(15.3,9.7),0.12));
	worn=max(worn,track(p,vec2(15.5,7.0),vec2(16.0,9.7),0.12));
	worn=max(worn,track(p,vec2(16.3,8.7),vec2(15.4,10.1),0.09));
	worn*=mix(0.4,1.0,noise2(p*8.0));
	float gravel_patch=1.0-smoothstep(1.0,2.5,length((p-vec2(17.2,6.3))*vec2(0.8,1.0))+warp);
	dust=max(dust,gravel_patch*0.45);
	// Broken, brush-like deposits rather than one clean outline around each prop.
	float pigment=mix(0.91,1.16,flow);
	ALBEDO=mix(dust_color.rgb*pigment,compact_color.rgb,smoothstep(0.12,0.55,worn));
	ALPHA=clamp(max(dust*0.70,worn*0.50)*(0.46+0.32*broad+0.22*flow),0.0,0.70);
	ROUGHNESS=1.0;
}
