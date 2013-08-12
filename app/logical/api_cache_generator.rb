class ApiCacheGenerator
  def generate_tag_cache
    cache_dir = "#{Rails.root}/public/cache"
    File.open("#{cache_dir}/tags.json", "w") do |f|
      f.print("[")
      Tag.without_timeout do
        Tag.find_each do |tag|
          next unless tag.post_count > 0
          hash = {
            "name" => tag.name,
            "id" => tag.id,
            "created_at" => tag.created_at,
            "post_count" => tag.post_count,
            "category" => tag.category
          }
          f.print(hash.to_json)
          f.print(", ")
        end
      end
      f.seek(-2, IO::SEEK_END)
      f.print("]\n")
    end
    Zlib::GzipWriter.open("#{cache_dir}/tags.json.gz") do |gz|
      gz.write(IO.binread("#{cache_dir}/tags.json"))
      gz.close
    end
    RemoteFileManager.new("#{cache_dir}/tags.json").distribute
    RemoteFileManager.new("#{cache_dir}/tags.json.gz").distribute
  end
end
