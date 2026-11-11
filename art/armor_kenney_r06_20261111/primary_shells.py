"""R06 primary forms. Executed inside the copied, self-contained R05 builder.

Broad chest planes, returned flanks, complete limb cuffs and patella caps.
Dimensions are normalized wearable coordinates, not assumed metres.
"""
legacy_sleeve=sleeve

def surface_shell(a, grid, mat=0, thickness=.055, back_mat=1):
 """Closed thin shell from a purpose-designed quad grid; no inflated slab."""
 rows=len(grid);cols=len(grid[0]);n=rows*cols
 v=[p for row in grid for p in row]
 v += [(x,y+thickness,z) for x,y,z in v]
 f=[];mi=[]
 for r in range(rows-1):
  for c in range(cols-1):
   i=r*cols+c;q=(i,i+1,i+cols+1,i+cols)
   f += [q,tuple(j+n for j in reversed(q))];mi += [mat,back_mat]
 border=list(range(cols))+[r*cols+cols-1 for r in range(1,rows)]+list(range(n-2,n-cols-1,-1))+[r*cols for r in range(rows-2,0,-1)]
 for i,j in zip(border,border[1:]+border[:1]):f.append((i,j,j+n,i+n));mi.append(mat)
 a.add(v,f,mi)

def armor_cuff(a,rings,mat=0,thickness=.055,profile=None):
 """A real circumferential shell with inner wall and annular end rims."""
 profile=profile or PROFILE;n=len(profile);nr=len(rings);v=[]
 for inside in [False,True]:
  for z,w,d,*cy in rings:
   v += [(x*(w-(thickness*2 if inside else 0)),y*(d-(thickness*2 if inside else 0))+(cy[0] if cy else 0),z) for x,y in profile]
 off=n*nr;f=[];mi=[]
 for r in range(nr-1):
  for j in range(n):
   q=(r*n+j,r*n+(j+1)%n,(r+1)*n+(j+1)%n,(r+1)*n+j)
   f += [q,tuple(k+off for k in reversed(q))];mi += [mat(r,j) if callable(mat) else mat,1]
 for r in [0,nr-1]:
  for j in range(n):
   i=r*n+j;k=r*n+(j+1)%n;f.append((i,k,k+off,i+off));mi.append(mat(0,j) if callable(mat) else mat)
 a.add(v,f,mi)

def chest_half(a,s,light):
 # Clavicle-to-sternum planes and a pronounced horizontal lower breast fold.
 # Rows are deliberately different polygons: no vertically stretched shield.
 outline=[[(.020,.40),(.29,.47),(.43,.40),(.53,.31)],
          [(.020,.19),(.29,.19),(.46,.19),(.59,.15)],
          [(.020,.055),(.29,-.010),(.43,.055),(.52,.12)]]
 # Each broad half has two genuinely planar front faces. The extra vertices
 # describe the outline and side return, not a diamond-shaped shading fan.
 grid=[]
 for row,points in enumerate(outline):
  grid.append([(x,(-.57+(.20 if row==0 else -.40)*(z-.19)+.08*x) if col<3 else [-.13,-.055,-.005][row],z) for col,(x,z) in enumerate(points)])
 if light:grid=[[(x*.82,y+.02,z*.53+.13) for x,y,z in row] for row in grid]
 else:grid=[[(x,y,(z-.20)*.76+.20) for x,y,z in row] for row in grid]
 surface_shell(a,[[(x*s,y,z) for x,y,z in row] for row in grid],0,.07 if light else .055)
 plate(a,octagon(s*.16,.23 if light else .19,.12,.025),-.46 if light else -.49,.27,1,.05)

def abdominal_shell(a,z,width,height,light=False,rear=False):
 # Front retains broad horizontal planes; its side wings turn around the waist.
 xs=[-.50,-.43,-.30,0,.30,.43,.50]
 ys=[.12,-.23,-.44,-.51,-.44,-.23,.12]
 if light:xs=[-.5,-.3,0,.3,.5];ys=[-.36,-.49,-.52,-.49,-.36]
 grid=[]
 for row in [-1,0,1]:
  grid.append([(x*width,(-y if rear else y)+(0 if row==0 else .035),z+height*row*.5+(abs(x)*.035 if row<0 else -.025*abs(x))) for x,y in zip(xs,ys)])
 surface_shell(a,grid,0,.16 if not rear else -.16)

def torso(family):
 a=Mesh('torso_'+family);light=family=='light';heavy=family=='heavy'
 # Internal carriers meet the wearable layers, but never replace their silhouette.
 loft(a,[(-.50,.48,.42),(-.25,.56,.49),(.18,.70,.54),(.39,.66,.49),(.50,.44,.38)],1)
 if not heavy:
  for s in [-1,1]:
   chest_half(a,s,light)
   tube(a,[(s*.24,-.31,.40),(s*.27,-.11,.49),(s*.27,.20,.44),(s*.22,.34,.31)],.026 if light else .036,0)
  for z,w,h in ([(-.15,.57,.13),(-.32,.48,.13)] if light else [(-.14,.71,.15),(-.31,.60,.15),(-.48,.51,.14)]):
   pts=[(-w*.50,z+h*.20),(-w*.30,z+h*.50),(w*.30,z+h*.50),(w*.50,z+h*.20),(w*.42,z-h*.43),(0,z-h*.28),(-w*.42,z-h*.43)]
   plate(a,pts,lambda x,zz:-.51+.22*abs(x),.18,0,.09,curve=.035)
   plate(a,octagon(0,z,.095,.027),-.536,.040,3,.1)
   if not light:
    ww={-.14:.82,-.31:.80,-.48:.86}[z]
    carrier=[(x, y*.74 if y<0 else y*.57) for x,y in PROFILE]
    armor_cuff(a,[(z-h*.40,ww*.98,1),(z+h*.40,ww,1)],2,.055,carrier)
  if light:
   back=Mesh('back');plate(back,octagon(0,.17,.43,.25),lambda x,z:-.43-.30*(z-.17),.24,0,.12,curve=.015)
   plate(back,octagon(0,-.12,.43,.11),-.38,.20,0,.12,curve=.015)
   a.add([(x,-y,z) for x,y,z in back.v],back.f,back.m)
  else:
   # Broad scapular panel, not three disconnected buttons down the spine.
   backgrid=[[(x,.49 if abs(x)<.3 else .29,z) for x,z in [(-.39,.30),(-.23,.41),(0,.35),(.23,.41),(.39,.30)]],
             [(x,.47 if abs(x)<.3 else .22,z) for x,z in [(-.51,.14),(-.28,.18),(0,.18),(.28,.18),(.51,.14)]],
             [(x,.41 if abs(x)<.3 else .19,z) for x,z in [(-.40,-.045),(-.25,.005),(0,.005),(.25,.005),(.40,-.045)]]]
   surface_shell(a,backgrid,0,-.242)
   for z,w,h in [(-.14,.76,.15),(-.31,.69,.15),(-.48,.63,.14)]:
    depth={-.14:.40,-.31:.44,-.48:.46}[z]
    b=Mesh('back');plate(b,octagon(0,z,w,h),lambda x,zz:-depth+.3*(zz-z),.20,0,.13,curve=.015)
    a.add([(x,-y,zz) for x,y,zz in b.v],b.f,b.m)
 else:
  # Three anatomically grouped parts make the heavy vest continuous in rest,
  # while keeping whole rigid waist plates on Spine/Hips during movement.
  armor_cuff(a,[(-.19,.88,.93),(.15,1.12,1.03),(.34,1.04,.94),(.47,.76,.72)],2,.055)
  armor_cuff(a,[(-.405,.80,.88),(-.29,.84,.92),(-.205,.88,.93)],2,.055)
  armor_cuff(a,[(-.54,.85,.91),(-.42,.80,.88)],2,.055)
  plate(a,[(-.34,.38),(.34,.38),(.40,.23),(.34,-.22),(0,-.37),(-.34,-.22),(-.40,.23)],lambda x,z:-.55+.32*abs(x)+.12*max(0,-z),.075,2,.08,curve=.025)
  plate(a,[(-.25,.22),(.25,.22),(.28,.10),(.22,-.23),(0,-.32),(-.22,-.23),(-.28,.10)],lambda x,z:-.61+.28*abs(x)+.13*max(0,-z),.075,0,.09,curve=.025)
  for s in [-1,1]:
   tube(a,[(s*.31,-.45,-.20),(s*.39,-.39,.16),(s*.32,-.38,.38),(s*.27,-.13,.48),(s*.27,.34,.40),(s*.34,.39,-.19)],.033,1)
   plate(a,octagon(s*.32,.30,.10,.063),-.465,.07,0,.1)
  for z,w,h in [(.29,.31,.30),(.015,.30,.18),(-.25,.32,.18)]:
   b=Mesh('back');plate(b,octagon(0,z,w,h),-.54,.10,0,.16,curve=.015)
   a.add([(x,-y,z) for x,y,z in b.v],b.f,b.m)
  plate(a,octagon(.19,.33,.095,.026),-.58,.075,3,.12)
 return a

def sleeve(family,kind):
 if kind=='pauldron':
  a=legacy_sleeve(family,kind)
  # A broad proximal roof closes over the deltoid. R05's narrow top cap let
  # the real shoulder appear as a dark island when viewed from above.
  def roof_vertex(x,y,z):
   if z>=.499:return (x*.95/(.30 if family=='light' else .28),y*.88/(.44 if family=='light' else .45),z)
   if z>.39:return (x/(.77 if family=='light' else .73 if family=='medium' else .72),y*.96/(.73 if family=='light' else .80 if family=='medium' else .78),z)
   return (x,y,z)
  a.v=[roof_vertex(x,y,z) for x,y,z in a.v]
  a.m=[0 if m==1 else m for m in a.m]
  return a
 if family=='light' or kind=='hand_guard':return legacy_sleeve(family,kind)
 a=Mesh(kind+'_'+family);heavy=family=='heavy'
 mat=2 if heavy and kind in ['shin','upper_arm'] else 0
 # Broad knee/ankle transition and taper follow the limb, not an oval badge.
 if kind=='thigh':
  rings=[(-.48,.76,.80),(-.36,.93,.96),(.20,1.03,1.04,-.03),(.42,.95,1.00,-.06),(.49,.76,.86,-.07)]
 elif kind=='shin':rings=[(-.49,.71,.80),(-.37,.83,.94),(.27,1.05,1.02),(.42,.94,.94),(.49,.78,.84)]
 else:rings=[(-.50,.73,.78),(-.39,.88,.93),(.25,1.04,1.04),(.43,.91,.96),(.5,.76,.83)]
 def material(r,j):
  if heavy and kind=='thigh':return 0 if j in [1,2,8,9] else 2
  return mat
 armor_cuff(a,rings,material,.055)
 # An integrated inset, deliberately flatter than the enclosing curved shell.
 if kind not in ['thigh','upper_arm']:
  plate(a,[(-.15,.25),(.15,.25),(.115,-.27),(-.115,-.27)],-.548,.045,1 if heavy else 2,.13,curve=.010)
 if heavy and kind=='forearm':plate(a,octagon(0,-.16,.060,.13),-.586,.035,3,.1)
 if heavy and kind=='thigh':
  for z in [-.20,.16]:
   armor_cuff(a,[(z-.045,1.055,1.075,-.02),(z+.045,1.055,1.075,-.02)],1,.065)
 return a

def knee(family):
 a=Mesh('knee_'+family);heavy=family=='heavy'
 outline=octagon(0,0,1.0,1.0,.23)
 n=len(outline);v=[]
 # The patella has a frontal plateau, sloping upper/lower facets, and a
 # continuous return at each side. The rim wraps behind the knee's front.
 for ring in range(4):
  for x,z in outline:
   if ring==0:v.append((x*.92,-.05-.10*(abs(z)/.5),z*.90))
   elif ring==1:v.append((x,-.24+.14*(abs(x)/.5),z))
   elif ring==2:v.append((x*.83,-.36+.02*(abs(z)/.5),z*.83))
   else:v.append((x*.65,-.38,z*.62))
 f=[tuple(reversed(range(n)))];mi=[1]
 for ring in range(3):
  for j in range(n):f.append((ring*n+j,ring*n+(j+1)%n,(ring+1)*n+(j+1)%n,(ring+1)*n+j));mi.append(0)
 f.append(tuple(range(3*n,4*n)));mi.append(0)
 a.add(v,f,mi)
 if heavy:
  for z in [-.13,.13]:plate(a,octagon(0,z,.50,.055),-.397,.035,2,.15)
 else:plate(a,octagon(0,0,.43,.41,.26),-.395,.035,2,.1)
 return a
