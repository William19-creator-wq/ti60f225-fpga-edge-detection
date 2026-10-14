from pathlib import Path
from typing import Dict, List

from efx_ipmgr.util import FileSetType
from common.ip_migration_common.ip_migration_api import IPMigrationApi
from common.ip_migration_common.ip_migration_model import IPMigrationModel
from common.ip_migration_common.ip_migration_interface import IPMigrationInterface
from common.ip_migration_common.ip_migration_setting import IPMigrationSetting
from common.ip_migration_common.ip_migration_exception import IPMigrationIncompatiblityException

class IPMigrationHandling(IPMigrationInterface):

    def __init__(self, settings_json_path: str) -> None:
        self.settings_json_path = Path(settings_json_path)
        self.ip_migration_setting = None
        self.ip_migration_api = IPMigrationApi()

        self.ip_migration_setting = IPMigrationSetting.load(self.settings_json_path)

        self.setup_ip_migration_model()

    def setup_ip_migration_model(self):
        self.ip_migration_model = IPMigrationModel()

        self.ip_migration_model.set_rename_param_map(
            from_ver="0.0",
            to_ver="1.3",
            rename_map={
                "DEPTH": "DEPTH_2",
                "PROG_FULL_NEGATE": "PFN_INTERNAL",
                "PROG_EMPTY_ASSERT": "PEA_INTERNAL",
                "PROG_EMPTY_NEGATE": "PEN_INTERNAL",
                "DEVICE_FAMILY": "FAMILY",
            },
        )

        self.ip_migration_model.set_reassign_param_value_map(
            from_ver="1.3",
            to_ver="5.0",
            param_name_to_reassign_value_map={
                "MODE": {"0": '"STANDARD"', "1": '"FWFT"'},
                "PROGRAMMABLE_FULL": {
                    "0": '"NONE"',
                    "1": '"STATIC_SINGLE"',
                    "2": '"STATIC_DUAL"',
                },
                "PROGRAMMABLE_EMPTY": {
                    "0": '"NONE"',
                    "1": '"STATIC_SINGLE"',
                    "2": '"STATIC_DUAL"',
                },
                "FAMILY": {"0": '"TRION"', "1": '"TITANIUM"'},
            },
        )

    # Overload. MUST BE IMPLEMENTED
    def migrate_params(self) -> Dict[str, str]:
        params = self.ip_migration_setting.params
        curr_version = self.ip_migration_setting.vlnv.version

        migrated_params_dict, latest_version = self.ip_migration_api.migrate_params_return_version(
            self.ip_migration_model, params, curr_version
        )

        from_ver = "5.0"
        to_ver = "7.0"
        latest_int_version = self.ip_migration_api.get_version_from_str(latest_version)
        if self.ip_migration_api.is_curr_version_within_version_range(latest_int_version, from_ver, to_ver):
            if curr_version == "6.0":
                if migrated_params_dict["PROGRAMMABLE_FULL"] == "\"NONE\"":
                    migrated_params_dict["PROG_FULL_ASSERT"] = "4"
                else:
                    migrated_params_dict["PROG_FULL_ASSERT"] = str(2**int(migrated_params_dict["DEPTH_2"])-2 )

                if migrated_params_dict["PROGRAMMABLE_FULL"] == "\"STATIC_DUAL\"":
                    migrated_params_dict["PFN_INTERNAL"] = str(int(migrated_params_dict["PROG_FULL_ASSERT"])-1)
                else:
                    migrated_params_dict["PFN_INTERNAL"] = "3"


        return migrated_params_dict

    # Overload. MUST BE IMPLEMENTED
    def migrate_filesets(self) -> Dict[str, List[str]]:
        fileset_map = self.ip_migration_setting.fileset_map
        curr_version = self.ip_migration_setting.vlnv.version

        migrated_filesets = self.ip_migration_api.migrate_filesets(
            self.ip_migration_model, fileset_map, curr_version
        )

        return migrated_filesets

