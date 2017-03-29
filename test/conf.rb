require 'yaml'

PROJ_ROOT = (Pathname(__FILE__).dirname.expand_path).to_s
FTYPES = YAML.load_file(PROJ_ROOT + "/../conf/ftypes.yaml")
