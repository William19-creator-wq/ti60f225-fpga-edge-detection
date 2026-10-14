import os,sys,re,copy
import subprocess
import platform
import shutil
from PyQt5.QtWidgets import *
from PyQt5.QtGui import *
from PyQt5.QtCore import *
from PyQt5 import uic
from functools import partial
import json
import re
from math import *
import zipfile


class parameters_generator(QWidget):
    def __init__(self, params):
        super().__init__()
        self.po = []
        self.p2 = {}

        self.outdir = os.path.dirname(__file__)
        self.params = params
        root = QVBoxLayout()
        self.setLayout(root)
        root_tab = QTabWidget()
        top = QVBoxLayout()
        top.addWidget(root_tab)
        self.log = QTextBrowser()
        self.log.setMaximumHeight(96)

        top.addWidget(self.log)
        root.addLayout(top)
        # root.addWidget(root_tab)
        self.w_expand = QSizePolicy(1, 0)
        self.h_expand = QSizePolicy(0, 1)
        for group in self.params["groups"]:
            tree = QTreeWidget()
            # tree.header().setVisible(False)
            tree.setHeaderLabels(["Parameter", "Value", "Desc"])
            self.po.append({"type": "group", "kn": group["name"]})
            root_tab.addTab(tree, group["name"])
            self.map_params(tree, tree, group)
            tree.expandAll()
            tree.resizeColumnToContents(0)

        bottom = QHBoxLayout()
        gen = QPushButton("Generate")
        open = QPushButton("Open")
        flabel = QLabel("Output Dir: ")
        file = QLineEdit("")
        gen.clicked.connect(self.dump)

        def slot(file):
            self.outdir = QFileDialog.getExistingDirectory()
            file.setText(self.outdir)
        open.clicked.connect(partial(slot, file))

        open.setSizePolicy(QSizePolicy(0, 1))
        gen.setSizePolicy(QSizePolicy(0, 1))
        bottom.addWidget(flabel)
        bottom.addWidget(file)
        bottom.addWidget(open)
        bottom.addWidget(gen)
        root.addLayout(bottom)

    def add_item(self, tree, root, key, item):
        if "name" in item:
            name = item["name"]
            if len(name) == 0:
                name = key
        else:
            name = key
        item['kn'] = key
        self.po.append(item)
        self.p2[key] = item

        if "type" not in item:
            return

        child = None
        it = item['type']
        if it == "ref":
            if "visible" in item:
                child = QLineEdit()
                child.setReadOnly(True)
                child.setStyleSheet("font-weight: bold; color: black")
                item["show"] = lambda x: child.setText(str(x))
            else:
                return
        elif it == "n":
            child = QSpinBox()
            if "min" in item:
                child.setMinimum(item["min"])
            if "max" in item:
                child.setMaximum(item["max"])
            child.setValue(item["val"])

            def slot(item, value):
                item["val"] = value
            child.valueChanged.connect(partial(slot, item))

        elif it == "combo":
            child = QComboBox()
            for i in item["list"]:
                child.addItem(str(i))
            child.setCurrentIndex(item["val"])

            def slot(item, index):
                item["val"] = index
            child.currentIndexChanged.connect(partial(slot, item))

        if "edit" in item:
            child.setEnabled(item["edit"])
        citem = QTreeWidgetItem(root)

        name = QLabel(name)
        name.setStyleSheet("font-weight: bold; color: black")

        desc = QWidget()
        if "desc" in item:
            child.setObjectName(item['desc'])
            desc = QLabel()  # QTextBrowser()#QLabel(item['desc'])
            desc.setWordWrap(True)
            desc.setText(item['desc'])

        child.setSizePolicy(0, 0)
        tree.setItemWidget(citem, 1, child)
        tree.setItemWidget(citem, 2, desc)
        citem.setText(0, key)
        desc.setStyleSheet("padding-left: 10px")

    def map_params(self, tree, root, params):
        for item in params["children"]:
            self.add_item(root, tree, item, params["children"][item])

    def dump(self):
        info = self.params['info']
        oname = info['config']
        opath = self.outdir + "/" + info['ipname']
        package = info['package']
        self.log.clear()
        self.log.append("Create output dir...")
        if not os.path.exists(opath):
            os.mkdir(opath)

        self.log.append("unpack ip package...")
        with zipfile.ZipFile(package, 'r') as zip_ref:
            zip_ref.extractall(opath)

        ofile = open(opath+"/" + oname, "w")
        ofstr = ""
        self.log.append("Generate params...")
        items = copy.deepcopy(self.po)
        self.p3 = copy.deepcopy(self.p2)
        for item in items:
            tp = item['type']
            if tp == 'combo':
                val = item['list'][item['val']]
                item['val'] = val
                self.p3[item['kn']]['val'] = val
        for item in items:
            tp = item['type']
            #if tp == 'combo':
            #    val = item['list'][item['val']]
            #    item['val'] = val
            if tp == 'ref':
                val = item['val']
                res = val.replace("${", "self.p3['").replace("}", "']['val']").replace("/", "//")
                try:
                    val = eval(res)
                    item['val'] = val
                    print(item['kn'], self.p3['DQ_WIDTH']['val'], res, val)
                    self.p3[item['kn']]['val'] = val
                    #ofstr += 'ref `define ' + \
                    #    item['kn'] + '\t' + str(val) + '\n'
                except:
                    item['val'] = val
                    item['eval'] = res

        for item in items:
            tp = item['type']
            if 'group' == tp:
                ofstr += "\n//"+item['kn']+'\n'
            elif 'n' == tp:
                ofstr += '`define ' + item['kn'] + '\t' + str(item['val'])+'\n'
            elif 'combo' == tp:
                val = item['val']
                val = str(val)
                if item['ctype'] == 's':
                    val = '"'+val+'"'
                ofstr += '`define ' + item['kn'] + '\t' + val + '\n'
            elif "ref" == tp:
                if 'lam' in item:
                    item['lam']("hello")
                if "eval" in item:
                    print(item, item['eval'], self.p3['DQS_WIDTH']['val'])
                    val = eval(item['eval'])
                    #item['val'] = val
                    print("0 =======> ", val)
                    ofstr += '`define ' + item['kn'] + '\t' + str(val) + '\n'
                else:
                    val = item['val']
                    ofstr += '`define ' + item['kn'] + '\t' + str(val) + '\n'
                    if 'show' in item:
                        item['show'](val)



        ofile.write(ofstr)
        ofile.close()
        self.log.append("Done.")


if __name__ == '__main__':
    app = QApplication(sys.argv)
    with open("ip/config.json", 'rb') as data:
        params = json.load(data)
    app.setStyle("Fusion")
    window = parameters_generator(params)
    window.resize(1024, 768)
    window.show()
    window.setWindowTitle(params["info"]["title"])
    logo_path = params["info"]["logo"]
    if os.path.exists(logo_path):
        window.setWindowIcon()
    app.exec()
