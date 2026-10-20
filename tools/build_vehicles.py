"""Original fictional vehicles: lofted body shells, wheel wells and detailed wheels.
Blender 4.3 exports real mesh GLBs. No real manufacturer designs or badges.
"""
import bpy,math,pathlib
from mathutils import Vector
OUT=pathlib.Path(__file__).resolve().parents[1]/'assets/imported/original';OUT.mkdir(parents=True,exist_ok=True)
def material(name,c,metal=0,rough=.4,emit=0):
 m=bpy.data.materials.new(name);m.diffuse_color=(*c,1);m.use_nodes=True;p=m.node_tree.nodes.get('Principled BSDF');p.inputs['Base Color'].default_value=(*c,1);p.inputs['Metallic'].default_value=metal;p.inputs['Roughness'].default_value=rough
 if emit:p.inputs['Emission Color'].default_value=(*c,1);p.inputs['Emission Strength'].default_value=emit
 return m
paint=material('Oba midnight blue pearl',(.035,.09,.135),.7,.25);redpaint=material('Adura burnt copper',(.38,.065,.025),.65,.24);rubber=material('Tyre rubber',(.013,.016,.019),0,.95);glass=material('Smoked automotive glazing',(.035,.07,.09),.45,.18);chrome=material('Satin alloy',(.42,.47,.50),.8,.27);dark=material('Grille and trim',(.025,.03,.035),.25,.5);lamp=material('Warm LED signature',(.85,.88,.72),.2,.2,1.8);tail=material('Red taillight lens',(.6,.012,.006),.3,.2,1)
def mesh(name,verts,faces,mat):
 d=bpy.data.meshes.new(name);d.from_pydata(verts,[],faces);d.update();d.materials.append(mat);o=bpy.data.objects.new(name,d);bpy.context.collection.objects.link(o);return o
def bevel(o,width=.025):
 m=o.modifiers.new('Precision edge fillet','BEVEL');m.width=width;m.segments=3
 o.modifiers.new('Weighted body normals','WEIGHTED_NORMAL');return o
def box(name,loc,size,mat,width=.025):
 bpy.ops.mesh.primitive_cube_add(size=1,location=loc);o=bpy.context.object;o.name=name;o.scale=size;bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);o.data.materials.append(mat);bevel(o,width);return o
def line(name,pts,mat,r=.012):
 c=bpy.data.curves.new(name,'CURVE');c.dimensions='3D';c.bevel_depth=r;c.bevel_resolution=2;sp=c.splines.new('POLY');sp.points.add(len(pts)-1)
 for v,p in zip(sp.points,pts):v.co=(*p,1)
 o=bpy.data.objects.new(name,c);bpy.context.collection.objects.link(o);o.data.materials.append(mat);return o
def cyl(name,loc,r,depth,mat,axis_x=False):
 bpy.ops.mesh.primitive_cylinder_add(vertices=32,radius=r,depth=depth,location=loc,rotation=(0,math.pi/2,0) if axis_x else (0,0,0));o=bpy.context.object;o.name=name;o.data.materials.append(mat);return o
for sport in [False,True]:
 bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
 colour=redpaint if sport else paint
 h=.85 if sport else 1.18;wheel_y=1.42;radius=.39 if sport else .44
 # Curved shell from twelve-point rounded cross-sections, shaped along length.
 sections=[(-2.35,.72,h-.24),(-2.22,.9,h-.13),(-1.8,.98,h-.03),(-1.1,1.0,h),(-.5,1.0,h),(.3,1.0,h),(.95,1.02,h+.02),(1.65,.99,h),(2.18,.92,h-.03),(2.32,.8,h-.15)]
 verts=[]
 for y,w,z in sections:
  for x,zz in [(-w*.83,.38),(-w,.48),(-w,z-.16),(-w*.95,z-.04),(-w*.75,z+.015),(0,z+.035),(w*.75,z+.015),(w*.95,z-.04),(w,z-.16),(w,.48),(w*.83,.38),(0,.36)]:verts.append((x,y,zz))
 faces=[]
 for i in range(len(sections)-1):
  for j in range(12):faces.append((i*12+j,i*12+(j+1)%12,(i+1)*12+(j+1)%12,(i+1)*12+j))
 faces.extend([tuple(reversed(range(12))),tuple((len(sections)-1)*12+j for j in range(12))])
 body=mesh('Sculpted body shell',verts,faces,colour)
 for yy in [-wheel_y,wheel_y]:
  cut=cyl('Wheel arch cutter',(0,yy,radius+.03),radius+.055,3,rubber,True)
  bpy.context.view_layer.objects.active=body;mod=body.modifiers.new('Open wheel wells','BOOLEAN');mod.operation='DIFFERENCE';mod.object=cut;bpy.ops.object.modifier_apply(modifier=mod.name);bpy.data.objects.remove(cut,do_unlink=True)
 bevel(body,.025)
 box('Underbody',(0,0,.35),(1.6,3.8,.15),dark)
 # Cabin silhouette; separate glazing, pillars and roof panels.
 front=-.7 if sport else -.82;rear=.9 if sport else 1.7;roof_front=-.28;roof_rear=.55 if sport else 1.15;roof_h=1.3 if sport else 1.87;rw=.69 if sport else .76;bw=.88
 mesh('Windscreen',[(-bw,front,h+.03),(bw,front,h+.03),(rw,roof_front,roof_h),(-rw,roof_front,roof_h)],[(0,1,2,3)],glass)
 mesh('Rear window',[(-rw,roof_rear,roof_h),(rw,roof_rear,roof_h),(bw,rear,h+.04),(-bw,rear,h+.04)],[(0,1,2,3)],glass)
 roof=mesh('Sculpted roof',[(-rw,roof_front,roof_h),(rw,roof_front,roof_h),(rw,roof_rear,roof_h),(-rw,roof_rear,roof_h),(-rw*.9,roof_front,roof_h+.05),(rw*.9,roof_front,roof_h+.05),(rw*.9,roof_rear,roof_h+.05),(-rw*.9,roof_rear,roof_h+.05)],[(0,1,5,4),(4,5,6,7),(2,3,7,6),(0,4,7,3),(1,2,6,5)],colour);bevel(roof,.025)
 for side in [-1,1]:
  pts=[(side*bw,front,h+.03),(side*rw,roof_front,roof_h),(side*rw,roof_rear,roof_h),(side*bw,rear,h+.04)]
  mesh('Side glazing',pts,[(0,1,2,3)],glass)
  line('Window surround',pts+[pts[0]],colour,.035)
  y=.35
  line('B pillar',[(side*bw,y,h+.03),(side*rw,y,roof_h)],dark,.045)
  # Door shut lines, handles, side skirts, mirrors and trim.
  for yy in [-.6,.8] if not sport else [-.55]:
   line('Door shut line',[(side*.97,yy,h-.04),(side*1.005,yy,.64),(side*.96,yy+.95,.58),(side*.97,yy+.95,h-.05)],dark,.008)
   box('Flush door handle',(side*1.01,yy+.65,h-.14),(.035,.22,.035),chrome,.012)
  box('Side sill',(side*.94,0,.43),(.12,1.8,.12),dark)
  mirror=box('Mirror housing',(side*1.12,front+.18,h+.15),(.3,.29,.17),colour,.065)
  box('Mirror glass',(side*1.13,front+.32,h+.15),(.21,.025,.105),chrome,.02)
  for yy,front_name in [(-wheel_y,'front'),(wheel_y,'back')]:
   before=set(bpy.context.scene.objects)
   xx=side*.98;zz=radius+.03
   # Torus tyre, detailed machined rim, brake disc, five double spokes.
   bpy.ops.mesh.primitive_torus_add(major_segments=40,minor_segments=12,location=(xx,yy,zz),rotation=(0,math.pi/2,0),major_radius=radius-.095,minor_radius=.095)
   bpy.context.object.name='Tyre';bpy.context.object.data.materials.append(rubber)
   cyl('Brake disc',(xx+side*.07,yy,zz),radius*.64,.035,dark,True)
   bpy.ops.mesh.primitive_torus_add(major_segments=32,minor_segments=8,location=(xx+side*.11,yy,zz),rotation=(0,math.pi/2,0),major_radius=radius*.66,minor_radius=.025);bpy.context.object.data.materials.append(chrome)
   for i in range(5):
    a=i*math.tau/5
    for da in [-.055,.055]:
     line('Alloy spoke',[(xx+side*.12,yy,zz),(xx+side*.12,yy+math.sin(a+da)*radius*.65,zz+math.cos(a+da)*radius*.65)],chrome,.023)
   cyl('Wheel centre',(xx+side*.125,yy,zz),.065,.025,chrome,True)
   parts=set(bpy.context.scene.objects)-before
   pivot=bpy.data.objects.new('wheel-'+front_name+('-left' if side>0 else '-right'),None);bpy.context.collection.objects.link(pivot);pivot.location=(xx,yy,zz);bpy.context.view_layer.update()
   for o in parts:
    matrix=o.matrix_world.copy();o.parent=pivot;o.matrix_world=matrix
 # Front grille / LEDs / rear lights; original no-brand badge.
 box('Front intake',(0,-2.31,h-.3),(1.25,.12,.23),dark,.06)
 for i in range(12):box('Grille vane',(-.54+i*.098,-2.38,h-.3),(.025,.025,.18),chrome,.005)
 for side in [-1,1]:
  box('Headlamp enclosure',(side*.68,-2.22,h-.1),(.44,.13,.15),dark,.045)
  box('LED running light',(side*.68,-2.3,h-.08),(.37,.025,.045),lamp,.02)
  box('Rear lamp',(side*.7,2.23,h-.12),(.38,.045,.10),tail,.03)
 box('Front lower lip',(0,-2.25,.4),(1.73,.18,.1),dark,.035)
 box('Rear diffuser',(0,2.23,.43),(1.5,.16,.15),dark,.035)
 if sport:
  for x in [-.65,.65]:box('Spoiler mount',(x,1.9,h+.16),(.06,.15,.28),dark)
  box('Rear aerofoil',(0,1.94,h+.31),(1.9,.24,.065),colour,.025)
 else:
  for x in [-.68,.68]:line('Roof rails',[(x,-.1,roof_h+.07),(x,.9,roof_h+.12),(x,1.2,roof_h+.06)],chrome,.035)
 for o in list(bpy.context.scene.objects):
  if o.type=='MESH':
   bpy.context.view_layer.objects.active=o
   for mod in list(o.modifiers):bpy.ops.object.modifier_apply(modifier=mod.name)
 # Consolidate by material and wheel pivot: retain independent wheel motion
 # while reducing hundreds of authored details to a few draw surfaces.
 for o in list(bpy.context.scene.objects):
  if o.type=='CURVE':
   bpy.ops.object.select_all(action='DESELECT');o.select_set(True);bpy.context.view_layer.objects.active=o;bpy.ops.object.convert(target='MESH')
 groups={}
 for o in bpy.context.scene.objects:
  if o.type=='MESH':groups.setdefault((o.parent,o.data.materials[0].name),[]).append(o)
 for (parent,name),parts in groups.items():
  bpy.ops.object.select_all(action='DESELECT')
  for o in parts:o.select_set(True)
  bpy.context.view_layer.objects.active=parts[0];bpy.ops.object.join();bpy.context.object.name=name
 # Controllers use a 1.9 visual scale. Bake inverse scale into the exported root.
 root=bpy.data.objects.new('VehicleVisual',None);bpy.context.collection.objects.link(root)
 for o in list(bpy.context.scene.objects):
  if o!=root and o.parent is None:o.parent=root
 root.scale=(1/1.9,)*3
 bpy.ops.export_scene.gltf(filepath=str(OUT/('adura-gt.glb' if sport else 'oba-grand.glb')),export_format='GLB',export_animations=False)
