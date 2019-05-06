Dir.glob(File.expand_path(File.join('..', 'util', '*.rb'), __FILE__), &method(:require))

(puts "usage: rake comments set_code [...]"; exit(0)) if ARGV.none?
ALL_SETS = read(SET_JSON_FILE_PATH)
SETS_TO_DUMP = ALL_SETS.select{|s| s['code'].in? ARGV}
