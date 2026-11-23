import re,struct,sys
t=open(sys.argv[1],'rb').read().decode('latin1').split('\n')
blobs=[];cur=None
for l in t:
    m=re.match(r'EVENTS: size (\d+)',l)
    if m: cur=bytearray(); blobs.append((int(m.group(1)),cur)); continue
    m=re.match(r'EVENTS: ([0-9a-f]{4}):((?: [0-9a-f]{2})+)',l)
    if m and cur is not None: cur.extend(bytes.fromhex(m.group(2).replace(' ','')))
def parse(raw):
    out=[]; p=0
    while p+4<=len(raw):
        i,fl,n=struct.unpack_from('<BBH',raw,p); p+=4
        es=8 if fl==0 else 4
        v=raw[p:p+es*n]; p+=es*n; out.append((i,fl,n,v))
    return out
for sz,b in blobs:
    raw=bytes(b); p=0
    if not raw: continue
    print('=== pull',sz)
    while p+8<=len(raw):
        k,l=struct.unpack_from('<II',raw,p); body=raw[p+8:p+8+l]
        if k==1: print('  ctrl',body.hex(' '))
        else:
            f={i:(fl,v) for i,fl,n,v in parse(body[4:])}
            def g(i):
                if i not in f: return None
                fl,v=f[i]
                if fl==0xc0: return ' '.join('%g'%struct.unpack('>f',v[q:q+4])[0] for q in range(0,len(v),4))
                if fl==0: return '%x'%struct.unpack('<Q',v[:8])[0]
                return '%x'%struct.unpack('<I',v[:4])[0]
            print('  event len',l,'35=',g(0x35),'36=',g(0x36),'37=',g(0x37),'screen',g(0x38),'win',g(0x39),'t',g(0x3a),'wnd',g(0x33),'ev',g(0x34),'flags',g(0x29),'ac',g(0xac))
        p+=8+l
