require_relative './script_util.rb'

FILE_PATH = File.expand_path('../../data_v2/sets.json', __FILE__)
EXCLUDED_SETS = %w[Vanguard]
THREAD_POOL_SIZE = 25

def extract_attrs(set_names)
  set_names.each_slice(THREAD_POOL_SIZE).map do |slice|
    slice.map do |set_name|
      Thread.new do
        set_page = get "http://gatherer.wizards.com/Pages/Search/Default.aspx?set=[%22#{set_name}%22]"
        set_img = set_page.css('img[src^="../../Handlers/Image.ashx?type=symbol&set="]').first
        set_code = set_img.attr(:src)[/set=(\w+)/, 1].downcase
        { 'name' => set_name, 'gatherer_code' => set_code }
      end
    end.map(&:join).map(&:value) # Wait for threads to finish and grab results
  end.flatten(1) # Flatten slices
end

def merge(set_json)
  existing = Hash[read(FILE_PATH).map{|s| [s['name'], s]}]
  set_json.each do |set|
    existing[set['name']] = (existing[set['name']] || {}).merge(set)
  end
  existing.values
end

page = get "http://gatherer.wizards.com/Pages/Default.aspx"
sets = page.css('select[name$="setAddText"] option').map(&:text)
sets.reject!(&:empty?).reject!{|name| name.in?(EXCLUDED_SETS)}

write FILE_PATH, merge(extract_attrs(sets)).sort_by{|set| set['name']}
