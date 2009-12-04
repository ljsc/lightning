#This class maps completions to their full paths for the given blobs
class Lightning
  class CompletionMap
    def self.ignore_paths
      unless @ignore_paths
        @ignore_paths = []
        @ignore_paths += Lightning.config[:ignore_paths] if Lightning.config[:ignore_paths]
      end
      @ignore_paths
    end

    attr_accessor :map
    attr_reader :alias_map
    
    def initialize(*globs)
      options = globs[-1].is_a?(Hash) ? globs.pop : {}
      globs.flatten!
      @map = create_map_for_globs(globs)
      @alias_map = (options[:global_aliases] || {}).merge(options[:aliases] || {})
    end
    
     def [](completion)
       @map[completion] || @alias_map[completion]
     end
     
     def keys
       (@map.keys + @alias_map.keys).uniq
     end
    
    #should return hash
    def create_map_for_globs(globs)
      path_hash = {}
      ignore_paths = ['.', '..'] + self.class.ignore_paths
      globs.each do |d|
        Dir.glob(d, File::FNM_DOTMATCH).each do |e|
          basename = File.basename(e)
          unless ignore_paths.include?(basename)
            #save paths of duplicate basenames to process later
            if path_hash.has_key?(basename)
              if path_hash[basename].is_a?(Array)
                path_hash[basename] << e
              else
                path_hash[basename] = [path_hash[basename], e]
              end
            else
              path_hash[basename] = e
            end
          end
        end
      end
      map_duplicate_basenames(path_hash)
      path_hash
    end
    
    #map saved duplicates
    def map_duplicate_basenames(path_hash)
      path_hash.select {|k,v| v.is_a?(Array)}.each do |key,paths|
        paths.each do |e|
          new_key = "#{key}/#{File.dirname(e)}"
          path_hash[new_key] = e
        end
        path_hash.delete(key)
      end
    end
    
  end
end
