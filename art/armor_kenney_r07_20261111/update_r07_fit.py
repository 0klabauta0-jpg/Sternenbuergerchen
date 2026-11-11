from pathlib import Path
ART=Path(__file__).resolve().parent;ROOT=ART.parents[1]
s=(ART/'origin_r06_runtime.gd').read_text(encoding='utf8').replace('r06','r07').replace('R06','R07')
s=s[:s.index('static var _body_variants:')]+(ART/'body_projection.gdinc').read_text(encoding='utf8')
s=s.replace('dimensions.y += shoulder.distance_to(elbow)*.06','''dimensions.y += shoulder.distance_to(elbow)*.06
			var roof_width:float={"light":1.06,"medium":1.40,"heavy":1.62}[armor_id]
			dimensions.x *= roof_width
			dimensions.y *= {"light":1.0,"medium":.90,"heavy":.82}[armor_id]''')
s=s.replace('center.x = bounds.get_center().x\n\t\t\t\tcenter.z = bounds.get_center().z\n\t\t\t\tdimensions.z = bounds.size.z * {"light":1.38', 'center.x = bounds.get_center().x + dimensions.x*(1-1/roof_width)*.40*(1 if bone.begins_with("Left") else -1)\n\t\t\t\tcenter.z = bounds.get_center().z\n\t\t\t\tdimensions.z = bounds.size.z * {"light":1.38')
s=s.replace('\t\telif part.begins_with("knee_"):', '''			var roof_center_world:Vector3=axes*center
			axes=axes*Basis(Vector3.BACK,deg_to_rad({"light":0.0,"medium":-40.0,"heavy":-50.0}[armor_id])*(1 if bone.begins_with("Left") else -1))
			center=axes.inverse()*roof_center_world
		elif part.begins_with("knee_"):''')
(ROOT/'output/native_glut_maps/personnel_armor_visual_r07.gd').write_text(s,encoding='utf8')
print('R07 helper updated')
