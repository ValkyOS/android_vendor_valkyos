#!/usr/bin/env python3
# ValkyOS: welcome animation of the setup wizard (res/raw/lottie_welcome.json,
# 512x260 like the LineageOS one it replaces): ValkyOS symbol with the same
# soft pulse. Usage: python3 hacer-lottie-bienvenida.py <output file>
import sys
import json
h=240.0; s=h/570; w=672*s
tx=(512-w)/2-176*s; ty=(260-h)/2-190*s
def T(p): return [round(p[0]*s+tx,3), round(p[1]*s+ty,3)]
def D(d): return [round(d[0]*s,3), round(d[1]*s,3)]
def shape(segs):
    # segs: list of (start, c1, c2, end), closed
    n=len(segs); v=[];i=[[0,0]]*n;o=[[0,0]]*n
    v=[seg[0] for seg in segs]
    i=[None]*n;o=[None]*n
    for k,(p0,c1,c2,p1) in enumerate(segs):
        o[k]=D((c1[0]-p0[0],c1[1]-p0[1]))
        i[(k+1)%n]=D((c2[0]-p1[0],c2[1]-p1[1]))
    return {"ty":"sh","ks":{"a":0,"k":{"c":True,"v":[T(p) for p in v],"i":i,"o":o}},"nm":"path"}
L=[((176,190),(337,210),(456,322),(512,760)),((512,760),(427,594),(353,463),(284,355)),((284,355),(247,297),(210,239),(176,190))]
R=[((848,190),(687,210),(568,322),(512,760)),((512,760),(597,594),(671,463),(740,355)),((740,355),(777,297),(814,239),(848,190))]
tr={"ty":"tr","p":{"a":0,"k":[0,0]},"a":{"a":0,"k":[0,0]},"s":{"a":0,"k":[100,100]},"r":{"a":0,"k":0},"o":{"a":0,"k":100}}
def hexc(h): return [int(h[i:i+2],16)/255 for i in (0,2,4)]
left={"ty":"gr","nm":"left","it":[shape(L),{"ty":"fl","c":{"a":0,"k":hexc("6C5CE0")+[1]},"o":{"a":0,"k":100},"r":1,"nm":"fill"},tr]}
g=[]
for off,c in ((0,"725CFF"),(0.66,"526CFF"),(1,"22D3EE")): g+= [off]+hexc(c)
right={"ty":"gr","nm":"right","it":[shape(R),{"ty":"gf","nm":"gradient","o":{"a":0,"k":100},"r":1,"t":1,
  "g":{"p":3,"k":{"a":0,"k":g}},"s":{"a":0,"k":T((734,210))},"e":{"a":0,"k":T((512,760))}},tr]}
ease_o={"x":[0.33],"y":[0]}; ease_i={"x":[0.67],"y":[1]}
ease2_o={"x":[0.33,0.33],"y":[0,0]}; ease2_i={"x":[0.67,0.67],"y":[1,1]}
layer={"ddd":0,"ind":1,"ty":4,"nm":"logo","sr":1,
 "ks":{"o":{"a":1,"k":[{"t":0,"s":[100],"o":ease_o,"i":ease_i},{"t":75,"s":[90],"o":ease_o,"i":ease_i},{"t":150,"s":[100]}]},
       "r":{"a":0,"k":0},"p":{"a":0,"k":[256,128]},"a":{"a":0,"k":[256,128]},
       "s":{"a":1,"k":[{"t":0,"s":[100,100],"o":ease2_o,"i":ease2_i},{"t":75,"s":[104,104],"o":ease2_o,"i":ease2_i},{"t":150,"s":[100,100]}]}},
 "ao":0,"shapes":[left,right],"ip":0,"op":150,"st":0,"bm":0}
d={"v":"5.7.0","fr":60,"ip":0,"op":150,"w":512,"h":260,"nm":"valkyos_welcome","ddd":0,"assets":[],"layers":[layer],"markers":[]}
open(sys.argv[1],'w').write(json.dumps(d,separators=(',',':')))
print(len(json.dumps(d)))
