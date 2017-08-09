require 'yaml'

REPOS_DIR = "test_repos"

PROJ_ROOT = (Pathname(__FILE__).dirname.expand_path).to_s
REPOS_ROOT = PROJ_ROOT + "/#{REPOS_DIR}"
FTYPES = YAML.load_file(PROJ_ROOT + "/../conf/ftypes.yaml")

GIT_REMOTE = "origin"
