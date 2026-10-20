"""Adapt the CC0 Quaternius humanoid into a fully skinned Lagos streetwear actor.
Run with Blender --background --python tools/build_character.py -- ASSET_ROOT.
Downloads remain outside the project; resulting GLB is checked in.
"""
import bpy,sys,pathlib,math,bmesh
from mathutils import Vector
ROOT=pathlib.Path(sys.argv[sys.argv.index('--')+1])
OUT=pathlib.Path(__file__).resolve().parents[1]/'assets/imported/characters/ayo.glb'
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
bpy.ops.import_scene.gltf(filepath=str(next((ROOT/'base').rglob('Superhero_Male_FullBody.gltf'))))
rig=next(o for o in bpy.context.scene.objects if o.type=='ARMATURE');rig.name='AyoRig'
body=next(o for o in bpy.context.scene.objects if o.type=='MESH' and 'SuperHero' in o.name);body.name='Ayo_Skin'
for o in list(bpy.context.scene.objects):
 if o.type=='MESH' and o != body and not o.modifiers: bpy.data.objects.remove(o,do_unlink=True)
# Each garment retains the source vertex groups and armature modifier. Surface
# selection follows anatomical mesh topology; no box-built body or clothing.
def material(name,color,rough=.8):
 m=bpy.data.materials.new(name);m.diffuse_color=(*color,1);m.use_nodes=True
 bs=m.node_tree.nodes.get('Principled BSDF');bs.inputs['Base Color'].default_value=(*color,1);bs.inputs['Roughness'].default_value=rough
 return m
shirtmat=material('Ayo woven indigo overshirt',(0.045,0.12,0.17));pantsmat=material('Sand tailored trousers',(0.34,0.29,0.20));shoemat=material('Ivory leather trainers',(0.70,0.72,0.65),.5)
def garment(name,predicate,mat,offset):
 obj=body.copy();obj.data=body.data.copy();bpy.context.collection.objects.link(obj);obj.name=name
 bm=bmesh.new();bm.from_mesh(obj.data)
 remove=[f for f in bm.faces if not predicate(sum((v.co for v in f.verts),Vector())/len(f.verts))]
 bmesh.ops.delete(bm,geom=remove,context='FACES')
 bm.normal_update()
 for v in bm.verts:
  v.co += v.normal*offset
  if v.is_boundary:
   if name=='Streetwear_overshirt':
    if v.co.z < 1.05:v.co.z=1.0
    if v.co.z > 1.52:v.co.z=1.55
    if abs(v.co.x) > .45:v.co.x=math.copysign(.52,v.co.x)
   elif name=='Streetwear_trousers' and v.co.z < .2:v.co.z=.11
 bm.to_mesh(obj.data);bm.free();obj.data.materials.clear();obj.data.materials.append(mat)
 for p in obj.data.polygons:p.material_index=0;p.use_smooth=True
 solid=obj.modifiers.new('Tailored fabric thickness','SOLIDIFY');solid.thickness=.009
 return obj
shirt=garment('Streetwear_overshirt',lambda c:.99<c.z<1.55 and abs(c.x)<.52,shirtmat,.025)
pants=garment('Streetwear_trousers',lambda c:.10<c.z<1.02,pantsmat,.019)
shoes=garment('Leather_trainers',lambda c:c.z<.13,shoemat,.025)
# Suppress skin under opaque garments while preserving hands, neck and face.
bm=bmesh.new();bm.from_mesh(body.data)
remove=[]
for f in bm.faces:
 c=sum((v.co for v in f.verts),Vector())/len(f.verts)
 if (.13<c.z<.98) or (.99<c.z<1.48 and abs(c.x)<.49):remove.append(f)
bmesh.ops.delete(bm,geom=remove,context='FACES');bm.to_mesh(body.data);bm.free()
# Import an actual rigged cropped hairstyle, bind to the existing compatible rig.
before=set(bpy.context.scene.objects)
hairpath=next(p for p in (ROOT/'base').rglob('Hair_Buzzed.gltf') if 'Rigged to Head' in str(p))
bpy.ops.import_scene.gltf(filepath=str(hairpath))
for o in set(bpy.context.scene.objects)-before:
 if o.type=='MESH' and any(m.type=='ARMATURE' for m in o.modifiers):
  matrix=o.matrix_world.copy();o.parent=rig;o.matrix_world=matrix;o.name='Cropped_Hair';o.data.materials.clear();o.data.materials.append(material('Natural dark cropped hair',(.018,.012,.009)))
  for mod in o.modifiers:
   if mod.type=='ARMATURE':mod.object=rig
for o in list(set(bpy.context.scene.objects)-before):
 if o.type=='ARMATURE' or (o.type=='MESH' and not any(m.type=='ARMATURE' for m in o.modifiers)):bpy.data.objects.remove(o,do_unlink=True)
# The library shares the exact Universal bone naming and rest rig.
before=set(bpy.context.scene.objects)
bpy.ops.import_scene.gltf(filepath=str(next((ROOT/'animation').rglob('UAL1_Standard.glb'))))
keep={'Idle_Loop':'Idle','Walk_Loop':'Walk','Jog_Fwd_Loop':'Run','Idle_Talking_Loop':'Talk','Driving_Loop':'Driving','Sitting_Enter':'Enter','Sitting_Exit':'Exit','Interact':'Interact'}
actions=[]
for a in list(bpy.data.actions):
 match=next((k for k in keep if a.name.startswith(k+'_Armature')),None)
 if match:a.name=keep[match];a.use_fake_user=True;actions.append(a)
for o in set(bpy.context.scene.objects)-before:bpy.data.objects.remove(o,do_unlink=True)
for a in list(bpy.data.actions):
 if a not in actions:bpy.data.actions.remove(a)
rig.animation_data_create()
for action in actions:
 track=rig.animation_data.nla_tracks.new();track.name=action.name
 strip=track.strips.new(action.name,0,action);strip.action_frame_start=action.frame_range[0];strip.action_frame_end=action.frame_range[1]
 track.mute=True
rig.animation_data.action=next(a for a in actions if a.name=='Idle')
bpy.context.scene.render.fps=24
# Textures are bounded for mobile. Hair alpha and source skin/eye maps retained.
for image in bpy.data.images:
 if image.size[0] and max(image.size)>1024:
  ratio=1024/max(image.size);image.scale(int(image.size[0]*ratio),int(image.size[1]*ratio))
for o in bpy.context.scene.objects:
 if o.type=='MESH':
  for p in o.data.polygons:p.use_smooth=True
bpy.ops.export_scene.gltf(filepath=str(OUT),export_format='GLB',export_animations=True,export_animation_mode='ACTIONS',export_nla_strips=True,export_def_bones=True,export_force_sampling=True,export_optimize_animation_size=True)
print('CHARACTER_EXPORT',OUT,'actions',[a.name for a in actions])
