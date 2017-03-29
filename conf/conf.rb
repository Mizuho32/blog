require 'yaml'

PROJ_ROOT = (Pathname(__FILE__ ).dirname + "../").expand_path.to_s
REPOS_ROOT = PROJ_ROOT + "/repos"
ART_ROOT = PROJ_ROOT + "/articles"
CONF_ROOT = PROJ_ROOT + "/conf"

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
