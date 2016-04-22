from .docker import *
#
INSTALLED_APPS += ["taiga_contrib_gogs"]
PROJECT_MODULES_CONFIGURATORS["gogs"] = "taiga_contrib_gogs.services.get_or_generate_config"
