"""Build original mesh props. Blender 4.3; no external input or textures."""
import bpy,math,pathlib
from mathutils import Vector
OUT=pathlib.Path(__file__).resolve().parents[1]/'assets/imported/original'
OUT.mkdir(parents=True,exist_ok=True)
def clear():
 bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
def mat(name,c,metal=0):
 m=bpy.data.materials.new(name);m.diffuse_color=(*c,1);m.use_nodes=True;p=m.node_tree.nodes.get('Principled BSDF');p.inputs['Base Color'].default_value=(*c,1);p.inputs['Metallic'].default_value=metal;p.inputs['Roughness'].default_value=.5 if metal else .85;return m
wood=mat('Oiled timber',(.21,.1,.045));green=mat('Forest green painted metal',(.035,.16,.12));cream=mat('Warm cream paint',(.79,.73,.55));steel=mat('Galvanized metal',(.22,.27,.28),.6);black=mat('Black rubber',(.015,.02,.022));red=mat('Tomato red',(.55,.045,.02));yellow=mat('Plantain gold',(.75,.46,.02));screen=mat('Pump display glass',(.02,.035,.037))
def mesh(name,vertices,faces,m):
 data=bpy.data.meshes.new(name);data.from_pydata(vertices,[],faces);data.materials.append(m);obj=bpy.data.objects.new(name,data);bpy.context.collection.objects.link(obj);return obj
def cube(name,loc,scale,m,bevel=.025):
 bpy.ops.mesh.primitive_cube_add(size=1,location=loc);o=bpy.context.object;o.name=name;o.scale=scale;bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);o.data.materials.append(m)
 if bevel: mod=o.modifiers.new('Manufactured edge radius','BEVEL');mod.width=bevel;mod.segments=3;o.modifiers.new('Weighted corner normals','WEIGHTED_NORMAL')
 return o
def cylinder(name,loc,r,depth,m):
 bpy.ops.mesh.primitive_cylinder_add(vertices=12,radius=r,depth=depth,location=loc);o=bpy.context.object;o.name=name;o.data.materials.append(m);return o
def curve(name,points,r,m):
 c=bpy.data.curves.new(name,'CURVE');c.dimensions='3D';c.bevel_depth=r;c.bevel_resolution=2;s=c.splines.new('POLY');s.points.add(len(points)-1)
 for p,co in zip(s.points,points):p.co=(*co,1)
 o=bpy.data.objects.new(name,c);bpy.context.collection.objects.link(o);o.data.materials.append(m)
def export(name):
 for o in list(bpy.context.scene.objects):
  if o.type=='MESH':
   bpy.context.view_layer.objects.active=o
   for mod in list(o.modifiers):bpy.ops.object.modifier_apply(modifier=mod.name)
 for o in list(bpy.context.scene.objects):
  if o.type=='CURVE':
   bpy.ops.object.select_all(action='DESELECT');o.select_set(True);bpy.context.view_layer.objects.active=o;bpy.ops.object.convert(target='MESH')
 groups={}
 for o in bpy.context.scene.objects:
  if o.type=='MESH':groups.setdefault(o.data.materials[0].name,[]).append(o)
 for parts in groups.values():
  bpy.ops.object.select_all(action='DESELECT')
  for o in parts:o.select_set(True)
  bpy.context.view_layer.objects.active=parts[0];bpy.ops.object.join()
 bpy.ops.export_scene.gltf(filepath=str(OUT/(name+'.glb')),export_format='GLB',export_animations=False)
clear()
for x in [-1.25,1.25]:
 for y in [-.65,.65]: cylinder('Canopy pole',(x,y,1.3),.035,2.6,steel)
for i in range(8):
 x=-1.5+i*.375
 mesh('Striped waterproof canopy',[(x,-1,2.45),(x+.375,-1,2.45),(x+.375,0,2.85),(x,0,2.85),(x,1,2.45),(x+.375,1,2.45)],[(0,1,2,3),(3,2,5,4)],green if i%2 else cream)
cube('Counter',(0,0,.85),(2.8,1.3,.12),wood)
for x in [-1,1]:
 for y in [-.45,.45]: cube('Counter legs',(x,y,.42),(.09,.09,.84),wood)
for x in [-.8,0,.8]:
 cube('Produce crate',(x,0,.98),(.68,.85,.2),wood)
 for i in range(3):
  for j in range(3):
   bpy.ops.mesh.primitive_uv_sphere_add(segments=8,ring_count=4,radius=.1,location=(x-.2+i*.2,-.2+j*.2,1.11));bpy.context.object.data.materials.append(red if x<0 else yellow)
export('market-stall')
clear()
cube('Pump plinth',(0,0,.08),(.8,.65,.16),steel)
cube('Rounded fuel pump',(0,0,.8),(.65,.5,1.5),green,.12)
cube('Instrument housing',(0,0,1.65),(.85,.55,.65),cream,.09)
cube('Digital display',(0,-.286,1.73),(.55,.025,.22),screen,.01)
for i in range(3):cube('Display segments',(-.15+i*.15,-.305,1.74),(.08,.01,.08),cream,.005)
curve('Fuel hose',[(.4,0,1.7),(.7,0,1.5),(.8,0,.4),(.55,0,.2),(.42,-.2,.5),(.42,-.2,1.1)],.035,black)
cube('Nozzle grip',(.42,-.2,1.2),(.08,.1,.3),steel)
export('fuel-pump')
clear()
cylinder('Concrete power pole',(0,0,4),.14,8,cream)
cube('Cross arm',(0,0,7.3),(2.3,.12,.16),wood)
for x in [-1,-.4,.4,1]:
 for z in [7.45,7.55,7.65]:cylinder('Ceramic insulator',(x,0,z),.07,.08,cream)
cylinder('Transformer',(0,.3,6.2),.3,.7,steel)
for x in [-1,-.4,.4,1]:curve('Power cable',[(x,0,7.7),(x,5,7.1),(x,10,7.7)],.012,black)
export('power-pole')
clear()
cylinder('Streetlamp post',(0,0,3),.07,6,steel)
curve('Curved light arm',[(0,0,5.5),(0,0,6),(.3,0,6.25),(1,0,6.3)],.06,steel)
cube('Luminaire',(1,0,6.25),(.65,.28,.13),cream)
export('streetlight')
clear()
for x in [-3.2,3.2]:
 cube('Gate masonry pillar',(x,0,1.4),(.5,.5,2.8),cream)
 cube('Pillar cap',(x,0,2.8),(.65,.65,.12),steel)
for side in [-1,1]:
 for z in [.3,1.9]:cube('Gate frame',(side*1.7,0,z),(2.7,.08,.08),green)
 for i in range(10):cube('Gate upright',(side*(.4+i*.27),0,1.1),(.045,.06,1.65),green,.015)
export('residence-gate')
clear()
white=mat('Limewashed cream stucco',(.72,.69,.60));stone=mat('Warm limestone trim',(.42,.37,.28));glass=mat('Blue grey architectural glazing',(.035,.085,.10),.55);tile=mat('Terracotta roof tiles',(.26,.075,.035));bronze=mat('Bronze window frames',(.12,.085,.035),.6)
# An original articulated villa, with two wings and a recessed entrance court.
for x,y,w,d,h in [(-5,5,6,10,6),(5,4.5,6,9,6),(0,6,4,8,5.6)]:
 cube('Stucco villa wing',(x,y,h/2),(w,d,h),white,.09)
 cube('Foundation plinth',(x,y,.2),(w+.15,d+.15,.4),stone,.04)
 cube('Cornice shadow course',(x,y,h-.15),(w+.35,d+.35,.2),stone,.03)
 cube('Roof cornice',(x,y,h+.02),(w+.55,d+.55,.18),white,.04)
 verts=[(x-w/2-.4,y-d/2-.4,h+.1),(x+w/2+.4,y-d/2-.4,h+.1),(x+w/2+.4,y+d/2+.4,h+.1),(x-w/2-.4,y+d/2+.4,h+.1),(x-w/2+1,y,h+1.25),(x+w/2-1,y,h+1.25)]
 mesh('Hipped terracotta roof',verts,[(0,1,5,4),(1,2,5),(2,3,4,5),(3,0,4)],tile)
 # Tile battens follow the sloped roof and cast readable fine shadows.
 for side in [-1,1]:
  for i in range(1,9):
   t=i/9; yy=y+side*(d/2+.4)*(1-t);zz=h+.1+1.15*t
   cube('Roof tile course',(x,yy,zz),(w+.5-2*t,.045,.035),tile,.01)
for level in [0,1]:
 for x in [-6.5,-3.5,3.5,6.5]:
  z=1.5+level*3
  yy=-.025 if x<0 else -.025
  cube('Window recess',(x,yy,z),(1.85,.05,1.9),stone,.035)
  cube('Architectural glazing',(x,yy-.04,z),(1.6,.04,1.65),glass,.02)
  for dx in [-.82,0,.82]:cube('Window mullion',(x+dx,yy-.08,z),(.045,.07,1.75),bronze,.01)
  for dz in [-.85,.85]:cube('Window frame',(x,yy-.08,z+dz),(1.7,.08,.06),bronze,.01)
  cube('Window sill',(x,yy-.15,z-.95),(2,.3,.12),white,.025)
# Entrance portal and wide shaded veranda.
cube('Carved entrance door',(0,1.94,1.45),(1.8,.13,2.9),wood,.04)
for x in [-1,1]:cube('Door surround',(x,1.87,1.5),(.22,.2,3.1),stone)
cube('Door lintel',(0,1.87,3),(2.3,.25,.22),stone)
for x in [-.12,.12]:cube('Door handle',(x,1.78,1.4),(.025,.06,.3),bronze,.01)
for i in range(4):cube('Entrance step',(0,.8-i*.4,.1+i*.06),(3.4,.45,.2+i*.12),stone)
cube('Veranda canopy',(0,.3,3.4),(6,3.6,.22),white,.05)
for x in [-2.6,2.6]:
 cylinder('Veranda column',(x,-1.25,1.7),.16,3.4,white)
 cube('Column base',(x,-1.25,.15),(.5,.5,.3),stone)
# Upper terrace balustrade, individually modelled.
for x in [-2.7,-1.8,-.9,0,.9,1.8,2.7]:cube('Balcony upright',(x,-1.4,4.05),(.045,.06,1.05),bronze,.01)
for z in [3.6,4.55]:cube('Balcony handrail',(0,-1.4,z),(5.5,.08,.07),bronze,.01)
for x in [-2.25,-1.35,-.45,.45,1.35,2.25]:cube('Balcony glass infill',(x,-1.4,4.05),(.83,.025,.84),glass,.01)
# Side windows avoid featureless end walls.
for x in [-8.02,8.02]:
 for y in [2,5,8]:
  for z in [1.6,4.5]:
   cube('Side window frame',(x,y,z),(.08,1.75,1.85),stone)
   cube('Side glazing',(x+math.copysign(.05,x),y,z),(.04,1.5,1.6),glass)
export('palm-court-villa')
