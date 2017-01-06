require 'celluloid/current'

class GathererSetScraper
  WORKER_POOL_SIZE = 25

  def self.run
    page = get "http://gatherer.wizards.com/Pages/Default.aspx"
    set_names = page.css('select[name$="setAddText"] option').map(&:text)
    set_names.reject!(&:empty?).reject!{|name| name.in?(EXCLUDED_SETS)}

    worker_pool = CelluloidWorker.pool(size: WORKER_POOL_SIZE)
    set_json = set_names.map do |set_name|
      worker_pool.future.fetch_data(set_name)
    end.map(&:value)

    self.merge(set_json).sort_by{|set| set['name']}
  end

  def self.merge(set_json)
    existing = Hash[read(SET_JSON_FILE_PATH).map{|s| [s['name'], s]}]
    set_json.each do |set|
      existing[set['name']] = (existing[set['name']] || {}).merge(set)
    end
    existing.values
  end

  class CelluloidWorker
    include Celluloid

    def fetch_data(set_name)
      set_page = get "http://gatherer.wizards.com/Pages/Search/Default.aspx?set=[%22#{set_name}%22]"
      set_img = set_page.css('img[src^="../../Handlers/Image.ashx?type=symbol&set="]').first
      set_code = set_img.attr(:src)[/set=(\w+)/, 1].downcase
      { 'name' => SET_NAME_OVERRIDES[set_name] || set_name,
        'code' => SET_CODE_OVERRIDES[set_code] || set_code }
    end
  end
end
