from pathlib import Path
import json,sys,shutil
root=Path(__file__).resolve().parents[2]
source=Path(sys.argv[1]);device=sys.argv[2];out=root/'artifacts/flags-oct19/store-10/assets'/device
langs=json.loads((Path(__file__).parent/'copy.json').read_text())
seen=set()
for test in json.loads((source/'manifest.json').read_text()):
 for attachment in test.get('attachments',[]):
  name=attachment.get('suggestedHumanReadableName','')
  for lang in langs:
   prefix='store-'+lang+'-'
   if name.startswith(prefix):
    scene=name[len(prefix):].split('_0_')[0]
    dest=out/lang;dest.mkdir(parents=True,exist_ok=True)
    shutil.copy(source/attachment['exportedFileName'],dest/(scene+'.png'));seen.add((lang,scene));break
assert len(seen)==80,(device,len(seen))
print(device,'80 real localized screenshots extracted')
