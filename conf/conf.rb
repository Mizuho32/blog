require 'yaml'

PROJ_ROOT = (Pathname(__FILE__ ).dirname + "../").expand_path.to_s
REPOS_ROOT = PROJ_ROOT + "/repos"
ART_ROOT = PROJ_ROOT + "/articles"
FTYPES = YAML.load_file(PROJ_ROOT + "/conf/ftypes.yaml")
