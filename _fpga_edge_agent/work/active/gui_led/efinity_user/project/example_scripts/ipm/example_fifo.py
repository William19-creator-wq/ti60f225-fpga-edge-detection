######################################################################
# Copyright (C) 2017 - 2023 Efinix Inc. All rights reserved.
#
# No portion of this code may be reused, modified or
# distributed in any way without the expressed written
# consent of Efinix Inc.
#
# example_fifo.py : Demonstrates how to do create and generate FIFO IP
#
# Revision : 1.0 - Initial release
######################################################################

# Get access to useful python package
import os
import sys
from pathlib import Path

# Tell python where to get IP Manager's API package
ipm_home = os.environ['EFXIPM_HOME']
sys.path.append(ipm_home + "/bin")

from ipm_api_service.design import IPMDesignAPI
from ipm_api_service.projectxml import ProjectXML

efinity_user_dir = os.environ['EFINITY_USER_DIR']
is_verbose = True  # Set to True to see detail messages from API engine
device_name = "T20F256"  # Matches Device name from Efinity's Project Editor
family_name = "Trion"
project_path = Path(efinity_user_dir)/"project"/"helloworld"   # Full path to Efinity project folder
project_xml_path = Path(efinity_user_dir)/"project"/"helloworld"/"helloworld.xml"

design = IPMDesignAPI(device_name=device_name, family_name=family_name, project_path=project_path, is_verbose=is_verbose)
projectxml = ProjectXML(project_xml_path=project_xml_path, is_verbose=is_verbose)

_, lang = design.create_ip(
    module_name='fifo1',
    vendor = 'efinixinc.com',
    library = 'memory',
    name='efx_fifo_top')

# Config IP
configs = {
    # "DEPTH" : "140",
    "DATA_WIDTH" : "24"
}

design.config_ip(module_name='fifo1', configs = configs)

# Validate IP
success, validated_param_result, param_template_list = design.validate_ip(module_name='fifo1')

# Generate IP and update project XML
if( success ):
    result = design.generate_ip(module_name='fifo1')
    if not projectxml.is_ip_exists(module_name='fifo1'):
        projectxml.add_ip(module_name='fifo1')
        projectxml.save()
