require 'yaml'
require 'pathname'

REPOS_DIR = "repos"
ARTS_DIR  = "articles"
CONF_DIR  = "conf"
CACHE_DIR = "cache"

PROJ_ROOT         = (Pathname(__FILE__ ).dirname + "../").expand_path.to_s
REPOS_ROOT        = PROJ_ROOT + "/#{REPOS_DIR}"
ART_ROOT          = PROJ_ROOT + "/#{ARTS_DIR}"
CONF_ROOT         = PROJ_ROOT + "/#{CONF_DIR}"
SEARCH_CACHE_ROOT = PROJ_ROOT + "/#{CACHE_DIR}/search"

FTYPES_FILE = CONF_ROOT + "/ftypes.yaml"
# regex key to IGNORECASE, $ match
(->(){
  raw = []
  tmp = YAML.load_file(FTYPES_FILE)
  tmp
    .each{|type, pat|
      raw += pat.keys
      tmp[type] = Hash[
        pat.map{|reg, lang| [Regexp.new("\\.#{reg.source}$", Regexp::IGNORECASE), lang]}
      ]
    }
  FTYPES = tmp
  FTYPES_RAW = raw
}).()
