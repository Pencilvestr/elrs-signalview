"""Headless adapter for the exact installed x64 Companion simulator DLL build.

Uses exported simulator methods, not OS input or desktop capture. Runs only in a
dedicated subprocess; native C++ ABI bindings are guarded by a SHA-256 manifest.
"""
from pathlib import Path
import ctypes as C
import os, sys, time, json, hashlib, argparse, shutil, re
from PIL import Image

HERE=Path(__file__).resolve().parent
PROJECT=HERE.parents[1]
RADIOS={'tx16smk3':(800,480),'tx16s':(480,272),'tx15':(480,320),'nv14':(320,480),'pa01':(320,240)}
P=C.c_void_p

def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('--radio',choices=RADIOS,required=True)
    parser.add_argument('--run-dir',required=True)
    parser.add_argument('--bootstrap',action='store_true')
    parser.add_argument('--settings-probe',action='store_true')
    parser.add_argument('--reuse-settings',action='store_true')
    parser.add_argument('--soak-seconds',type=int,default=0)
    parser.add_argument('--zone-probe',action='store_true')
    parser.add_argument('--demo',action='store_true',help='Capture a continuous documentation animation')
    parser.add_argument('--footer',nargs=4,metavar='ELRS_SOURCE',help='Set four ELRS footer sources')
    parser.add_argument('--source-picker-probe',action='store_true',help='Open first MK3 footer source picker in settings')
    parser.add_argument('--picker-select-power',action='store_true',help='Select visible TPWR in the MK3 picker probe')
    parser.add_argument('--profile',action='store_true',help='Measure Lua instruction budget and VM heap without functional-test overhead')
    parser.add_argument('--widget-source',help='Alternate local Lua for controlled baseline comparisons')
    parser.add_argument('--reference-source',help='Enable deterministic drawing/state comparison against this local Lua')
    parser.add_argument('--antenna-preview',choices=['single1','single2','dual'],help='Capture full-history antenna layout with synthetic telemetry')
    parser.add_argument('--antenna-mode',choices=['Auto','Single','Dual'],help='Persist antenna CHOICE in the model fixture')
    parser.add_argument('--antenna-tests',action='store_true',help='Run bounded antenna detection/rendering cases')
    parser.add_argument('--rf-tests',action='store_true',help='Run versioned RF label and layout cases')
    parser.add_argument('--rf-preview',action='store_true',help='Capture RF mode transitions and a full history')
    parser.add_argument('--elrs-major',type=int,choices=[3,4],default=4)
    parser.add_argument('--antenna-settings-probe',action='store_true',help='Scroll native MK3 settings to antenna dropdown')
    parser.add_argument('--antenna-picker-probe',action='store_true',help='Open native antenna choices after scrolling')
    parser.add_argument('--antenna-select-dual',action='store_true',help='Select Dual in the observed MK3 antenna dropdown')
    args=parser.parse_args()
    width,height=RADIOS[args.radio]
    run=Path(args.run_dir).resolve()
    if not run.is_relative_to(PROJECT.resolve()):raise RuntimeError('Run directory must remain in this project')
    run.mkdir(parents=True,exist_ok=True)
    manifest=json.loads((HERE/'binding-manifest.json').read_text())
    bindir=Path(os.environ.get('SIGNALVIEW_RUNTIME', str(PROJECT/manifest['library_directory'])))
    for name in manifest['sha256']:
        actual=hashlib.sha256((bindir/name).read_bytes()).hexdigest()
        if actual!=manifest['sha256'][name]:raise RuntimeError(f'Unreviewed binary build: {name}; refresh bindings before use')
    sd=run/'sd';settings=run/'settings'
    sd.mkdir(exist_ok=True);settings.mkdir(exist_ok=True)
    if not args.bootstrap and not args.reuse_settings:
        shutil.copytree(HERE/'fixtures'/args.radio,settings,dirs_exist_ok=True)
        model=settings/'MODELS/model1.yml'
        content=model.read_text()
        vals=[86,55,'Manual',-96,-101,2] if args.settings_probe else [80,60,'Auto',-98,-103,1]
        footer=args.footer or ['NONE']*4
        telemetry=content.split('telemetrySensors:',1)[1]
        sensor_slots={name:int(slot) for slot,name in re.findall(
            r'(?ms)^   (\d+):\s*\n(?:(?!^   \d+:).)*?^      label: "([^"]+)"',telemetry)}
        vals+=footer
        if args.antenna_mode:vals.append(['Auto','Single','Dual'].index(args.antenna_mode)+1)
        entries=''
        for i,v in enumerate(vals):
            if i==10:
                typ='Unsigned';field='unsignedValue';val=str(v)
            elif i>=6:
                typ='Source';field='source'
                val=f'tele({sensor_slots[v]})' if v in sensor_slots else v
            else:
                typ='String' if isinstance(v,str) else 'Signed'
                field='stringValue' if isinstance(v,str) else 'signedValue'
                val='"'+v+'"' if isinstance(v,str) else str(v)
            entries+=f'                     {i}:\n                        type: {typ}\n                        value:\n                           {field}: {val}\n'
        content=content.replace('               widgetData: \n','               widgetData: \n                  options:\n'+entries,1)
        model.write_text(content)
    # The production widget file is copied unchanged.
    target=sd/'WIDGETS/SignalView';target.mkdir(parents=True,exist_ok=True)
    source=Path(args.widget_source).resolve() if args.widget_source else PROJECT/'WIDGETS/SignalView/main.lua'
    if not source.is_relative_to(PROJECT.resolve()):raise RuntimeError('Widget source must remain in this project')
    shutil.copyfile(source,target/'main.lua')
    lab=sd/'WIDGETS/LabTest';lab.mkdir(parents=True,exist_ok=True)
    shutil.copyfile(HERE/'instrument.lua',lab/'main.lua')
    shutil.copyfile(HERE/'threshold-tests.lua',lab/'threshold-tests.lua')
    shutil.copyfile(HERE/'smoothing-tests.lua',lab/'smoothing-tests.lua')
    shutil.copyfile(HERE/'footer-tests.lua',lab/'footer-tests.lua')
    shutil.copyfile(HERE/'antenna-tests.lua',lab/'antenna-tests.lua')
    shutil.copyfile(HERE/'rf-tests.lua',lab/'rf-tests.lua')
    (lab/'rf-enabled.lua').write_text('return '+('true' if args.rf_tests else 'false')+'\n')
    (lab/'antenna-enabled.lua').write_text('return '+('true' if args.antenna_tests else 'false')+'\n')
    shutil.copyfile(HERE/'profile.lua',lab/'profile.lua')
    (lab/'profile-enabled.lua').write_text('return '+('true' if args.profile else 'false')+'\n')
    (lab/'reference-enabled.lua').write_text('return '+('true' if args.reference_source else 'false')+'\n')
    shutil.copyfile(HERE/'equivalence-tests.lua',lab/'equivalence-tests.lua')
    if args.reference_source:
        reference=Path(args.reference_source).resolve()
        if not reference.is_relative_to(PROJECT.resolve()):raise RuntimeError('Reference must remain in this project')
        shutil.copyfile(reference,lab/'reference.lua')
    os.add_dll_directory(str(bindir))
    core=C.CDLL(str(bindir/'Qt6Core.dll'))
    sim=C.CDLL(str(bindir/f'libedgetx-{args.radio}-simulator.dll'))
    def fn(dll,name,params,ret=None):
        f=getattr(dll,name);f.argtypes=params;f.restype=ret;return f
    # Oversized aligned host storage for QCoreApplication; no GUI window is created.
    application=C.create_string_buffer(65536)
    argc=C.c_int(1);argument=C.create_string_buffer(b'ELRS-native-test')
    argv=(C.c_char_p*2)(C.cast(argument,C.c_char_p),None)
    fn(core,'??0QCoreApplication@@QEAA@AEAHPEAPEADH@Z',[P,C.POINTER(C.c_int),C.POINTER(C.c_char_p),C.c_int])(application,C.byref(argc),argv,0x060000)
    factory=fn(sim,'registerSimu',[],P)()
    vtable=C.cast(factory,C.POINTER(P))[0]
    # MSVC x64 SimulatorFactory: deleting destructor, name, type, create.
    create=C.cast(vtable,C.POINTER(P))[3]
    obj=C.CFUNCTYPE(P,P)(create)(factory)
    strings=[]
    def qstring(value):
        buf=C.create_string_buffer(64)
        fn(core,'??0QString@@QEAA@PEBD@Z',[P,C.c_char_p])(buf,str(value).encode())
        strings.append(buf);return buf
    fn(sim,'?setSdPath@OpenTxSimulator@@UEAAXAEBVQString@@0@Z',[P,P,P])(obj,qstring(sd),qstring(settings))
    fn(sim,'?init@OpenTxSimulator@@UEAAXXZ',[P])(obj)
    connection=C.create_string_buffer(64)
    # Follow Companion's normal LCD-change handshake. Acknowledge only an
    # emitted completed frame, never blindly during display initialization.
    fn(core,'?connect@QObject@@SA?AVConnection@QMetaObject@@PEBV1@PEBD01W4ConnectionType@Qt@@@Z',
       [P,P,C.c_char_p,P,C.c_char_p,C.c_int],P)(connection,obj,b'2lcdChange(bool)',obj,b'1lcdFlushed()',0)
    fn(sim,'?start@OpenTxSimulator@@UEAAXPEBD_N@Z',[P,C.c_char_p,C.c_bool])(obj,None,True)
    process=fn(core,'?processEvents@QCoreApplication@@SAXV?$QFlags@W4ProcessEventsFlag@QEventLoop@@@@@Z',[C.c_int])
    lcd=fn(sim,'?getLcd@OpenTxSimulator@@UEAAPEAEXZ',[P],P)
    touch=fn(sim,'?touchEvent@OpenTxSimulator@@UEAAXHHH@Z',[P,C.c_int,C.c_int,C.c_int])
    key=fn(sim,'?setKey@OpenTxSimulator@@UEAAXE_N@Z',[P,C.c_uint8,C.c_bool])
    send=fn(sim,'?sendInternalModuleTelemetry@OpenTxSimulator@@UEAAXEVQByteArray@@@Z',[P,C.c_uint8,P])
    ba_ctor=fn(core,'??0QByteArray@@QEAA@PEBD_J@Z',[P,C.c_char_p,C.c_int64])
    streaming=False
    version_sent=False
    stats=[-62,-65,99,8,0,29,7,-75,97,6]
    def send_packet(payload):
        crc=0
        for b in payload:
            crc^=b
            for _ in range(8):crc=((crc<<1)^0xd5)&255 if crc&128 else (crc<<1)&255
        packet=bytes([0xc8,len(payload)+1])+payload+bytes([crc])
        ba=C.create_string_buffer(64)
        ba_ctor(ba,packet,len(packet))
        # By-value QByteArray is destroyed by the callee in the MSVC x64 ABI.
        send(obj,2,ba)
    def inject():
        nonlocal version_sent
        if args.antenna_preview=='single1':stats[1]=0
        elif args.antenna_preview=='single2':stats[0]=0;stats[4]=1
        send_packet(bytes([0x14]+[v&255 for v in stats]))
        if not version_sent:
            send_packet(bytes([0x29,0xEA,0xEE])+b'Sim ELRS\0ELRS'+bytes([0,0,0,0,0,args.elrs_major,0,0,0,0]))
            version_sent=True
    def wait(seconds):
        deadline=time.monotonic()+seconds;next_packet=0
        while time.monotonic()<deadline:
            now=time.monotonic()
            if streaming and now>=next_packet:inject();next_packet=now+.1
            process(0)
            time.sleep(.005)
    def capture(name):
        raw=C.string_at(lcd(obj),width*height*2)
        Image.frombytes('RGB',(width,height),raw,'raw','BGR;16').save(run/f'{name}.png')
        print('CAPTURE|'+name,flush=True)
    def tap(x,y,duration=.12):
        touch(obj,1,int(x),int(y));wait(duration);touch(obj,0,int(x),int(y));wait(.4)
    def press(index,duration=.12):
        key(obj,index,True);wait(duration);key(obj,index,False);wait(.4)
    try:
        if args.bootstrap:
            wait(1)
            key(obj,0,True);wait(.12);key(obj,0,False)
            wait(5)
            capture('bootstrap')
            fn(sim,'?stop@OpenTxSimulator@@UEAAXXZ',[P])(obj)
            sys.stdout.flush();sys.stderr.flush();os._exit(0)
        wait(6)
        if args.settings_probe:
            tap(width/2,height/2,1.1)
            tap(width/2,height/2+42)
            capture('settings-reopened' if args.reuse_settings else 'settings-saved')
            if args.antenna_settings_probe:
                assert args.radio=='tx16smk3','Antenna settings coordinates target MK3'
                touch(obj,1,620,380);wait(.1)
                for y in range(360,119,-20):touch(obj,2,620,y);wait(.05)
                touch(obj,0,620,120);wait(.8)
                capture('antenna-settings')
                if args.antenna_picker_probe:
                    tap(450,400)
                    capture('antenna-choices')
                    if args.antenna_select_dual:
                        tap(310,287)
                        capture('antenna-choice-changed')
            if args.source_picker_probe:
                assert args.radio=='tx16smk3','Picker coordinates target the MK3'
                # Bring Footer 1 fully inside the scrollable settings pane.
                touch(obj,1,620,380);wait(.1)
                for y in range(360,259,-20):touch(obj,2,620,y);wait(.05)
                touch(obj,0,620,260);wait(2)
                capture('footer-settings')
                tap(425,210)
                tap(205,255)  # Telemetry category in EdgeTX's native source picker.
                capture('footer-source-picker')
                if args.picker_select_power:
                    for _ in range(2):
                        touch(obj,1,550,410);wait(.1)
                        for y in range(390,89,-20):touch(obj,2,550,y);wait(.05)
                        touch(obj,0,550,90);wait(2)
                    capture('footer-picker-scrolled')
                    tap(455,160)
                    capture('footer-picker-changed')
            fn(sim,'?stop@OpenTxSimulator@@UEAAXXZ',[P])(obj)
            sys.stdout.flush();sys.stderr.flush();os._exit(0)
        capture('01-no-data-preview')
        if args.radio=='pa01':
            # PA01 has no touch screen: long ENTER selects widgets, short ENTER
            # opens the selected widget's menu, then ENTER chooses full screen.
            press(2,1.1);press(2)
            capture('02-widget-menu')
            press(2)
        else:
            tap(width/2,height/2,1.1)
            capture('02-widget-menu')
            tap(width/2,height/2-5)
        wait(.5)
        capture('03-no-data-fullscreen')
        if args.demo:
            import math
            print('PHASE|demo',flush=True)
            # Forty seconds from disconnected startup through connection,
            # degradation and recovery. No warm-up or fabricated zero readings.
            for index in range(160):
                streaming=index>=12
                if streaming:
                    elapsed=(index-12)/4
                    phase=max(0,min(1,(elapsed-5)/24))
                    degradation=(1-math.cos(phase*2*math.pi))/2
                    stats[0]=round(-62-43*degradation)
                    stats[1]=stats[0]-3
                    stats[2]=round(99-53*degradation)
                    stats[3]=round(9-14*degradation)
                    stats[5]=(29,28,27,28)[min(3,int(phase*4))] if phase<1 else 29
                    stats[6]=(2,3,7,4)[min(3,int(degradation*4))]
                    stats[8]=round(99-31*degradation)
                capture(f'demo-{index:03d}')
                wait(.25)
            (run/'demo-capture.json').write_text(json.dumps({
                'frames':160,'frame_duration_ms':250,'duration_ms':40000,
                'disconnected_frames':12,'firmware':'2.12.5','radio':args.radio,
                'widget_sha256':hashlib.sha256(source.read_bytes()).hexdigest(),
                'synthetic_telemetry':True,'synthetic_module_version':True},indent=2))
            print('PHASE|complete',flush=True)
            fn(sim,'?stop@OpenTxSimulator@@UEAAXXZ',[P])(obj)
            sys.stdout.flush();sys.stderr.flush();os._exit(0)
        print('PHASE|connected',flush=True)
        if args.elrs_major==3:stats[5]=9
        streaming=True;wait(3)
        capture('04-connected')
        if args.rf_preview:
            for mode in ([29,28,11,100,33,255] if args.elrs_major==4 else [9,8,2,7,19,13,255]):
                stats[5]=mode;wait(1);capture(f'rf-{mode}')
            stats[5]=29 if args.elrs_major==4 else 9
            wait(32);capture('rf-full-history')
            streaming=False;wait(12);capture('rf-stale')
            print('PHASE|complete',flush=True)
            fn(sim,'?stop@OpenTxSimulator@@UEAAXXZ',[P])(obj)
            sys.stdout.flush();sys.stderr.flush();os._exit(0)
        if args.antenna_preview:
            wait(32)
            capture('antenna-full-history')
            print('PHASE|complete',flush=True)
            fn(sim,'?stop@OpenTxSimulator@@UEAAXXZ',[P])(obj)
            sys.stdout.flush();sys.stderr.flush();os._exit(0)
        if args.reference_source or args.antenna_tests or args.rf_tests:
            # The oracle chunks comparisons across callbacks so test code does
            # not compete with a complete renderer for the Lua CPU budget.
            wait(75)
        if args.zone_probe:
            press(1,1.1);wait(.6)
            capture('zone-connected')
            wait(40)
            capture('zone-full-history')
            print('PHASE|complete',flush=True)
            fn(sim,'?stop@OpenTxSimulator@@UEAAXXZ',[P])(obj)
            sys.stdout.flush();sys.stderr.flush();os._exit(0)
        if args.soak_seconds:
            print('PHASE|soak',flush=True)
            start=time.monotonic()
            while time.monotonic()-start<args.soak_seconds:
                elapsed=time.monotonic()-start
                stats[0]=-62-int(elapsed)%45
                stats[1]=stats[0]-3
                stats[2]=99-int(elapsed)%55
                wait(.5)
            capture('04d-full-history')
            print('PHASE|connected',flush=True)
        print('PHASE|warning',flush=True)
        stats[:]=[-96,-97,72,1,0,29,7,-85,94,2]
        wait(2);capture('04b-warning')
        print('PHASE|critical',flush=True)
        stats[:]=[-103,-105,48,-4,1,29,7,-95,75,-3]
        wait(2);capture('04c-critical')
        print('PHASE|changed',flush=True)
        stats[:]=[-88,-90,74,-3,1,27,4,-91,80,-5]
        wait(1.5);capture('05-changed')
        print('PHASE|stale',flush=True)
        streaming=False;wait(12)
        capture('06-stale')
        print('PHASE|recovery',flush=True)
        stats[:]=[-62,-65,98,8,0,29,7,-75,97,6]
        streaming=True;wait(2)
        capture('07-recovery')
        print('PHASE|exit',flush=True)
        # EnumKeys KEY_EXIT=1 in the matched simulator source.
        press(1,1.1);wait(.6);capture('08-exit')
        print('PHASE|complete',flush=True)
    finally:
        fn(sim,'?stop@OpenTxSimulator@@UEAAXXZ',[P])(obj)
    sys.stdout.flush();sys.stderr.flush()
    # Qt native object teardown is isolated to this process, after explicit stop.
    os._exit(0)

if __name__=='__main__':main()

