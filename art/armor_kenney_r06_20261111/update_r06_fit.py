from pathlib import Path
root=Path(__file__).resolve().parents[2]
art=root/'art/armor_kenney_r06_20261111'
s=(root/'art/armor_kenney_r05_20261111/runtime_candidate.gd').read_text(encoding='utf8').replace('r05','r06').replace('R05','R06')
start=s.index('\t\telif part.begins_with("knee_"):')
end=s.index('\t\telif part.begins_with("forearm_")',start)
s=s[:start]+'''\t\telif part.begins_with("knee_"):
\t\t\tvar joint := skeleton.get_bone_global_rest(skeleton.find_bone(bone)).origin
\t\t\tvar ankle := skeleton.get_bone_global_rest(skeleton.find_bone(bone.replace("Leg","Foot"))).origin
\t\t\taxes = body_axes
\t\t\tcenter = axes.inverse()*joint
\t\t\tvar bounds := _joint_section_bounds(model,skeleton,[bone,bone.replace("Leg","UpLeg")],axes,center.y,joint.distance_to(ankle)*.055)
\t\t\tif bounds.size.x>0.0 and bounds.size.z>0.0:
\t\t\t\tdimensions = Vector3(bounds.size.x * {"light":.90,"medium":1.18,"heavy":1.26}[armor_id],bounds.size.x * {"light":.73,"medium":1.0,"heavy":1.02}[armor_id],bounds.size.z*1.10)
\t\t\t\tcenter.x = bounds.get_center().x
\t\t\t\tcenter.z = bounds.get_center().z + bounds.size.z*.13
\t\t\t\tmodel.set_meta("r06_knee_section_"+bone,{"bounds":bounds,"center":center,"dimensions":dimensions})
'''+s[end:]
s=s.replace('or String(spec.part).begins_with("shin_"):', 'or String(spec.part).begins_with("shin_") or String(spec.part).begins_with("knee_"):')
s=s.replace('"light":1.02,"medium":1.16,"heavy":1.36','"light":1.02,"medium":1.18,"heavy":1.26')
s=s.replace('(1.10 if armor_id=="medium" else 1.22)','(1.16 if armor_id=="medium" else 1.24)')
s=s.replace('(1.12 if armor_id=="medium" else 1.22)','(1.16 if armor_id=="medium" else 1.24)')
s=s.replace('(1.10 if armor_id=="medium" else 1.30)','(1.15 if armor_id=="medium" else 1.25)')
s=s.replace('(1.18 if armor_id=="medium" else 1.30)','(1.20 if armor_id=="medium" else 1.25)')
s=s.replace('"light":1.18,"medium":1.25,"heavy":1.26','"light":1.12,"medium":1.14,"heavy":1.16')
s=s.replace('center = axes.inverse() * shoulder.lerp(elbow, 0.10)','center = axes.inverse() * shoulder.lerp(elbow, 0.07)\n\t\t\tdimensions.y += shoulder.distance_to(elbow)*.06')
s=s.replace('"light":.90,"medium":1.18,"heavy":1.26','"light":.80,"medium":1.18,"heavy":1.26')
s=s.replace('static func apply_to_model(model: Node3D, armor_id: String) -> Dictionary:\n','static func apply_to_model(model: Node3D, armor_id: String) -> Dictionary:\n\t_prepare_body_variant(model)\n')
s+='\n\n'+(art/'knee_section.gdinc').read_text(encoding='utf8')+'\n\n'+(art/'body_projection.gdinc').read_text(encoding='utf8')
(root/'output/native_glut_maps/personnel_armor_visual_r06.gd').write_text(s,encoding='utf8')
(art/'anatomical_fit.gdinc').write_text(s[s.index('static func _fit_anatomical_specs'):],encoding='utf8')
print('R06 anatomical fits updated')
