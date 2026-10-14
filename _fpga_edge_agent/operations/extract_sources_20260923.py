from pathlib import Path
import json, subprocess,hashlib,sys
from pypdf import PdfReader
sys.stdout.reconfigure(encoding="utf8")
root=Path(r"D:\大三\FPGA_verilog")
out=root/"_fpga_edge_agent/reports/audit/environment_20260923/pdf_evidence"
out.mkdir(parents=True,exist_ok=True)
poppler=Path(r"C:\Users\34528\.cache\codex-runtimes\codex-primary-runtime\dependencies\native\poppler\Library\bin\pdftoppm.exe")
records=[]
for pdf in root.glob("*.pdf"):
 r=PdfReader(pdf)
 record={"name":pdf.name,"path":str(pdf),"sha256":hashlib.sha256(pdf.read_bytes()).hexdigest(),"pages":len(r.pages),"extraction":"all_pages_text_only; visual selections listed separately","chars":0}
 texts=[]
 for i,p in enumerate(r.pages,1):
  t=p.extract_text() or ""
  record["chars"]+=len(t);texts.append(f"\n===== PDF PAGE {i} =====\n"+t)
 (out/(pdf.stem+".txt")).write_text("".join(texts),encoding="utf8")
 records.append(record)
(out/"reading_ledger.json").write_text(json.dumps(records,ensure_ascii=False,indent=2),encoding="utf8")
print([(r["name"],r["pages"],r["chars"]) for r in records])
targets=[(next(root.glob("2026 FPGA*pdf")),25,"track4_base"),(next(root.glob("2026 FPGA*pdf")),26,"track4_advanced"),(root/"摄像头SC431HAI_数据手册_V1.1.pdf",16,"camera_mipi"),(root/"TI60F225I3-V4 DEMO板软硬件设计说明-260920.pdf",98,"v4_camera_chain")]
for p,page,name in targets:
 result=subprocess.run([str(poppler),"-f",str(page),"-l",str(page),"-scale-to","1500","-singlefile","-png",str(p),str(out/name)],stdout=subprocess.PIPE,stderr=subprocess.PIPE,timeout=40)
 print("render",name,result.returncode)

